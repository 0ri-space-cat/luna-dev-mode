extends SceneTree
## Real EventBus overflow requests a safe in-game recovery once, without
## destroying the world or clearing the last stable checkpoint.
const GAME = preload("res://scenes/runtime2d/sandbox.tscn")
const Guard = preload("res://scripts/runtime2d/game_recovery_2d.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game = GAME.instantiate()
	root.add_child(game)
	await physics_frame
	assert(game.recovery_guard.has_checkpoint())
	assert(game.mark_safe_state())
	var actor = game.world_registry.get_entity("DEV_ENTITY_01")
	assert(actor != null)
	var safe: Dictionary = game.make_snapshot().duplicate(true)
	var notices: Array[String] = []
	game.recovery_available.connect(func(reason: String): notices.append(reason))
	assert(game.set_entity_parameter(actor.record.id, "speed", 4.0))
	assert(game.projection.drop_at(Vector2.ZERO, "DEV_SANDBOX_A"))

	# Real queue overload, not a synthetic status flag. Overflow must be
	# contained by EventBus and offer recovery, never kill the process.
	var rejected := 0
	for i in range(170):
		if not game.queue_world_event({"type": "DEV_STRESS", "index": i}):
			rejected += 1
	assert(rejected > 0)
	assert(game.event_bus.pending_count() <= 128)
	assert(game.recovery_guard.pending)
	assert(notices.size() == 1)
	assert(not game.mark_safe_state())
	assert(game.recovery_guard.snapshot_for_recovery() == safe)
	assert(game.recover_last_safe_state())
	assert(game.make_snapshot() == safe)
	assert(game.event_bus.pending_count() == 0)
	assert(not game.recovery_guard.pending)
	assert(not game.recover_last_safe_state())
	assert(game.mark_safe_state())

	var guard = Guard.new()
	assert(not guard.capture({"format": 2, "entities": []}))
	assert(guard.report("NO_SAFE_STATE"))
	assert(guard.snapshot_for_recovery().is_empty())
	assert(not guard.report("DUPLICATE"))
	guard.acknowledge()
	assert(not guard.pending)
	game.queue_free()
	print("LUNA runtime2d: real overflow, single incident and safe world recovery passed")
	quit(0)
