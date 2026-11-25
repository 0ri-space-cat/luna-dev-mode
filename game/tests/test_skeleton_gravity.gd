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
	assert(not scene.request_wand_parameter_edit(TARGET, "GRAVITY_SCALE", NAN))
	assert(not scene.request_wand_parameter_edit(TARGET, "GRAVITY_SCALE", -1.0))
	var initial: Dictionary = scene.make_snapshot()
	var base_height: float = body.motion.elevation
	body.jump()
	await _ticks(20)
	var normal_height: float = body.motion.elevation
	assert(scene.apply_snapshot(initial))
	body = scene.entities.get_entity(TARGET)
	assert(scene.request_wand_parameter_edit(TARGET, "GRAVITY_SCALE", 0.2))
	body.jump()
	await _ticks(20)
	assert(body.motion.elevation > normal_height + 15.0)
	assert(body.motion.elevation > base_height)
	assert(not body.flight_enabled)
	var speed: float = body.motion.vertical_speed
	assert(scene.commands.execute_set(body, "gravity_scale", 1.0))
	assert(is_equal_approx(body.motion.vertical_speed, speed))
	assert(scene.commands.execute_set(body, "gravity_scale", 0.2))
	var state: Dictionary = JSON.parse_string(JSON.stringify(scene.make_snapshot()))
	assert(scene.apply_snapshot(state))
	body = scene.entities.get_entity(TARGET)
	assert(is_equal_approx(body.gravity_scale, 0.2))
	assert(is_equal_approx(body.motion.vertical_speed, speed))
	assert(scene.apply_snapshot(initial))
	body = scene.entities.get_entity(TARGET)
	assert(scene.request_wand_parameter_edit(TARGET, "GRAVITY_SCALE", 0.0))
	await _ticks(20)
	assert(body.motion.grounded and is_equal_approx(body.motion.elevation, base_height))
	var bad: Dictionary = scene.make_snapshot()
	for entry in bad["entities"]:
		if entry["id"] == TARGET:
			entry["gravity_scale"] = "invalid"
	assert(not scene.apply_snapshot(bad))
	assert(scene.entities.get_entity(TARGET) == body)
	print("P9-02: adjustable gravity, impulse preservation, neutral support and snapshots passed")
	scene.queue_free()
	await process_frame
	quit()

func _ticks(count: int) -> void:
	for tick in range(count):
		await physics_frame
