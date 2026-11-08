extends RefCounted
## 2D lifecycle adapter for canonical CommandProcessor entity create/delete + Undo/Redo.
const Actor = preload("res://scripts/2d/entity_actor_2d.gd")
const MAX_ENTITIES := 36
var world
var parent: Node2D
var parameter_registry
var player: CharacterBody2D
var actors: Array

func _init(environment, entities_parent: Node2D, registry, controlled_player: CharacterBody2D, actor_list: Array) -> void:
	world = environment
	parent = entities_parent
	parameter_registry = registry
	player = controlled_player
	actors = actor_list

func capture(entity_id: String) -> Dictionary:
	var actor: Node = world.get_entity(entity_id)
	if actor == null or actor.record == null:
		return {}
	var item: Variant = actor.record
	return {
		"id": str(item.id), "category": str(item.category),
		"name": str(item.display_name), "position": actor.position,
		"parameters": item.parameters.duplicate(true)
	}

func validate_blueprint(blueprint: Dictionary) -> bool:
	for key in ["id","category","name","position","parameters"]:
		if not blueprint.has(key):
			return false
	var entity_id := str(blueprint["id"])
	var category := str(blueprint["category"])
	var label := str(blueprint["name"])
	if not entity_id.is_valid_identifier() or entity_id.length() > 90 or entity_id == "luna":
		return false
	if label.strip_edges().is_empty() or label.length() > 80:
		return false
	if category not in ["tree","fridge","arcane_creature","arcane_object"]:
		return false
	if not (blueprint["position"] is Vector2) or not (blueprint["parameters"] is Dictionary):
		return false
	var parameters: Dictionary = blueprint["parameters"]
	var specs: Array[Dictionary] = parameter_registry.get_specs_for(category)
	if parameters.size() != specs.size():
		return false
	for spec in specs:
		var key := str(spec["id"])
		if not parameters.has(key):
			return false
		var check: Dictionary = parameter_registry.normalize(category,key,parameters[key])
		if not bool(check["ok"]):
			return false
	return true

func restore_entity(blueprint: Dictionary) -> Node:
	if not validate_blueprint(blueprint):
		return null
	if world.count_live() >= MAX_ENTITIES:
		return null
	var entity_id := str(blueprint["id"])
	if world.get_entity(entity_id) != null:
		return null
	var actor := Actor.new()
	actor.name = "Entity_"+entity_id
	actor.position = blueprint["position"]
	parent.add_child(actor)
	actor.setup(entity_id,str(blueprint["category"]),str(blueprint["name"]),
		parameter_registry,blueprint["parameters"])
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 17.0
	shape.shape = circle
	actor.add_child(shape)
	if not world.register_entity(entity_id,actor,str(blueprint["category"]).to_upper()):
		actor.queue_free()
		return null
	actor.set_context(player,world)
	actors.append(actor)
	return actor

func delete_entity(entity_id: String) -> Dictionary:
	var blueprint := capture(entity_id)
	if blueprint.is_empty():
		return {}
	if not world.retire_entity(entity_id):
		return {}
	var actor: Node = null
	for candidate in actors:
		if is_instance_valid(candidate) and str(candidate.record.id) == entity_id:
			actor = candidate
			break
	if actor != null:
		actors.erase(actor)
		actor.queue_free()
	return blueprint

func clone_blueprint(entity_id: String, at: Vector2) -> Dictionary:
	var blueprint := capture(entity_id)
	if blueprint.is_empty():
		return {}
	for number in range(1,24):
		var duplicate_id := "%s_copy_%02d" % [entity_id,number]
		if world.get_entity(duplicate_id) == null and not world.was_deleted(duplicate_id):
			blueprint["id"] = duplicate_id
			blueprint["name"] = "Копия "+str(blueprint["name"])
			blueprint["position"] = at
			return blueprint
	return {}
