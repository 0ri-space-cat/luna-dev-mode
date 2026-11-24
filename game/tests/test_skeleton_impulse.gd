extends SceneTree

const Fixture = preload("res://scenes/skeleton/elevation_fixture.tscn")
const Motion = preload("res://scripts/skeleton/elevation_motion_2d.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_check_bounce_at_contact()
	var scene = Fixture.instantiate()
	scene.keyboard = false
	root.add_child(scene)
	await physics_frame

	var initial: Dictionary = scene.make_snapshot()
	var light_distance := 0.0
	for mass in [1.0, 4.0]:
		assert(scene.apply_snapshot(initial))
		var body = scene.actor
		var start := Vector2(174, 300)
		_place(body, start, 0.0)
		assert(body.configure_dynamics(mass, 0.0))
		assert(body.apply_impulse(Vector2(220.0, 0.0), 180.0))
		assert(is_equal_approx(_planar_impulse(body).x, 220.0 / mass))
		assert(is_equal_approx(body.motion.vertical_speed, 180.0 / mass))
		body.direction = Vector2.DOWN
		await _ticks(10)
		var distance: float = body.position.x - start.x
		assert(body.position.y > start.y + 8.0)
		assert(distance > 0.0 and _planar_impulse(body).x > 0.0)
		assert(_planar_impulse(body).x < 220.0 / mass)
		if mass == 1.0:
			light_distance = distance
		else:
			assert(light_distance > distance * 3.0)
		body.direction = Vector2.ZERO
		var released_at: float = body.position.x
		await _ticks(4)
		assert(body.position.x > released_at)

	assert(scene.apply_snapshot(initial))
	var actor = scene.actor
	_place(actor, Vector2(416, 288), 0.0)
	assert(actor.configure_dynamics(2.0, 0.65))
	assert(actor.apply_impulse(Vector2(520.0, 110.0)))
	assert(await _until(func(): return _planar_impulse(actor).x < -35.0))
	assert(actor.position.x < 454.0)
	assert(_planar_impulse(actor).y > 0.0)
	var at_wall: float = actor.position.x
	await _ticks(4)
	assert(actor.position.x < at_wall - 3.0)

	# Saving and reopening preserves the live motion and the two properties.
	var saved: Dictionary = scene.make_snapshot()
	var json_snapshot: Dictionary = JSON.parse_string(JSON.stringify(saved))
	assert(scene.apply_snapshot(json_snapshot))
	actor = scene.actor
	assert(actor.dynamics_snapshot() == saved["actor"]["dynamics"])
	assert(is_equal_approx(actor.position.x, float(saved["actor"]["position"][0])))
	var before: Dictionary = actor.dynamics_snapshot()
	assert(not actor.configure_dynamics(0.0, 0.5))
	assert(not actor.configure_dynamics(1.0, -0.5))
	assert(not actor.configure_dynamics(1.0, 1.1))
	assert(not actor.apply_impulse(Vector2(INF, 0.0), 3.0))
	assert(not actor.apply_impulse(Vector2(1.0, 0.0), INF))
	assert(actor.dynamics_snapshot() == before)
	var invalid := json_snapshot.duplicate(true)
	invalid["actor"]["dynamics"]["mass"] = -2.0
	assert(not scene.apply_snapshot(invalid))
	assert(is_same(actor, scene.actor))
	var from_first_slice := json_snapshot.duplicate(true)
	from_first_slice["actor"].erase("dynamics")
	from_first_slice["actor"].erase("water")
	assert(scene.apply_snapshot(from_first_slice))
	actor = scene.actor
	assert(actor.dynamics_snapshot()["mass"] == 1.0)
	assert(actor.dynamics_snapshot()["bounciness"] == 0.0)
	assert(_planar_impulse(actor).is_zero_approx())
	assert(actor.water_snapshot() == {"buoyancy": 0.0, "swim_enabled": false})

	_place(actor, Vector2(530, 310), 0.0)
	assert(actor.configure_dynamics(1.0, 0.5))
	assert(actor.apply_impulse(Vector2.ZERO, 240.0))
	assert(await _until(func(): return actor.motion.vertical_speed < -100.0))
	assert(await _until(func(): return actor.motion.vertical_speed > 70.0))
	assert(not actor.motion.grounded)
	assert(await _until(func(): return actor.motion.grounded))
	assert(is_zero_approx(actor.motion.elevation) and is_zero_approx(actor.motion.vertical_speed))

	# Recovery keeps the body's configuration and discards residual push.
	_place(actor, Vector2(552, 310), 0.0)
	assert(actor.apply_impulse(Vector2(420.0, 0.0)))
	assert(await _until(func(): return actor.recoveries == 1))
	assert(actor.entity_id == "DEV_ELEVATION_ACTOR")
	assert(is_same(actor, scene.actor))
	assert(_planar_impulse(actor).is_zero_approx())
	assert(actor.dynamics_snapshot()["bounciness"] == 0.5)

	print("P9-01: mass, persistent impulse, wall and floor restitution, and snapshots passed")
	scene.queue_free()
	await process_frame
	quit()


func _check_bounce_at_contact() -> void:
	var platform: Array[Dictionary] = [{"bounds": Rect2(0, 0, 100, 100), "height": 0.0}]
	var point := Vector2(50, 50)
	for hz in [30, 60, 120]:
		var motion := Motion.new()
		motion.reset_on_surface(point, 0.0)
		motion.add_impulse(180.0)
		for tick in range(int(hz * 0.8)):
			motion.step(point, point, 1.0 / hz, -600.0, platform, 0.5)
		assert(not motion.grounded)
		assert(is_equal_approx(motion.elevation, 6.0))
		assert(is_equal_approx(motion.vertical_speed, -30.0))
		for tick in range(hz):
			motion.step(point, point, 1.0 / hz, -600.0, platform, 0.5)
		assert(motion.grounded and is_zero_approx(motion.vertical_speed))


func _planar_impulse(body) -> Vector2:
	var coordinates: Array = body.dynamics_snapshot()["impulse_velocity"]
	return Vector2(float(coordinates[0]), float(coordinates[1]))


func _place(body, point: Vector2, height: float) -> void:
	body.direction = Vector2.ZERO
	body.thrust_requested = false
	body.position = point
	body.motion.reset_on_surface(point, height)


func _ticks(count: int) -> void:
	for tick in range(count):
		await physics_frame
	await process_frame


func _until(condition: Callable) -> bool:
	for tick in range(180):
		await physics_frame
		if condition.call():
			return true
	return false
