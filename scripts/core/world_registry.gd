extends RefCounted
## Runtime IDs and weak references. No gameplay rule retains a stale Node.
## Scene ownership remains in Main/WorldManager, never here.

var _entries: Dictionary = {}


func register_entity(entity_id: String, entity: Node, group: String) -> bool:
	if entity_id.is_empty() or not is_instance_valid(entity):
		return false
	if _entries.has(entity_id) and get_entity(entity_id) != null:
		return false
	_entries[entity_id] = {"ref": weakref(entity), "group": group}
	return true


func unregister_entity(entity_id: String) -> void:
	_entries.erase(entity_id)


func get_entity(entity_id: String) -> Node:
	if not _entries.has(entity_id):
		return null
	var ref: WeakRef = _entries[entity_id]["ref"]
	var result: Object = ref.get_ref()
	if not is_instance_valid(result):
		_entries.erase(entity_id)
		return null
	return result as Node


func candidates(origin_id: String, position: Vector3, target_group: String, sensing_distance: float) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	var max_squared := sensing_distance * sensing_distance
	for entity_id in _entries.keys():
		if entity_id == origin_id:
			continue
		var target: Node = get_entity(str(entity_id))
		if target == null or not (target is Node3D):
			continue
		var entry: Dictionary = _entries.get(entity_id, {})
		if entry.is_empty():
			continue
		var group: String = str(entry["group"])
		if target_group != "ANY" and target_group != group:
			continue
		var where: Vector3 = (target as Node3D).global_position
		if position.distance_squared_to(where) > max_squared:
			continue
		found.append({"id": str(entity_id), "position": where, "group": group})
	return found


func count_live() -> int:
	var count := 0
	for entity_id in _entries.keys():
		if get_entity(str(entity_id)) != null:
			count += 1
	return count


func list_ids() -> Array[String]:
	var result: Array[String] = []
	for entity_id in _entries.keys():
		if get_entity(str(entity_id)) != null:
			result.append(str(entity_id))
	result.sort()
	return result
