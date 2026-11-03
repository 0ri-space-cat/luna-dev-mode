extends RefCounted
## One elemental state machine for every editable Entity. SpellService calls
## apply_element after a successful hit. HackableEntity reads movement_factor.
## All remaining durations are in simulated seconds, not wall-clock time.

signal reaction_triggered(details: Dictionary)
signal state_changed(entity_id: String, active: Dictionary)
signal fire_spread(details: Dictionary)

const MaterialProfile = preload("res://scripts/core/material_profile.gd")

const FORMAT_VERSION := 1
const MAX_ENTITIES := 96
const MAX_STATUS_FIELDS := 4
const BURN_TIME := 4.0
const CHILL_TIME := 4.0
const FROZEN_TIME := 1.8
const SHOCK_TIME := 1.25
const BURN_INTERVAL := 1.0
const BURN_DAMAGE := 2
const SPREAD_RADIUS := 2.8
const SPREAD_AT_REMAINING := 2.0
const MAX_NEW_FIRES_PER_TICK := 3
const MAX_BURNING := 12

var world
var effects
var surfaces
var _states: Dictionary = {}


func _init(world_registry, effect_engine, surface_service = null) -> void:
	world = world_registry
	effects = effect_engine
	surfaces = surface_service


func get_state(entity_id: String) -> Dictionary:
	return (_states.get(entity_id, {}) as Dictionary).duplicate(true)


func has_status(entity_id: String, status: String) -> bool:
	return (_states.get(entity_id, {}) as Dictionary).has(status)


func movement_factor(entity_id: String) -> float:
	var active: Dictionary = _states.get(entity_id, {})
	if active.has("SHOCK") or active.has("FROZEN"):
		return 0.0
	if active.has("CHILL"):
		return 0.45
	return 1.0


func apply_element(entity_id: String, element: String, spread_from: String = "") -> bool:
	var target: Node = world.get_entity(entity_id)
	if target == null or not target.has_method("get_parameter"):
		return false
	if not ["FIRE", "FROST", "STORM"].has(element):
		return false
	if _states.size() >= MAX_ENTITIES and not _states.has(entity_id):
		return false
	var active: Dictionary = get_state(entity_id)
	var reaction := ""
	match element:
		"FIRE":
			if surfaces != null and target is Node3D:
				var melted: int = surfaces.melt_at((target as Node3D).global_position)
				if melted > 0:
					reaction = "THAW"
			if active.has("CHILL") or active.has("FROZEN"):
				active.erase("CHILL")
				active.erase("FROZEN")
				reaction = "STEAM"
			# Steam extinguishes the cold; fire is shorter after melting ice.
			active["BURN"] = _burn(2.5 if reaction == "STEAM" else BURN_TIME, spread_from)
		"FROST":
			if active.has("BURN"):
				active.erase("BURN")
				reaction = "QUENCH"
				active["CHILL"] = _duration(2.5)
			elif active.has("CHILL") or active.has("FROZEN"):
				active.erase("CHILL")
				active["FROZEN"] = _duration(FROZEN_TIME)
				reaction = "FREEZE"
			else:
				active["CHILL"] = _duration(CHILL_TIME)
		"STORM":
			var duration := SHOCK_TIME
			if active.has("CHILL") or active.has("FROZEN"):
				var was_frozen: bool = active.has("FROZEN")
				active.erase("CHILL")
				active.erase("FROZEN")
				reaction = "SUPERCONDUCT"
				duration = 3.0 if was_frozen else 2.5
			elif active.has("BURN"):
				reaction = "OVERLOAD"
				var burning: Dictionary = active["BURN"]
				burning["interval"] = 0.5
				active["BURN"] = burning
			active["SHOCK"] = _duration(duration)
	_states[entity_id] = active
	if element == "FROST" and surfaces != null and target is Node3D:
		surfaces.add_ice_at((target as Node3D).global_position)
	state_changed.emit(entity_id, get_state(entity_id))
	if not reaction.is_empty():
		reaction_triggered.emit({
			"entity_id": entity_id, "reaction": reaction, "element": element
		})
	return true


func advance(delta: float) -> void:
	## Called by the world once per physics tick; no timers or Node ownership.
	if is_nan(delta) or is_inf(delta) or delta <= 0.0:
		return
	var elapsed: float = minf(delta, 1.0) # Avoid huge damage spikes on lag.
	var spread_candidates: Array[String] = []
	for entity_id in _states.keys():
		if world.get_entity(str(entity_id)) == null:
			_states.erase(entity_id)
			continue
		var active: Dictionary = _states[entity_id]
		var updated := false
		for status in active.keys():
			var item: Dictionary = active[status]
			var before: float = float(item["remaining"])
			var lived: float = minf(elapsed, before)
			item["remaining"] = maxf(0.0, before - elapsed)
			if status == "BURN" and lived > 0.0:
				if before > SPREAD_AT_REMAINING and float(item["remaining"]) <= SPREAD_AT_REMAINING:
					spread_candidates.append(str(entity_id))
				item["elapsed"] = float(item["elapsed"]) + lived
				var period: float = float(item["interval"])
				var pulses := 0
				while float(item["elapsed"]) + 0.00001 >= period and pulses < 4:
					item["elapsed"] = maxf(0.0, float(item["elapsed"]) - period)
					if world.get_entity(str(entity_id)) == null:
						break
					effects.apply_batch(
						[{"operation": "ADD", "parameter_id": "health", "value": -BURN_DAMAGE}],
						str(entity_id), "world:element", "element:BURN"
					)
					pulses += 1
			if float(item["remaining"]) <= 0.0:
				active.erase(status)
				updated = true
			else:
				active[status] = item
		if active.is_empty():
			_states.erase(entity_id)
		else:
			_states[entity_id] = active
		if updated:
			state_changed.emit(str(entity_id), get_state(str(entity_id)))
	# Resolve ignition after iterating the current state snapshot so new fires
	# never recursively spread within the same physics tick.
	var spread_count := 0
	for source_id in spread_candidates:
		if spread_count >= MAX_NEW_FIRES_PER_TICK:
			break
		if _try_spread_fire(source_id):
			spread_count += 1



func _try_spread_fire(source_id: String) -> bool:
	var source: Node = world.get_entity(source_id)
	if not (source is Node3D):
		return false
	var burning := 0
	for state_id in _states.keys():
		if (_states[state_id] as Dictionary).has("BURN"):
			burning += 1
	if burning >= MAX_BURNING:
		return false
	var origin: Vector3 = (source as Node3D).global_position
	var source_burn: Dictionary = (_states.get(source_id, {}) as Dictionary).get("BURN", {})
	var parent_id: String = str(source_burn.get("spread_from", ""))
	var options: Array[Dictionary] = world.candidates(source_id, origin, "ANY", SPREAD_RADIUS)
	options.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var da: float = origin.distance_squared_to(a["position"])
		var db: float = origin.distance_squared_to(b["position"])
		if is_equal_approx(da, db):
			return str(a["id"]) < str(b["id"])
		return da < db
	)
	for candidate in options:
		var next_id: String = str(candidate["id"])
		if next_id == parent_id or has_status(next_id, "BURN"):
			continue
		var node: Node = world.get_entity(next_id)
		if node == null or not node.has_method("get_parameter"):
			continue
		if not MaterialProfile.is_flammable(str(node.call("get_parameter", "material"))):
			continue
		if apply_element(next_id, "FIRE", source_id):
			fire_spread.emit({"from_id": source_id, "to_id": next_id})
			return true
	return false


func export_data() -> Dictionary:
	var saved := {}
	for entity_id in _states.keys():
		if world.get_entity(str(entity_id)) != null:
			saved[entity_id] = (_states[entity_id] as Dictionary).duplicate(true)
	return {"version": FORMAT_VERSION, "entities": saved}


func validate_data(data: Variant) -> bool:
	# Old snapshots without elemental state are read as empty state.
	if typeof(data) != TYPE_DICTIONARY:
		return false
	if data.is_empty():
		return true
	if data.size() != 2 or typeof(data.get("version")) not in [TYPE_INT, TYPE_FLOAT]:
		return false
	if int(data["version"]) != FORMAT_VERSION or typeof(data.get("entities")) != TYPE_DICTIONARY:
		return false
	var entries: Dictionary = data["entities"]
	if entries.size() > MAX_ENTITIES:
		return false
	for entity_id in entries.keys():
		if typeof(entity_id) != TYPE_STRING or not entity_id.is_valid_identifier():
			return false
		if typeof(entries[entity_id]) != TYPE_DICTIONARY:
			return false
		var active: Dictionary = entries[entity_id]
		if active.is_empty() or active.size() > MAX_STATUS_FIELDS:
			return false
		for status in active.keys():
			if status not in ["BURN", "CHILL", "FROZEN", "SHOCK"]:
				return false
			if typeof(active[status]) != TYPE_DICTIONARY:
				return false
			var item: Dictionary = active[status]
			var required: Array = ["remaining", "elapsed", "interval"] if status == "BURN" else ["remaining"]
			if status == "BURN" and item.has("spread_from"):
				if typeof(item["spread_from"]) != TYPE_STRING or not str(item["spread_from"]).is_valid_identifier():
					return false
				required.append("spread_from")
			if item.size() != required.size():
				return false
			for key in required:
				if key == "spread_from":
					continue
				if typeof(item.get(key)) not in [TYPE_FLOAT, TYPE_INT]:
					return false
				var value: float = float(item[key])
				if is_nan(value) or is_inf(value):
					return false
				if key == "remaining" and (value <= 0.0 or value > 10.0):
					return false
				if key == "elapsed" and (value < 0.0 or value > 1.0):
					return false
				if key == "interval" and value not in [0.5, 1.0]:
					return false
	return true


func import_data(data: Dictionary) -> bool:
	if not validate_data(data):
		return false
	var previous: Array = _states.keys()
	_states.clear()
	if not data.is_empty():
		for entity_id in data["entities"].keys():
			if world.get_entity(str(entity_id)) != null:
				_states[entity_id] = (data["entities"][entity_id] as Dictionary).duplicate(true)
	# Updating the world snapshot must also refresh visible state markers.
	for entity_id in previous:
		state_changed.emit(str(entity_id), get_state(str(entity_id)))
	for entity_id in _states.keys():
		if not previous.has(entity_id):
			state_changed.emit(str(entity_id), get_state(str(entity_id)))
	return true


func _duration(seconds: float) -> Dictionary:
	return {"remaining": seconds}


func _burn(seconds: float, spread_from: String = "") -> Dictionary:
	var state := {"remaining": seconds, "elapsed": 0.0, "interval": BURN_INTERVAL}
	if not spread_from.is_empty():
		state["spread_from"] = spread_from
	return state
