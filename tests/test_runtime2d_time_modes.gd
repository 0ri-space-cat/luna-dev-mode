extends SceneTree
## Real actor/AI/regen simulation uses the approved SLOW/NORMAL/FAST modes.
## Protective save/rewind cooldowns deliberately remain on real-world time.
const GAME = preload("res://scenes/runtime2d/sandbox.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _walk_for_frames(actor: CharacterBody2D, frames: int) -> float:
	var first: Vector2 = actor.global_position
	for i in range(frames):
		await physics_frame
	return actor.global_position.distance_to(first)


func _run() -> void:
	var game = GAME.instantiate()
	root.add_child(game)
	await physics_frame
	var actor = game.world_registry.get_entity("DEV_ENTITY_01")
	assert(actor != null)
	assert(game.set_entity_parameter(actor.record.id, "ai_enabled", false))
	actor.set_external_drive(Vector2.RIGHT)
	assert(not game.set_world_time_mode("STOP"))
	assert(game.world_clock.mode == "NORMAL")
	assert(game.set_world_time_mode("SLOW"))
	actor.global_position = Vector2(-60, 120)
	var slow: float = await _walk_for_frames(actor, 12)
	assert(game.set_world_time_mode("NORMAL"))
	actor.global_position = Vector2(-60, 120)
	var ordinary: float = await _walk_for_frames(actor, 12)
	assert(game.set_world_time_mode("FAST"))
	actor.global_position = Vector2(-60, 120)
	var fast: float = await _walk_for_frames(actor, 12)
	assert(slow > 0.0 and ordinary > slow * 1.7 and fast > ordinary * 1.7)
	actor.clear_external_drive()

	assert(game.set_entity_parameter(actor.record.id, "health", 90))
	assert(game.set_entity_ability(actor.record.id, "REGENERATION", true))
	actor.passive_abilities._regeneration_elapsed = 1.92
	assert(game.set_world_time_mode("SLOW"))
	for i in range(5):
		await physics_frame
	assert(int(actor.get_parameter("health")) == 90)
	assert(game.set_world_time_mode("FAST"))
	for i in range(5):
		await physics_frame
	assert(int(actor.get_parameter("health")) == 91)

	var before: Dictionary = game.make_snapshot().duplicate(true)
	assert(before["time_clock"]["mode"] == "FAST")
	assert(game.set_world_time_mode("NORMAL"))
	assert(game.apply_snapshot(before))
	assert(game.world_clock.mode == "FAST")
	var invalid: Dictionary = game.make_snapshot().duplicate(true)
	invalid["time_clock"] = {"mode": "STOP"}
	var unchanged: Dictionary = game.make_snapshot()
	assert(not game.apply_snapshot(invalid))
	assert(game.make_snapshot() == unchanged)

	# FAST cannot consume a safety cooldown twice as quickly.
	game.timeline.cooldown_remaining = 10.0
	for i in range(5):
		await physics_frame
	assert(game.timeline.cooldown_remaining > 9.7)

	game.queue_free()
	print("LUNA runtime2d: scaled actor movement and regen, unscaled safety, save restore passed")
	quit(0)
