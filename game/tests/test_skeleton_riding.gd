extends SceneTree
## Exercise the carrier relationship through real body movement and fixture saves.

const Fixture = preload("res://scenes/skeleton/riding_fixture.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene = Fixture.instantiate()
	scene.keyboard = false
	root.add_child(scene)
	await physics_frame
	var rider = scene.actor
	var mount = scene.carrier
	var initial: Dictionary = scene.make_snapshot()

	# Near a real seat in XY and Z, within its load budget, with only one link.
	assert(not mount.try_board(mount))
	_place(rider, Vector2(115, 330), 94.0)
	assert(not mount.try_board(rider))
	_place(rider, Vector2(160, 332), 0.0)
	assert(not mount.try_board(rider))
	_place(rider, Vector2(160, 332), 94.0)
	assert(rider.configure_dynamics(2.5, 0.0))
	assert(not mount.try_board(rider))
	assert(rider.configure_dynamics(1.0, 0.0))
	assert(mount.apply_impulse(Vector2(120.0, 0.0)))
	assert(is_equal_approx(_inertia_x(mount), 40.0))
	assert(mount.apply_impulse(Vector2(-120.0, 0.0)))
	assert(mount.try_board(rider))
	assert(not mount.try_board(rider))
	assert(mount.has_rider() and rider.is_riding())
	assert(not rider.configure_dynamics(3.0, 0.0))
	assert(rider.apply_impulse(Vector2(120.0, 0.0)))
	assert(is_equal_approx(_inertia_x(mount), 30.0))
	assert(is_zero_approx(_inertia_x(rider)))
	assert(rider.apply_impulse(Vector2(-120.0, 0.0)))

	var start_y: float = mount.position.y
	mount.direction = Vector2.DOWN
	await _ticks(10)
	assert(mount.position.y > start_y + 12.0)
	assert(_at_seat(rider, mount))
	assert(rider.try_dismount())
	assert(not mount.has_rider() and not rider.is_riding())
	assert(await _until(func(): return rider.motion.grounded))
	assert(is_equal_approx(rider.motion.elevation, 94.0))
	assert(rider.position.distance_to(mount.position) > 20.0)

	# Ride into the air using the carrier's FLY; losing it causes a real fall.
	assert(scene.apply_snapshot(initial))
	rider = scene.actor
	mount = scene.carrier
	assert(mount.try_board(rider))
	mount.direction = Vector2.RIGHT
	mount.thrust_requested = true
	assert(await _until(func(): return mount.position.x > 326.0 and mount.motion.elevation > 135.0))
	mount.direction = Vector2.ZERO
	assert(_at_seat(rider, mount) and not rider.flight_enabled)
	assert(not rider.try_dismount())
	mount.flight_enabled = false
	assert(await _until(func(): return mount.motion.vertical_speed < -15.0))
	assert(await _until(func(): return mount.motion.elevation < 70.0))
	assert(_at_seat(rider, mount))

	# The protected seat carries the rider below the waterline without giving SWIM.
	mount.swim_intent = -1.0
	assert(await _until(func(): return rider.motion.elevation + 27.0 < 76.0))
	assert(_at_seat(rider, mount))
	assert(not rider.water_snapshot()["swim_enabled"])
	assert(not rider.try_dismount())
	var submerged: Dictionary = JSON.parse_string(JSON.stringify(scene.make_snapshot()))
	var invalid := submerged.duplicate(true)
	invalid["carrier"]["seat"]["protected"] = false
	assert(not scene.apply_snapshot(invalid))
	assert(is_same(rider, scene.actor) and rider.is_riding())
	invalid = submerged.duplicate(true)
	invalid["actor"]["motion"]["elevation"] = float(invalid["actor"]["motion"]["elevation"]) + 4.0
	assert(not scene.apply_snapshot(invalid))
	assert(scene.apply_snapshot(submerged))
	rider = scene.actor
	mount = scene.carrier
	assert(rider.is_riding() and _at_seat(rider, mount))
	assert(rider.entity_id == "DEV_ELEVATION_ACTOR")
	assert(mount.entity_id == "DEV_ELEVATION_CARRIER")

	mount.direction = Vector2.RIGHT
	mount.swim_intent = 1.0
	assert(await _until(func(): return mount.position.x > 757.0, 420))
	mount.direction = Vector2.ZERO
	assert(await _until(func(): return mount.motion.grounded))
	assert(rider.try_dismount())
	assert(await _until(func(): return rider.motion.grounded))
	assert(is_zero_approx(rider.motion.elevation) and rider.position.x >= 730.0)
	assert(rider.recoveries == 0)

	# An open seat cannot descend below the head's waterline.
	assert(scene.apply_snapshot(initial))
	rider = scene.actor
	mount = scene.carrier
	assert(mount.configure_seat(16.0, 2.0, false))
	_air_start(rider, Vector2(395, 324), 58.0)
	_air_start(mount, Vector2(415, 324), 58.0)
	assert(mount.try_board(rider))
	mount.swim_intent = -1.0
	assert(await _until(func(): return mount.motion.elevation < 42.0))
	await _ticks(24)
	assert(rider.is_riding() and _at_seat(rider, mount))
	assert(rider.motion.elevation + 27.0 > 82.0)
	assert(not rider.try_dismount())

	# Despawning a carrier clears the relationship and recovers the same rider on dry land.
	mount.queue_free()
	await process_frame
	await process_frame
	assert(not rider.is_riding() and is_same(rider, scene.actor))
	assert(rider.motion.grounded and rider.position.x < 250.0)
	assert(rider.recoveries == 1)
	var after_loss: Dictionary = scene.make_snapshot()
	assert(after_loss["carrier"] == null and after_loss["mounted_on"] == "")
	assert(scene.apply_snapshot(after_loss))
	assert(not scene.actor.is_riding())

	print("P9-01: boarding, capacity, loaded motion, flight, water seats, dismount and recovery passed")
	scene.queue_free()
	await process_frame
	quit()


func _at_seat(rider, mount) -> bool:
	return rider.position.is_equal_approx(mount.position) \
		and is_equal_approx(rider.motion.elevation - mount.motion.elevation, 16.0)


func _inertia_x(body) -> float:
	return float(body.dynamics_snapshot()["impulse_velocity"][0])


func _place(body, point: Vector2, height: float) -> void:
	body.direction = Vector2.ZERO
	body.swim_intent = 0.0
	body.position = point
	body.motion.reset_on_surface(point, height)


func _air_start(body, point: Vector2, height: float) -> void:
	_place(body, point, 0.0)
	body.motion.elevation = height
	body.motion.grounded = false


func _ticks(count: int) -> void:
	for tick in range(count):
		await physics_frame
	await process_frame


func _until(condition: Callable, limit: int = 180) -> bool:
	for tick in range(limit):
		await physics_frame
		if condition.call():
			return true
	return false
