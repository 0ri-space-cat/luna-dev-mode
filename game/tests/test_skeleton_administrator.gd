extends SceneTree

const AdventureScene = preload("res://scenes/skeleton/adventure.tscn")
const Adventure = preload("res://scripts/skeleton/adventure.gd")
const Access = preload("res://scripts/runtime2d/access_state_2d.gd")
const Journal = preload("res://scripts/runtime2d/system_incident_journal_2d.gd")

var game: Adventure
var _profile := "user://luna_administrator_test_%d.json" % OS.get_process_id()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	Engine.time_scale = 3.0
	_open_playable_world()
	await physics_frame
	assert(game.journal.serial == 0)

	# Start the ordinary adventure and physically open the already authored bridge.
	assert(await _walk(Vector2(320, 264)))
	assert(game.home.interact() and game.home.has_donut)
	assert(await _walk(Vector2(320, 480)))
	assert(game.home.interact() and game.home.access.wand_mode == Access.PLAYFUL)
	assert(await _walk(Vector2(320, 374)) and await _walk(Vector2(686, 374)))
	assert(game.home.request_wand_parameter_edit(game.home.BRIDGE_YETI_ID, "ASLEEP", false))
	assert(game.home.interact() and not game.home.has_donut)
	assert(await _walk(Vector2(1288, 374)))
	await _walk_to_lake()
	assert(game.home.interact() and game.home.wand_pair.duplicate != null)
	assert(game.home.tick_wand_self_hack(3.05, true))
	assert(game.home.access.wand_mode == Access.DEVELOPER)
	assert(game.home.exchange_nearby_wand())
	assert(game.home.wand_pair.held == game.home.WandPair.DUPLICATE)
	assert(game.save_game())
	var known_world := game.home.make_snapshot()
	# Simulate a pre-M3.73 rollback snapshot with the original wand on the shore.
	known_world.erase("address_schema")
	for entry in known_world["entities"]:
		if entry["location_id"] == game.home.Lake.LOCATION_ID:
			entry["location_id"] = game.home.Lake.LEGACY_LOCATION_ID
	known_world["island"]["projection"]["location_id"] = game.home.Lake.LEGACY_LOCATION_ID

	# An integrity fault has ordinary recovery but does not count as player overload.
	assert(game.report_system_incident("DEV_SINGLE_FAULT"))
	assert(await _wait_for_recovery())
	assert(game.journal.applied == 0 and not game.journal.history[-1]["overload"])
	for repeat in 2:
		assert(game.demonstrate_overload())
		assert(await _wait_for_recovery())
		assert(game.journal.applied == 0)

	# Closing the game while a real overflow is pending replays the same
	# recovery once. The already solved bridge and both physical wands survive.
	assert(game.demonstrate_overload())
	assert(game.journal.pending["action"] == Journal.RESET_WAND)
	assert(not game.demonstrate_overload())
	var accepted := game.journal.serial
	await _restart()
	assert(await _wait_for_recovery())
	assert(game.journal.applied == 1 and game.journal.serial == accepted)
	assert(game.home.access.wand_mode == Access.ORDINARY)
	assert(game.home.wand_pair.held == game.home.WandPair.DUPLICATE)
	assert(game.apply_local_rollback(known_world))
	assert(game.home.wand_pair.original.ground_location_id == game.home.Lake.LOCATION_ID)
	assert(known_world["island"]["projection"]["location_id"] == game.home.Lake.LEGACY_LOCATION_ID)
	assert(game.load_game() and game.journal.applied == 1)
	assert(game.home.access.wand_mode == Access.ORDINARY and game.home.retreat_step == 2)
	assert(game.home.exchange_nearby_wand() and game.home.wand_pair.held == game.home.WandPair.ORIGINAL)
	assert(not game.home.tick_wand_self_hack(4.0, true))

	# Both routes remain physically open with an ordinary wand.
	await _walk_lake_to_meadows()
	assert(await _walk(Vector2(1290, 374)) and await _walk(Vector2(320, 374)))
	assert(await _walk(Vector2(320, 480)))
	assert(game.home.interact() and game.home.access.wand_mode == Access.PLAYFUL)
	assert(await _walk(Vector2(320, 256)))
	assert(game.home.interact() and game.home.has_donut)
	assert(await _walk(Vector2(320, 374)) and await _walk(Vector2(1288, 374)))
	await _walk_to_lake()
	assert(game.home.tick_wand_self_hack(3.05, true))
	assert(game.home.access.wand_mode == Access.DEVELOPER)

	# Bring a real carried prop into the second recovery. The exact recovered
	# Entity and attachment move to the authored Void scene and back.
	await _walk_lake_to_meadows()
	assert(await _walk(Vector2(1290, 374)) and await _walk(Vector2(1420, 396)))
	var plank_id := game.home.Meadows.PLANK_ID
	assert(game.home.interact_with_attachment(plank_id))
	assert(game.home.actor.has_passenger())
	assert(game.demonstrate_overload() and await _wait_for_recovery())
	assert(game.journal.applied == 1 and game.home.actor.has_passenger())
	var return_point := game.home.actor.position
	assert(game.demonstrate_overload())
	assert(game.journal.pending["action"] == Journal.REMOVE_LUNA)
	assert(await _wait_for_recovery())
	assert(game.journal.applied == 2 and game._away)
	assert(game.outer.actor == game.home.actor)
	assert(game.outer.current_address == game.outer.BLACK_VOID)
	assert(game.outer.actor.has_passenger() and game.outer.read_local_record() == "")
	assert(not game.load_game())
	Input.action_press("ui_right")
	for tick in 92:
		if game.outer.actor.position.x > 430.0:
			break
		await physics_frame
	Input.action_release("ui_right")
	assert(game.outer.actor.position.x > 430.0 and not game.outer.actor.motion.grounded)
	var saved_void_point := game.outer.actor.position
	assert(game.save_game())
	var final_serial := game.journal.serial
	await _restart()
	assert(game.journal.serial == final_serial and game.journal.applied == 2)
	assert(game._away and game.outer.actor == game.home.actor)
	assert(game.outer.actor.position.distance_to(saved_void_point) < 12.0)
	assert(not game.outer.use_route())
	var same_traveler := game.outer.actor
	assert(game.load_game() and game.outer.actor == same_traveler)

	var traveler := game.home.actor
	var item := game.home.entities.get_entity(plank_id)
	assert(traveler.has_passenger() and traveler._rider == item)
	Input.action_press("ui_right")
	assert(await _reach_pad())
	Input.action_release("ui_right")
	assert(game.outer.use_route())
	assert(not game._away and game.home.actor == traveler)
	assert(traveler.position.is_equal_approx(return_point) and traveler._rider == item)
	assert(game.home.has_donut and game.home.retreat_step == 2)
	assert(game.home.access.wand_mode == Access.DEVELOPER)
	await _restart()
	assert(not game._away and game.journal.serial == final_serial and game.journal.applied == 2)
	assert(game.home.actor.has_passenger() and game.home.actor.position.is_equal_approx(return_point))

	# An unavailable profile cannot prevent the ordinary technical recovery.
	game.profile_path = "res://unwritable_adventure_test.json"
	assert(game.demonstrate_overload() and await _wait_for_recovery())
	assert(game.journal.serial == final_serial and game.journal.applied == 2)

	game.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_profile))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_profile + ".bak"))
	print("ADMIN: playable island, W6, overload, durable reset and physical Void round trip passed")
	quit()


func _open_playable_world() -> void:
	game = AdventureScene.instantiate()
	game.profile_path = _profile
	game.get_node("Home").keyboard = false
	root.add_child(game)


func _restart() -> void:
	game.queue_free()
	await process_frame
	paused = false
	_open_playable_world()
	await physics_frame


# Use the ordinary meadow bypass and actual forest-valley route in both directions.
const LAKE_ROUTE := [Vector2(1290, 605), Vector2(1885, 605), Vector2(1888, 246),
	Vector2(1909, 109), Vector2(2140, 120), Vector2(2140, 220), Vector2(2130, 305),
	Vector2(2240, 305), Vector2(2240, 425), Vector2(2265, 425), Vector2(2340, 425),
	Vector2(2445, 426)]

func _walk_to_lake() -> void:
	for point in LAKE_ROUTE:
		assert(await _walk(point))
	assert(game.home.actor.motion.grounded and game.home.actor.location_id == game.home.Lake.LOCATION_ID)

func _walk_lake_to_meadows() -> void:
	var route := LAKE_ROUTE.duplicate()
	route.reverse()
	for point in route:
		assert(await _walk(point))
	assert(game.home.actor.motion.grounded and game.home.actor.location_id == game.home.Meadows.LOCATION_ID)


func _walk(target: Vector2) -> bool:
	for tick in 320:
		var offset := target - game.home.actor.position
		if offset.length_squared() < 76.0:
			game.home.apply_player_input(Vector2.ZERO)
			await physics_frame
			return true
		game.home.apply_player_input(offset.normalized())
		await physics_frame
	game.home.apply_player_input(Vector2.ZERO)
	push_error("Could not walk to %s, stopped at %s" % [target, game.home.actor.position])
	return false


func _wait_for_recovery() -> bool:
	var saw_error := false
	for tick in 100:
		saw_error = saw_error or game._recovery_view.get_node("Message").text == "ERROR. CHARACTER NOT FOUND."
		if game._interrupted.is_empty():
			return saw_error and not paused
		await physics_frame
	return false


func _reach_pad() -> bool:
	for tick in 180:
		if game.outer._at_action():
			return true
		await physics_frame
	return false
