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



func observe_magic(source_id: String, target_id: String) -> int:
	## Innocuous magic is interesting to idle creatures. Prior danger has
	## priority, and curiosity never changes a permanent relation.
	var source: Node = world.get_entity(source_id)
	var target: Node = world.get_entity(target_id)
	if not (source is Node3D) or not (target is Node3D) or source_id == target_id:
		return 0
	var observers: Array[String] = []
	if _is_aware_actor(target):
		observers.append(target_id)
	for candidate in world.candidates(target_id, (target as Node3D).global_position,
			"ANY", WITNESS_RADIUS):
		if observers.size() >= MAX_WITNESSES_PER_HIT:
			break
		var observer_id: String = str(candidate["id"])
		if observer_id == source_id or observers.has(observer_id):
			continue
		if _is_aware_actor(world.get_entity(observer_id)):
			observers.append(observer_id)
	var interested := 0
	for observer_id in observers:
		if _remember(observer_id, source_id, "CURIOUS"):
			interested += 1
	return interested


## Delete both the actor's alert and alerts *about* this actor.
## Restore only valid, still-present participants during Undo.
func take_related_alerts(entity_id: String) -> Dictionary:
	var captured := {}
	for observer_id in _alerts.keys():
		var item: Dictionary = _alerts[observer_id]
		if str(observer_id) == entity_id or str(item.get("source_id", "")) == entity_id:
			captured[str(observer_id)] = item.duplicate(true)
			_alerts.erase(observer_id)
			alert_changed.emit(str(observer_id), {})
	return captured


func restore_related_alerts(data: Dictionary) -> void:
	for observer_id in data.keys():
		if _alerts.size() >= MAX_ALERTS:
			break
		var entry: Dictionary = data[observer_id]
		if _is_aware_actor(world.get_entity(str(observer_id))) and world.get_entity(str(entry.get("source_id", ""))) != null:
			_alerts[str(observer_id)] = entry.duplicate(true)
			alert_changed.emit(str(observer_id), get_alert(str(observer_id)))


func get_alert(entity_id: String) -> Dictionary:
	return (_alerts.get(entity_id, {}) as Dictionary).duplicate(true)


func advance(delta: float) -> void:
	if is_nan(delta) or is_inf(delta) or delta <= 0.0:
		return
	var elapsed: float = minf(delta, 1.0)
	for entity_id in _alerts.keys():
		var entry: Dictionary = _alerts[entity_id]
		if world.get_entity(str(entity_id)) == null or world.get_entity(str(entry["source_id"])) == null:
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
		# Older 0.17 files used aggressor_id for the source of danger.
		var source: Variant = entry.get("source_id", entry.get("aggressor_id"))
		if entry.size() != 3 or typeof(source) != TYPE_STRING:
			return false
		if str(source).is_empty() or str(source) == str(entity_id):
			return false
		if entry.get("reason") not in ["DIRECT", "WITNESS", "CURIOUS"]:
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
			var source_id: String = str(entry.get("source_id", entry.get("aggressor_id", "")))
			if _is_aware_actor(world.get_entity(str(entity_id))) and world.get_entity(source_id) != null:
				var normalized: Dictionary = entry.duplicate(true)
				normalized.erase("aggressor_id")
				normalized["source_id"] = source_id
				_alerts[entity_id] = normalized
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
	if not existing.is_empty():
		if existing["reason"] == "DIRECT" and reason != "DIRECT":
			return false
		if existing["reason"] == "WITNESS" and reason == "CURIOUS":
			return false
	_alerts[entity_id] = {
		"source_id": aggressor_id,
		"reason": reason,
		"remaining": ALERT_DURATION
	}
	alert_changed.emit(entity_id, get_alert(entity_id))
	return true
