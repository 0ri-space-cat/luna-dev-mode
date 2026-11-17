extends SceneTree
## A physical push and an entire short train of PUSHABLE objects form one
## reversible CommandProcessor transaction. No teleporting through walls.
const GAME = preload("res://scenes/runtime2d/sandbox.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game = GAME.instantiate()
	root.add_child(game)
	await physics_frame

	# Unrelated old NPC cannot affect the test train.
	var npc = game.world_registry.get_entity("DEV_ENTITY_01")
	assert(npc != null)
	assert(game.set_entity_parameter(npc.record.id, "ai_enabled", false))
	npc.global_position = Vector2(350, 200)
	var first = game.spawn_actor("DEV_TRAIN_A", "object", "Push A", Vector2(-90, 100))
	var second = game.spawn_actor("DEV_TRAIN_B", "object", "Push B", Vector2(-62, 100))
	var third = game.spawn_actor("DEV_TRAIN_C", "object", "Push C", Vector2(-34, 100))
	assert(first != null and second != null and third != null)
	for target in [first, second, third]:
		assert(game.set_entity_parameter(target.record.id, "ai_enabled", false))
		assert(game.set_entity_parameter(target.record.id, "pushable", true))
	game.player.global_position = Vector2(-130, 100)
	await physics_frame

	var origin_a: Vector2 = first.global_position
	var origin_b: Vector2 = second.global_position
	var origin_c: Vector2 = third.global_position
	assert(not game.push_chain("luna", ["DEV_TRAIN_A", "DEV_TRAIN_A"],
		Vector2.RIGHT, 28.0))
	assert(not game.push_chain("luna", ["DEV_TRAIN_A", "DOES_NOT_EXIST"],
		Vector2.RIGHT, 28.0))
	assert(not game.push_chain("luna", ["DEV_TRAIN_A", "DEV_TRAIN_B"],
		Vector2.LEFT, 28.0))
	assert(first.global_position == origin_a and second.global_position == origin_b)

	# Caller order is deliberately shuffled. Engine must move front to rear.
	assert(game.push_chain("luna",
		["DEV_TRAIN_A", "DEV_TRAIN_C", "DEV_TRAIN_B"], Vector2.RIGHT, 28.0))
	var moved_a: Vector2 = first.global_position
	var moved_b: Vector2 = second.global_position
	var moved_c: Vector2 = third.global_position
	assert(moved_a.x > origin_a.x + 26.0)
	assert(moved_b.x > origin_b.x + 26.0)
	assert(moved_c.x > origin_c.x + 26.0)
	assert(game.command_processor.undo())
	assert(first.global_position.distance_to(origin_a) < 0.1)
	assert(second.global_position.distance_to(origin_b) < 0.1)
	assert(third.global_position.distance_to(origin_c) < 0.1)
	assert(game.command_processor.redo())
	assert(first.global_position.distance_to(moved_a) < 0.1)
	assert(second.global_position.distance_to(moved_b) < 0.1)
	assert(third.global_position.distance_to(moved_c) < 0.1)

	# External movement invalidates a stale history entry without damaging
	# the real world or consuming the Undo record.
	first.global_position += Vector2(0, 40)
	assert(not game.command_processor.undo())
	assert(second.global_position.distance_to(moved_b) < 0.1)
	assert(third.global_position.distance_to(moved_c) < 0.1)
	first.global_position = moved_a
	assert(game.command_processor.undo())
	assert(first.global_position.distance_to(origin_a) < 0.1)
	assert(second.global_position.distance_to(origin_b) < 0.1)
	assert(third.global_position.distance_to(origin_c) < 0.1)

	# The real 2D physical wall prevents front object from moving too far.
	# The motion is capped by collision and the whole train follows it.
	first.global_position = Vector2(-110, -160)
	second.global_position = Vector2(-82, -160)
	third.global_position = Vector2(-54, -160)
	game.player.global_position = Vector2(-150, -160)
	await physics_frame
	var wall_a: Vector2 = first.global_position
	var wall_b: Vector2 = second.global_position
	var wall_c: Vector2 = third.global_position
	assert(game.push_chain("luna",
		["DEV_TRAIN_C", "DEV_TRAIN_B", "DEV_TRAIN_A"], Vector2.RIGHT, 64.0))
	assert(third.global_position.x > wall_c.x)
	assert(third.global_position.x < -39.0)
	assert(first.global_position.x > wall_a.x)
	assert(game.command_processor.undo())
	assert(first.global_position.distance_to(wall_a) < 0.1)
	assert(second.global_position.distance_to(wall_b) < 0.1)
	assert(third.global_position.distance_to(wall_c) < 0.1)

	# A saved snapshot preserves positions after gameplay and reload.
	var snapshot: Dictionary = game.make_snapshot().duplicate(true)
	first.global_position = Vector2(240, 190)
	assert(game.apply_snapshot(snapshot))
	first = game.world_registry.get_entity("DEV_TRAIN_A")
	assert(first.global_position.distance_to(wall_a) < 0.1)
	assert(game.world_registry.get_entity("DEV_TRAIN_B").global_position.distance_to(wall_b) < 0.1)
	assert(game.world_registry.get_entity("DEV_TRAIN_C").global_position.distance_to(wall_c) < 0.1)

	game.queue_free()
	print("LUNA runtime2d P1: atomic multi-body push, collision-limited Undo/Redo passed")
	quit(0)
