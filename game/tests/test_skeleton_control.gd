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
	var luna = scene.actor
	var fridge = scene.entities.get_entity(FRIDGE)
	var yeti = scene.entities.get_entity(YETI)
	assert(luna.accepts_player_input())
	assert(scene.request_wand_parameter_edit(FRIDGE, "IS_ALIVE", true))
	assert(scene.request_wand_parameter_edit(FRIDGE, "AUTONOMY", false))
	assert(scene.request_wand_parameter_edit(FRIDGE, "CONTROL_SOURCE", "PLAYER"))
	assert(scene.request_wand_parameter_edit(YETI, "AUTONOMY", false))
	assert(scene.request_wand_parameter_edit(YETI, "CONTROL_SOURCE", "PLAYER"))
	assert(not yeti.accepts_player_input())
	assert(not scene.request_wand_parameter_edit(FRIDGE, "CONTROL_SOURCE", "INVALID"))
	var a: Vector2 = luna.position
	var b: Vector2 = fridge.position
	var c: Vector2 = yeti.position
	scene.apply_player_input(Vector2.RIGHT)
	await _ticks(10)
	assert(luna.position.x > a.x + 10.0 and fridge.position.x > b.x + 10.0)
	assert(yeti.position.is_equal_approx(c))
	assert(scene.request_wand_parameter_edit(YETI, "ASLEEP", false))
	assert(yeti.accepts_player_input())
	assert(scene.request_wand_parameter_edit(FRIDGE, "CONTROL_SOURCE", "NONE"))
	b = fridge.position
	scene.apply_player_input(Vector2.UP)
	await _ticks(8)
	assert(fridge.position.is_equal_approx(b))
	assert(yeti.position.y < c.y - 10.0)
	assert(luna.set_parameter("ai_enabled", true))
	assert(not luna.accepts_player_input())
	assert(not scene.request_wand_parameter_edit(FRIDGE, "MASS", 3.0))
	assert(scene.return_to_luna() and luna.accepts_player_input())
	scene.apply_player_input(Vector2.ZERO)
	var state: Dictionary = JSON.parse_string(JSON.stringify(scene.make_snapshot()))
	var bad := state.duplicate(true)
	bad["entities"][0]["control"]["control_source"] = "INVALID"
	assert(not scene.apply_snapshot(bad))
	assert(scene.actor == luna)
	assert(scene.apply_snapshot(state))
	assert(scene.actor.accepts_player_input())
	assert(scene.entities.get_entity(YETI).accepts_player_input())
	assert(not scene.entities.get_entity(FRIDGE).accepts_player_input())
	var legacy := state.duplicate(true)
	legacy["entity_state_version"] = 1
	for body in legacy["entities"]:
		body.erase("control")
		body.erase("movement")
	assert(scene.apply_snapshot(legacy))
	assert(scene.actor.accepts_player_input())
	assert(not scene.entities.get_entity(YETI).accepts_player_input())
	print("P9-02: shared player control, sleep, autonomy, return and compatible snapshots passed")
	scene.queue_free()
	await process_frame
	quit()

func _ticks(count: int) -> void:
	for tick in range(count):
		await physics_frame
