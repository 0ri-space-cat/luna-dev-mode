extends RefCounted
## One runtime path for creation, deletion and undoable restoration.
## Stable IDs are data; no action depends on the previous Node surviving.
## This service deliberately never touches Luna's controller or player profile.
const ArcaneGrammar = preload("res://scripts/core/arcane_grammar.gd")
const EntityRecord = preload("res://scripts/core/entity_record.gd")
const ComponentRegistry = preload("res://scripts/core/component_registry.gd")
const BASE_IDS := {"tree_001": "tree", "tree_002": "tree", "fridge_001": "fridge"}

var world
var parameter_registry
var relationships
var elements
var awareness
var spawn_actor: Callable
var last_error := ""


func _init(world_registry, fields, relationship_service, elemental_service,
		awareness_service, spawn_callback: Callable) -> void:
	world = world_registry
	parameter_registry = fields
	relationships = relationship_service
	elements = elemental_service
	awareness = awareness_service
	spawn_actor = spawn_callback


func capture(entity_id: String) -> Dictionary:
	var actor: Node = world.get_entity(entity_id)
	if actor == null or not (actor is Node3D) or not actor.has_method("get_parameter"):
		return {}
	var record: Variant = actor.get("record")
	if record == null or str(record.id) != entity_id:
		return {}
	var spec := {
		"id": entity_id,
		"category": str(record.category),
		"position": (actor as Node3D).position,
		"parameters": record.parameters.duplicate(true),
		"roles": record.get_stored_roles(),
		"tags": record.get_tags(),
		"components": record.get_components()
	}
	if actor.has_meta("copy_origin"):
		spec["copy_origin"] = str(actor.get_meta("copy_origin"))
	if str(record.category).begins_with("arcane_"):
		spec["construct"] = actor.arcane_manifestation.duplicate(true)
	return spec


func validate_blueprint(data: Dictionary) -> bool:
	if not spawn_actor.is_valid():
		return false
	if typeof(data.get("id")) != TYPE_STRING or typeof(data.get("category")) != TYPE_STRING:
		return false
	var entity_id: String = str(data["id"])
	var category: String = str(data["category"])
	if entity_id.length() > 96 or not entity_id.is_valid_identifier() or entity_id == "luna":
		return false
	if typeof(data.get("position")) != TYPE_VECTOR3:
		return false
	var where: Vector3 = data["position"]
	if not is_finite(where.x) or not is_finite(where.y) or not is_finite(where.z):
		return false
	if typeof(data.get("roles")) != TYPE_ARRAY or typeof(data.get("tags")) != TYPE_ARRAY or typeof(data.get("parameters")) != TYPE_DICTIONARY:
		return false
	if not EntityRecord.validate_trait_list(data["roles"]) or not EntityRecord.validate_trait_list(data["tags"]):
		return false
	if not ComponentRegistry.validate_collection(data.get("components", {})):
		return false
	if BASE_IDS.has(entity_id):
		if str(BASE_IDS[entity_id]) != category or data.has("construct") or data.has("copy_origin"):
			return false
	elif category in ["tree", "fridge"]:
		if typeof(data.get("copy_origin")) != TYPE_STRING or str(data["copy_origin"]).is_empty():
			return false
		var prefix := category + "_copy_"
		if not entity_id.begins_with(prefix) or not entity_id.substr(prefix.length()).is_valid_int():
			return false
	elif category.begins_with("arcane_"):
		if not entity_id.begins_with("arcane_") or not entity_id.substr(7).is_valid_int():
			return false
		if typeof(data.get("construct")) != TYPE_DICTIONARY:
			return false
		var normalized: Dictionary = ArcaneGrammar.normalize(data["construct"])
		if normalized.is_empty() or not ArcaneGrammar.valid(normalized) or category != "arcane_" + str(normalized["create"]).to_lower():
			return false
	else:
		return false
	var values: Dictionary = data["parameters"]
	for key in values.keys():
		if typeof(key) != TYPE_STRING:
			return false
		var checked: Dictionary = parameter_registry.normalize(category, str(key), values[key])
		if not bool(checked["ok"]) or checked["value"] != values[key]:
			return false
	return true


func restore_entity(data: Dictionary) -> Node:
	last_error = ""
	if not validate_blueprint(data):
		last_error = "Invalid entity blueprint"
		return null
	var entity_id: String = str(data["id"])
	if world.get_entity(entity_id) != null:
		last_error = "Entity ID already active"
		return null
	var actor: Node = spawn_actor.call(data)
	if actor == null or world.get_entity(entity_id) != actor:
		last_error = "Unable to instantiate entity"
		return null
	for key in data["parameters"].keys():
		if not actor.call("set_parameter", str(key), data["parameters"][key]):
			_discard_actor(entity_id, false)
			last_error = "Actor rejected saved parameter"
			return null
	if not actor.record.set_traits(data["roles"], data["tags"]) or not actor.record.set_components(data.get("components", {})):
		_discard_actor(entity_id, false)
		last_error = "Actor rejected saved traits or components"
		return null
	if relationships != null:
		relationships.restore_entity_links(data.get("links", {}))
	if elements != null:
		elements.restore_entity_state(entity_id, data.get("elemental_state", {}))
	if awareness != null:
		awareness.restore_related_alerts(data.get("social_alerts", {}))
	return actor


func delete_entity(entity_id: String) -> Dictionary:
	last_error = ""
	var snapshot: Dictionary = capture(entity_id)
	if snapshot.is_empty():
		last_error = "Unknown or noneditable entity"
		return {}
	if not _discard_actor(entity_id, true):
		last_error = "Unable to remove entity"
		return {}
	# Only relations involving this ID are captured. Other participants keep
	# their own history and can continue playing while the entity is absent.
	if relationships != null:
		snapshot["links"] = relationships.take_entity_links(entity_id)
	if elements != null:
		snapshot["elemental_state"] = elements.take_entity_state(entity_id)
	if awareness != null:
		snapshot["social_alerts"] = awareness.take_related_alerts(entity_id)
	return snapshot


func unload_entity(entity_id: String) -> bool:
	## Checkpoint reconciliation discards nodes without authoring a deletion.
	var erased: bool = _discard_actor(entity_id, false)
	if erased:
		if relationships != null:
			relationships.take_entity_links(entity_id)
		if elements != null:
			elements.take_entity_state(entity_id)
		if awareness != null:
			awareness.take_related_alerts(entity_id)
	return erased


func _discard_actor(entity_id: String, mark_deleted: bool) -> bool:
	var actor: Node = world.get_entity(entity_id)
	if actor == null:
		return false
	if mark_deleted:
		if not world.retire_entity(entity_id):
			return false
	else:
		world.unregister_entity(entity_id)
	if actor is Node3D:
		(actor as Node3D).visible = false
	if actor is CollisionObject3D:
		(actor as CollisionObject3D).collision_layer = 0
		(actor as CollisionObject3D).collision_mask = 0
	actor.set_physics_process(false)
	actor.queue_free()
	return true
