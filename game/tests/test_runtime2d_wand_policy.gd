extends SceneTree
## The later hack window may call exactly one public authorization entrypoint.
## Distance, room, wand carriage and protected self/system properties are real.

const GAME = preload("res://scenes/runtime2d/sandbox.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game = GAME.instantiate()
	root.add_child(game)
	await physics_frame
	var fixture = game.world_registry.get_entity("DEV_ENTITY_01")
	assert(fixture != null)
	assert(not game.request_wand_parameter_edit(fixture.record.id, "speed", 4.0))
	assert(game.wand_edit_policy.last_error == "OUT_OF_REACH")

	game.player.global_position = fixture.global_position + Vector2(20, 0)
	assert(game.request_wand_parameter_edit(fixture.record.id, "speed", 4.0))
	assert(is_equal_approx(float(fixture.get_parameter("speed")), 4.0))
	assert(game.command_processor.undo())
	assert(is_equal_approx(float(fixture.get_parameter("speed")), 2.0))
	assert(not game.request_wand_parameter_edit(fixture.record.id, "material", "STONE"))
	assert(game.wand_edit_policy.last_error == "PROTECTED_PARAMETER")
	assert(not game.request_wand_parameter_edit("luna", "speed", 5.0))
	assert(game.wand_edit_policy.last_error == "REQUIRES_SELF_HACK_FLOW")

	assert(game.projection.drop_at(game.player.global_position, "DEV_SANDBOX_A"))
	assert(not game.request_wand_parameter_edit(fixture.record.id, "speed", 3.0))
	assert(game.wand_edit_policy.last_error == "WAND_NOT_CARRIED")
	assert(game.projection.pick_up_from(game.player.global_position, 36.0, "DEV_SANDBOX_A"))

	game.player.global_position = Vector2(260, 0)
	assert(game.enter_nearby_door())
	assert(not game.request_wand_parameter_edit(fixture.record.id, "speed", 3.0))
	assert(game.wand_edit_policy.last_error == "OTHER_LOCATION")
	assert(fixture.get_parameter("speed") == 2.0)
	game.queue_free()
	print("LUNA runtime2d: physical wand reach, live edits and protected targets passed")
	quit(0)
