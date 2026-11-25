extends SceneTree

const Scene = preload("res://scenes/skeleton/outer_routes.tscn")
const Routes = preload("res://scripts/skeleton/outer_routes_fixture.gd")
const Access = preload("res://scripts/runtime2d/access_state_2d.gd")
const TIMEOUT_TICKS := 430

var world: Routes


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	world = Scene.instantiate()
	root.add_child(world)
	await physics_frame
	var traveler := world.actor
	assert(world.current_address == Routes.MEADOWS)
	assert(not world.begin_station_ride())
	assert(not world.play_buffer_melody("M02"))
	assert(world.access.set_wand_mode(Access.ORDINARY))
	world._place_actor(Vector2(913, 434))
	assert(world.actor.configure_dynamics(1.5, 0.12))
	assert(world.begin_station_ride())
	assert(world.current_address == Routes.BUFFER and world.actor == traveler)

	# Even a brief outward movement after crossing the line is safe.
	world._place_actor(Vector2(380, Routes.FRAME.position.y + 1.0))
	Input.action_press("ui_up")
	await _ticks(8)
	assert(world.outward_elapsed > 0.0)
	Input.action_release("ui_up")
	Input.action_press("ui_right")
	assert(await _wait_for(Routes.LUMA))
	Input.action_release("ui_right")
	assert(world.actor == traveler and traveler.dynamics_snapshot()["mass"] == 1.5)
	assert(world.access.wand_mode == Access.ORDINARY)

	# Knowledge enters the same buffer without boarding, and can return safely.
	world._place_actor(Vector2(681, 477))
	var safe := world.actor.position
	assert(world.play_buffer_melody("M08") and world.ride_destination == "")
	assert(world.actor == traveler and world.current_address == Routes.BUFFER)
	assert(world.use_route() and world.actor.position == safe and world.current_address == Routes.LUMA)

	# Deliberate sustained movement outside the frame breaks it, records state
	# and drops the actual traveler through a separate gravity-driven scene.
	world._place_actor(Vector2(925, 440))
	assert(world.begin_station_ride())
	Input.action_press("ui_up")
	for index in 220:
		await physics_frame
		if world.cracking:
			break
	Input.action_release("ui_up")
	assert(world.cracking and world.current_address == Routes.BUFFER)
	assert(not world.use_route() and not world.send_to_trash())
	assert(world.apply_snapshot(_round_trip_snapshot()))
	assert(world.cracking)
	traveler = world.actor
	assert(await _wait_for(Routes.SUBSPACE))
	assert(world.actor == traveler and not world.actor.motion.grounded)
	var height := world.actor.motion.elevation
	await _ticks(12)
	assert(world.actor.motion.elevation < height)
	assert(world.apply_snapshot(_round_trip_snapshot()))
	traveler = world.actor
	assert(await _wait_for(Routes.EDGE))
	assert(world.actor == traveler and world.actor.motion.grounded)
	assert(not world.use_route() and not world.begin_station_ride())

	Input.action_press("ui_right")
	assert(await _walk_until_x(1007.0, 320))
	Input.action_release("ui_right")
	assert(world.use_route() and world.current_address == Routes.COAST)
	assert(world.actor == traveler)
	assert(not world.use_route())

	# With ORDINARY and no modules, cross a real gap using the area's physics.
	# The saved anchor returns to the exact ordinary point, not a generic spawn.
	world._place_actor(Vector2(463, 524))
	var recovery_point := world.actor.position
	world.world_clock.set_time_of_day(world.Clock.NIGHT_MINUTE)
	assert(world.send_to_trash() and world.current_address == Routes.TRASH)
	assert(world.actor == traveler and world.last_safe_point == recovery_point)
	assert(not world.use_route())
	var broken := _round_trip_snapshot()
	broken["last_safe"]["address"] = Routes.BUFFER
	assert(not world.apply_snapshot(broken) and world.actor == traveler)

	Input.action_press("ui_right")
	assert(await _walk_until_x(500.0, 150))
	Input.action_release("ui_right")
	assert(not world.actor.motion.grounded and world.actor.motion.elevation == 0.0)
	var before_brake := world.actor.direction.length()
	world._tick_drift(0.18, Vector2.RIGHT, true)
	assert(world.actor.direction.length() < before_brake * 0.25)
	assert(world.apply_snapshot(_round_trip_snapshot()))
	traveler = world.actor
	assert(world.actor.gravity_scale == 0.0 and not world.actor.motion.grounded)
	Input.action_press("ui_right")
	assert(await _walk_until_x(912.0, 180))
	Input.action_release("ui_right")
	assert(world.actor.motion.grounded and world.use_route())
	assert(world.current_address == Routes.COAST and world.actor == traveler)
	assert(world.actor.position == recovery_point and world.actor.gravity_scale == 1.0)
	assert(world.access.wand_mode == Access.ORDINARY and world.actor.dynamics_snapshot()["mass"] == 1.5)
	assert(world.world_clock.phase() == world.Clock.Phase.NIGHT)
	print("P9-07: safe ride, M08 return, deliberate P01, gravity fall, coastal exit and Trash recovery passed")
	world.queue_free()
	await process_frame
	quit()


func _wait_for(address: String) -> bool:
	for tick in TIMEOUT_TICKS:
		if world.current_address == address:
			return true
		await physics_frame
	return false


func _walk_until_x(x: float, limit: int) -> bool:
	for tick in limit:
		if world.actor.position.x >= x:
			return true
		await physics_frame
	return false


func _round_trip_snapshot() -> Dictionary:
	return JSON.parse_string(JSON.stringify(world.make_snapshot()))


func _ticks(count: int) -> void:
	for tick in count:
		await physics_frame
