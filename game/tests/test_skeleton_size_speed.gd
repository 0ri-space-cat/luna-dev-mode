extends SceneTree

const Fixture = preload("res://scenes/skeleton/entity_fixture.tscn")
const TARGET := "DEV_P9_02_FRIDGE"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene = Fixture.instantiate()
	scene.keyboard = false
	root.add_child(scene)
	await physics_frame
	var body = scene.entities.get_entity(TARGET)
	assert(scene.request_wand_parameter_edit(TARGET, "IS_ALIVE", true))
	assert(scene.request_wand_parameter_edit(TARGET, "AUTONOMY", false))
	assert(scene.request_wand_parameter_edit(TARGET, "CONTROL_SOURCE", "PLAYER"))
	assert(not scene.request_wand_parameter_edit(TARGET, "SCALE", NAN))
	assert(not scene.request_wand_parameter_edit(TARGET, "MOVE_SPEED", -1.0))
	assert(body.apply_impulse(Vector2(90.0, 0.0)))
	var inertia: Array = body.dynamics_snapshot()["impulse_velocity"]
	assert(scene.request_wand_parameter_edit(TARGET, "MOVE_SPEED", 0.0))
	assert(body.dynamics_snapshot()["impulse_velocity"] == inertia)
	assert(body.apply_impulse(Vector2(-90.0, 0.0)))
	var initial: Dictionary = scene.make_snapshot()
	var a: Vector2 = body.position
	assert(scene.request_wand_parameter_edit(TARGET, "MOVE_SPEED", 1.0))
	body.direction = Vector2.RIGHT
	await _ticks(6)
	var slow: float = body.position.x - a.x
	assert(scene.apply_snapshot(initial))
	body = scene.entities.get_entity(TARGET)
	assert(scene.request_wand_parameter_edit(TARGET, "MOVE_SPEED", 3.0))
	body.direction = Vector2.RIGHT
	await _ticks(6)
	assert(body.position.x - a.x > slow * 2.0)
	assert(scene.apply_snapshot(initial))
	body = scene.entities.get_entity(TARGET)
	# Two native wall shapes leave a sixteen-pixel gap.
	for wall in [
		{"bounds": Rect2(270, 226, 30, 30), "height": 160.0, "layer": 4},
		{"bounds": Rect2(270, 272, 30, 96), "height": 160.0, "layer": 8},
	]:
		scene._walls.append(wall)
		scene._build_wall(wall)
	await physics_frame
	assert(scene.request_wand_parameter_edit(TARGET, "MOVE_SPEED", 2.0))
	body.direction = Vector2.RIGHT
	await _ticks(25)
	assert(body.position.x < 268.0)
	assert(scene.request_wand_parameter_edit(TARGET, "SCALE", 0.5))
	assert(is_equal_approx(body.foot_radius(), 5.5))
	body.direction = Vector2.RIGHT
	await _ticks(8)
	assert(body.position.x > 270.0 and body.position.x < 296.0)
	body.direction = Vector2.ZERO
	var before: Vector2 = body.position
	assert(not scene.request_wand_parameter_edit(TARGET, "SCALE", 1.0))
	assert(body.get_parameter("size") == 0.5 and body.position.is_equal_approx(before))
	var saved: Dictionary = JSON.parse_string(JSON.stringify(scene.make_snapshot()))
	var bad := saved.duplicate(true)
	for state in bad["entities"]:
		if state["id"] == TARGET:
			state["movement"]["size"] = 1.0
	assert(not scene.apply_snapshot(bad))
	assert(scene.apply_snapshot(saved))
	body = scene.entities.get_entity(TARGET)
	assert(body.get_parameter("size") == 0.5 and body.position.is_equal_approx(before))
	body.direction = Vector2.RIGHT
	await _ticks(12)
	assert(body.position.x > 300.0)
	print("P9-02: speed, independent inertia, physical narrow passage, safe resize and snapshots passed")
	scene.queue_free()
	await process_frame
	quit()

func _ticks(count: int) -> void:
	for tick in range(count):
		await physics_frame
