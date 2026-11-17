extends SceneTree
## P2 foundation: author-created spell command bundles change a real entity
## through the protected wand policy with one atomic history transaction.
## No spell names, projectiles, mana cost or HUD are invented here.
const GAME = preload("res://scenes/runtime2d/sandbox.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game = GAME.instantiate()
	root.add_child(game)
	await physics_frame
	var actor = game.world_registry.get_entity("DEV_ENTITY_01")
	assert(actor != null)
	assert(game.set_entity_parameter(actor.record.id, "ai_enabled", false))
	actor.global_position = Vector2(-80, 100)
	game.player.global_position = Vector2(-95, 100)
	var independent = game.clone_actor(actor.record.id)
	assert(independent != null)
	independent.global_position = Vector2(250, 200)

	var steps: Array = [
		{"operation":"ADD", "parameter_id":"speed", "value":1.0},
		{"operation":"MULTIPLY", "parameter_id":"speed", "value":0.5},
		{"operation":"ADD", "parameter_id":"health", "value":-15}
	]
	assert(game.request_wand_spell_program(actor.record.id, steps))
	assert(is_equal_approx(float(actor.get_parameter("speed")), 1.5))
	assert(int(actor.get_parameter("health")) == 85)
	assert(is_equal_approx(float(independent.get_parameter("speed")), 2.0))
	assert(int(independent.get_parameter("health")) == 100)

	# One Undo reverses the entire program, including multiple writes of
	# the same parameter. A single Redo reapplies all three steps.
	assert(game.command_processor.undo())
	assert(is_equal_approx(float(actor.get_parameter("speed")), 2.0))
	assert(int(actor.get_parameter("health")) == 100)
	assert(game.command_processor.redo())
	assert(is_equal_approx(float(actor.get_parameter("speed")), 1.5))
	assert(int(actor.get_parameter("health")) == 85)

	var good: Dictionary = game.make_snapshot().duplicate(true)
	assert(not game.request_wand_spell_program(actor.record.id, [
		{"operation":"SET", "parameter_id":"speed", "value":2.5},
		{"operation":"SET", "parameter_id":"material", "value":"STONE"}
	]))
	assert(game.spell_program.last_error == "PROTECTED_PARAMETER")
	assert(game.make_snapshot() == good)
	assert(not game.request_wand_spell_program(actor.record.id, [
		{"operation":"EXECUTE_CODE", "parameter_id":"speed", "value":5}
	]))
	assert(game.spell_program.last_error == "UNKNOWN_OPERATION")
	assert(not game.request_wand_spell_program(actor.record.id, [
		{"operation":"MULTIPLY", "parameter_id":"health", "value":INF}
	]))
	assert(game.spell_program.last_error == "INVALID_NUMERIC_OPERATION")
	var excessive: Array = []
	for index in range(9):
		excessive.append({"operation":"ADD", "parameter_id":"speed", "value":0.1})
	assert(not game.request_wand_spell_program(actor.record.id, excessive))
	assert(game.spell_program.last_error == "PROGRAM_LENGTH")
	assert(game.make_snapshot() == good)

	# A spell with a false operand or misplaced field must not be treated
	# as an executable user script or bypass the ordinary TAB authorization.
	game.player.global_position = Vector2(800, 800)
	assert(not game.request_wand_spell_program(actor.record.id, steps))
	assert(game.spell_program.last_error == "OUT_OF_REACH")
	game.player.global_position = Vector2(-95, 100)
	assert(game.projection.drop_at(Vector2(-95, 100), "DEV_SANDBOX_A"))
	assert(not game.request_wand_spell_program(actor.record.id, steps))
	assert(game.spell_program.last_error == "WAND_NOT_CARRIED")
	assert(game.projection.pick_up_from(game.player.global_position, 36.0,
		"DEV_SANDBOX_A"))
	assert(not game.request_wand_spell_program("luna", [
		{"operation":"TOGGLE", "parameter_id":"alive"}
	]))
	assert(game.spell_program.last_error == "REQUIRES_SELF_HACK_FLOW")

	assert(game.request_wand_spell_program(actor.record.id, [
		{"operation":"TOGGLE", "parameter_id":"alive"},
		{"operation":"TOGGLE", "parameter_id":"ai_enabled"}
	]))
	assert(bool(actor.get_parameter("alive")))
	assert(bool(actor.get_parameter("ai_enabled")))
	assert(game.command_processor.undo())
	assert(not bool(actor.get_parameter("alive")))
	assert(not bool(actor.get_parameter("ai_enabled")))

	# V2 snapshots preserve the observed physical effect, but do not
	# resurrect stale in-memory command references after a world reload.
	assert(game.apply_snapshot(good))
	actor = game.world_registry.get_entity("DEV_ENTITY_01")
	assert(is_equal_approx(float(actor.get_parameter("speed")), 1.5))
	assert(int(actor.get_parameter("health")) == 85)
	assert(not game.command_processor.can_undo())
	game.queue_free()
	print("LUNA runtime2d P2: authorized atomic spell bundles, rollback and bounded inputs passed")
	quit(0)
