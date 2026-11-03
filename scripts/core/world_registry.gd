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


## Deterministic, bounded classification search. New systems (magic, rules,
## factions and discoveries) can share this selector rather than adding
## custom species-by-species loops.
func query_ids(selector: Dictionary, limit: int = 16) -> Array[String]:
	var result: Array[String] = []
	if limit < 1 or limit > 24:
		return result
	for key in selector.keys():
		if str(key) not in ["category", "role", "tag", "alive"]:
			return result
		if str(key) == "alive":
			if typeof(selector[key]) != TYPE_BOOL:
				return result
		elif typeof(selector[key]) != TYPE_STRING or str(selector[key]).is_empty():
			return result
	for entity_id in list_ids():
		var actor: Node = get_entity(entity_id)
		if actor == null or not actor.has_method("get_parameter"):
			continue
		var record: Variant = actor.get("record")
		if record == null:
			continue
		if selector.has("category") and str(record.category) != str(selector["category"]):
			continue
		if selector.has("role") and not record.has_role(str(selector["role"])):
			continue
		if selector.has("tag") and not record.has_tag(str(selector["tag"])):
			continue
		if selector.has("alive") and bool(actor.call("get_parameter", "alive")) != bool(selector["alive"]):
			continue
		result.append(entity_id)
		if result.size() >= limit:
			break
	return result
