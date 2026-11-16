extends SceneTree
## Tests real colliders, portable flight, location activation, observation,
## visibility and restore validation. No UI or approved map is required.

const GAME = preload("res://scenes/runtime2d/sandbox.tscn")
const ObservationBody = preload("res://scripts/runtime2d/observation_body_2d.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game = GAME.instantiate()
	root.add_child(game)
	await physics_frame
	var level = game._live_level
	assert(level.geometry.solid_count() == 2)
	assert(level.geometry.zone_count() == 1)
	assert(level.foreground_mount != null)
	# Catalog import validates every entry before replacing live route data.
	var initial_routes: Dictionary = game.router.snapshot_routes()
	assert(not game.router.import_catalog({"locations": [
		{"id": "MISSING_MAP", "scene": "res://scenes/does_not_exist.tscn",
			"entries": {"entry": [0, 0]}}
	], "doors": []}))
	assert(game.router.snapshot_routes() == initial_routes)
	var actor = game.world_registry.get_entity("DEV_ENTITY_01")
	assert(actor is CharacterBody2D)
	assert(actor.location_id == "DEV_SANDBOX_A")
	assert(game.set_entity_parameter("DEV_ENTITY_01", "ai_enabled", false))

	# Low obstacles are actual physics. Giving FLY changes the collision mask
	# through the same ABILITY_SET component used by the old generic core.
	actor.global_position = Vector2(74, -60)
	actor.set_external_drive(Vector2.RIGHT)
	for i in range(12):
		await physics_frame
	assert(actor.global_position.x < 94.0)
	assert(game.set_entity_ability(actor.record.id, "FLY", true))
	assert(actor.has_ability("FLY"))
	assert(actor.collision_mask & 4 == 0)
	for i in range(25):
		await physics_frame
	assert(actor.global_position.x > 145.0)
	# Flying must still respect a full-height wall.
	actor.global_position = Vector2(-62, -165)
	for i in range(20):
		await physics_frame
	assert(actor.global_position.x < -39.0)
	assert(game.command_processor.undo())
	assert(not actor.has_ability("FLY"))
	await physics_frame
	assert(actor.collision_mask & 4 != 0)
	actor.clear_external_drive()
	assert(game.set_entity_parameter(actor.record.id, "is_visible", false))
	assert(not actor.art_anchor.visible)
	assert(actor.collision_layer == 2)
	assert(game.command_processor.undo())
	assert(actor.art_anchor.visible)

	# Camera and Luna vision are separately tested. A world surface may opt
	# into them without baking any specific bridge or level into engine code.
	var law = ObservationBody.new()
	law.solidity_rule = law.WHEN_UNOBSERVED
	law.observer_source = law.CAMERA
	law.starts_invisible = true
	law.position = Vector2(-100, 0)
	level.add_child(law)
	await physics_frame
	assert(game.observation_at(law.global_position)["player_camera"])
	law.apply_observation({"player_camera": true, "luna_eyes": false})
	await process_frame
	assert(not law.is_solid)
	assert(law.collision_layer == 0)
	law.global_position = Vector2(5000, 5000)
	law.apply_observation({"player_camera": false, "luna_eyes": false})
	await process_frame
	assert(law.is_solid)
	assert(law.collision_layer == 1)

	# Leaving a location must not keep its actors physically present.
	var clone = game.clone_actor(actor.record.id)
	assert(clone != null)
	var clone_id: String = clone.record.id
	var nearby_a: Array[Dictionary] = game.find_nearby_entities("luna", 10000.0)
	assert(nearby_a.size() == 2)
	# The same coordinates in a different room must not receive this wand's image.
	assert(game.projection.drop_at(Vector2(260, 0), "DEV_SANDBOX_A"))
	game.player.global_position = Vector2(260, 0)
	assert(game.enter_nearby_door())
	assert(game.current_location_id == "DEV_SANDBOX_B")
	game._update_perception()
	assert(game._live_level.plate.underside)
	assert(not game.projection.pick_up_from(game.player.global_position, 36.0, "DEV_SANDBOX_B"))
	assert(not actor.visible and actor.collision_layer == 0)
	assert(not clone.visible and clone.collision_layer == 0)
	assert(actor.process_mode == Node.PROCESS_MODE_DISABLED)
	# Editing an off-room actor's component must not reactivate collision in
	# the current room (the rooms can share identical 2D coordinates).
	assert(game.set_entity_ability(actor.record.id, "CLIMB", true))
	assert(actor.collision_layer == 0 and actor.collision_mask == 0)
	assert(game.command_processor.undo())
	assert(actor.collision_layer == 0 and actor.collision_mask == 0)
	var b_actor = game.spawn_actor("DEV_B_ENTITY", "object", "Second test room", Vector2(40, 45))
	assert(b_actor != null and b_actor.visible)
	var nearby_b: Array[Dictionary] = game.find_nearby_entities("luna", 10000.0)
	assert(nearby_b.size() == 1 and nearby_b[0]["id"] == "DEV_B_ENTITY")
	game.player.global_position = Vector2(260, 0)
	assert(game.enter_nearby_door())
	assert(game.current_location_id == "DEV_SANDBOX_A")
	game.player.global_position = Vector2(260, 0)
	game._update_perception()
	assert(not game._live_level.plate.underside)
	assert(actor.visible and clone.visible)
	assert(not b_actor.visible)
	assert(game.world_registry.get_entity(clone_id) == clone)

	# A checkpoint preserves all rooms' inhabitants and rejects broken data.
	var before: Dictionary = game.make_snapshot()
	var rejected := 0
	for index in range(150):
		if not game.queue_world_event({"type": "DEV_PULSE", "index": index}):
			rejected += 1
	assert(rejected > 0)
	assert(game.event_bus.pending_count() <= 128)
	assert(game.apply_snapshot(before))
	assert(game.event_bus.pending_count() == 0)
	assert(game.world_registry.get_entity(clone_id) != null)
	assert(game.world_registry.get_entity("DEV_B_ENTITY") != null)
	var damaged: Dictionary = game.make_snapshot().duplicate(true)
	damaged["entities"][0]["position"] = ["broken", "coordinate"]
	assert(not game.apply_snapshot(damaged))
	assert(game.make_snapshot() == before)

	game.queue_free()
	print("LUNA runtime2d: authored physics, real FLY, visibility, gaze and multi-room state passed")
	quit(0)
