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

	# The initial technical actor now comes from a scene manifest rather
	# than hardcoded creation in the world controller.
	var prepared = game.world_registry.get_entity("DEV_ENTITY_01")
	assert(prepared != null and bool(prepared.get_parameter("alive")))
	assert(prepared.location_id == "DEV_SANDBOX_A")
	var current_state: Dictionary = game.make_snapshot()
	assert(game.router.register_location("DEV_BAD_ROOM",
		"res://scenes/runtime2d/level_shell.tscn", {"entry": Vector2.ZERO}, 0, [
			{"id": "BAD_ENTITY", "category": "object", "label": "bad",
				"position": [5, 10], "parameters": {"NOT_A_REAL_PARAMETER": true}}
		]))
	assert(not game._enter_location("DEV_BAD_ROOM"))
	assert(game.make_snapshot() == current_state)
	assert(game.current_location_id == "DEV_SANDBOX_A")

	# Deleting a pre-authored actor is persistent gameplay state. Revisiting its
	# scene does not silently recreate it; restoring an older snapshot can.
	var before_delete: Dictionary = game.make_snapshot()
	assert(game.retire_actor("DEV_ENTITY_01"))
	assert(game.world_registry.was_deleted("DEV_ENTITY_01"))
	assert(game._enter_location("DEV_SANDBOX_A"))
	assert(game.world_registry.get_entity("DEV_ENTITY_01") == null)
	var removed_snapshot: Dictionary = game.make_snapshot()
	assert(removed_snapshot["deleted_ids"].has("DEV_ENTITY_01"))
	assert(game.apply_snapshot(removed_snapshot))
	assert(game.world_registry.was_deleted("DEV_ENTITY_01"))
	assert(game.apply_snapshot(before_delete))
	assert(game.world_registry.get_entity("DEV_ENTITY_01") != null)
	assert(not game.world_registry.was_deleted("DEV_ENTITY_01"))

	# The parallel art branch may supply arbitrary PackedScenes. A malformed
	# replacement must leave already-mounted art untouched.
	var valid_visual := PackedScene.new()
	var sprite_root := Node2D.new()
	assert(valid_visual.pack(sprite_root) == OK)
	sprite_root.free()
	assert(game.player.attach_visual(valid_visual))
	assert(game.player.art_anchor.get_child_count() == 1)
	var broken_visual := PackedScene.new()
	var invalid_root := Node.new()
	assert(broken_visual.pack(invalid_root) == OK)
	invalid_root.free()
	assert(not game.player.attach_visual(broken_visual))
	assert(game.player.art_anchor.get_child_count() == 1)
	assert(game.player.get_visual_scene() == valid_visual)
	assert(game.player.attach_visual(null))

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
