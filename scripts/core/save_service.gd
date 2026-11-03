extends RefCounted
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


func _init(path: String = DEFAULT_PATH) -> void:
	save_path = path


func has_save() -> bool:
	return FileAccess.file_exists(save_path)


func snapshot(world, player: Node3D) -> Dictionary:
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
		entities[entity_id] = {
			"category": str(record.category),
			"position": _pack_position((node as Node3D).position),
			"parameters": packed_parameters
		}
	return {
		"version": FORMAT_VERSION,
		"scene": SCENE_ID,
		"player_position": _pack_position(player.position),
		"entities": entities
	}


func save_world(world, player: Node3D) -> bool:
	last_error = ""
	if not is_instance_valid(player):
		return _fail("Player is unavailable")
	var data := snapshot(world, player)
	var serialized := JSON.stringify(data, "\t")
	var temp_path := save_path + ".tmp"
	var stream := FileAccess.open(temp_path, FileAccess.WRITE)
	if stream == null:
		return _fail("Cannot open temporary save file: %s" % FileAccess.get_open_error())
	stream.store_string(serialized)
	stream.flush()
	stream.close()
	var source := ProjectSettings.globalize_path(temp_path)
	var destination := ProjectSettings.globalize_path(save_path)
	var error: Error = DirAccess.rename_absolute(source, destination)
	if error != OK:
		return _fail("Cannot replace save file: %s" % error)
	return true


func load_world(world, player: Node3D) -> bool:
	last_error = ""
	if not has_save():
		return _fail("No save found")
	var stream := FileAccess.open(save_path, FileAccess.READ)
	if stream == null:
		return _fail("Cannot open save: %s" % FileAccess.get_open_error())
	var serialized := stream.get_as_text()
	stream.close()
	var parser := JSON.new()
	var error: Error = parser.parse(serialized)
	if error != OK:
		return _fail("Invalid save JSON at line %d" % parser.get_error_line())
	if typeof(parser.data) != TYPE_DICTIONARY:
		return _fail("Save root must be a dictionary")
	return apply_snapshot(parser.data, world, player)


func apply_snapshot(data: Dictionary, world, player: Node3D) -> bool:
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
