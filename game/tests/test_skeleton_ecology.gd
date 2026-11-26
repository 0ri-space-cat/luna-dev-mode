extends SceneTree

const Scene = preload("res://scenes/skeleton/adventure.tscn")
const Adventure = preload("res://scripts/skeleton/adventure.gd")
const Island = preload("res://scripts/skeleton/start_island.gd")
const Journal = preload("res://scripts/runtime2d/system_incident_journal_2d.gd")
const Ecology = preload("res://scripts/runtime2d/ecology_journal_2d.gd")
const Access = preload("res://scripts/runtime2d/access_state_2d.gd")

const FISH_A := "DEV_POOL_FISH_A"
const FISH_B := "DEV_POOL_FISH_B"

var game: Adventure
var _path := "user://luna_ecology_test_%d.json" % OS.get_process_id()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	Engine.time_scale = 3.0
	_open_game()
	await physics_frame
	assert(game.ecology.episodes.is_empty())
	var legacy := game.home.make_snapshot()
	legacy.erase("ecology_layout")
	legacy.erase("crystal_fauna_layout")
	legacy.erase("duplicate_elapsed")
	legacy.erase("lake_layout")
	legacy.erase("coastal_life_layout")
	legacy.erase("friend_layout")
	legacy.erase("city_layout")
	legacy["entities"] = legacy["entities"].filter(func(state):
		return not Island.FISH_POINTS.has(state["id"]) and state["id"] != Island.ECOLOGY_CATALOG \
			and state["id"] != Island.MIRROR_SNAIL and state["id"] != Island.LAKE_STONE_ID \
			and state["id"] not in [Island.Life.MIA_ID, Island.Life.SHELL_ID, Island.Life.STONE_ID] \
			and not Island.Life.FAUNA.has(state["id"]) and state["id"] != Island.Visits.ONI_ID \
			and not Island.City.DEFINITIONS.any(func(definition): return definition["id"] == state["id"]))
	for state in legacy["entities"]:
		state.erase("components")
		state["life"].erase("respawn_remaining")
	assert(game.apply_local_rollback(legacy) and game.home.get_natural_fauna(FISH_A) != null)
	_place(Vector2(320, 480))
	assert(game.home.interact() and game.home.access.wand_mode == Access.PLAYFUL)
	await _complete_actual_help()
	await _vital_loss_and_restoration()
	await _targeted_history_and_intervention()

	game.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_path + ".bak"))
	print("ADMIN ecology: actual help, reversible SWIM transfer, respawn, proven harm and independent response passed")
	quit()


func _complete_actual_help() -> void:
	_place(Vector2(320, 262))
	assert(game.home.interact() and game.home.has_donut)
	_place(Vector2(686, 374))
	assert(game.home.request_wand_parameter_edit(game.home.BRIDGE_YETI_ID, "ASLEEP", false))
	assert(game.home.interact())
	assert(game.ecology.help.is_empty())
	for tick in 190:
		if game.ecology.help.has("START_YETI_DONUT"):
			break
		await physics_frame
	assert(game.ecology.help.has("START_YETI_DONUT"))
	assert(game.ecology.help.size() == 1 and game.ecology.episodes.is_empty())


func _vital_loss_and_restoration() -> void:
	var fish := _pose_fish(FISH_A)
	assert(not game.home.request_extract_swim(FISH_A))
	_place(Island.CATALOG_SPOT + Vector2(-20, 0))
	assert(game.home.interact_with_attachment(Island.ECOLOGY_CATALOG))
	fish = _pose_fish(FISH_A)
	assert(game.home.get_wand_editor_tabs(FISH_A).has("Способности"))
	assert(fish.has_vital_swim())
	assert(game.home.request_wand_parameter_edit(FISH_A, "SWIM_ENABLED", false))
	assert(not fish.has_vital_swim() and game.ecology.exposures.has(FISH_A))
	assert(game.home.request_wand_parameter_edit(FISH_A, "SWIM_ENABLED", true))
	assert(fish.has_vital_swim() and game.ecology.exposures.is_empty())
	assert(game.home.request_extract_swim(FISH_A))
	assert(game.ecology.exposures.has(FISH_A))
	assert(game.home.request_restore_swim(FISH_A))
	assert(game.ecology.exposures.is_empty() and game.ecology.episodes.is_empty())
	assert(game.home.request_extract_swim(FISH_A))
	var planted := fish.position
	await physics_frame
	await physics_frame
	assert(fish.is_vitally_deprived() and fish.position.is_equal_approx(planted))
	assert(game.ecology.episodes.is_empty())
	game.journal.advance(Ecology.VITAL_DELAY + 0.05)
	game._tick_ecology()
	assert(game.ecology.episodes.is_empty()) # only simulated exposure counts
	game._tick_ecology(Ecology.VITAL_DELAY + 0.05)
	assert(game.ecology.episodes.size() == 1 and game.ecology.episodes[0]["kind"] == Ecology.VITAL_LOSS)
	assert(game.home.ability_bank.amount(Island.ENTITY_ID, "SWIM") == 1)
	assert(game.save_game())
	await _restart()
	assert(not game.home.get_natural_fauna(FISH_A).has_vital_swim())
	assert(game.home.ability_bank.amount(Island.ENTITY_ID, "SWIM") == 1)
	assert(game.home._holds_ecology_catalog())
	assert(game.home.request_restore_swim(FISH_A))
	assert(game.home.get_natural_fauna(FISH_A).has_vital_swim())
	assert(game.ecology.episodes[0]["repaired"])
	assert(game.home.ability_bank.amount(Island.ENTITY_ID, "SWIM") == 0)
	assert(game.ecology.help.has("START_YETI_DONUT"))


func _targeted_history_and_intervention() -> void:
	var identity := Island.Meadows.FOX_ID
	var fox := _pose_fox()
	assert(game.home.request_wand_parameter_edit(identity, "SIZE", 0.9))
	assert(game.ecology.episodes.size() == 1)
	assert(game.home.commands.execute_set(fox, "alive", false, Island.ENTITY_ID, "damage:self_defense"))
	assert(game.ecology.episodes.size() == 1)
	fox._physics_process(Island.Fauna.RESPAWN_SECONDS)
	assert(fox.get_parameter("alive"))
	assert(game.home.commands.execute_set(fox, "alive", false, "", "physics:fall"))
	assert(game.ecology.episodes.size() == 1)
	fox._physics_process(Island.Fauna.RESPAWN_SECONDS)
	_pose_fox()

	# Player repairs actual harm. A repeated no-op and the same event in an old
	# local snapshot cannot create extra entries or cancel durable history.
	assert(game.home.request_wand_parameter_edit(identity, "IS_ALIVE", false))
	assert(game.home.request_wand_parameter_edit(identity, "IS_ALIVE", false))
	assert(game.ecology.episodes.size() == 2)
	assert(game.home.request_wand_parameter_edit(identity, "IS_ALIVE", true))
	assert(game.ecology.episodes[-1]["repaired"])
	_pose_fox()
	var before_death := game.home.make_snapshot()
	assert(game.home.request_wand_parameter_edit(identity, "IS_ALIVE", false))
	assert(game.apply_local_rollback(before_death))
	assert(game.home.request_wand_parameter_edit(identity, "IS_ALIVE", false))
	assert(game.ecology.episodes.size() == 3 and not game.ecology.episodes[-1]["repaired"])
	assert(game.ecology.restriction_remaining(game.journal.active_seconds) == 0.0)
	assert(game.save_game())
	await _restart()
	fox = game.home.get_natural_fauna(identity)
	assert(not fox.get_parameter("alive") and fox.death_remaining > 0.0)
	fox._physics_process(2.0)
	assert(not fox.visible)
	assert(_previously_surrendered())

	var group := [identity, FISH_A, FISH_B]
	for cycle in 3:
		for subject in group:
			var body := game.home.get_natural_fauna(subject)
			if not body.get_parameter("alive"):
				body._physics_process(Island.Fauna.RESPAWN_SECONDS)
				assert(body.get_parameter("alive"))
			if subject == identity:
				_pose_fox()
			else:
				_pose_fish(subject)
			# The unrestored death before the loop is already one of the nine.
			if cycle != 2 or subject != FISH_B:
				assert(game.home.request_wand_parameter_edit(subject, "IS_ALIVE", false))
		if cycle < 2:
			assert(game.ecology.restriction_remaining(game.journal.active_seconds) == 0.0)
			game.journal.advance(Island.Fauna.RESPAWN_SECONDS)

	assert(game.ecology.episodes.size() == 11 and game.ecology.handled == 11)
	assert(game.journal.attitude == Journal.MERCY and game.journal.restriction_remaining() == 0.0)
	assert(game.ecology.restriction_remaining(game.journal.active_seconds) > 359.0)
	assert(game.system_pause.mode.is_empty() and not game._away)
	game._tick_ecology()
	assert("восстановиться" in game.home.get_node("Interface/SaveNotice").text)
	assert(game.home.access.wand_mode == Access.PLAYFUL)
	assert(game.save_game())
	await _restart()
	assert(game.ecology.episodes.size() == 11 and game.journal.attitude == Journal.MERCY)
	assert(game.ecology.restriction_remaining(game.journal.active_seconds) > 357.0)
	assert(not game.ecology.notice_pending)

	_place(Vector2(1488, 351))
	assert(game.home.actor.try_drop())
	game.home.freeze_selected = true
	assert(game.home.interact() and game.home.ice_remaining > 0.0)
	assert(not game._allow_frost())
	var stored := game.ecology.restriction_until
	assert(game.demonstrate_overload())
	for tick in 130:
		if game._interrupted.is_empty():
			break
		await physics_frame
	assert(game._interrupted.is_empty() and game.journal.history[-1]["action"] == Journal.NONE)
	assert(game.ecology.restriction_until == stored and game.journal.attitude == Journal.MERCY)
	game.journal.advance(Ecology.RESTRICTION_SECONDS)
	assert(game._allow_frost() and game.ecology.restriction_remaining(game.journal.active_seconds) == 0.0)


func _previously_surrendered() -> bool:
	# The overload chain is orthogonal. Install the same durable MERCY
	# state that the integrated stasis test reaches through the real editor.
	for index in 7:
		if not game.journal.accept("Queue capacity exceeded", true):
			return false
		game.journal.acknowledge()
	game.journal.wand_mode = Access.PLAYFUL
	return game.journal.surrender()


func _pose_fox() -> Island.Fauna:
	var body := game.home.get_natural_fauna(Island.Meadows.FOX_ID)
	body.set_parameter("ai_enabled", false)
	_place(body.position + Vector2(45, -18))
	return body


func _pose_fish(identity: String) -> Island.Fauna:
	var body := game.home.get_natural_fauna(identity)
	body.set_parameter("ai_enabled", false)
	body.position = Island.FISH_POINTS[identity]
	body.motion.reset_on_surface(body.position, Island.Lake.BED_HEIGHT)
	_place(Vector2(2471, body.position.y))
	return body


func _place(point: Vector2) -> void:
	game.home.actor.position = point
	game.home.actor.motion.reset_on_surface(point, 0.0)
	game.home.actor.direction = Vector2.ZERO
	game.home.actor.location_id = game.home._entity_location(point)
	game.home.actor._update_rider_position()


func _open_game() -> void:
	game = Scene.instantiate()
	game.profile_path = _path
	game.get_node("Home").keyboard = false
	root.add_child(game)


func _restart() -> void:
	game.queue_free()
	await process_frame
	_open_game()
	await physics_frame
