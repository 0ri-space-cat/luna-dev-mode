extends RefCounted

const JsonStore = preload("res://scripts/core/json_store.gd")
const ArcaneGrammar = preload("res://scripts/core/arcane_grammar.gd")
const EntityRecord = preload("res://scripts/core/entity_record.gd")
const ComponentRegistry = preload("res://scripts/core/component_registry.gd")
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


func snapshot(world, player: Node3D, relationships = null, elemental_statuses = null, surface_fields = null, social_awareness = null, rules = null) -> Dictionary:
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
			"parameters": packed_parameters,
			"roles": record.get_stored_roles(),
			"tags": record.get_tags(),
			"components": record.get_components()
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
		"deleted_entities": world.deleted_ids(),
		"relationships": relationships.export_data() if relationships != null else {},
		"elemental_statuses": elemental_statuses.export_data() if elemental_statuses != null else {},
		"surface_fields": surface_fields.export_data() if surface_fields != null else {},
		"social_awareness": social_awareness.export_data() if social_awareness != null else {},
		"rules": rules.export_data() if rules != null else {}
	}


func save_world(world, player: Node3D, relationships = null, elemental_statuses = null, surface_fields = null, social_awareness = null, rules = null) -> bool:
	last_error = ""
	if not is_instance_valid(player):
		return _fail("Player is unavailable")
	var data := snapshot(world, player, relationships, elemental_statuses, surface_fields, social_awareness, rules)
	var written: Dictionary = JsonStore.write_document(save_path, data)
	if not bool(written["ok"]):
		return _fail(str(written["error"]))
	return true


func load_world(world, player: Node3D, relationships = null, create_actor: Callable = Callable(), parameter_registry = null, elemental_statuses = null, surface_fields = null, social_awareness = null, create_duplicate: Callable = Callable(), rules = null, remove_actor: Callable = Callable(), create_original: Callable = Callable()) -> bool:
	last_error = ""
	var received: Dictionary = JsonStore.read_document(save_path)
	if not bool(received["ok"]):
		return _fail(str(received["error"]))
	return apply_snapshot(received["data"], world, player, relationships, create_actor, parameter_registry, elemental_statuses, surface_fields, social_awareness, create_duplicate, rules, remove_actor, create_original)


func apply_snapshot(data: Dictionary, world, player: Node3D, relationships = null, create_actor: Callable = Callable(), parameter_registry = null, elemental_statuses = null, surface_fields = null, social_awareness = null, create_duplicate: Callable = Callable(), rules = null, remove_actor: Callable = Callable(), create_original: Callable = Callable()) -> bool:
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
	var deleted: Variant = data.get("deleted_entities", [])
	if not world.validate_deleted_ids(deleted):
		return _fail("Malformed deleted entity IDs")
	for deleted_id in deleted:
		if deleted_id == "luna" or entries.has(deleted_id):
			return _fail("Deleted ID still has a live entity")
		if world.get_entity(str(deleted_id)) != null and not remove_actor.is_valid():
			return _fail("Missing entity removal callback")
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
	var rule_data: Variant = data.get("rules", {})
	if rules != null and not rules.validate_data(rule_data):
		return _fail("Invalid saved rules")
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
		var restore_base := false
		if entity == null:
			if id in ["tree_001", "tree_002", "fridge_001"] and not item.has("copy_origin") and not item.has("construct"):
				if not create_original.is_valid() or parameter_registry == null:
					continue
				if category != ("fridge" if id == "fridge_001" else "tree"):
					return _fail("Invalid original entity category")
				fields_registry = parameter_registry
				restore_base = true
			elif item.has("copy_origin"):
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
		var saved_roles: Variant = item.get("roles", EntityRecord.default_roles(category))
		var saved_tags: Variant = item.get("tags", EntityRecord.default_tags(category))
		if not EntityRecord.validate_trait_list(saved_roles) or not EntityRecord.validate_trait_list(saved_tags):
			return _fail("Invalid entity roles/tags: %s" % id)
		var saved_components: Variant = item.get("components", {})
		if not ComponentRegistry.validate_collection(saved_components):
			return _fail("Invalid entity components: %s" % id)
		plan.append({
			"roles": saved_roles, "tags": saved_tags, "components": saved_components,
			"node": entity, "id": id, "manifest": manifest,
			"copy_origin": copy_origin, "category": category,
			"restore_base": restore_base,
			"position": pos["value"], "parameters": normalized
		})
		ids_in_save.append(id)
	# Rebuild missing actors only after every saved field has been validated.
	# This keeps malformed files from partially changing the world.
	if not _validate_carried_references(entries, world):
		return _fail("Invalid inventory ownership or capacity")
	# Save a reversible runtime checkpoint before any creation callback.
	var before: Dictionary = _runtime_checkpoint(world, player, relationships,
		elemental_statuses, surface_fields, social_awareness, rules)
	for deleted_id in deleted:
		var doomed: Node = world.get_entity(str(deleted_id))
		if doomed != null and not _can_recreate_existing(str(deleted_id), doomed,
				create_actor, create_duplicate, create_original):
			return _fail("Cannot safely undo deletion: %s" % deleted_id)
	var created: Array[Node] = []
	for item in plan:
		if item["node"] != null:
			continue
		var actor: Node
		if bool(item["restore_base"]):
			actor = create_original.call(
				str(item["id"]), str(item["category"]), item["position"]
			)
		elif not str(item["copy_origin"]).is_empty():
			actor = create_duplicate.call(
				str(item["id"]), str(item["category"]), item["position"], str(item["copy_origin"])
			)
		else:
			actor = create_actor.call(
				str(item["id"]), item["manifest"], item["position"]
			)
		if actor == null:
			return _rollback_load("Failed to recreate entity", world, player, before,
				created, relationships, elemental_statuses, surface_fields,
				social_awareness, rules, create_actor, create_duplicate, create_original)
		item["node"] = actor
		created.append(actor)
	for item in plan:
		var node: Node3D = item["node"]
		node.position = item["position"]
		for key in item["parameters"].keys():
			if not node.call("set_parameter", key, item["parameters"][key]):
				return _rollback_load("Failed to restore %s" % key, world, player,
					before, created, relationships, elemental_statuses, surface_fields,
					social_awareness, rules, create_actor, create_duplicate, create_original)
		if not node.record.set_traits(item["roles"], item["tags"]):
			return _rollback_load("Failed to restore entity roles/tags", world, player,
				before, created, relationships, elemental_statuses, surface_fields,
				social_awareness, rules, create_actor, create_duplicate, create_original)
		if not node.record.set_components(item["components"]):
			return _rollback_load("Failed to restore entity components", world, player,
				before, created, relationships, elemental_statuses, surface_fields,
				social_awareness, rules, create_actor, create_duplicate, create_original)
	player.position = start["value"]
	if (relationships != null and not relationships.import_data(relationship_data)) or \
			(elemental_statuses != null and not elemental_statuses.import_data(elemental_data)) or \
			(surface_fields != null and not surface_fields.import_data(surface_data)) or \
			(social_awareness != null and not social_awareness.import_data(social_data)) or \
			(rules != null and not rule_data.is_empty() and not rules.import_data(rule_data)):
		return _rollback_load("Failed to restore world services", world, player,
			before, created, relationships, elemental_statuses, surface_fields,
			social_awareness, rules, create_actor, create_duplicate, create_original)
	# Deletions are facts, not invisible defaults that respawn on restart.
	# Clean active tombstoned actors only after the full snapshot validated.
	for deleted_id in deleted:
		if world.get_entity(str(deleted_id)) != null:
			if not bool(remove_actor.call(str(deleted_id))):
				return _rollback_load("Unable to apply deletion: %s" % deleted_id,
					world, player, before, created, relationships, elemental_statuses,
					surface_fields, social_awareness, rules,
					create_actor, create_duplicate, create_original)
	if not world.restore_deleted_ids(deleted):
		return _rollback_load("Unable to restore deleted-entity registry",
			world, player, before, created, relationships, elemental_statuses,
			surface_fields, social_awareness, rules,
			create_actor, create_duplicate, create_original)
	last_restored_ids = ids_in_save
	return true


## A transient in-memory copy, intentionally never serialized. Includes
## services and actors not mentioned by the incoming save, since deletion
## callbacks may remove them during commit.
func _validate_carried_references(entries: Dictionary, world) -> bool:
	var usage := {}
	for entity_id in entries.keys():
		var components: Variant = entries[entity_id].get("components", {})
		if typeof(components) != TYPE_DICTIONARY or not components.has("PICKUP"):
			continue
		var held: Dictionary = components["PICKUP"]
		var owner_id: String = str(held.get("holder_id", ""))
		if owner_id.is_empty():
			continue
		if owner_id == str(entity_id) or (world.get_entity(owner_id) == null and not entries.has(owner_id)):
			return false
		if owner_id != "luna" and not entries.has(owner_id):
			return false
		var max_slots := 12
		var max_weight := 50.0
		if owner_id != "luna":
			var carrier_components: Variant = entries[owner_id].get("components", {})
			if typeof(carrier_components) != TYPE_DICTIONARY or not carrier_components.has("INVENTORY"):
				return false
			var capacity: Dictionary = carrier_components["INVENTORY"]
			max_slots = int(capacity["max_slots"])
			max_weight = float(capacity["max_weight"])
		var stats: Dictionary = usage.get(owner_id, {"count": 0, "weight": 0.0})
		stats["count"] = int(stats["count"]) + 1
		stats["weight"] = float(stats["weight"]) + float(held["weight"])
		if int(stats["count"]) > max_slots or float(stats["weight"]) > max_weight:
			return false
		usage[owner_id] = stats
		var visited := {}
		var next_id: String = owner_id
		while not next_id.is_empty() and next_id != "luna":
			if next_id == str(entity_id) or visited.has(next_id):
				return false
			visited[next_id] = true
			var next_components: Variant = entries[next_id].get("components", {})
			if typeof(next_components) != TYPE_DICTIONARY:
				return false
			next_id = str(next_components.get("PICKUP", {}).get("holder_id", ""))
	return true


func _runtime_checkpoint(world, player: Node3D, relationships, elemental_statuses,
		surface_fields, social_awareness, rules) -> Dictionary:
	var actors := {}
	for entity_id in world.list_ids():
		var node: Node = world.get_entity(entity_id)
		if not (node is Node3D) or not node.has_method("get_parameter"):
			continue
		var record: Variant = node.get("record")
		if record == null:
			continue
		var entry := {
			"category": str(record.category),
			"position": (node as Node3D).position,
			"parameters": record.parameters.duplicate(true),
			"roles": record.get_stored_roles(),
			"tags": record.get_tags(),
			"components": record.get_components()
		}
		if node.has_meta("copy_origin"):
			entry["copy_origin"] = str(node.get_meta("copy_origin"))
		if str(record.category).begins_with("arcane_"):
			entry["construct"] = node.arcane_manifestation.duplicate(true)
		actors[entity_id] = entry
	return {
		"actors": actors, "player_position": player.position,
		"deleted": world.deleted_ids(),
		"relationships": relationships.export_data() if relationships != null else {},
		"elemental_statuses": elemental_statuses.export_data() if elemental_statuses != null else {},
		"surface_fields": surface_fields.export_data() if surface_fields != null else {},
		"social_awareness": social_awareness.export_data() if social_awareness != null else {},
		"rules": rules.export_data() if rules != null else {}
	}


func _can_recreate_existing(entity_id: String, actor: Node, create_actor: Callable,
		create_duplicate: Callable, create_original: Callable) -> bool:
	var record: Variant = actor.get("record")
	if record == null:
		return false
	var category: String = str(record.category)
	if actor.has_meta("copy_origin"):
		return category in ["tree", "fridge"] and create_duplicate.is_valid()
	if category.begins_with("arcane_"):
		return create_actor.is_valid() and ArcaneGrammar.valid(actor.arcane_manifestation)
	return entity_id in ["tree_001", "tree_002", "fridge_001"] and create_original.is_valid()


func _rollback_load(message: String, world, player: Node3D, before: Dictionary,
		created: Array[Node], relationships, elemental_statuses, surface_fields,
		social_awareness, rules, create_actor: Callable,
		create_duplicate: Callable, create_original: Callable) -> bool:
	var recovered := true
	for node in created:
		if not is_instance_valid(node):
			continue
		var record: Variant = node.get("record")
		if record != null:
			world.unregister_entity(str(record.id))
		node.queue_free()
	var originals: Dictionary = before["actors"]
	for entity_id in originals.keys():
		var saved: Dictionary = originals[entity_id]
		var actor: Node = world.get_entity(str(entity_id))
		if actor == null:
			if saved.has("copy_origin") and create_duplicate.is_valid():
				actor = create_duplicate.call(str(entity_id), str(saved["category"]),
					saved["position"], str(saved["copy_origin"]))
			elif saved.has("construct") and create_actor.is_valid():
				actor = create_actor.call(str(entity_id), saved["construct"],
					saved["position"])
			elif create_original.is_valid():
				actor = create_original.call(str(entity_id), str(saved["category"]),
					saved["position"])
		if not (actor is Node3D):
			recovered = false
			continue
		(actor as Node3D).position = saved["position"]
		for key in saved["parameters"].keys():
			if not actor.call("set_parameter", str(key), saved["parameters"][key]):
				recovered = false
		if not actor.record.set_traits(saved["roles"], saved["tags"]):
			recovered = false
		if not actor.record.set_components(saved["components"]):
			recovered = false
	player.position = before["player_position"]
	if relationships != null and not relationships.import_data(before["relationships"]):
		recovered = false
	if elemental_statuses != null and not elemental_statuses.import_data(before["elemental_statuses"]):
		recovered = false
	if surface_fields != null and not surface_fields.import_data(before["surface_fields"]):
		recovered = false
	if social_awareness != null and not social_awareness.import_data(before["social_awareness"]):
		recovered = false
	if rules != null and not rules.import_data(before["rules"]):
		recovered = false
	if not world.restore_deleted_ids(before["deleted"]):
		recovered = false
	return _fail(message if recovered else message + " (ROLLBACK INCOMPLETE)")


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
