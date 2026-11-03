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


func snapshot(world, player: Node3D, relationships = null, elemental_statuses = null, surface_fields = null, social_awareness = null) -> Dictionary:
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
		if node.has_meta("copy_origin"):
			entry["copy_origin"] = str(node.get_meta("copy_origin"))
		entities[entity_id] = entry
	return {
		"version": FORMAT_VERSION,
		"scene": SCENE_ID,
		"player_position": _pack_position(player.position),
		"entities": entities,
		"relationships": relationships.export_data() if relationships != null else {},
		"elemental_statuses": elemental_statuses.export_data() if elemental_statuses != null else {},
		"surface_fields": surface_fields.export_data() if surface_fields != null else {},
		"social_awareness": social_awareness.export_data() if social_awareness != null else {}
	}


func save_world(world, player: Node3D, relationships = null, elemental_statuses = null, surface_fields = null, social_awareness = null) -> bool:
	last_error = ""
	if not is_instance_valid(player):
		return _fail("Player is unavailable")
	var data := snapshot(world, player, relationships, elemental_statuses, surface_fields, social_awareness)
	var written: Dictionary = JsonStore.write_document(save_path, data)
	if not bool(written["ok"]):
		return _fail(str(written["error"]))
	return true


func load_world(world, player: Node3D, relationships = null, create_actor: Callable = Callable(), parameter_registry = null, elemental_statuses = null, surface_fields = null, social_awareness = null, create_duplicate: Callable = Callable()) -> bool:
	last_error = ""
	var received: Dictionary = JsonStore.read_document(save_path)
	if not bool(received["ok"]):
		return _fail(str(received["error"]))
	return apply_snapshot(received["data"], world, player, relationships, create_actor, parameter_registry, elemental_statuses, surface_fields, social_awareness, create_duplicate)


func apply_snapshot(data: Dictionary, world, player: Node3D, relationships = null, create_actor: Callable = Callable(), parameter_registry = null, elemental_statuses = null, surface_fields = null, social_awareness = null, create_duplicate: Callable = Callable()) -> bool:
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
	var elemental_data: Variant = data.get("elemental_statuses", {})
	if elemental_statuses != null and not elemental_statuses.validate_data(elemental_data):
		return _fail("Invalid elemental status data")
	var surface_data: Variant = data.get("surface_fields", {})
	if surface_fields != null and not surface_fields.validate_data(surface_data):
		return _fail("Invalid surface field data")
	var social_data: Variant = data.get("social_awareness", {})
	if social_awareness != null and not social_awareness.validate_data(social_data):
		return _fail("Invalid social awareness data")
	var plan: Array[Dictionary] = []
	var ids_in_save: Array[String] = []
	var generated_count := 0
	var copy_count := 0
	for id in entries.keys():
		if typeof(id) != TYPE_STRING or typeof(entries[id]) != TYPE_DICTIONARY:
			return _fail("Invalid entity record")
		var item: Dictionary = entries[id]
		var entity: Node = world.get_entity(id)
		var category: String = str(item.get("category", ""))
		var fields_registry = null
		var manifest: Dictionary = {}
		var copy_origin := ""
		if entity == null:
			if item.has("copy_origin"):
				if not create_duplicate.is_valid() or parameter_registry == null:
					continue # Old save callers still work without copy spawning.
				if typeof(item["copy_origin"]) != TYPE_STRING:
					return _fail("Invalid copy origin")
				copy_origin = str(item["copy_origin"])
				if category not in ["tree", "fridge"] or copy_origin.is_empty():
					return _fail("Invalid copy category or source")
				var prefix := category + "_copy_"
				if not id.begins_with(prefix) or not id.substr(prefix.length()).is_valid_int():
					return _fail("Invalid duplicate ID")
				copy_count += 1
				if copy_count > 24:
					return _fail("Duplicate entity limit reached")
				fields_registry = parameter_registry
			else:
				if not item.has("construct"):
					continue # Entity removed by a newer version of the game.
				if not create_actor.is_valid() or parameter_registry == null:
					continue # Old callers can still restore their existing actors.
				if typeof(item["construct"]) != TYPE_DICTIONARY:
					return _fail("Invalid created entity")
				manifest = ArcaneGrammar.normalize(item["construct"])
				if not ArcaneGrammar.valid(manifest) or manifest.is_empty():
					return _fail("Invalid generated entity recipe")
				if not id.begins_with("arcane_") or not id.substr(7).is_valid_int():
					return _fail("Invalid generated entity ID")
				if category != "arcane_" + str(manifest["create"]).to_lower():
					return _fail("Generated category mismatch")
				generated_count += 1
				if generated_count > 40:
					return _fail("Generated entity limit reached")
				fields_registry = parameter_registry
		else:
			if not (entity is Node3D) or not entity.has_method("set_parameter"):
				return _fail("Save target cannot be edited")
			var record: Variant = entity.get("record")
			if record == null or category != str(record.category):
				return _fail("Entity category mismatch")
			fields_registry = record.registry
			if item.has("construct"):
				if typeof(item["construct"]) != TYPE_DICTIONARY:
					return _fail("Invalid construct metadata")
				manifest = ArcaneGrammar.normalize(item["construct"])
				if manifest.is_empty() or not ArcaneGrammar.valid(manifest):
					return _fail("Invalid construct metadata")
				if category != "arcane_" + str(manifest["create"]).to_lower():
					return _fail("Construct category mismatch")
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
			var checked: Dictionary = fields_registry.normalize(category, key, value["value"])
			if not bool(checked["ok"]):
				if fields_registry.get_spec(category, key).is_empty():
					continue # Backward compatibility with removed parameters.
				return _fail("Invalid typed value for %s.%s" % [id, key])
			normalized[key] = checked["value"]
		plan.append({
			"node": entity, "id": id, "manifest": manifest,
			"copy_origin": copy_origin, "category": category,
			"position": pos["value"], "parameters": normalized
		})
		ids_in_save.append(id)
	# Rebuild missing actors only after every saved field has been validated.
	# This keeps malformed files from partially changing the world.
	var created: Array[Node] = []
	for item in plan:
		if item["node"] != null:
			continue
		var actor: Node
		if not str(item["copy_origin"]).is_empty():
			actor = create_duplicate.call(
				str(item["id"]), str(item["category"]), item["position"], str(item["copy_origin"])
			)
		else:
			actor = create_actor.call(
				str(item["id"]), item["manifest"], item["position"]
			)
		if actor == null:
			for added in created:
				world.unregister_entity(str(added.record.id))
				added.queue_free()
			return _fail("Failed to recreate entity")
		item["node"] = actor
		created.append(actor)
	for item in plan:
		var node: Node3D = item["node"]
		node.position = item["position"]
		for key in item["parameters"].keys():
			if not node.call("set_parameter", key, item["parameters"][key]):
				return _fail("Failed to restore %s" % key)
	player.position = start["value"]
	if relationships != null:
		relationships.import_data(relationship_data)
	if elemental_statuses != null:
		elemental_statuses.import_data(elemental_data)
	if surface_fields != null:
		surface_fields.import_data(surface_data)
	if social_awareness != null:
		social_awareness.import_data(social_data)
	last_restored_ids = ids_in_save
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
