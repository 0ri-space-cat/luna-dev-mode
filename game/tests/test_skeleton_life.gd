extends SceneTree

const Fixture = preload("res://scenes/skeleton/entity_fixture.tscn")
const FRIDGE := "DEV_P9_02_FRIDGE"
const YETI := "DEV_P9_02_YETI"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene = Fixture.instantiate()
	scene.keyboard = false
	root.add_child(scene)
	await physics_frame
	var fridge = scene.entities.get_entity(FRIDGE)
	var yeti = scene.entities.get_entity(YETI)
	var initial: Dictionary = scene.make_snapshot()
	var a: Vector2 = fridge.position
	var b: Vector2 = yeti.position
	assert(not fridge.get_parameter("alive"))
	assert(yeti.get_parameter("alive") and yeti.get_parameter("asleep"))
	yeti.direction = Vector2.RIGHT
	yeti.jump()
	await _ticks(10)
	assert(yeti.position.is_equal_approx(b) and yeti.motion.grounded)
	assert(yeti.apply_impulse(Vector2.ZERO, 150.0))
	await _ticks(8)
	assert(yeti.motion.elevation > 80.0)
	await _ticks(60)
	assert(yeti.motion.grounded)
	assert(not scene.request_wand_parameter_edit(YETI, "IS_ALIVE", false))
	assert(not scene.request_wand_parameter_edit(FRIDGE, "IS_ALIVE", "true"))
	assert(scene.request_wand_parameter_edit(FRIDGE, "IS_ALIVE", true))
	assert(scene.request_wand_parameter_edit(YETI, "ASLEEP", false))
	await _ticks(12)
	assert(fridge.position.distance_to(a) > 12.0)
	assert(yeti.position.distance_to(b) > 12.0)
	assert(fridge.record.has_role("OBJECT") and fridge.record.has_role("CREATURE"))
	assert(scene.request_wand_parameter_edit(YETI, "ASLEEP", true))
	assert(scene.request_wand_parameter_edit(FRIDGE, "IS_ALIVE", false))
	a = fridge.position
	b = yeti.position
	await _ticks(15)
	assert(fridge.position.is_equal_approx(a) and yeti.position.is_equal_approx(b))
	assert(not fridge.record.has_role("CREATURE"))
	assert(scene.commands.undo())
	var saved: Dictionary = JSON.parse_string(JSON.stringify(scene.make_snapshot()))
	var bad := saved.duplicate(true)
	bad["entities"][0].erase("life")
	assert(not scene.apply_snapshot(bad))
	assert(scene.entities.get_entity(FRIDGE) == fridge)
	assert(scene.apply_snapshot(saved))
	fridge = scene.entities.get_entity(FRIDGE)
	yeti = scene.entities.get_entity(YETI)
	assert(fridge.record.id == FRIDGE and fridge.record.category == "fridge")
	assert(yeti.record.id == YETI and yeti.get_parameter("asleep"))
	await _ticks(12)
	assert(fridge.position.distance_to(a) > 12.0 and yeti.position.is_equal_approx(b))
	await _ticks(200)
	assert(fridge.motion.grounded and fridge.recoveries == 0)
	var legacy := initial.duplicate(true)
	legacy.erase("entity_state_version")
	legacy["entities"] = legacy["entities"].filter(func(body): return body["id"] != YETI)
	for body in legacy["entities"]:
		body.erase("life")
	assert(scene.apply_snapshot(legacy))
	assert(not scene.entities.get_entity(FRIDGE).get_parameter("alive"))
	assert(scene.actor.get_parameter("alive"))
	print("P9-02: life, sleep, passive physics, identity and compatible saves passed")
	scene.queue_free()
	await process_frame
	quit()

func _ticks(count: int) -> void:
	for tick in range(count):
		await physics_frame
