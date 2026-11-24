extends SceneTree

const Fixture = preload("res://scenes/skeleton/water_fixture.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene = Fixture.instantiate()
	scene.keyboard = false
	root.add_child(scene)
	await physics_frame
	var actor = scene.actor
	var volume = actor.water_volumes[0]
	var basin := Vector2(430, 324)
	assert(is_equal_approx(volume.submerged_fraction(basin, 68.5, 27.0), 0.5))
	assert(is_equal_approx(volume.submerged_fraction(basin, -10.0, 27.0), 17.0 / 27.0))
	assert(is_zero_approx(volume.submerged_fraction(basin, 112.0, 27.0)))
	assert(is_zero_approx(volume.submerged_fraction(Vector2(810, 325), 30.0, 27.0)))
	var initial: Dictionary = scene.make_snapshot()

	# Walk off the bank. Height, rather than trigger overlap alone, enters the water.
	actor.direction = Vector2.RIGHT
	assert(await _until(func(): return actor.position.x > 258.0))
	actor.direction = Vector2.ZERO
	assert(await _until(func(): return actor.motion.elevation < 82.0))
	assert(not actor.motion.grounded)

	# A light passive body floats with its feet immersed and drifts with the water.
	assert(scene.apply_snapshot(initial))
	actor = scene.actor
	_place(actor, basin, 25.0)
	assert(actor.configure_water(1.55, false))
	assert(await _until(func(): return actor.motion.elevation > 58.0))
	await _ticks(85)
	assert(actor.motion.elevation > 58.0 and actor.motion.elevation < 76.0)
	assert(not actor.motion.grounded)
	assert(actor.position.x > basin.x + 36.0)
	var passive_y: float = actor.position.y
	actor.direction = Vector2.DOWN
	actor.swim_intent = -1.0
	await _ticks(24)
	assert(absf(actor.position.y - passive_y) < 0.01)
	assert(actor.motion.elevation > 58.0)

	# The same displacement force cannot support a heavy body.
	assert(scene.apply_snapshot(initial))
	actor = scene.actor
	_place(actor, basin, 72.0)
	assert(actor.configure_dynamics(3.0, 0.0))
	assert(actor.configure_water(1.55, false))
	actor.flight_enabled = true
	actor.thrust_requested = true
	assert(await _until(func(): return actor.motion.grounded))
	assert(is_zero_approx(actor.motion.elevation))
	await _ticks(18)
	assert(actor.motion.grounded and is_zero_approx(actor.motion.vertical_speed))

	# The actual swimmer can drive downward, rise again, then reach dry footing.
	actor.flight_enabled = false
	actor.thrust_requested = false
	assert(actor.configure_water(1.55, true))
	actor.swim_intent = 1.0
	assert(await _until(func(): return actor.motion.elevation > 32.0))
	actor.swim_intent = -1.0
	assert(await _until(func(): return actor.motion.grounded))
	assert(is_zero_approx(actor.motion.elevation))
	var before_upstream: float = actor.position.x
	actor.direction = Vector2.LEFT
	actor.swim_intent = 0.0
	await _ticks(18)
	assert(actor.position.x < before_upstream - 12.0)
	actor.direction = Vector2.RIGHT
	actor.swim_intent = 1.0
	assert(await _until(func(): return actor.position.x > 746.0, 260))
	actor.direction = Vector2.ZERO
	assert(await _until(func(): return actor.motion.grounded))
	assert(actor.position.x >= 730.0)
	assert(actor.recoveries == 0)

	# A bridge above the water is dry. A matching sideways impulse in the water damps faster.
	assert(scene.apply_snapshot(initial))
	actor = scene.actor
	_place(actor, Vector2(374, 229), 112.0)
	actor.swim_intent = 1.0
	await _ticks(20)
	assert(actor.motion.grounded and is_equal_approx(actor.motion.elevation, 112.0))
	assert(is_equal_approx(actor.position.x, 374.0))
	assert(actor.apply_impulse(Vector2(0.0, 110.0)))
	await _ticks(12)
	var dry_speed := _inertia_y(actor)
	assert(actor.motion.grounded and is_equal_approx(actor.motion.elevation, 112.0))

	assert(scene.apply_snapshot(initial))
	actor = scene.actor
	_place(actor, basin, 32.0)
	assert(actor.configure_water(1.0, false))
	assert(actor.apply_impulse(Vector2(0.0, 110.0)))
	await _ticks(12)
	assert(_inertia_y(actor) > 0.0 and _inertia_y(actor) < dry_speed - 8.0)
	assert(actor.position.x > basin.x + 1.0)
	assert(is_equal_approx(actor.motion.elevation, 32.0))

	# Load a snapshot in the volume. Medium contact is derived from restored world position.
	var snapshot: Dictionary = JSON.parse_string(JSON.stringify(scene.make_snapshot()))
	assert(scene.apply_snapshot(snapshot))
	actor = scene.actor
	assert(actor.water_snapshot() == snapshot["actor"]["water"])
	var restored: Dictionary = actor.dynamics_snapshot()
	var expected: Dictionary = snapshot["actor"]["dynamics"]
	for axis in range(2):
		assert(is_equal_approx(float(restored["impulse_velocity"][axis]),
			float(expected["impulse_velocity"][axis])))
	assert(is_equal_approx(actor.motion.elevation, 32.0))
	await _ticks(10)
	assert(is_equal_approx(actor.motion.elevation, 32.0))
	var invalid := snapshot.duplicate(true)
	invalid["actor"]["water"]["buoyancy"] = -0.5
	assert(not scene.apply_snapshot(invalid))
	assert(is_same(scene.actor, actor))

	print("P9-01: tank boundaries, buoyancy, drag, current, swimming, bridge and snapshots passed")
	scene.queue_free()
	await process_frame
	quit()


func _place(actor, point: Vector2, height: float) -> void:
	actor.direction = Vector2.ZERO
	actor.thrust_requested = false
	actor.swim_intent = 0.0
	actor.position = point
	actor.motion.reset_on_surface(point, height if height == 112.0 else 0.0)
	if height != 112.0 and height > 0.0:
		actor.motion.elevation = height
		actor.motion.grounded = false


func _inertia_y(actor) -> float:
	return float(actor.dynamics_snapshot()["impulse_velocity"][1])


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
