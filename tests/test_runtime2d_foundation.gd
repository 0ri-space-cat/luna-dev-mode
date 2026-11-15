extends SceneTree
## 2D runtime smoke: physical actors, independent copies, camera, wand, addresses,
## in-memory rollback and an isolated V2 save. No UI assets or map required.

const WORLD_SCENE = preload("res://scenes/runtime2d/sandbox.tscn")
const SAVE_TEST_PATH := "user://luna_runtime2d_test_only.json"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game = WORLD_SCENE.instantiate()
	root.add_child(game)
	await process_frame

	assert(game is Node2D)
	assert(game.player is CharacterBody2D)
	assert(game.camera is Camera2D)
	assert(game.camera.mode == "FOLLOW")
	assert(game.current_location_id == "DEV_SANDBOX_A")
	assert(game._live_level.plate.underside == false)

	# Changed parameters affect actual physics, and commands are reversible.
	var original = game.world_registry.get_entity("DEV_ENTITY_01")
	assert(original != null)
	assert(game.set_entity_parameter("DEV_ENTITY_01", "speed", 3.5))
	assert(is_equal_approx(float(original.get_parameter("speed")), 3.5))
	assert(game.command_processor.undo())
	assert(is_equal_approx(float(original.get_parameter("speed")), 2.0))

	var duplicate = game.clone_actor("DEV_ENTITY_01")
	assert(duplicate != null and duplicate.record != original.record)
	assert(duplicate.record.id != original.record.id)
	assert(game.world_registry.get_entity(duplicate.record.id) == duplicate)
	assert(game.set_entity_parameter("DEV_ENTITY_01", "speed", 4.0))
	assert(not is_equal_approx(float(duplicate.get_parameter("speed")), 4.0))

	# The underside requires a dropped wand and a genuine distance crossing.
	game.player.global_position = Vector2(850, 0)
	game._update_perception()
	assert(not game._live_level.plate.underside) # Wand still carried.
	assert(game.projection.drop_at(Vector2.ZERO))
	game._update_perception()
	assert(game._live_level.plate.underside)
	game.player.global_position = Vector2(0, 0)
	game._update_perception()
	assert(not game._live_level.plate.underside)
	assert(game.projection.pick_up_from(game.player.global_position))
	game.player.global_position = Vector2(900, 0)
	game._update_perception()
	assert(not game._live_level.plate.underside)

	# The locked camera does not stop autonomous physical entities.
	game.camera.set_mode("LOCKED")
	var fixed_camera_position: Vector2 = game.camera.global_position
	var moving_object = game.world_registry.get_entity("DEV_ENTITY_01")
	var before: Vector2 = moving_object.global_position
	await create_timer(0.2).timeout
	assert(game.camera.global_position.distance_to(fixed_camera_position) < 0.01)
	assert(moving_object.global_position.distance_to(before) > 0.01)
	assert(not game.observation_at(Vector2(99999, 99999))["player_camera"])

	# Door routing is a real location swap with persistent address data.
	assert(not game.router.redirect_door("DEV_DOOR_A", "UNKNOWN", "PLAYFUL"))
	game.player.global_position = Vector2(260, 0)
	assert(game.enter_nearby_door())
	assert(game.current_location_id == "DEV_SANDBOX_B")
	assert(game.router.redirect_door("DEV_DOOR_B", "DEV_SANDBOX_A", "PLAYFUL"))
	game.player.global_position = Vector2(260, 0)
	assert(game.enter_nearby_door())
	assert(game.current_location_id == "DEV_SANDBOX_A")

	# Save state and restore independent actors and physical wand state.
	game.record_checkpoint()
	var saved: Dictionary = game.make_snapshot()
	assert(game.store.write_snapshot(saved, SAVE_TEST_PATH))
	var from_disk: Dictionary = game.store.read_snapshot(SAVE_TEST_PATH)
	assert(not from_disk.is_empty())
	var restored: bool = game.apply_snapshot(from_disk)
	if not restored:
		print("DIAG restore: loc=", from_disk.get("location"), " player_loc=", game.player.location_id,
			" routes=", game.router.validate_routes(from_disk.get("routes")),
			" camera=", from_disk.get("camera_position"), " access=", from_disk.get("access"))
		var ActorScript = preload("res://scripts/runtime2d/actor_body_2d.gd")
		for item in from_disk.get("entities", []):
			var probe = ActorScript.new()
			print("DIAG actor ", item.get("id"), " location=", item.get("location_id"),
				" valid=", probe.load_snapshot(item, game.parameter_registry))
			probe.free()
	assert(restored)
	assert(game.world_registry.count_live() == 3)
	assert(game.player is CharacterBody2D)
	game.player.global_position = Vector2(120, -90)
	assert(game.restore_checkpoint())
	assert(game.player.global_position.distance_to(Vector2(120, -90)) > 1.0)
	assert(game.router.snapshot_routes() == saved["routes"])

	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_TEST_PATH))
	game.queue_free()
	print("LUNA runtime2d: scene, command/clone, projection, camera, route and save passed")
	quit(0)
