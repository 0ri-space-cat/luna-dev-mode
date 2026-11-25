extends SceneTree

const Start = preload("res://scenes/skeleton/start_island.tscn")
const Clock = preload("res://scripts/runtime2d/world_clock_2d.gd")
const Access = preload("res://scripts/runtime2d/access_state_2d.gd")
const Meadows = preload("res://scripts/skeleton/meadows_layout.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene = Start.instantiate()
	scene.keyboard = false
	root.add_child(scene)
	await physics_frame
	assert(scene.world_clock.phase() == Clock.Phase.DAY)
	var daylight: Color = scene.get_node("WorldLight").color

	assert(scene.world_clock.set_time_of_day(Clock.EVENING_MINUTE - 0.01))
	await physics_frame
	await physics_frame
	assert(scene.world_clock.phase() == Clock.Phase.EVENING)
	assert(scene.get_node("WorldLight").color != daylight)

	_place(scene, Vector2(1480, 350))
	scene.freeze_selected = true
	assert(scene.interact())
	var ice_before: float = scene.ice_remaining
	assert(ice_before > 0.0)
	_place(scene, Meadows.CAMP_SPOT)
	scene.has_donut = true
	assert(scene.interact())
	assert(scene.world_clock.phase() == Clock.Phase.MORNING)
	assert(scene.has_donut and scene.actor.position == Meadows.CAMP_SPOT)
	assert(scene.ice_remaining == ice_before)
	assert(scene.interact())
	assert(scene.world_clock.phase() == Clock.Phase.NIGHT)
	var night: Color = scene.get_node("WorldLight").color
	assert(night != daylight)

	var saved: Dictionary = JSON.parse_string(JSON.stringify(scene.make_snapshot()))
	var invalid := saved.duplicate(true)
	invalid["world_clock"]["day_minute"] = -1
	assert(not scene.apply_snapshot(invalid))
	assert(scene.world_clock.phase() == Clock.Phase.NIGHT)
	scene.world_clock.set_time_of_day(Clock.START_MINUTE)
	assert(scene.apply_snapshot(saved))
	assert(scene.world_clock.phase() == Clock.Phase.NIGHT)
	assert(scene.get_node("WorldLight").color == night)
	assert(scene.actor.position == Meadows.CAMP_SPOT and scene.has_donut)
	assert(is_equal_approx(scene.ice_remaining, ice_before))

	# The editor pauses active seconds and the clock. Rest changes only the clock.
	assert(scene.access.set_wand_mode(Access.PLAYFUL))
	_place(scene, scene.FRIDGE_SPOT + Vector2(0, 34))
	scene._toggle_debug_editor()
	assert(is_instance_valid(scene._debug_editor))
	var paused: Dictionary = scene.world_clock.snapshot()
	var remaining: float = scene.ice_remaining
	for tick in range(8):
		await physics_frame
	assert(scene.world_clock.snapshot() == paused and scene.ice_remaining == remaining)
	scene._toggle_debug_editor()
	for tick in range(8):
		await physics_frame
	assert(scene.world_clock.snapshot() != paused and scene.ice_remaining < remaining)

	saved.erase("world_clock")
	assert(scene.apply_snapshot(saved))
	assert(scene.world_clock.minute_of_day() == Clock.START_MINUTE)
	assert(scene.get_node("WorldLight").color == daylight)
	print("P9-04: natural phases, camp rest, light, clock persistence and active effect time passed")
	scene.queue_free()
	await process_frame
	quit()


func _place(scene: Node, point: Vector2) -> void:
	scene.actor.position = point
	assert(scene.actor.motion.start_on_safe_support(point, 0.0, scene._surfaces))
	scene.actor.location_id = scene._entity_location(point)
