extends SceneTree

const Scene = preload("res://scenes/skeleton/outer_routes.tscn")
const Routes = preload("res://scripts/skeleton/outer_routes_fixture.gd")
const Access = preload("res://scripts/runtime2d/access_state_2d.gd")
const Clock = preload("res://scripts/runtime2d/world_clock_2d.gd")

var world: Routes


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	world = Scene.instantiate()
	root.add_child(world)
	await physics_frame
	var old := _snapshot()
	old.erase("outer_exploration")
	old["routes"] = {}
	assert(world.apply_snapshot(old))
	assert(world.current_address == Routes.MEADOWS)
	await _test_ghost_route()
	await _test_house_route()
	assert(world.send_to_trash())
	assert(world.read_local_record() == "" and not world.void_ghost_available())
	assert(world._record_text == "")
	assert(not world.use_route())
	print("P9-07: bounded voluntary ghost rides, distant record, exact house link and both natural exits passed")
	world.queue_free()
	await process_frame
	quit()


func _test_ghost_route() -> void:
	world._place_actor(Vector2(922, 436))
	assert(not world.play_station_melody("M02"))
	world.world_clock.set_time_of_day(Clock.NIGHT_MINUTE)
	assert(not world.play_station_melody("M08"))
	assert(world.play_station_melody("M02") and not world._board_station_ghost())
	assert(world.apply_snapshot(_snapshot()) and world.station_ghost_available())
	assert(world.access.set_wand_mode(Access.ORDINARY))
	var traveler := world.actor
	world._place_actor(Vector2(755, 545))
	assert(world.use_route())
	assert(world.current_address == Routes.TRASH and world.actor == traveler)
	assert(world.actor.position == Vector2(638, 254))
	assert(not world._at_action() and world.read_local_record() == "")
	assert(not world.use_route())
	var delay := world.exploration.return_delay
	assert(delay >= Routes.VoidExploration.MIN_WAIT and delay <= Routes.VoidExploration.MAX_WAIT)

	# Fly across the real gaps to the distant technical fragment. No tool or
	# earlier address entry is available, and the text stays local to the record.
	assert(await _drift_to(Vector2(1080, 672)))
	assert(world.actor.motion.grounded)
	assert(world.use_route() and world._record_text == "META_WHITE_VOID")
	assert(world.exploration.return_wait > 0.0)
	assert(world.apply_snapshot(_snapshot()))
	assert(is_equal_approx(world.exploration.return_delay, delay) and world._record_text == "")
	traveler = world.actor
	assert(await _drift_to(Vector2(635, 250)))
	for tick in 550:
		if world.void_ghost_available():
			break
		await physics_frame
	assert(world.void_ghost_available())
	assert(world.current_address == Routes.TRASH and world._record_text == "")
	world.world_clock.set_time_of_day(Clock.START_MINUTE)
	assert(world.use_route() and world.current_address == Routes.LUMA)
	assert(world.actor == traveler and world.world_clock.phase() == Clock.Phase.NIGHT)
	assert(world.access.wand_mode == Access.ORDINARY)


func _test_house_route() -> void:
	world._place_actor(Vector2(461, 421))
	var source := world.actor.position
	assert(not world.use_route() and not world.request_door_address(Routes.HOUSE_04))
	assert(world.access.set_wand_mode(Access.PLAYFUL))
	assert(not world.request_door_address("et_luma_res_04"))
	assert(world.request_door_address(Routes.HOUSE_04))
	assert(world.current_address == Routes.HOUSE_04 and world.actor.gravity_scale == 1.0)
	assert(world.apply_snapshot(_snapshot()))
	var traveler := world.actor
	assert(world.use_route() and world.current_address == Routes.LUMA)
	assert(world.actor == traveler and world.actor.position == source)
	assert(world.use_route() and world.current_address == Routes.HOUSE_04)
	assert(world.toggle_local_door() and world.current_address == Routes.HOUSE_04)
	assert(world.use_route() and world.current_address == Routes.TRASH)
	assert(world.actor.position == Vector2(248, 242) and not world.use_route())

	world._place_actor(Vector2(950, 440))
	assert(world.use_route() and world.current_address == Routes.LUMA and world.actor.position == source)
	assert(not world.use_route())
	assert(world.request_door_address(Routes.HOUSE_04))
	world._place_actor(Vector2(920, 434))
	assert(world.use_route() and world._record_text == "M08")
	assert(world.play_buffer_melody("M08") and world.current_address == Routes.BUFFER)
	assert(world.apply_snapshot(_snapshot()))
	assert(world.use_route() and world.current_address == Routes.HOUSE_04)

	assert(world.toggle_local_door())
	for attempt in Routes.VoidExploration.MAX_OPENINGS:
		assert(world.toggle_local_door())
		if world.exploration.door_glowing():
			break
		assert(world.toggle_local_door())
	assert(world.exploration.door_glowing())
	assert(world.exploration.door_openings >= Routes.VoidExploration.MIN_OPENINGS)
	assert(world.apply_snapshot(_snapshot()) and world.exploration.door_glowing())
	traveler = world.actor
	assert(world.use_route() and world.current_address == Routes.LUMA and world.actor == traveler)
	assert(world.actor.position == Vector2(238, 434) and not world.use_route())
	assert(world.exploration.house_source == null)
	assert(get_nodes_in_group("runtime2d_address_doors").size() == 1)
	var invalid := _snapshot()
	invalid["outer_exploration"]["house_source"] = [940, 445]
	assert(not world.apply_snapshot(invalid) and world.actor == traveler)


func _snapshot() -> Dictionary:
	return JSON.parse_string(JSON.stringify(world.make_snapshot()))


func _drift_to(target: Vector2) -> bool:
	for tick in 430:
		var offset := target - world.actor.position
		_set_axis("ui_left", "ui_right", offset.x)
		_set_axis("ui_up", "ui_down", offset.y)
		if offset.length() < 19.0 and world.actor.motion.grounded:
			Input.action_release("ui_left")
			Input.action_release("ui_right")
			Input.action_release("ui_up")
			Input.action_release("ui_down")
			return true
		await physics_frame
	push_error("Did not reach %s from %s" % [target, world.actor.position])
	return false


func _set_axis(negative: String, positive: String, offset: float) -> void:
	if offset < -11.0:
		Input.action_press(negative)
	else:
		Input.action_release(negative)
	if offset > 11.0:
		Input.action_press(positive)
	else:
		Input.action_release(positive)
