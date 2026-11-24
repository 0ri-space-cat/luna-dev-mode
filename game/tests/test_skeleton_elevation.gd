extends SceneTree
## Check both the vertical solver and the scene's real CharacterBody2D.

const Motion = preload("res://scripts/skeleton/elevation_motion_2d.gd")
const Fixture = preload("res://scenes/skeleton/elevation_fixture.tscn")
const SaveStore = preload("res://scripts/runtime2d/save_store_2d.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_check_solver()
	var scene = Fixture.instantiate()
	scene.keyboard = false
	root.add_child(scene)
	await physics_frame
	var body = scene.actor

	# Both decks overlap in world XY. Starting on the top deck is stable.
	assert(body.motion.grounded and is_equal_approx(body.motion.elevation, 72.0))
	body.direction = Vector2.RIGHT
	assert(await _until(func(): return body.position.x > 350.0 and not body.motion.grounded))
	body.direction = Vector2.ZERO
	assert(await _until(func(): return body.motion.grounded))
	assert(is_zero_approx(body.motion.elevation))
	assert(body.position.x > 350.0)

	# The same wall blocks travel on the floor and has a usable top.
	_place(body, Vector2(420, 280), 0.0)
	body.direction = Vector2.RIGHT
	await _ticks(30)
	assert(body.position.x < 454.0)
	body.jump()
	assert(await _until(func(): return body.position.x > 510.0))
	body.direction = Vector2.ZERO
	assert(await _until(func(): return body.motion.grounded))
	assert(is_zero_approx(body.motion.elevation))

	# Having flight available and pushing upward does not erase a higher wall.
	_place(body, Vector2(782, 280), 0.0)
	body.direction = Vector2.RIGHT
	body.flight_enabled = true
	body.thrust_requested = true
	await _ticks(30)
	assert(body.position.x < 820.0)
	assert(body.motion.elevation > 8.0 and body.motion.elevation < 160.0)
	assert(not body.motion.grounded)
	body.flight_enabled = false
	body.direction = Vector2.ZERO
	assert(await _until(func(): return body.motion.vertical_speed < 0.0))
	assert(await _until(func(): return body.motion.grounded))

	# Miss every support, then recover the original live object and identity.
	_place(body, Vector2(552, 290), 0.0)
	body.direction = Vector2.RIGHT
	assert(await _until(func(): return body.recoveries == 1))
	body.direction = Vector2.ZERO
	assert(is_same(body, scene.actor))
	assert(body.entity_id == "DEV_ELEVATION_ACTOR")
	assert(body.motion.grounded and is_zero_approx(body.motion.vertical_speed))
	assert(body.position.x < 590.0 and body.position.x >= 552.0)

	# Round-trip in flight, including the prior support used for recovery.
	_place(body, Vector2(160, 270), 72.0)
	body.jump()
	await _ticks(7)
	var saved: Dictionary = scene.make_snapshot()
	assert(not saved["actor"]["motion"]["grounded"])
	var decoded: Dictionary
	if OS.has_environment("LUNA_ELEVATION_JSON_ONLY"):
		decoded = JSON.parse_string(JSON.stringify(saved))
	else:
		var path := "user://p9_01_elevation_test_%d.json" % OS.get_process_id()
		var store := SaveStore.new()
		assert(store.write_snapshot(saved, path))
		decoded = store.read_snapshot(path)
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	assert(scene.apply_snapshot(decoded))
	var restored = scene.actor
	assert(restored.entity_id == saved["actor"]["id"])
	assert(is_equal_approx(restored.motion.elevation, float(saved["actor"]["motion"]["elevation"])))
	assert(is_equal_approx(restored.motion.vertical_speed,
		float(saved["actor"]["motion"]["vertical_speed"])))
	assert(restored.motion.snapshot()["anchor"] == saved["actor"]["motion"]["anchor"])
	assert(not restored.motion.grounded)
	var invalid := decoded.duplicate(true)
	invalid["actor"]["motion"]["anchor"] = [635, 315, 0]
	assert(not scene.apply_snapshot(invalid))
	invalid = decoded.duplicate(true)
	invalid["actor"]["position"] = [477, 300]
	invalid["actor"]["motion"]["elevation"] = 0
	invalid["actor"]["motion"]["vertical_speed"] = 0
	invalid["actor"]["motion"]["grounded"] = true
	assert(not scene.apply_snapshot(invalid))
	assert(is_same(restored, scene.actor))
	assert(await _until(func(): return restored.motion.grounded))
	assert(is_equal_approx(restored.motion.elevation, 72.0))

	print("P9-01: Z rates, overlapping platforms, walls, thrust, recovery and snapshot passed")
	scene.queue_free()
	await process_frame
	quit()


func _check_solver() -> void:
	var ground: Array[Dictionary] = [
		{"height": 0.0, "bounds": Rect2(0, 0, 100, 100)},
		{"height": 72.0, "bounds": Rect2(20, 20, 60, 60)},
	]
	var point := Vector2(50, 50)
	for hz in [30, 60, 120]:
		var body := Motion.new()
		body.reset_on_surface(point, 0.0)
		body.step(point, point, 1.0 / hz, -600.0, ground)
		assert(body.grounded and is_zero_approx(body.elevation))
		body.add_impulse(-100.0)
		assert(body.grounded and is_zero_approx(body.vertical_speed))
		body.add_impulse(270.0)
		for step in range(int(hz / 5.0)):
			body.step(point, point, 1.0 / hz, -600.0, ground)
		assert(is_equal_approx(body.elevation, 42.0))
		assert(is_equal_approx(body.vertical_speed, 150.0))
		# Zero gravity alone does not initiate ascent.
		body.reset_on_surface(point, 0.0)
		body.step(point, point, 1.0 / hz, 0.0, ground)
		assert(body.grounded and is_zero_approx(body.elevation))
		# Actual thrust can lift from rest even where a floor is present.
		body.step(point, point, 1.0 / hz, 200.0, ground)
		assert(not body.grounded and body.elevation > 0.0)
		# Descending at shared XY lands on the first crossed, upper support.
		body.elevation = 95.0
		body.vertical_speed = -200.0
		body.step(point, point, 0.2, -600.0, ground)
		assert(body.grounded and is_equal_approx(body.elevation, 72.0))

	# Stepping off halfway through a tick falls for the remaining time.
	var edge_body := Motion.new()
	edge_body.reset_on_surface(Vector2(70, 50), 72.0)
	edge_body.step(Vector2(70, 50), Vector2(90, 50), 0.2, -600.0, ground)
	assert(not edge_body.grounded)
	assert(is_equal_approx(edge_body.elevation, 69.0))


func _place(body, point: Vector2, height: float) -> void:
	body.direction = Vector2.ZERO
	body.thrust_requested = false
	body.position = point
	body.motion.reset_on_surface(point, height)


func _ticks(count: int) -> void:
	for i in range(count):
		await physics_frame
	await process_frame


func _until(condition: Callable) -> bool:
	for i in range(180):
		await physics_frame
		if condition.call():
			return true
	return false
