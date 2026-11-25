extends SceneTree

const Scene = preload("res://scenes/skeleton/adventure.tscn")
const Adventure = preload("res://scripts/skeleton/adventure.gd")
const Island = preload("res://scripts/skeleton/start_island.gd")
const Observations = preload("res://scripts/runtime2d/administrator_observations_2d.gd")
const Access = preload("res://scripts/runtime2d/access_state_2d.gd")

var game: Adventure
var _path := "user://luna_observations_%d.json" % OS.get_process_id()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	Engine.time_scale = 3.0
	var exit_path := _path
	_open_world()
	await physics_frame
	_test_legacy_geometry()
	_place(Vector2(320, 480))
	assert(game.home.interact() and game.home.access.wand_mode == Access.PLAYFUL)

	await _verify_yeti_wakes()
	await _verify_fridge_group()
	await _visit_bank()
	assert(game.home._nearby_action() == "")
	_send_echo()
	assert(game.observations.forest_count == 0)
	assert(game.home.interact() and game.home.forest_bank.remaining > 0.0)
	assert(game.home.interact() and game.home.interact())
	assert(game.observations.forest_count == 3 and not game.observations.delivered.has(Observations.FOREST))
	assert("3 раза" not in _notice_text())
	assert(await _walk(Vector2(2097, 32)))
	game.journal.advance(Adventure.OBSERVATION_SECONDS)
	assert(await _wait_for_notice(Observations.FOREST))
	assert("E 3 раза" in _notice_text())
	assert(await _walk(Vector2(2118, -53)))
	assert(game.home.interact())
	assert(game.observations.forest_count == 3 and game.observations.pending.is_empty())
	_assert_no_sanctions()

	game.queue_free()
	await process_frame
	_path = exit_path.replace(".json", "_restart.json")
	_open_world()
	await physics_frame
	await _visit_bank()
	for index in 5:
		assert(game.home.interact())
	assert(game.observations.forest_count == 5 and game.observations.pending.is_empty())
	await _restart()
	assert(await _wait_for_notice(Observations.FOREST))
	assert("E 5 раз" in _notice_text())
	assert(game.home.interact() and game.observations.forest_count == 5)
	await _restart()
	assert(game.observations.delivered == [Observations.FOREST])
	assert(game.observations.pending.is_empty() and "E 5 раз" not in _notice_text())
	_assert_no_sanctions()
	assert(game.observations.forest_count == 5)

	game.queue_free()
	await process_frame
	for file in [exit_path, _path]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(file))
		DirAccess.remove_absolute(ProjectSettings.globalize_path(file + ".bak"))
	print("ADMIN observations: varied naps, living group, optional dry bank, exact one-shot exit/load reports passed")
	quit()


func _test_legacy_geometry() -> void:
	var early := game.home.make_snapshot()
	early.erase("observation_layout")
	early["entities"] = early["entities"].filter(func(state): return not Island.COURT_FRIDGES.has(state["id"]))
	assert(game.apply_local_rollback(early))
	for identity in Island.COURT_FRIDGES:
		assert(game.home.entities.get_entity(identity) != null)


func _verify_yeti_wakes() -> void:
	_place(Vector2(686, 374))
	assert(_set_yeti_sleep(false))
	assert(game.observations.wakes == 0)
	assert(_set_yeti_sleep(true))
	await _ticks(100)
	var old := game.home.make_snapshot()
	assert(_set_yeti_sleep(false) and game.observations.wakes == 1)
	assert(game.apply_local_rollback(old))
	await _ticks(100)
	assert(_set_yeti_sleep(false) and game.observations.wakes == 1)
	for index in range(1, Observations.WAKE_THRESHOLD):
		assert(_set_yeti_sleep(true))
		await _ticks(100)
		assert(_set_yeti_sleep(false))
	assert(await _wait_for_notice(Observations.YETI))
	assert("будильник" in _notice_text())
	assert(game.observations.wakes == Observations.WAKE_THRESHOLD)
	assert(_set_yeti_sleep(false))
	assert(game.observations.pending.is_empty())


func _verify_fridge_group() -> void:
	_place(Vector2(1526, 67))
	var identities := Island.COURT_FRIDGES.keys()
	for index in identities.size() - 1:
		assert(game.home.request_wand_parameter_edit(identities[index], "IS_ALIVE", true))
	await _ticks(100)
	assert(game.home.awake_fridges_nearby() == 5)
	assert(game.observations.pending.is_empty())
	assert(game.home.request_wand_parameter_edit(identities.back(), "IS_ALIVE", true))
	await _ticks(16)
	assert(game.observations.pending.is_empty())
	assert(game.home.request_wand_parameter_edit(identities.back(), "IS_ALIVE", false))
	await _ticks(3)
	assert(game.home.request_wand_parameter_edit(identities.back(), "IS_ALIVE", true))
	await _ticks(80)
	assert(not game.observations.delivered.has(Observations.FRIDGES))
	await _ticks(18)
	game.journal.advance(Adventure.OBSERVATION_GAP)
	assert(await _wait_for_notice(Observations.FRIDGES))
	assert("Холодильников уже 6" in _notice_text())


func _visit_bank() -> void:
	_place(Vector2(1900, 240))
	assert(await _walk(Vector2(1900, 129)))
	assert(await _walk(Vector2(1900, 54)))
	assert(await _walk(Vector2(2078, 37)))
	assert(await _walk(Vector2(2118, -53)))
	assert(game.home.actor.motion.grounded and game.home.actor.location_id == Island.ForestBank.LOCATION_ID)


func _send_echo() -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_E
	event.pressed = true
	event.echo = true
	game.home.keyboard = true
	game.home._unhandled_key_input(event)
	game.home.keyboard = false


func _assert_no_sanctions() -> void:
	assert(game.journal.applied == 0 and game.journal.serial == 0)
	assert(game.ecology.episodes.is_empty() and game.ecology.restriction_until == 0.0)
	assert(game.system_pause.mode.is_empty() and not game.home.has_donut and not game._away)


func _set_yeti_sleep(asleep: bool) -> bool:
	return game.home.request_wand_parameter_edit(Island.BRIDGE_YETI_ID, "ASLEEP", asleep)


func _wait_for_notice(topic: String) -> bool:
	for tick in 45:
		if game.observations.delivered.has(topic):
			return true
		await physics_frame
	return false


func _notice_text() -> String:
	return game.home.get_node("Interface/SaveNotice").text


func _place(point: Vector2) -> void:
	game.home.actor.position = point
	game.home.actor.motion.reset_on_surface(point, 0.0)
	game.home.actor.direction = Vector2.ZERO
	game.home.actor.location_id = game.home._entity_location(point)


func _walk(target: Vector2) -> bool:
	for tick in 160:
		var offset := target - game.home.actor.position
		if offset.length_squared() < 79.0:
			game.home.apply_player_input(Vector2.ZERO)
			await physics_frame
			return true
		game.home.apply_player_input(offset.normalized())
		await physics_frame
	game.home.apply_player_input(Vector2.ZERO)
	push_error("Approach did not reach %s from %s" % [target, game.home.actor.position])
	return false


func _ticks(count: int) -> void:
	for index in count:
		await physics_frame


func _open_world() -> void:
	game = Scene.instantiate()
	game.profile_path = _path
	game.get_node("Home").keyboard = false
	root.add_child(game)


func _restart() -> void:
	game.queue_free()
	await process_frame
	_open_world()
	await physics_frame
