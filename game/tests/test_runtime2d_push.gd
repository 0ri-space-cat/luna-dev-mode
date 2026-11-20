extends SceneTree
## P1: PUSHABLE uses Godot's real physical collision solver rather than
## changing coordinates through an unrestricted editing shortcut.

const GAME = preload("res://scenes/runtime2d/sandbox.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game = GAME.instantiate()
	root.add_child(game)
	await physics_frame
	var target = game.spawn_actor("DEV_PUSH_PROP", "object", "Push test fixture",
		Vector2(-110, 100))
	assert(target != null)
	game.player.global_position = Vector2(-150, 100)
	assert(not game.push_entity("luna", target.record.id, Vector2.RIGHT))
	assert(game.set_entity_parameter(target.record.id, "pushable", true))
	var prior: Vector2 = target.global_position
	assert(game.push_entity("luna", target.record.id, Vector2.RIGHT, 28.0))
	assert(target.global_position.x > prior.x + 20.0)
	assert(not game.push_entity("luna", target.record.id, Vector2.LEFT))
	assert(not game.push_entity("luna", target.record.id, Vector2.RIGHT, 1000.0))
	game.player.global_position = Vector2(-600, 100)
	assert(not game.push_entity("luna", target.record.id, Vector2.RIGHT))

	# Wall x=-30..2, y=-200..-122 is true collision layer 1.
	# Pushing cannot pass the target's 11px circle through the wall edge.
	game.player.global_position = Vector2(-104, -160)
	target.global_position = Vector2(-64, -160)
	await physics_frame
	assert(game.push_entity("luna", target.record.id, Vector2.RIGHT, 64.0))
	assert(target.global_position.x > -64.0)
	assert(target.global_position.x <= -40.0)
	assert(not game.push_entity("luna", target.record.id, Vector2.RIGHT, 64.0)
		or target.global_position.x <= -40.0)
	# A second contact can consume a tiny safe-margin displacement.
	# Compare the restored position with the actual saved state.
	var at_wall: Vector2 = target.global_position
	var checkpoint: Dictionary = game.make_snapshot().duplicate(true)
	target.global_position = Vector2(40, 100)
	assert(game.apply_snapshot(checkpoint))
	target = game.world_registry.get_entity("DEV_PUSH_PROP")
	assert(target != null)
	assert(target.global_position.distance_to(at_wall) < 0.1)
	assert(target.get_parameter("pushable"))

	game.queue_free()
	print("LUNA runtime2d P1: bounded physical pushing, wall collision and save restore passed")
	quit(0)
