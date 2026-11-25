extends SceneTree

const Scene = preload("res://scenes/skeleton/adventure.tscn")
const Adventure = preload("res://scripts/skeleton/adventure.gd")
const Island = preload("res://scripts/skeleton/start_island.gd")
const Console = preload("res://scripts/skeleton/ancient_console_2d.gd")
const Routes = preload("res://scripts/skeleton/outer_routes_fixture.gd")
const Access = preload("res://scripts/runtime2d/access_state_2d.gd")
const Clock = preload("res://scripts/runtime2d/world_clock_2d.gd")

var game: Adventure
var _path := "user://luna_ancient_console_%d.json" % OS.get_process_id()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	Engine.time_scale = 3.0
	_open_world()
	await physics_frame
	var home := game.home
	assert(not home.interact())
	assert(await _walk_to(Vector2(320, 480)))
	assert(home.interact() and home.access.wand_mode == Access.PLAYFUL)
	assert(await _walk_to(Vector2(320, 259)))
	assert(home.interact() and home.has_donut)
	assert(await _walk_to(Vector2(320, 374)))
	assert(await _walk_to(Vector2(684, 374)))
	assert(home.request_wand_parameter_edit(Island.BRIDGE_YETI_ID, "ASLEEP", false))
	assert(home.interact() and not home.has_donut)
	for point in [Vector2(1010, 371), Vector2(1277, 370), Vector2(1287, 602),
		Vector2(1885, 603), Vector2(1888, 246), Vector2(1909, 109),
		Vector2(2170, 84), Vector2(2346, 85), Console.RETURN_POINT]:
		assert(await _walk_to(point))
	assert(home.actor.location_id == Console.LOCATION_ID and home.at_ancient_console())
	assert(home.wand_pair.duplicate == null)
	var actor := home.actor
	var original_position := actor.position

	# The real E and Enter path opens an empty focused field. It does not
	# expose a command list, edit individual objects, or suggest an address.
	_key(KEY_E)
	await process_frame
	var field := home.ancient_console.field
	assert(field.visible and field.has_focus() and field.text.is_empty() and field.placeholder_text.is_empty(),
		"Console open=%s focus=%s input=%s prompt=%s" % [field.visible, field.has_focus(), field.text, field.placeholder_text])
	_key(KEY_ESCAPE)
	assert(not field.visible)
	_key(KEY_E)
	await _type_command("TELEPORT meta_white_void")
	assert(field.visible and not game._away and actor.position.is_equal_approx(original_position))
	await _type_command("SET LUNA IS_ALIVE FALSE")
	assert(field.visible and not game._away and actor.get_parameter("alive"))
	await _type_command("TIME_OF_DAY NIGHT")
	assert(not field.visible and home.world_clock.phase() == Clock.Phase.NIGHT)
	_key(KEY_E)
	await process_frame
	var count := home.entities.count_live()
	await _type_command("SPAWN CAT")
	assert(field.visible and home.entities.count_live() == count)
	await _type_command("SPAWN FOX")
	var fox := home.entities.get_entity("FOREST_CONSOLE_FOX_00") as Island.EntityBody
	assert(not field.visible and home.entities.count_live() == count + 1)
	assert(fox != null and fox.get_parameter("alive") and fox.location_id == Console.LOCATION_ID)
	assert(fox.motion.grounded and Console.CLEARING.has_point(fox.position))
	await _assert_unsafe_landing_keeps_traveler()

	_key(KEY_E)
	await process_frame
	game.profile_path = "res://unwritable.json"
	await _type_command("TELEPORT " + Routes.WHITE_ADDRESS)
	assert(field.visible and not game._away and game.outer == null and actor.get_parent() == home)
	assert(actor.position.is_equal_approx(original_position))

	game.profile_path = _path
	await _type_command("TELEPORT " + Routes.WHITE_ADDRESS)
	assert(game._away and not field.visible and game.outer.current_address == Routes.WHITE_ADDRESS)
	assert(game.outer.actor == actor and game.outer.access == home.access and game.outer.world_clock == home.world_clock)
	assert(actor.motion.grounded and not game.outer.use_route())
	assert(game.journal.applied == 0 and game.journal.serial == 0)
	assert(game.outer._room.floor_bounds.has_point(actor.position))
	assert(not game.outer.read_local_record().contains(Routes.WHITE_ADDRESS))
	var invalid_guest := game.outer.make_snapshot()
	invalid_guest["address"] = Routes.BLACK_VOID
	assert(not game.outer.apply_snapshot(invalid_guest) and game.outer.current_address == Routes.WHITE_ADDRESS)

	assert(await _walk_to(Vector2(637, 441)))
	var saved_position := actor.position
	assert(game.save_game())
	assert(await _walk_to(Vector2(764, 438)))
	assert(game.load_game() and actor == game.outer.actor and actor.position.is_equal_approx(saved_position))

	game.queue_free()
	await process_frame
	_open_world()
	await physics_frame
	assert(game._profile_valid and game._away and game.outer.current_address == Routes.WHITE_ADDRESS)
	assert(game.outer.actor.position.is_equal_approx(saved_position) and game.outer.access.wand_mode == Access.PLAYFUL)
	assert(await _walk_to(game.outer._room.action_bounds.get_center()))
	actor = game.outer.actor
	_key(KEY_E)
	await process_frame
	assert(not game._away and game.outer == null and game.home.actor == actor)
	assert(actor.position.is_equal_approx(original_position) and actor.location_id == Console.LOCATION_ID)
	assert(game.home.access.wand_mode == Access.PLAYFUL and game.home.wand_pair.duplicate == null)
	assert(game.home.entities.get_entity("FOREST_CONSOLE_FOX_00") != null)
	assert(game.home.retreat_step == 2 and game.journal.applied == 0 and game.journal.serial == 0)

	assert(game.load_game() and game._away and game.outer.current_address == Routes.WHITE_ADDRESS)
	assert(game.outer.actor.position.is_equal_approx(saved_position))
	assert(await _walk_to(game.outer._room.action_bounds.get_center()))
	_key(KEY_E)
	await process_frame
	assert(not game._away and game.home.actor.position.is_equal_approx(original_position))

	game.queue_free()
	await process_frame
	_open_world()
	await physics_frame
	assert(game._profile_valid and not game._away and game.home.actor.position.is_equal_approx(original_position))
	game.queue_free()
	await process_frame
	for path in [_path, _path + ".bak"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("ANCIENT CONSOLE: dry approach, exact commands, checked placement, saved White Void and physical return passed")
	quit()


func _assert_unsafe_landing_keeps_traveler() -> void:
	var candidate: Routes = game.OUTER.instantiate()
	candidate.hosted_entry = Routes.WHITE_ADDRESS
	candidate.return_to_host = func() -> bool: return true
	game.add_child(candidate)
	var actor := game.home.actor
	var point := actor.position
	candidate.router.locations[Routes.WHITE_ADDRESS]["entries"]["entry"] = Vector2(-99, -99)
	assert(not candidate.mount_host_traveler(actor, game.home.access, game.home.world_clock))
	assert(candidate.actor == null and actor.get_parent() == game.home)
	assert(actor.position.is_equal_approx(point))
	candidate.queue_free()
	await process_frame


func _type_command(source: String) -> void:
	game.home.ancient_console.field.text = source
	_key(KEY_ENTER)
	await process_frame


func _key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	root.push_input(event)
	var released := event.duplicate() as InputEventKey
	released.pressed = false
	root.push_input(released)


func _walk_to(target: Vector2) -> bool:
	var body := game.home.actor
	for frame in 310:
		if body.position.distance_to(target) < 7.0:
			await physics_frame
			return body.motion.grounded
		var offset := target - body.position
		var action := &"ui_left" if offset.x < 0 else &"ui_right"
		if absf(offset.y) > absf(offset.x):
			action = &"ui_up" if offset.y < 0 else &"ui_down"
		Input.action_press(action)
		await physics_frame
		Input.action_release(action)
	push_error("Failed to walk toward %s at %s" % [target, body.position])
	return false


func _open_world() -> void:
	game = Scene.instantiate()
	game.profile_path = _path
	root.add_child(game)
