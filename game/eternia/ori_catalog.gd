extends RefCounted
## Species templates are built from Eternia's authored creature data.

var templates := {}
var serial := 0

func load_rooms(rooms: Dictionary) -> void:
	for room in rooms.values():
		for entry in room.entities:
			if entry.category == "creature":
				templates[entry.id] = entry

func name_for(actor) -> String:
	return str(templates[actor.form_id].label) if templates.has(actor.form_id) else actor.record.display_name

func replace_form(actor, species: String) -> bool:
	if not actor or actor.record.category != "creature" or not templates.has(species):
		return false
	actor.form_id = species
	return true

func instantiate(game, species: String, at: Vector2) -> CharacterBody2D:
	if not templates.has(species) or not Rect2(-555,-305,1110,610).has_point(at):
		return null
	# Leave room for authored entities in unvisited locations.
	var reserved: int = game.world_registry.count_live()
	for room in game.rooms.values():
		for row in room.entities:
			if not game.world_registry.get_entity(row.id) and not game.world_registry.was_deleted(row.id):
				reserved += 1
	if reserved >= game.actor_capacity():
		return null
	var definition: Dictionary = templates[species].duplicate(true)
	var query := PhysicsShapeQueryParameters2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 11.0 * float(definition.get("parameters",{}).get("size",1.0))
	query.shape = shape
	query.transform = Transform2D(0.0,game._actor_slot.to_global(at))
	query.collision_mask = 31
	if not game.get_world_2d().direct_space_state.intersect_shape(query,1).is_empty():
		return null
	serial += 1
	while game.world_registry.get_entity("ORI_%d" % serial) or game.world_registry.was_deleted("ORI_%d" % serial):
		serial += 1
	definition.id = "ORI_%d" % serial
	definition.position = [at.x,at.y]
	if definition.get("components",{}).has("PICKUP"):
		definition.components.PICKUP.world_position = [at.x,at.y,0.0]
	var blueprint = preload("res://scripts/runtime2d/entity_blueprint_2d.gd")
	var actor = blueprint.create_actor(definition,game.current_location_id,game.parameter_registry)
	if not actor:
		return null
	actor.form_id = species
	if not game.register_spawned_actor(actor):
		actor.free()
		return null
	return actor
