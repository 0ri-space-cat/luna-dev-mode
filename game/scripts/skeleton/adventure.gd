extends Node2D
## The normal playable island and outer routes share one profile and traveler.

signal gameplay_event(event: Dictionary)
signal intervention_applied(action: String)

const Island = preload("res://scripts/skeleton/start_island.gd")
const OuterRoutes = preload("res://scripts/skeleton/outer_routes_fixture.gd")
const OUTER = preload("res://scenes/skeleton/outer_routes.tscn")
const Recovery = preload("res://scripts/runtime2d/game_recovery_2d.gd")
const RecoveryView = preload("res://scripts/runtime2d/recovery_presentation_2d.gd")
const SystemPause = preload("res://scripts/runtime2d/system_pause_2d.gd")
const Observations = preload("res://scripts/runtime2d/administrator_observations_2d.gd")
const Ecology = preload("res://scripts/runtime2d/ecology_journal_2d.gd")
const Journal = preload("res://scripts/runtime2d/system_incident_journal_2d.gd")
const EventBus = preload("res://scripts/core/event_bus.gd")
const Store = preload("res://scripts/runtime2d/save_store_2d.gd")
const GUEST_OFFSET := Vector2(6000, 0)
const PROFILE_KIND := "luna_adventure"
const CHECKPOINT_SECONDS := 0.5
const JOURNAL_FLUSH_SECONDS := 30.0
const OBSERVATION_SECONDS := 7.0
const OBSERVATION_GAP := 20.0

@export var profile_path := "user://luna_adventure.json"
var journal := Journal.new()
var ecology := Ecology.new()
var observations := Observations.new()
var _observation_presence_until := 0.0
var _observation_next_at := 0.0
var _observation_line := ""
var _ecology_presence_until := 0.0
var recovery := Recovery.new()
var events := EventBus.new()
var outer: OuterRoutes

var _store := Store.new()
var _manual: Dictionary = {}
var _continuity: Dictionary = {}
var _interrupted: Dictionary = {}
var _away := false
var _guest_save: Dictionary = {}
var _recovery_only := false
var _ready_for_play := false
var _profile_valid := true
var _checkpoint_elapsed := 0.0
var _journal_elapsed := 0.0

@onready var home: Island = $Home
@onready var _recovery_view: RecoveryView = $Recovery
@onready var system_pause: SystemPause = $SystemPause


func _ready() -> void:
	home.managed_save = true
	home.system_pause = system_pause
	system_pause.ended.connect(_on_pause_ended)
	home.frost_cast_allowed = _allow_frost
	home.restriction_text = _restriction_label
	home.frost_cast.connect(_on_frost_cast)
	home.wand_mode_requested = _commit_wand_mode
	home.public_ride_requested = _start_public_ride
	home.ghost_ride_requested = _start_ghost_ride
	home.commands.parameter_changed.connect(_on_parameter_changed)
	home.commands.component_changed.connect(_on_component_changed)
	home.fauna_respawned.connect(_on_fauna_respawned)
	home.help_completed.connect(_on_help_completed)
	home.forest_bank_interacted.connect(_on_forest_press)
	home.forest_bank_left.connect(_queue_forest_report)
	home.ancient_console.command_submitted.connect(_on_ancient_command)
	events.event_dropped.connect(_on_overflow)
	_recovery_view.finished.connect(_finish_recovery)
	var profile := _store.read_snapshot(profile_path)
	if not profile.is_empty():
		_profile_valid = _restore_profile(profile)
	elif FileAccess.file_exists(profile_path) or FileAccess.file_exists(profile_path + ".bak"):
		_profile_valid = false
	if not _profile_valid:
		_notice("Запись мира недоступна")
	_ready_for_play = true
	if _profile_valid and not profile.is_empty():
		_queue_forest_report()
	if not _away and _interrupted.is_empty():
		mark_safe_state()
		_present_encounter()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and _ready_for_play and _has_persistent_history() and _interrupted.is_empty():
		_write_profile(journal, _manual, _continuity, {}, _away, _guest_save)


func _process(delta: float) -> void:
	if not _ready_for_play or _simulation_suspended():
		return
	journal.advance(delta)
	if not _away:
		_tick_ecology(delta)
		_tick_observations(delta)
	if is_instance_valid(home.administrator) and not journal.encounter_is_active() \
			and journal.active_seconds >= maxf(_ecology_presence_until, _observation_presence_until):
		home.hide_administrator()
	events.drain(self)
	_checkpoint_elapsed += delta
	if _checkpoint_elapsed >= CHECKPOINT_SECONDS:
		_checkpoint_elapsed = 0.0
		mark_safe_state()
		if not _away and journal.encounter_is_active() and not is_instance_valid(home.administrator):
			home.show_administrator(_commit_mercy)
	if _has_persistent_history() and _interrupted.is_empty():
		_journal_elapsed += delta
		if _journal_elapsed >= JOURNAL_FLUSH_SECONDS:
			_journal_elapsed = 0.0
			_write_profile(journal, _manual, _continuity, {}, _away, _guest_save)


func _unhandled_key_input(event: InputEvent) -> void:
	if not _ready_for_play or get_tree().paused or not event is InputEventKey or not event.pressed or event.echo:
		return
	var key: Key = event.physical_keycode if event.physical_keycode != KEY_NONE else event.keycode
	if not system_pause.mode.is_empty():
		_handle_suspended_key(key)
		return
	match key:
		KEY_F5:
			_notice("Сохранено" if save_game() else "Сохранение недоступно")
		KEY_F9:
			_notice("Загружено" if load_game() else "Загрузка недоступна")
		KEY_F7:
			demonstrate_overload()
		_:
			return
	get_viewport().set_input_as_handled()


func _handle_suspended_key(key: Key) -> void:
	if key == KEY_F5 and system_pause.mode == SystemPause.STASIS:
		_notice("Сохранено" if save_game() else "Сохранение недоступно")
	elif key in [KEY_TAB, KEY_ESCAPE] and is_instance_valid(home._debug_editor):
		home._toggle_debug_editor()
	elif key == KEY_TAB and system_pause.mode == SystemPause.STASIS and system_pause.freed:
		home._toggle_debug_editor()
	else:
		return
	get_viewport().set_input_as_handled()


func _simulation_suspended() -> bool:
	return get_tree().paused or not system_pause.mode.is_empty()


func queue_world_event(event: Dictionary) -> bool:
	return _interrupted.is_empty() and events.enqueue(event)


func process_event(event: Dictionary) -> void:
	gameplay_event.emit(event)


func _on_parameter_changed(change: Dictionary) -> void:
	_observe_life_change(change)
	_observe_yeti_change(change)
	queue_world_event({"type": "PARAMETER_CHANGED", "change": change})


func _observe_yeti_change(change: Dictionary) -> void:
	if change["entity_id"] != Island.BRIDGE_YETI_ID or change["parameter_id"] != "asleep" \
			or change["source_id"] != "wand:luna" or change["initiator_id"] != Island.ENTITY_ID:
		return
	if not change["before"] and change["after"] and observations.start_nap():
		_persist_home_history()
	elif change["before"] and not change["after"] and observations.record_wake():
		_persist_home_history()


func _on_forest_press() -> void:
	if observations.record_forest_press():
		_persist_home_history()


func _queue_forest_report() -> void:
	if observations.queue_forest_report():
		_persist_home_history()


func _tick_observations(delta: float) -> void:
	var yeti := home.entities.get_entity(Island.BRIDGE_YETI_ID) as Island.EntityBody
	if yeti != null:
		observations.observe_sleep(yeti.get_parameter("asleep"), delta)
	if observations.watching_fridges() and observations.observe_fridges(home.awake_fridges_nearby(), delta):
		_persist_home_history()
	if not _observation_line.is_empty() and journal.active_seconds >= _observation_presence_until:
		var label: Label = home.get_node("Interface/SaveNotice")
		if label.text == _observation_line:
			label.text = ""
		_observation_line = ""
	if observations.pending.is_empty() or journal.encounter_is_active() \
			or journal.active_seconds < _ecology_presence_until:
		return
	var forest_report: bool = observations.pending[0]["topic"] == Observations.FOREST
	var show_after := _observation_presence_until if forest_report else _observation_next_at
	if journal.active_seconds < show_after:
		return
	var previous := observations.snapshot()
	var item := observations.take_pending()
	if not _persist_home_history():
		observations.restore(previous)
		_observation_next_at = journal.active_seconds + 2.0
		_observation_presence_until = journal.active_seconds + 2.0
		return
	_observation_presence_until = journal.active_seconds + OBSERVATION_SECONDS
	_observation_next_at = journal.active_seconds + OBSERVATION_GAP
	_observation_line = _observation_message(item)
	home.show_administrator(Callable(), journal.attitude)
	_notice(_observation_line)


func _observation_message(item: Dictionary) -> String:
	match item["topic"]:
		Observations.YETI:
			return "Администратор · Я начинаю подозревать, что будильник здесь ты."
		Observations.FRIDGES:
			return "Администратор · Холодильников уже %d. Им понадобится расписание." % item["count"]
		Observations.FOREST:
			var count: int = item["count"]
			var unit := "раза" if count % 10 in [2, 3, 4] and count % 100 not in [12, 13, 14] else "раз"
			return "Администратор · На берегу ты нажала E %d %s." % [count, unit]
	return ""


func _observe_life_change(change: Dictionary) -> void:
	if change["parameter_id"] != "alive" or change["initiator_id"] != Island.ENTITY_ID \
			or change["source_id"] != "wand:luna":
		return
	var subject := home.get_natural_fauna(change["entity_id"])
	if subject == null or not change["before"] is bool or not change["after"] is bool:
		return
	if change["before"] and not change["after"]:
		if ecology.confirm(subject.entity_id, Ecology.DEATH, journal.active_seconds):
			_assess_ecology()
	elif not change["before"] and change["after"] and ecology.close(subject.entity_id, Ecology.DEATH, true):
		_persist_home_history()


func _on_component_changed(change: Dictionary) -> void:
	if change["initiator_id"] != Island.ENTITY_ID \
			or change["source_id"] not in ["ability:extract_instance", "ability:install_instance", "wand:ability_enabled"]:
		return
	var subject := home.get_natural_fauna(change["entity_id"])
	if subject == null or not subject.aquatic_bounds.has_area():
		return
	var before := Island.Fauna.swim_in(change["before"])
	var after := Island.Fauna.swim_in(change["after"])
	var altered := false
	if before and not after and subject.is_vitally_deprived():
		altered = ecology.arm_exposure(subject.entity_id)
	elif not before and after:
		altered = ecology.exposures.erase(subject.entity_id)
		altered = ecology.close(subject.entity_id, Ecology.VITAL_LOSS, true) or altered
	if altered:
		_persist_home_history()


func _on_fauna_respawned(identity: String) -> void:
	if ecology.close(identity, Ecology.DEATH, false):
		_persist_home_history()


func _on_help_completed(outcome: String, identity: String) -> void:
	if ecology.record_help(outcome, identity, journal.active_seconds):
		_persist_home_history()


func _tick_ecology(delta: float = 0.0) -> void:
	var edited := false
	var previous_count := ecology.episodes.size()
	for identity in ecology.exposures.keys():
		var subject := home.get_natural_fauna(identity)
		var deprived := subject != null and subject.is_vitally_deprived()
		if ecology.observe_exposure(identity, deprived, delta, journal.active_seconds):
			edited = true
	if ecology.episodes.size() > previous_count:
		_assess_ecology()
	elif edited:
		_persist_home_history()
	if ecology.notice_pending:
		ecology.notice_pending = false
		if ecology.restriction_remaining(journal.active_seconds) > 0.0:
			_ecology_presence_until = journal.active_seconds + 9.0
			if not journal.encounter_is_active():
				home.show_administrator(Callable(), journal.attitude)
			_notice("Администратор · Оставь их в покое. Им нужно восстановиться.")
		_persist_home_history()


func _assess_ecology() -> void:
	ecology.assess(journal.active_seconds)
	_persist_home_history()


func _has_persistent_history() -> bool:
	return journal.serial > 0 or not ecology.episodes.is_empty() or not ecology.help.is_empty() \
		or not ecology.exposures.is_empty() or observations.wakes > 0 or observations.forest_count > 0 \
		or not observations.pending.is_empty() or not observations.delivered.is_empty()


func _persist_home_history() -> bool:
	if _away or not _interrupted.is_empty():
		return false
	var checkpoint := home.make_snapshot()
	if not _write_profile(journal, _manual, checkpoint, {}, false):
		return false
	_continuity = checkpoint
	return true


func demonstrate_overload() -> bool:
	if _away or _simulation_suspended() or not _interrupted.is_empty():
		return false
	mark_safe_state()
	for index in EventBus.MAX_QUEUE + 1:
		queue_world_event({"type": "DEV_OVERLOAD_PROBE", "index": index})
	return not _interrupted.is_empty()


func _on_overflow(reason: String) -> void:
	report_system_incident(reason, reason == "Queue capacity exceeded")


func mark_safe_state() -> bool:
	if _away or not _interrupted.is_empty() or not is_instance_valid(home.actor):
		return false
	var body := home.actor
	if not body.motion.grounded or body.is_attached() \
			or not body.motion._has_support(body.position, body.motion.elevation, home._decks, true):
		return false
	return recovery.capture(home.make_snapshot(), _is_home_snapshot)


func report_system_incident(reason: String, overload: bool = false) -> bool:
	if _away or _simulation_suspended() or not _interrupted.is_empty() \
			or not recovery.has_checkpoint() or not recovery.report(reason):
		return false
	var checkpoint := recovery.snapshot_for_recovery()
	var candidate := _copy_journal()
	_recovery_only = not candidate.accept(recovery.reason, overload) \
		or not _write_profile(candidate, _manual, _continuity, checkpoint, false)
	if not _recovery_only:
		journal = candidate
	_interrupted = checkpoint
	_begin_recovery()
	return true


func _begin_recovery() -> void:
	events.clear_pending()
	home.ancient_console.close()
	home.hide_administrator()
	system_pause.begin(SystemPause.RECOVERY, home, home.actor)
	_recovery_view.begin()


func _finish_recovery() -> void:
	if _interrupted.is_empty():
		return
	if recovery.pending and not recovery.recover(_apply_home_snapshot):
		_abort_display("Снимок восстановления недоступен")
		return
	if _recovery_only:
		_recovery_only = false
		_interrupted = {}
		_abort_display("Симуляция восстановлена. Запись инцидента недоступна")
		mark_safe_state()
		return
	system_pause.finish()
	var action: String = journal.pending["action"]
	var candidate := _copy_journal()
	candidate.acknowledge(Time.get_unix_time_from_system())
	var checkpoint := home.make_snapshot()
	_overlay_wand_mode(checkpoint, candidate)
	var travel := action == Journal.REMOVE_LUNA
	if travel and not _activate_guest(OuterRoutes.BLACK_VOID):
		_abort_display("Точка прибытия недоступна")
		return
	if not _write_profile(candidate, _manual, checkpoint, {}, travel):
		if travel:
			_reactivate_home(checkpoint)
		_abort_display("Восстановление не записалось")
		return
	journal = candidate
	_continuity = checkpoint
	_interrupted = {}
	_away = travel
	_guest_save = {}
	if not journal.wand_mode.is_empty():
		home.access.set_wand_mode(journal.wand_mode)
	_recovery_view.hide()
	if not travel:
		mark_safe_state()
	match action:
		Journal.RESET_WAND:
			_notice("Администратор · Возможности палочки сброшены")
		Journal.REMOVE_LUNA:
			_notice("Администратор · Луна перемещена")
		Journal.PARLEY, Journal.STARE, Journal.STASIS:
			pass
		_:
			_notice("Симуляция восстановлена")
	_present_encounter(action in [Journal.PARLEY, Journal.STARE, Journal.STASIS])
	if not action.is_empty():
		intervention_applied.emit(action)


func _abort_display(message: String) -> void:
	_recovery_view.hide()
	system_pause.finish()
	_notice(message)


func _on_ancient_command(command: String, argument: String) -> void:
	var console := home.ancient_console
	var succeeded := false
	if not _away and not _simulation_suspended() and _interrupted.is_empty() and home.at_ancient_console():
		match command:
			"TELEPORT":
				if argument == OuterRoutes.WHITE_ADDRESS:
					succeeded = _visit_white_void()
				else:
					succeeded = home.teleport_known_location(argument)
					if succeeded:
						mark_safe_state()
			"TIME_OF_DAY":
				var clock := home.world_clock
				var minute: int = {
					"MORNING": clock.MORNING_MINUTE, "DAY": clock.START_MINUTE,
					"EVENING": clock.EVENING_MINUTE, "NIGHT": clock.NIGHT_MINUTE,
				}.get(argument, -1)
				succeeded = clock.set_time_of_day(minute)
			"SPAWN":
				succeeded = home.spawn_console_species(argument)
	if succeeded:
		console.close()
	else:
		if not console.is_open():
			console.open()
		console.reject()


func _visit_white_void(saved_guest: Dictionary = {}) -> bool:
	if not home.can_return_traveler(home.actor.position, home.actor.motion.elevation):
		return false
	var checkpoint := home.make_snapshot()
	if not _activate_guest(OuterRoutes.WHITE_ADDRESS):
		return false
	if (not saved_guest.is_empty() and not outer.apply_snapshot(saved_guest)) \
			or not _write_profile(journal, _manual, checkpoint, {}, true, saved_guest):
		_reactivate_home(checkpoint)
		return false
	_continuity = checkpoint
	_guest_save = saved_guest
	_away = true
	return true


func _start_public_ride(destination: String) -> bool:
	if _away or _simulation_suspended() or not _interrupted.is_empty() or destination != home._city_station_destination():
		return false
	var source := home.make_snapshot()
	var entry := OuterRoutes.MEADOWS if destination == Island.City.CITY_ID else OuterRoutes.LUMA
	if not _activate_guest(entry):
		return false
	if not outer.start_hosted_public_ride():
		_reactivate_home(source)
		return false
	var guest := outer.make_snapshot()
	if not _write_profile(journal, _manual, source, {}, true, guest):
		_reactivate_home(source)
		return false
	_continuity = source
	_guest_save = guest
	_away = true
	return true


func _start_ghost_ride() -> bool:
	if _away or _simulation_suspended() or not _interrupted.is_empty() or not home._ghost_action():
		return false
	var source := home.make_snapshot()
	if not _activate_guest(OuterRoutes.GHOST_ENTRY):
		return false
	var guest := outer.make_snapshot()
	if not _write_profile(journal, _manual, source, {}, true, guest):
		_reactivate_home(source)
		return false
	_continuity = source
	_guest_save = guest
	_away = true
	home.ghost_offer = ""
	return true


func _finish_public_ride(destination: String) -> bool:
	if not _away or not is_instance_valid(outer) or outer.hosted_entry not in [OuterRoutes.MEADOWS, OuterRoutes.LUMA, OuterRoutes.GHOST_ENTRY]:
		return false
	if destination not in [OuterRoutes.LUMA, OuterRoutes.MEADOWS, OuterRoutes.EDGE]:
		return false
	if outer.hosted_entry == OuterRoutes.GHOST_ENTRY and destination != OuterRoutes.LUMA:
		return false
	var address := Island.Edge.ID if destination == OuterRoutes.EDGE else (Island.City.CITY_ID if destination == OuterRoutes.LUMA else Island.Meadows.LOCATION_ID)
	var arrivals: Array[Vector2] = []
	if destination == OuterRoutes.EDGE:
		arrivals.append(Island.Edge.FALL_ENTRY)
		arrivals.append(Island.Edge.ENTRY)
	elif destination == OuterRoutes.LUMA:
		arrivals.append(Island.City.ARRIVAL)
		arrivals.append(Vector2(4590, 410))
	else:
		arrivals.append(Island.City.MEADOWS_STATION + Vector2(0, 28))
		arrivals.append(Vector2(1900, 600))
	var arrival := Vector2.INF
	for point in arrivals:
		if home._ordinary_arrival_is_safe(address, point):
			arrival = point
			break
	if not arrival.is_finite():
		return _return_to_home()
	_reactivate_home(_continuity)
	home._move_home_travelers(arrival, address)
	var checkpoint := home.make_snapshot()
	_continuity = checkpoint
	_away = false
	_guest_save = {}
	mark_safe_state()
	if not _write_profile(journal, _manual, checkpoint, {}, false):
		_notice("Луна прибыла. Запись точки пока недоступна")
	return true


func _activate_guest(address: String) -> bool:
	var leaving_bank := home._at_forest_bank()
	var guest: OuterRoutes = OUTER.instantiate()
	guest.position = GUEST_OFFSET
	guest.process_mode = Node.PROCESS_MODE_PAUSABLE
	guest.hosted_entry = address
	guest.return_to_host = _return_to_home
	if address in [OuterRoutes.MEADOWS, OuterRoutes.LUMA, OuterRoutes.GHOST_ENTRY]:
		guest.public_arrival = _finish_public_ride
	add_child(guest)
	var player := home.actor as Island.EntityBody
	if not guest.mount_host_traveler(player, home.access, home.world_clock):
		guest.free()
		return false
	player.step_obstacle = null
	player.secondary_step_obstacle = null
	home.set_home_active(false)
	var camera := Camera2D.new()
	camera.position = Vector2(640, 400)
	guest.add_child(camera)
	camera.make_current()
	outer = guest
	if leaving_bank:
		observations.queue_forest_report()
	return true


func _return_to_home() -> bool:
	if not _away or not is_instance_valid(outer):
		return false
	_reactivate_home(_continuity)
	var checkpoint := home.make_snapshot()
	_continuity = checkpoint
	_away = false
	_guest_save = {}
	mark_safe_state()
	if not _write_profile(journal, _manual, checkpoint, {}, false):
		_notice("Луна вернулась. Запись точки пока недоступна")
	return true


func _reactivate_home(checkpoint: Dictionary) -> void:
	for entity in checkpoint["entities"]:
		if entity["id"] != Island.ENTITY_ID:
			continue
		var point := Vector2(entity["position"][0], entity["position"][1])
		var height := float(entity["motion"]["elevation"])
		if outer.hosted_entry == OuterRoutes.WHITE_ADDRESS and not home.can_return_traveler(point, height):
			point = Island.AncientConsole.RETURN_POINT
			height = 0.0
			if not home.can_return_traveler(point, height):
				point = Island.SPAWN
		home.return_traveler(point, height)
		break
	outer.hide()
	outer.get_node("Interface").hide()
	outer.process_mode = Node.PROCESS_MODE_DISABLED
	outer.queue_free()
	outer = null


func apply_local_rollback(checkpoint: Dictionary) -> bool:
	if _away or not _interrupted.is_empty() or _simulation_suspended():
		return false
	if not _apply_home_snapshot(checkpoint):
		return false
	mark_safe_state()
	if journal.encounter_is_active():
		_present_encounter()
	return true


func save_game() -> bool:
	if not _interrupted.is_empty():
		return false
	var checkpoint := _continuity.duplicate(true) if _away else home.make_snapshot()
	checkpoint["world_clock"] = home.world_clock.snapshot()
	var guest := outer.make_snapshot() if _away else {}
	var manual := checkpoint
	if _away and outer.hosted_entry == OuterRoutes.WHITE_ADDRESS:
		manual = checkpoint.duplicate(true)
		manual["white_visit"] = guest
	elif _away and outer.hosted_entry in [OuterRoutes.MEADOWS, OuterRoutes.LUMA, OuterRoutes.GHOST_ENTRY]:
		manual = checkpoint.duplicate(true)
		manual["public_visit"] = {"entry": outer.hosted_entry, "guest": guest}
	if not _write_profile(journal, manual, checkpoint, {}, _away, guest):
		return false
	_guest_save = guest
	_manual = manual
	_continuity = checkpoint
	mark_safe_state()
	return true


func load_game() -> bool:
	if _simulation_suspended():
		return false
	if _away:
		return not _guest_save.is_empty() and outer.apply_snapshot(_guest_save)
	if not _interrupted.is_empty():
		_begin_recovery()
		return true
	var checkpoint := _manual if not _manual.is_empty() else _store.read_snapshot(Island.SAVE_PATH)
	if checkpoint.has("white_visit"):
		return _load_saved_white_visit(checkpoint)
	if checkpoint.has("public_visit"):
		return _load_saved_public_visit(checkpoint)
	if not apply_local_rollback(checkpoint):
		return false
	_queue_forest_report()
	return true


func _load_saved_public_visit(checkpoint: Dictionary) -> bool:
	var visit: Variant = checkpoint.get("public_visit")
	if not visit is Dictionary or visit.get("entry") not in [OuterRoutes.MEADOWS, OuterRoutes.LUMA, OuterRoutes.GHOST_ENTRY] \
			or not visit.get("guest") is Dictionary or visit["guest"].is_empty():
		return false
	var previous := home.make_snapshot()
	if not _apply_home_snapshot(checkpoint):
		return false
	var source := home.make_snapshot()
	if not _activate_guest(visit["entry"]):
		_apply_home_snapshot(previous)
		return false
	if not outer.apply_snapshot(visit["guest"]) or not _write_profile(journal, _manual, source, {}, true, visit["guest"]):
		_reactivate_home(source)
		_apply_home_snapshot(previous)
		mark_safe_state()
		return false
	_continuity = source
	_guest_save = visit["guest"]
	_away = true
	return true


func _load_saved_white_visit(checkpoint: Dictionary) -> bool:
	var guest: Variant = checkpoint["white_visit"]
	if not guest is Dictionary or guest.is_empty():
		return false
	var previous := home.make_snapshot()
	if not _apply_home_snapshot(checkpoint):
		return false
	if not _visit_white_void(guest):
		_apply_home_snapshot(previous)
		mark_safe_state()
		return false
	_queue_forest_report()
	return true


func _commit_wand_mode(mode: String) -> bool:
	if _away or not _interrupted.is_empty():
		return false
	if journal.wand_mode.is_empty():
		return true
	var candidate := _copy_journal()
	candidate.wand_mode = mode
	var checkpoint := home.make_snapshot()
	_overlay_wand_mode(checkpoint, candidate)
	if not _write_profile(candidate, _manual, checkpoint, {}, false):
		return false
	journal = candidate
	_continuity = checkpoint
	return true


func _apply_home_snapshot(checkpoint: Dictionary) -> bool:
	var data := checkpoint.duplicate(true)
	_overlay_wand_mode(data, journal)
	if not home.apply_snapshot(data):
		return false
	observations.clear_transient_observation()
	return true


func _overlay_wand_mode(checkpoint: Dictionary, source: Journal) -> void:
	if not source.wand_mode.is_empty() and checkpoint.get("island") is Dictionary \
			and checkpoint["island"].get("access") is Dictionary:
		checkpoint["island"]["access"]["wand_mode"] = source.wand_mode


func _restore_profile(profile: Dictionary) -> bool:
	var candidate := Journal.new()
	if profile.get("kind") != PROFILE_KIND or not candidate.restore(profile.get("journal")) \
			or not profile.get("state") is Dictionary or not profile.get("manual") is Dictionary \
			or not profile.get("interrupted") is Dictionary or not profile.get("away") is bool:
		return false
	var candidate_ecology := Ecology.new()
	if not candidate_ecology.restore(profile.get("ecology", {}), candidate.active_seconds):
		return false
	var candidate_observations := Observations.new()
	if not candidate_observations.restore(profile.get("observations", {})):
		return false
	var interrupted: Dictionary = profile["interrupted"]
	var continuity: Dictionary = profile["state"]
	var away: bool = profile["away"]
	var guest_entry: Variant = profile.get("guest_entry", OuterRoutes.BLACK_VOID if away else "")
	if interrupted.is_empty() != candidate.pending.is_empty() \
			or (away and (not interrupted.is_empty() or continuity.is_empty() \
				or guest_entry not in [OuterRoutes.BLACK_VOID, OuterRoutes.WHITE_ADDRESS, OuterRoutes.MEADOWS, OuterRoutes.LUMA, OuterRoutes.GHOST_ENTRY])) \
			or (guest_entry == OuterRoutes.BLACK_VOID and candidate.applied != 2) \
			or (not away and guest_entry != ""):
		return false
	var guest_save: Variant = profile.get("guest", {})
	if not guest_save is Dictionary or (not profile["away"] and not guest_save.is_empty()):
		return false
	var source := interrupted if not interrupted.is_empty() else continuity
	var checkpoint := source.duplicate(true)
	_overlay_wand_mode(checkpoint, candidate)
	if not source.is_empty() and (not _is_home_snapshot(checkpoint) or not home.apply_snapshot(checkpoint)):
		return false
	# Home has already validated and migrated the selected snapshot. Keep its
	# canonical state for hosted returns and recovery, rather than restoring
	# the stale coordinates or addresses from the pre-migration envelope.
	# The independent manual rollback remains untouched until it is loaded.
	if not source.is_empty():
		checkpoint = home.make_snapshot()
	_manual = profile["manual"]
	_continuity = checkpoint if interrupted.is_empty() and not source.is_empty() else continuity
	_interrupted = checkpoint if not interrupted.is_empty() else interrupted
	_away = profile["away"]
	journal = candidate
	ecology = candidate_ecology
	observations = candidate_observations
	if _away:
		if not _activate_guest(guest_entry):
			return false
		if not guest_save.is_empty():
			if outer.apply_snapshot(guest_save):
				_guest_save = guest_save
			else:
				if guest_entry in [OuterRoutes.MEADOWS, OuterRoutes.LUMA, OuterRoutes.GHOST_ENTRY]:
					return _return_to_home()
				_notice("Восстановлена безопасная точка прибытия")
		elif guest_entry in [OuterRoutes.MEADOWS, OuterRoutes.LUMA, OuterRoutes.GHOST_ENTRY]:
			return _return_to_home()
		return true
	if not _interrupted.is_empty():
		if not recovery.capture(checkpoint, _is_home_snapshot) or not recovery.report(journal.pending["reason"]):
			return false
		_begin_recovery()
	return true


func _present_encounter(announce: bool = true) -> void:
	if _away or not journal.encounter_is_active():
		return
	home.show_administrator(_commit_mercy)
	match journal.encounter:
		Journal.PARLEY:
			if announce:
				_notice("Администратор · Пожалуйста, не доводи систему до перезапуска.")
		Journal.STARE:
			if announce:
				_notice("")
		Journal.STASIS:
			var remaining := clampf(journal.stasis_deadline - Time.get_unix_time_from_system(), 0.0, Journal.STASIS_SECONDS)
			if remaining > 0.0:
				system_pause.begin(SystemPause.STASIS, home, home.actor, remaining)
				_notice("Стазис")
			elif journal.stasis_deadline > 0.0:
				_clear_stasis()


func _on_pause_ended(mode: String) -> void:
	if mode != SystemPause.STASIS or journal.stasis_deadline <= 0.0:
		return
	_clear_stasis()
	_notice("Стазис снят")
	if is_instance_valid(home._debug_editor):
		system_pause.begin(SystemPause.EDITOR, home, home.actor)


func _clear_stasis() -> void:
	journal.stasis_deadline = 0.0
	var checkpoint := home.make_snapshot()
	if _write_profile(journal, _manual, checkpoint, {}, _away, _guest_save):
		_continuity = checkpoint


func _commit_mercy(target: Island.Administrator) -> bool:
	if target != home.administrator or _away or not _interrupted.is_empty() \
			or (system_pause.mode == SystemPause.STASIS and not system_pause.freed) \
			or home.get_wand_editor_tabs(target.entity_id).is_empty():
		return false
	var candidate := _copy_journal()
	if not candidate.surrender():
		return false
	var checkpoint := home.make_snapshot()
	if not _write_profile(candidate, _manual, checkpoint, {}, false):
		return false
	journal = candidate
	_continuity = checkpoint
	call_deferred("_finish_mercy")
	return true


func _finish_mercy() -> void:
	if is_instance_valid(home._debug_editor):
		home._toggle_debug_editor()
	if system_pause.mode == SystemPause.STASIS:
		system_pause.finish()
	home.hide_administrator()
	_notice("Администратор · Сдаюсь. Ты победила.")


func _on_frost_cast(base_seconds: float) -> void:
	var overload_adjusted := journal.record_frost_cast(base_seconds)
	var ecology_adjusted := ecology.record_frost(base_seconds, journal.active_seconds)
	if overload_adjusted or ecology_adjusted:
		var checkpoint := home.make_snapshot()
		if _write_profile(journal, _manual, checkpoint, {}, false):
			_continuity = checkpoint


func _allow_frost() -> bool:
	return journal.allow_frost() and ecology.allow_frost(journal.active_seconds)


func _restriction_label() -> String:
	var seconds := ceili(maxf(journal.restriction_remaining(), ecology.restriction_remaining(journal.active_seconds)))
	if seconds <= 0:
		return ""
	return "  ·  Ограничение магии %d:%02d" % [floori(seconds / 60.0), seconds % 60]


func _write_profile(current: Journal, manual: Dictionary, state: Dictionary, interrupted: Dictionary,
		away: bool, guest: Dictionary = {}) -> bool:
	return _profile_valid and _store.write_snapshot({"format": Store.FORMAT, "kind": PROFILE_KIND,
		"journal": current.snapshot(), "ecology": ecology.snapshot(), "observations": observations.snapshot(),
		"manual": manual, "state": state,
		"away": away, "interrupted": interrupted, "guest": guest,
		"guest_entry": outer.hosted_entry if away else ""}, profile_path)


func _copy_journal() -> Journal:
	var candidate := Journal.new()
	candidate.restore(journal.snapshot())
	return candidate


func _is_home_snapshot(data: Dictionary) -> bool:
	return data.get("fixture") == Island.ISLAND_ID and data.get("island") is Dictionary \
		and data.get("entities") is Array and not data["entities"].is_empty()


func _notice(message: String) -> void:
	if is_instance_valid(outer):
		outer.get_node("Interface/Feedback").text = message
	else:
		home.get_node("Interface/SaveNotice").text = message
