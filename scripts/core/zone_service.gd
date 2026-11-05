extends RefCounted
## Small bounded spatial sensor. No physics areas or hard-coded species.
## All notifications flow through EventBus and can trigger RuleEngine.
const MAX_ZONES := 24
const MAX_TRACKED_ACTORS := 64
const MAX_EVENTS_PER_TICK := 24

var world
var events
var _inside: Dictionary = {}


func _init(world_registry, event_bus) -> void:
	world = world_registry
	events = event_bus


func reset() -> void:
	_inside.clear()


func scan() -> int:
	var emitted := 0
	var seen := {}
	var checked := 0
	for zone_id in world.list_ids():
		var zone: Node = world.get_entity(zone_id)
		if not (zone is Node3D):
			continue
		var record: Variant = zone.get("record")
		if record == null or not record.has_component("TRIGGER_ZONE"):
			continue
		checked += 1
		if checked > MAX_ZONES:
			break
		seen[zone_id] = true
		var spec: Dictionary = record.get_component("TRIGGER_ZONE")
		var old: Array = _inside.get(zone_id, [])
		var current: Array[String] = []
		if bool(spec["enabled"]):
			var radius: float = float(spec["radius"])
			for other_id in world.list_ids():
				if other_id == zone_id or current.size() >= MAX_TRACKED_ACTORS:
					continue
				var other: Node = world.get_entity(other_id)
				if not (other is Node3D) or not _matches(other_id, other, str(spec["watch_group"])):
					continue
				if (zone as Node3D).global_position.distance_squared_to(
						(other as Node3D).global_position) <= radius * radius:
					current.append(other_id)
		current.sort()
		var committed: Array = old.duplicate()
		for other_id in current:
			if old.has(other_id):
				continue
			if emitted >= MAX_EVENTS_PER_TICK:
				break
			if events.enqueue(_event("zone.entered", zone_id, other_id)):
				committed.append(other_id)
				emitted += 1
		for other_id in old:
			if current.has(other_id):
				continue
			if emitted >= MAX_EVENTS_PER_TICK:
				break
			if events.enqueue(_event("zone.exited", zone_id, str(other_id))):
				committed.erase(other_id)
				emitted += 1
		committed.sort()
		_inside[zone_id] = committed
	for zone_id in _inside.keys():
		if not seen.has(zone_id):
			_inside.erase(zone_id)
	return emitted


func _matches(other_id: String, target: Node, group: String) -> bool:
	if group == "ANY":
		return true
	if group == "LUNA":
		return other_id == "luna"
	var record: Variant = target.get("record")
	if record == null:
		return false
	if group == "CREATURE":
		return record.has_role("CREATURE")
	return str(record.category).to_upper() == group


func _event(kind: String, zone_id: String, other_id: String) -> Dictionary:
	return {
		"type": kind, "source_id": zone_id, "target_id": other_id,
		"payload": {"zone_id": zone_id, "actor_id": other_id}
	}
