extends SceneTree
## Real actor/AI/regen simulation uses the approved SLOW/NORMAL/FAST modes.
## Protective save/rewind cooldowns deliberately remain on real-world time.
const GAME = preload("res://scenes/runtime2d/sandbox.tscn")
const WorldClock2D = preload("res://scripts/runtime2d/world_clock_2d.gd")


func _initialize() -> void:
	call_deferred("_run")


func _walk_for_frames(actor: CharacterBody2D, frames: int) -> float:
	var first: Vector2 = actor.global_position
	for i in range(frames):
		await physics_frame
	return actor.global_position.distance_to(first)


func _run() -> void:
	_check_daily_clock()
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

	_check_daily_rules_and_door(game)
	game.queue_free()
	print("LUNA runtime2d: scaled movement, daily clock, night rules, doors and V2 save restore passed")
	quit(0)


func _check_daily_clock() -> void:
	var clock := WorldClock2D.new()
	var minutes: Array[int] = []
	clock.minute_changed.connect(func(minute: int): minutes.append(minute))
	assert(clock.set_time_of_day(1439.5))
	assert(clock.set_mode("SLOW"))
	clock.advance(1.0) # 23:59.5 + half a simulated minute.
	assert(clock.minute_of_day() == 0)
	assert(minutes == [1439, 0])
	assert(clock.is_in_window(18 * 60, 6 * 60))
	assert(clock.set_mode("FAST"))
	clock.advance(2.25)
	assert(clock.snapshot()["day_minute"] == 4.5)
	assert(clock.set_time_of_day(6 * 60))
	assert(not clock.is_in_window(18 * 60, 6 * 60))
	assert(clock.is_in_window(6 * 60, 18 * 60))
	assert(not clock.is_in_window(0, 0))
	assert(not clock.restore({"mode": "NORMAL", "day_minute": NAN}))
	assert(clock.mode == "FAST" and clock.minute_of_day() == 6 * 60)
	assert(clock.restore({"mode": "NORMAL"})) # Earlier V2 records only saved the rate.
	assert(clock.minute_of_day() == WorldClock2D.START_MINUTE)


func _check_daily_rules_and_door(game: Node) -> void:
	var definitions := [
		{"id":"DEV_EVENING_SIGNAL","event":"ZONE_ENTERED","zone_id":"DEV_OBSERVATION_AREA",
		 "conditions":[{"type":"TIME_WINDOW","start_minute":1080.0,"end_minute":360.0}],
		 "action":{"type":"ANNOUNCE","event_id":"DEV_NIGHT_REACHED"}}
	]
	assert(game.world_rules.configure_location("DEV_SANDBOX_A", definitions))
	var malformed: Array = definitions.duplicate(true)
	malformed[0]["conditions"][0]["start_minute"] = 1439.5
	assert(not game.world_rules.configure_location("DEV_SANDBOX_A", malformed))
	var entered := {"type":"ZONE_ENTERED","zone_id":"DEV_OBSERVATION_AREA",
		"entity_id":"luna","location_id":"DEV_SANDBOX_A"}
	game._door.opens_at_minute = 18 * 60
	game._door.closes_at_minute = 6 * 60
	game.player.global_position = game._door.global_position
	var night_tint := Color("a4b8e8")
	game._live_level.night_tint = night_tint
	var world := game.get_node("World") as Node2D
	assert(game.world_clock.set_time_of_day(12 * 60))
	assert(world.modulate == Color.WHITE)
	assert(game.world_rules.process_event(entered, game) == 0)
	assert(not game.enter_nearby_door())
	assert(game.current_location_id == "DEV_SANDBOX_A")
	assert(game.world_clock.set_time_of_day(18 * 60))
	assert(world.modulate == night_tint)
	assert(game.world_rules.process_event(entered, game) == 1)
	assert(game.enter_nearby_door())
	assert(game.current_location_id == "DEV_SANDBOX_B")
	assert(game.world_clock.minute_of_day() == 18 * 60)
	assert(world.modulate == Color.WHITE) # The next room has its own lighting.
	assert(game.world_clock.set_time_of_day(3 * 60 + 0.25))
	var path := "user://test_luna_day_minute.json"
	var evening: Dictionary = game.make_snapshot()
	assert(game.store.write_snapshot(evening, path))
	assert(game.world_clock.set_time_of_day(12 * 60))
	assert(game.apply_snapshot(game.store.read_snapshot(path)))
	assert(game.world_clock.snapshot() == evening["time_clock"])
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path + ".bak"))

	var unchanged: Dictionary = game.make_snapshot()
	var invalid := unchanged.duplicate(true)
	invalid["time_clock"]["day_minute"] = 1440
	assert(not game.apply_snapshot(invalid))
	assert(game.make_snapshot() == unchanged)
