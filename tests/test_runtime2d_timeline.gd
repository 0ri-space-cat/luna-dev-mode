extends SceneTree
## The world can rewind through real snapshots without rewinding its cooldown.
## This is a system primitive; no Time Button visual or puzzle is implemented.

const GAME = preload("res://scenes/runtime2d/sandbox.tscn")
const Timeline = preload("res://scripts/runtime2d/world_timeline_2d.gd")


func _initialize() -> void:
	call_deferred("_run")


func _advance_one_second(history, world_snapshot: Dictionary) -> void:
	for i in range(4):
		if history.tick(0.25):
			assert(history.record(world_snapshot))


func _run() -> void:
	var game = GAME.instantiate()
	root.add_child(game)
	await physics_frame
	game.timeline.reset(game.make_snapshot())
	game.player.global_position = Vector2(20, 20)
	_advance_one_second(game.timeline, game.make_snapshot())
	game.player.global_position = Vector2(180, 20)
	_advance_one_second(game.timeline, game.make_snapshot())
	assert(game.timeline.available_samples() >= 3)
	var candidate: Dictionary = game.timeline.preview(0.5)
	assert(not candidate.is_empty())
	assert(candidate["world"]["location"] == "DEV_SANDBOX_A")
	(candidate["world"] as Dictionary)["location"] = "INVALID"
	assert(game.timeline.preview(0.5)["world"]["location"] == "DEV_SANDBOX_A")

	assert(game.rewind_world(0.5))
	assert(game.player.global_position == Vector2(20, 20))
	assert(game.timeline.cooldown_remaining > 0.0)
	assert(not game.rewind_world(0.5))
	# Reloading a valid saved state must not bypass the anti-loop safeguard.
	assert(game.apply_snapshot(game.make_snapshot()))
	assert(game.timeline.cooldown_remaining > 0.0)
	assert(not game.rewind_world(0.5))

	var bounded = Timeline.new()
	bounded.reset({"format": 2, "checkpoint": 0})
	for n in range(75):
		_advance_one_second(bounded, {"format": 2, "checkpoint": n + 1})
	assert(bounded.available_samples() == bounded.MAX_SAMPLES)
	assert(bounded.preview(1.0)["world"]["checkpoint"] == 74)
	assert(bounded.preview(64.0).is_empty()) # Beyond the supported horizon.
	game.queue_free()
	print("LUNA runtime2d: bounded temporal snapshots, cooldown and atomic rewind passed")
	quit(0)
