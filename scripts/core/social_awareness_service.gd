extends RefCounted
## Short-lived social awareness: eyewitnesses and victims react to actual
## damage without rewriting directional relationships or editor parameters.
## No per-species AI scripts and no wall-clock timers.

signal alert_changed(entity_id: String, alert: Dictionary)

const FORMAT_VERSION := 1
const ALERT_DURATION := 5.0
const WITNESS_RADIUS := 5.0
const MAX_ALERTS := 96
const MAX_WITNESSES_PER_HIT := 6

var world
var relationships
var _alerts: Dictionary = {}


func _init(world_registry, relationship_service) -> void:
	world = world_registry
	relationships = relationship_service


func observe_damage(aggressor_id: String, victims: Array) -> int:
	var aggressor: Node = world.get_entity(aggressor_id)
	if not (aggressor is Node3D) or victims.is_empty():
		return 0
	var actual_victims: Array[String] = []
	for raw_victim in victims:
		if typeof(raw_victim) != TYPE_STRING:
			continue
		var victim_id: String = str(raw_victim)
		if victim_id == aggressor_id or actual_victims.has(victim_id):
			continue
		var target: Node = world.get_entity(victim_id)
		if _is_aware_actor(target):
			actual_victims.append(victim_id)
	if actual_victims.is_empty():
		return 0
	var recorded := 0
	for victim_id in actual_victims:
		if _remember(victim_id, aggressor_id, "DIRECT"):
			recorded += 1
	for victim_id in actual_victims:
		var victim: Node3D = world.get_entity(victim_id) as Node3D
		if victim == null:
			continue
		var seen := 0
		for candidate in world.candidates(victim_id, victim.global_position, "ANY", WITNESS_RADIUS):
			if seen >= MAX_WITNESSES_PER_HIT:
				break
			var observer_id: String = str(candidate["id"])
			if observer_id == aggressor_id or actual_victims.has(observer_id):
				continue
			var observer: Node = world.get_entity(observer_id)
			if not _is_aware_actor(observer):
				continue
			if _remember(observer_id, aggressor_id, "WITNESS"):
				recorded += 1
				seen += 1
	return recorded


func get_alert(entity_id: String) -> Dictionary:
	return (_alerts.get(entity_id, {}) as Dictionary).duplicate(true)


func advance(delta: float) -> void:
	if is_nan(delta) or is_inf(delta) or delta <= 0.0:
		return
	var elapsed: float = minf(delta, 1.0)
	for entity_id in _alerts.keys():
		var entry: Dictionary = _alerts[entity_id]
		if world.get_entity(str(entity_id)) == null or world.get_entity(str(entry["aggressor_id"])) == null:
			_alerts.erase(entity_id)
			alert_changed.emit(str(entity_id), {})
			continue
		entry["remaining"] = maxf(0.0, float(entry["remaining"]) - elapsed)
		if float(entry["remaining"]) <= 0.0:
			_alerts.erase(entity_id)
			alert_changed.emit(str(entity_id), {})
		else:
			_alerts[entity_id] = entry


func export_data() -> Dictionary:
	return {"version": FORMAT_VERSION, "alerts": _alerts.duplicate(true)}


func validate_data(data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false
	if data.is_empty():
		return true # World snapshots predating social awareness.
	if data.size() != 2 or typeof(data.get("version")) not in [TYPE_INT, TYPE_FLOAT]:
		return false
	if int(data["version"]) != FORMAT_VERSION or typeof(data.get("alerts")) != TYPE_DICTIONARY:
		return false
	var entries: Dictionary = data["alerts"]
	if entries.size() > MAX_ALERTS:
		return false
	for entity_id in entries.keys():
		if typeof(entity_id) != TYPE_STRING or str(entity_id).is_empty():
			return false
		if typeof(entries[entity_id]) != TYPE_DICTIONARY:
			return false
		var entry: Dictionary = entries[entity_id]
		if entry.size() != 3 or typeof(entry.get("aggressor_id")) != TYPE_STRING:
			return false
		if str(entry["aggressor_id"]).is_empty() or str(entry["aggressor_id"]) == str(entity_id):
			return false
		if entry.get("reason") not in ["DIRECT", "WITNESS"]:
			return false
		if typeof(entry.get("remaining")) not in [TYPE_INT, TYPE_FLOAT]:
			return false
		var remaining: float = float(entry["remaining"])
		if is_nan(remaining) or is_inf(remaining) or remaining <= 0.0 or remaining > ALERT_DURATION:
			return false
	return true


func import_data(data: Dictionary) -> bool:
	if not validate_data(data):
		return false
	var previous_ids: Array = _alerts.keys()
	_alerts.clear()
	if not data.is_empty():
		for entity_id in data["alerts"].keys():
			var entry: Dictionary = data["alerts"][entity_id]
			if _is_aware_actor(world.get_entity(str(entity_id))) and world.get_entity(str(entry["aggressor_id"])) != null:
				_alerts[entity_id] = entry.duplicate(true)
	for entity_id in previous_ids:
		alert_changed.emit(str(entity_id), get_alert(str(entity_id)))
	for entity_id in _alerts.keys():
		if not previous_ids.has(entity_id):
			alert_changed.emit(str(entity_id), get_alert(str(entity_id)))
	return true


func _is_aware_actor(actor: Node) -> bool:
	return actor != null and actor.has_method("get_parameter") \
		and bool(actor.call("get_parameter", "alive")) \
		and bool(actor.call("get_parameter", "ai_enabled"))


func _remember(entity_id: String, aggressor_id: String, reason: String) -> bool:
	if _alerts.size() >= MAX_ALERTS and not _alerts.has(entity_id):
		return false
	var existing: Dictionary = _alerts.get(entity_id, {})
	if not existing.is_empty() and existing["reason"] == "DIRECT" and reason == "WITNESS":
		return false
	_alerts[entity_id] = {
		"aggressor_id": aggressor_id,
		"reason": reason,
		"remaining": ALERT_DURATION
	}
	alert_changed.emit(entity_id, get_alert(entity_id))
	return true
