extends SceneTree

const Scene = preload("res://scenes/skeleton/adventure.tscn")
const Adventure = preload("res://scripts/skeleton/adventure.gd")
const Journal = preload("res://scripts/runtime2d/system_incident_journal_2d.gd")
const Access = preload("res://scripts/runtime2d/access_state_2d.gd")
const Profile = preload("res://scripts/runtime2d/save_store_2d.gd")
const Pause = preload("res://scripts/runtime2d/system_pause_2d.gd")
const Admin = preload("res://scripts/skeleton/administrator_body_2d.gd")

var game: Adventure
var _file := "user://luna_administrator_stasis_test_%d.json" % OS.get_process_id()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	Engine.time_scale = 3.0
	_open_world()
	await physics_frame
	assert(_seed_previous_release())
	await _restart()
	assert(game.journal.applied == 2 and game.home.access.wand_mode == Access.PLAYFUL)
	_test_shared_editor_input()
	assert(await _wait_for_editor_movement())
	game._handle_suspended_key(KEY_ESCAPE)
	assert(game.system_pause.mode.is_empty())
	_place_luna(Vector2(387, 310))

	assert(await _overloads(2))
	assert(game.journal.applied == 3 and game.journal.encounter == Journal.PARLEY)
	assert("Пожалуйста" in game.home.get_node("Interface/SaveNotice").text)
	assert(game.home.get_wand_editor_tabs(Admin.ID).has("Отношения"))
	assert(not game.home.request_wand_parameter_edit(Admin.ID, "MASS", 6.0))
	var early := Journal.new()
	assert(early.restore(game.journal.snapshot()) and early.surrender())
	assert(early.accept("AFTER_EARLY_HACK", true) and early.pending["action"] == Journal.NONE)

	assert(await _overloads(1))
	assert(game.journal.applied == 4 and game.journal.encounter == Journal.STARE)
	assert(is_instance_valid(game.home.administrator))
	assert(game.home.get_node("Interface/SaveNotice").text.is_empty())

	assert(await _overloads(1))
	assert(game.system_pause.mode == Pause.STASIS and game.journal.applied == 5)
	assert(not game.home.request_wand_parameter_edit(Admin.ID, "LUNA_RELATION", Admin.MERCY))
	var serial := game.journal.serial
	var before := game.journal.restriction_remaining()
	assert(is_equal_approx(before, Journal.RESTRICTION_SECONDS))
	assert(game.save_game())
	await _restart()
	assert(game.journal.serial == serial and game.system_pause.mode == Pause.STASIS)
	assert(is_equal_approx(game.journal.restriction_remaining(), before))
	var clock := game.home.world_clock.snapshot()
	for tick in 14:
		await physics_frame
	assert(game.home.world_clock.snapshot() == clock)
	assert(is_equal_approx(game.journal.restriction_remaining(), before))
	assert(await _wait_for_stasis_end())
	assert(game.journal.stasis_deadline == 0.0 and is_instance_valid(game.home.administrator))

	# Drive the real frost action. The base ice timer can finish first while
	# the temporary cooldown still exists, including after a local load.
	_place_luna(Vector2(1488, 351))
	game.home.freeze_selected = true
	assert(game.home.interact())
	var duration: float = game.home.ice_remaining
	assert(is_equal_approx(duration, game.home.Meadows.ICE_SECONDS))
	assert(not game.journal.allow_frost())
	assert(game.save_game())
	game.home._ice_duration.tick(duration + 0.01)
	game.journal.advance(duration + 0.05)
	assert(game.home.ice_remaining == 0.0 and not game.home.interact())
	assert(game.load_game())
	assert(not game.journal.allow_frost())
	game.home._ice_duration.tick(duration + 0.01)
	game.journal.advance(Journal.EXTRA_FROST_COOLDOWN)
	assert(game.journal.allow_frost() and game.home.interact())
	var end_time := game.journal.restriction_until
	var expiry := Journal.new()
	assert(expiry.restore(game.journal.snapshot()))
	expiry.advance(Journal.RESTRICTION_SECONDS)
	assert(expiry.restriction_remaining() == 0.0 and expiry.allow_frost())

	assert(await _overloads(2))
	assert(game.system_pause.mode == Pause.STASIS)
	assert(is_equal_approx(game.journal.restriction_until, end_time))
	var luna := game.home.actor
	var frozen_clock := game.home.world_clock.snapshot()
	var origin := luna.position
	var step := _direction_to_administrator()
	assert(game.system_pause.resist(step) and luna.position == origin)
	assert(game.system_pause.resist(step) and luna.position == origin)
	assert(game.system_pause.resist(step) and game.system_pause.freed)
	await physics_frame
	await physics_frame
	assert(luna.position.distance_to(origin) > 1.0)
	assert(game.home.world_clock.snapshot() == frozen_clock)
	game._handle_suspended_key(KEY_TAB)
	assert(is_instance_valid(game.home._debug_editor))
	var dropdown := _find_dropdown(game.home._debug_editor)
	assert(dropdown != null and dropdown.get_item_text(1) == Admin.MERCY)
	dropdown.item_selected.emit(1)
	await process_frame
	await process_frame
	assert(game.system_pause.mode.is_empty() and game.journal.attitude == Journal.MERCY)
	assert(game.journal.restriction_remaining() == 0.0 and not is_instance_valid(game.home.administrator))
	assert(game.home.access.wand_mode == Access.PLAYFUL)
	assert(game.load_game() and game.journal.attitude == Journal.MERCY)
	var resolution := game.journal.serial
	await _restart()
	assert(game.journal.serial == resolution and game.journal.attitude == Journal.MERCY)
	assert(await _overloads(2))
	assert(game.journal.serial == resolution + 2 and game.journal.applied == 5)
	assert(game.journal.history[-1]["action"] == Journal.NONE and game.system_pause.mode.is_empty())
	assert(not is_instance_valid(game.home.administrator))

	game.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_file))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_file + ".bak"))
	print("ADMIN: shared freeze, parley, stare, bounded stasis, active cooldown and durable mercy passed")
	quit()


func _open_world() -> void:
	game = Scene.instantiate()
	game.profile_path = _file
	game.get_node("Home").keyboard = false
	root.add_child(game)
	game.system_pause.keyboard = false


func _seed_previous_release() -> bool:
	var old := Journal.new()
	for step in 5:
		if not old.accept("Queue capacity exceeded", true):
			return false
		old.acknowledge()
	old.wand_mode = Access.PLAYFUL
	var data := old.snapshot()
	data.erase("administrator")
	_place_luna(Vector2(320, 278))
	var world := game.home.make_snapshot()
	world["island"]["access"]["wand_mode"] = Access.PLAYFUL
	return Profile.new().write_snapshot({"format": Profile.FORMAT, "kind": Adventure.PROFILE_KIND,
		"journal": data, "state": world, "manual": world, "away": false, "interrupted": {}}, _file)


func _restart() -> void:
	game.queue_free()
	await process_frame
	_open_world()
	await physics_frame


func _test_shared_editor_input() -> void:
	game.home._toggle_debug_editor()
	assert(game.system_pause.mode == Pause.EDITOR)
	for step in 2:
		assert(game.system_pause.resist(Vector2.RIGHT) and not game.system_pause.freed)
	assert(game.system_pause.resist(Vector2.RIGHT) and game.system_pause.freed)


func _wait_for_editor_movement() -> bool:
	var start := game.home.actor.position
	var clock := game.home.world_clock.snapshot()
	for tick in 5:
		await physics_frame
	return game.home.actor.position.x > start.x + 2.0 \
		and game.system_pause.mode == Pause.EDITOR and game.home.world_clock.snapshot() == clock


func _overloads(count: int) -> bool:
	for event_index in count:
		if not game.demonstrate_overload() or not await _recovered():
			return false
	return true


func _recovered() -> bool:
	var saw_error := false
	for tick in 130:
		saw_error = saw_error or game._recovery_view.get_node("Message").text == "ERROR. CHARACTER NOT FOUND."
		if game._interrupted.is_empty():
			return saw_error
		await physics_frame
	return false


func _wait_for_stasis_end() -> bool:
	for tick in 220:
		if game.system_pause.mode.is_empty():
			return true
		await physics_frame
	return false


func _place_luna(point: Vector2) -> void:
	game.home.actor.position = point
	game.home.actor.motion.reset_on_surface(point, 0.0)
	game.home.actor.direction = Vector2.ZERO
	game.home.actor.location_id = game.home._entity_location(point)


func _direction_to_administrator() -> Vector2:
	return (game.home.administrator.position - game.home.actor.position).normalized()


func _find_dropdown(node: Node) -> OptionButton:
	if node is OptionButton:
		return node
	for child in node.get_children():
		var match_in_child := _find_dropdown(child)
		if match_in_child != null:
			return match_in_child
	return null
