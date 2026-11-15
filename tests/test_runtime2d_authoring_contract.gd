extends SceneTree
## Author-added doors work without gameplay code edits. Corrupt snapshots cannot
## change location, player, geometry or door routes; valid B saves remain in B.

const GAME = preload("res://scenes/runtime2d/sandbox.tscn")
const DOOR = preload("res://scripts/runtime2d/doorway_2d.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game = GAME.instantiate()
	root.add_child(game)
	await physics_frame

	# Any future authored level can place a plain Doorway2D at its mapped
	# coordinates and connect it to an approved route in the address catalog.
	assert(game.router.register_door("DEV_TEST_AUTHORED_DOOR", "DEV_SANDBOX_B"))
	var authored = DOOR.new()
	authored.entity_id = "DEV_TEST_AUTHORED_DOOR"
	authored.position = Vector2(-80, 0)
	authored.interaction_radius = 96.0
	game._live_level.add_child(authored)
	game.player.global_position = authored.global_position
	assert(game.enter_nearby_door())
	assert(game.current_location_id == "DEV_SANDBOX_B")
	assert(game.player.location_id == "DEV_SANDBOX_B")
	assert(game.player.global_position == Vector2(160, 0))

	var checkpoint: Dictionary = game.make_snapshot().duplicate(true)
	var malformed: Dictionary = checkpoint.duplicate(true)
	malformed["camera_position"] = ["unsafe", 0]
	assert(not game.apply_snapshot(malformed))
	assert(game.make_snapshot() == checkpoint)
	malformed = checkpoint.duplicate(true)
	malformed["eyes_open"] = "true"
	assert(not game.apply_snapshot(malformed))
	assert(game.make_snapshot() == checkpoint)
	malformed = checkpoint.duplicate(true)
	malformed["entities"][0]["location_id"] = "DOES_NOT_EXIST"
	assert(not game.apply_snapshot(malformed))
	assert(game.make_snapshot() == checkpoint)
	malformed = checkpoint.duplicate(true)
	for entity in malformed["entities"]:
		if entity["id"] == "luna":
			entity["location_id"] = "DEV_SANDBOX_A"
	assert(not game.apply_snapshot(malformed))
	assert(game.make_snapshot() == checkpoint)

	# A valid checkpoint in the second room must stay in that room.
	game.player.global_position = Vector2(40, 45)
	assert(game.apply_snapshot(checkpoint))
	assert(game.current_location_id == "DEV_SANDBOX_B")
	assert(game.player.location_id == "DEV_SANDBOX_B")
	assert(game.player.global_position == Vector2(160, 0))
	game.queue_free()
	print("LUNA runtime2d: generic doorway, room identity and atomic validation passed")
	quit(0)
