extends SceneTree
## AI decisions are real world motion and use bounded active-room target discovery.
## GLOW and REGENERATION are real passive adapters, not decorative inventory flags.

const GAME = preload("res://scenes/runtime2d/sandbox.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game = GAME.instantiate()
	root.add_child(game)
	await physics_frame

	var actor = game.world_registry.get_entity("DEV_ENTITY_01")
	assert(actor is CharacterBody2D)
	assert(game.set_entity_parameter(actor.record.id, "behavior_mode", "CHASE"))
	assert(game.set_entity_parameter(actor.record.id, "target_group", "LUNA"))
	assert(game.set_entity_parameter(actor.record.id, "sense_range", 12.0))
	game.player.global_position = Vector2(-170, 30)
	actor.global_position = Vector2(210, 30)
	var initial_distance: float = actor.global_position.distance_to(game.player.global_position)
	for i in range(15):
		await physics_frame
	assert(actor.behavior.last_resolved_mode == "CHASE")
	assert(actor.behavior.last_target_id == "luna")
	assert(actor.global_position.distance_to(game.player.global_position) < initial_distance)

	assert(game.set_entity_parameter(actor.record.id, "behavior_mode", "FLEE"))
	actor.global_position = Vector2(100, 150)
	initial_distance = actor.global_position.distance_to(game.player.global_position)
	for i in range(10):
		await physics_frame
	assert(actor.behavior.last_resolved_mode == "FLEE")
	assert(actor.global_position.distance_to(game.player.global_position) > initial_distance)

	assert(game.set_entity_parameter(actor.record.id, "behavior_mode", "FOLLOW"))
	actor.global_position = game.player.global_position + Vector2(30, 0)
	assert(actor.behavior.direction_for(actor, game.world_registry, 0.016) == Vector2.ZERO)
	assert(game.set_entity_parameter(actor.record.id, "behavior_mode", "AUTO"))
	assert(game.set_entity_parameter(actor.record.id, "luna_relation", "HOSTILE"))
	assert(actor.behavior.direction_for(actor, game.world_registry, 0.016).length() > 0.0)
	assert(actor.behavior.last_resolved_mode == "CHASE")
	assert(game.set_entity_parameter(actor.record.id, "luna_relation", "AFRAID"))
	assert(actor.behavior.direction_for(actor, game.world_registry, 0.016).length() > 0.0)
	assert(actor.behavior.last_resolved_mode == "FLEE")
	assert(game.set_entity_parameter(actor.record.id, "ai_enabled", false))
	await physics_frame
	assert(actor.velocity.length_squared() < 0.01)

	# A real world light is created on the entity rather than on screen UI.
	assert(not game.set_entity_ability(actor.record.id, "INVENTED_ABILITY", true))
	assert(game.set_entity_ability(actor.record.id, "GLOW", true))
	assert(actor.has_ability("GLOW"))
	assert(actor._glow_light is PointLight2D)
	assert(actor._glow_light.enabled)
	assert(game.set_entity_ability(actor.record.id, "GLOW", false))
	assert(not actor._glow_light.enabled)

	# Configured regeneration is bounded by the old registry default health.
	assert(game.set_entity_parameter(actor.record.id, "health", 90))
	assert(game.set_entity_ability(actor.record.id, "REGENERATION", true))
	actor.passive_abilities._regeneration_elapsed = 1.99
	await physics_frame
	assert(int(actor.get_parameter("health")) == 91)
	assert(game.set_entity_ability(actor.record.id, "REGENERATION", false))
	actor.passive_abilities._regeneration_elapsed = 1.99
	for i in range(4):
		await physics_frame
	assert(int(actor.get_parameter("health")) == 91)

	# AI and ability components remain independent after a full 2D save/restore.
	var copy = game.clone_actor(actor.record.id)
	assert(copy != null and copy.behavior != actor.behavior)
	var snapshot: Dictionary = game.make_snapshot()
	assert(game.apply_snapshot(snapshot))
	var after = game.world_registry.get_entity(actor.record.id)
	assert(after != null)
	assert(after.get_parameter("behavior_mode") == "AUTO")
	assert(not after.has_ability("REGENERATION"))
	assert(game.world_registry.get_entity(copy.record.id) != null)

	game.queue_free()
	print("LUNA runtime2d: chase/flee/follow/AUTO, GLOW, REGENERATION and clone isolation passed")
	quit(0)
