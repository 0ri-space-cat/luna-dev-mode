extends SceneTree
## Local steering handles other moving bodies without weakening collisions.
## Both agents detour on opposite physical sides of a head-on encounter.
const GAME = preload("res://scenes/runtime2d/sandbox.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game = GAME.instantiate()
	root.add_child(game)
	await physics_frame
	var a = game.world_registry.get_entity("DEV_ENTITY_01")
	assert(a != null)
	assert(game.set_entity_parameter(a.record.id, "ai_enabled", false))
	a.global_position = Vector2(-60, 0)
	var b = game.spawn_actor("DEV_STEERING_PEER", "object", "Steering fixture", Vector2(-25,0))
	assert(b != null)
	assert(b.avoidance != a.avoidance)
	var right: Vector2 = a.avoidance.adjust(a, game.world_registry, Vector2.RIGHT, "", 0.016)
	var left: Vector2 = b.avoidance.adjust(b, game.world_registry, Vector2.LEFT, "", 0.016)
	assert(right.x > 0.0 and right.y > 0.0)
	assert(left.x < 0.0 and left.y < 0.0)
	assert(right.length() <= 1.0001 and left.length() <= 1.0001)
	assert(a.avoidance.last_obstacle_id == b.record.id)
	assert(b.avoidance.last_obstacle_id == a.record.id)

	# Chasing a designated target gets close to contact without fighting the
	# generic obstacle avoidance. At contact the AI stops, instead of jittering.
	a.avoidance.reset()
	assert(a.avoidance.adjust(a, game.world_registry, Vector2.RIGHT,
		b.record.id, 0.016) == Vector2.RIGHT)
	b.global_position = Vector2(-40,0)
	assert(a.avoidance.adjust(a, game.world_registry, Vector2.RIGHT,
		b.record.id, 0.016) == Vector2.ZERO)

	# Off-room bodies are never local avoidance targets, even when occupying
	# the same 2D coordinates. This is essential for overlapping map origins.
	b.location_id = "DEV_SANDBOX_B"
	a.avoidance.reset()
	assert(a.avoidance.adjust(a, game.world_registry, Vector2.RIGHT, "",
		0.016) == Vector2.RIGHT)
	assert(a.avoidance.adjust(a, game.world_registry, Vector2.ZERO, "",
		0.016) == Vector2.ZERO)
	game.queue_free()
	print("LUNA runtime2d: bounded symmetric local avoidance and room isolation passed")
	quit(0)
