extends RefCounted
## One elemental state machine for every editable Entity. SpellService calls
## apply_element after a successful hit. HackableEntity reads movement_factor.
## All remaining durations are in simulated seconds, not wall-clock time.

signal reaction_triggered(details: Dictionary)
signal state_changed(entity_id: String, active: Dictionary)

const FORMAT_VERSION := 1
const MAX_ENTITIES := 96
const MAX_STATUS_FIELDS := 3
const BURN_TIME := 4.0
const CHILL_TIME := 4.0
const SHOCK_TIME := 1.25
const BURN_INTERVAL := 1.0
const BURN_DAMAGE := 2

var world
var effects
var _states: Dictionary = {}


func _init(world_registry, effect_engine) -> void:
	world = world_registry
	effects = effect_engine


func get_state(entity_id: String) -> Dictionary:
	return (_states.get(entity_id, {}) as Dictionary).duplicate(true)


func has_status(entity_id: String, status: String) -> bool:
	return (_states.get(entity_id, {}) as Dictionary).has(status)


func movement_factor(entity_id: String) -> float:
	var active: Dictionary = _states.get(entity_id, {})
	if active.has("SHOCK"):
		return 0.0
	if active.has("CHILL"):
		return 0.45
	return 1.0


func apply_element(entity_id: String, element: String) -> bool:
	var target: Node = world.get_entity(entity_id)
	if target == null or not target.has_method("get_parameter"):
		return false
	if not ["FIRE", "FROST", "STORM"].has(element):
		return false
	var active: Dictionary = get_state(entity_id)
	var reaction := ""
	match element:
		"FIRE":
			if active.has("CHILL"):
				active.erase("CHILL")
				reaction = "STEAM"
			# Steam extinguishes the cold; fire is shorter after melting ice.
			active["BURN"] = _burn(2.5 if reaction == "STEAM" else BURN_TIME)
		"FROST":
			if active.has("BURN"):
				active.erase("BURN")
				reaction = "QUENCH"
			active["CHILL"] = _duration(2.5 if reaction == "QUENCH" else CHILL_TIME)
		"STORM":
			var duration := SHOCK_TIME
			if active.has("CHILL"):
				active.erase("CHILL")
				reaction = "SUPERCONDUCT"
				duration = 2.5
			elif active.has("BURN"):
				reaction = "OVERLOAD"
				var burning: Dictionary = active["BURN"]
				burning["interval"] = 0.5
				active["BURN"] = burning
			active["SHOCK"] = _duration(duration)
	_states[entity_id] = active
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
			if status not in ["BURN", "CHILL", "SHOCK"]:
				return false
			if typeof(active[status]) != TYPE_DICTIONARY:
				return false
			var item: Dictionary = active[status]
			var required: Array = ["remaining", "elapsed", "interval"] if status == "BURN" else ["remaining"]
			if item.size() != required.size():
				return false
			for key in required:
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
	_states.clear()
	if data.is_empty():
		return true
	for entity_id in data["entities"].keys():
		if world.get_entity(str(entity_id)) != null:
			_states[entity_id] = (data["entities"][entity_id] as Dictionary).duplicate(true)
	return true


func _duration(seconds: float) -> Dictionary:
	return {"remaining": seconds}


func _burn(seconds: float) -> Dictionary:
	return {"remaining": seconds, "elapsed": 0.0, "interval": BURN_INTERVAL}
