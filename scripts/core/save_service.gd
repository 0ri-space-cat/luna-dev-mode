extends RefCounted

const JsonStore = preload("res://scripts/core/json_store.gd")
const ArcaneGrammar = preload("res://scripts/core/arcane_grammar.gd")
## Versioned world snapshots. Writes only data, never Node references or scripts.
## JSON is validated before any state is applied. Save uses temp + rename.
##
## World state belongs to a run; persistent discovery/profile saves will live
## in another service later.

const FORMAT_VERSION := 1
const SCENE_ID := "sandbox_01"
const DEFAULT_PATH := "user://luna_world_v1.json"

var save_path: String
var last_error := ""
var last_restored_ids: Array[String] = []


func _init(path: String = DEFAULT_PATH) -> void:
	save_path = path


func has_save() -> bool:
	return FileAccess.file_exists(save_path)


func snapshot(world, player: Node3D, relationships = null) -> Dictionary:
	var entities := {}
	for entity_id in world.list_ids():
		var node: Node = world.get_entity(entity_id)
		if node == null or not (node is Node3D) or not node.has_method("get_parameter"):
			continue
		var record: Variant = node.get("record")
		if record == null:
			continue
		var packed_parameters := {}
		var keys: Array = record.parameters.keys()
		keys.sort()
		for key in keys:
			packed_parameters[str(key)] = _pack_value(record.parameters[key])
		var entry := {
			"category": str(record.category),
			"position": _pack_position((node as Node3D).position),
			"parameters": packed_parameters
		}
		if str(record.category).begins_with("arcane_"):
			var manifest: Dictionary = node.get("arcane_manifestation")
			if ArcaneGrammar.valid(manifest) and not manifest.is_empty():
				entry["construct"] = ArcaneGrammar.normalize(manifest)
		entities[entity_id] = entry
	return {
		"version": FORMAT_VERSION,
		"scene": SCENE_ID,
		"player_position": _pack_position(player.position),
		"entities": entities,
		"relationships": relationships.export_data() if relationships != null else {}
	}


func save_world(world, player: Node3D, relationships = null) -> bool:
	last_error = ""
	if not is_instance_valid(player):
		return _fail("Player is unavailable")
	var data := snapshot(world, player, relationships)
	var written: Dictionary = JsonStore.write_document(save_path, data)
	if not bool(written["ok"]):
		return _fail(str(written["error"]))
	return true


func load_world(world, player: Node3D, relationships = null, create_actor: Callable = Callable(), parameter_registry = null) -> bool:
	last_error = ""
	var received: Dictionary = JsonStore.read_document(save_path)
	if not bool(received["ok"]):
		return _fail(str(received["error"]))
	return apply_snapshot(received["data"], world, player, relationships, create_actor, parameter_registry)


func apply_snapshot(data: Dictionary, world, player: Node3D, relationships = null, create_actor: Callable = Callable(), parameter_registry = null) -> bool:
	last_error = ""
	if not is_instance_valid(player):
		return _fail("Player is unavailable")
	if typeof(data.get("version")) != TYPE_FLOAT and typeof(data.get("version")) != TYPE_INT:
		return _fail("Missing save version")
	if int(data["version"]) != FORMAT_VERSION or str(data.get("scene", "")) != SCENE_ID:
		return _fail("Incompatible save version or world")
	var start := _unpack_position(data.get("player_position"))
	if not bool(start["ok"]):
		return _fail("Invalid player position")
	var entries: Variant = data.get("entities")
	if typeof(entries) != TYPE_DICTIONARY:
		return _fail("Missing entity data")
	var relationship_data: Variant = data.get("relationships", {})
	if relationships != null and not relationships.validate_data(relationship_data):
		return _fail("Invalid relationship data")
	var plan: Array[Dictionary] = []
	for id in entries.keys():
		if typeof(id) != TYPE_STRING or typeof(entries[id]) != TYPE_DICTIONARY:
			return _fail("Invalid entity record")
		var entity: Node = world.get_entity(id)
		if entity == null:
			# Allows older saves to contain entities removed from a later version.
			continue
		if not (entity is Node3D) or not entity.has_method("set_parameter"):
			return _fail("Save target is not an editable entity: %s" % id)
		var record: Variant = entity.get("record")
		var item: Dictionary = entries[id]
		if record == null or str(item.get("category", "")) != str(record.category):
			return _fail("Entity category changed: %s" % id)
		var pos := _unpack_position(item.get("position"))
		if not bool(pos["ok"]):
			return _fail("Invalid entity position: %s" % id)
		var raw_values: Variant = item.get("parameters")
		if typeof(raw_values) != TYPE_DICTIONARY:
			return _fail("Invalid parameters: %s" % id)
		var normalized := {}
		for key in raw_values.keys():
			if typeof(key) != TYPE_STRING:
				return _fail("Invalid parameter key")
			var value := _unpack_value(raw_values[key])
			if not bool(value["ok"]):
				return _fail("Invalid value for %s.%s" % [id, key])
			var checked: Dictionary = record.registry.normalize(record.category, key, value["value"])
			if not bool(checked["ok"]):
				# Removed parameters from future/old version saves are ignored.
				if record.registry.get_spec(record.category, key).is_empty():
					continue
				return _fail("Invalid typed value for %s.%s" % [id, key])
			normalized[key] = checked["value"]
		plan.append({"node": entity, "position": pos["value"], "parameters": normalized})
	# All input is valid. Apply only after validation, without replaying hacks.
	for item in plan:
		var node: Node3D = item["node"]
		node.position = item["position"]
		for key in item["parameters"].keys():
			if not node.call("set_parameter", key, item["parameters"][key]):
				return _fail("Failed to restore %s" % key)
	player.position = start["value"]
	if relationships != null:
		relationships.import_data(relationship_data)
	return true


func _pack_position(position: Vector3) -> Array:
	return [position.x, position.y, position.z]


func _unpack_position(data: Variant) -> Dictionary:
	if typeof(data) != TYPE_ARRAY or data.size() != 3:
		return {"ok": false}
	var floats: Array[float] = []
	for component in data:
		if typeof(component) != TYPE_INT and typeof(component) != TYPE_FLOAT:
			return {"ok": false}
		var amount := float(component)
		if is_nan(amount) or is_inf(amount) or absf(amount) > 100000.0:
			return {"ok": false}
		floats.append(amount)
	return {"ok": true, "value": Vector3(floats[0], floats[1], floats[2])}


func _pack_value(value: Variant) -> Variant:
	if typeof(value) == TYPE_COLOR:
		return {"type": "color", "value": (value as Color).to_html(true)}
	return value


func _unpack_value(data: Variant) -> Dictionary:
	if typeof(data) == TYPE_DICTIONARY:
		if str(data.get("type", "")) != "color" or typeof(data.get("value")) != TYPE_STRING:
			return {"ok": false}
		var code: String = data["value"]
		if not Color.html_is_valid(code):
			return {"ok": false}
		return {"ok": true, "value": Color.html(code)}
	if typeof(data) in [TYPE_BOOL, TYPE_STRING, TYPE_INT, TYPE_FLOAT]:
		return {"ok": true, "value": data}
	return {"ok": false}


func _fail(reason: String) -> bool:
	last_error = reason
	return false
