extends SceneTree

const Scene = preload("res://scenes/skeleton/adventure.tscn")
const Island = preload("res://scripts/skeleton/start_island.gd")
const City = preload("res://scripts/skeleton/luma_city_layout.gd")
const Outer = preload("res://scripts/skeleton/outer_routes_fixture.gd")
const RareDirector = preload("res://scripts/runtime2d/rare_encounter_director_2d.gd")
const Finds = preload("res://scripts/skeleton/secret_finds_layout.gd")
const Store = preload("res://scripts/runtime2d/save_store_2d.gd")
var profile := "user://luna_public_campaign_%d.json" % OS.get_process_id()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	Engine.time_scale = 2.0
	var game = _open_adventure()
	await physics_frame
	var home = game.home
	var player = home.actor
	# Follow the public route from the default Adventure start, without
	# addressing the city or granting access, meetings or gifts.
	assert(await _walk(home, Vector2(320, 480)))
	assert(home.interact() and home.access.wand_mode == "PLAYFUL")
	for point in [Vector2(320, 374), Vector2(320, 259)]:
		assert(await _walk(home, point))
	assert(home.interact() and home.has_donut)
	for point in [Vector2(320, 374), Vector2(684, 374)]:
		assert(await _walk(home, point))
	assert(home.request_wand_parameter_edit(Island.BRIDGE_YETI_ID, "ASLEEP", false))
	assert(home.interact() and not home.has_donut)
	for point in [Vector2(1020, 373), Vector2(1300, 373), Vector2(1300, 606),
		Vector2(1890, 606), Vector2(1860, 427), Vector2(1820, 434)]:
		assert(await _walk(home, point))
	assert(home.interact() and home.social.meetings.has("TOFFI"))
	assert(home.interact() and home.social.invitations.has("TOFFI"))
	for point in [Vector2(1900, 439), Vector2(1925, 535), City.MEADOWS_STATION]:
		assert(await _walk(home, point))
	assert(home.interact() and game._away)
	assert(game.outer.current_address == Outer.BUFFER and game.outer.actor == player)
	assert(game.outer.ride_destination == Outer.LUMA)
	assert(game.save_game())
	var guest: Dictionary = game.outer.make_snapshot()
	assert(game.outer.apply_snapshot(guest))
	assert(await _wait_for_arrival(game, City.CITY_ID))
	assert(home.actor == player)
	for door_index in [2, 3, 0, 1]:
		var door: Dictionary = City.DOORS[door_index]
		var outside: Vector2 = door["outside"]
		var path: Array[Vector2] = []
		match door_index:
			2:
				path = [Vector2(4820, 425), Vector2(4935, 425)]
			3:
				path = [Vector2(4935, 417), Vector2(5065, 417), Vector2(5065, 660)]
			0:
				path = [Vector2(5165, 416)]
			1:
				path = [Vector2(5170, 425), Vector2(5295, 445)]
		for point in path + [outside]:
			assert(await _walk(home, point))
		assert(home.interact(), door["name"])
		assert(player.position.distance_to(door["inside"]) < 1.0)
		assert(player.location_id == door["address"])
		assert(home._room_view.visible and home._room_view.bounds.has_point(player.position))
		if door_index in [2, 3]:
			var friend_id := "YUKI" if door_index == 2 else "ORI"
			var friend := Vector2(5700, 639) if door_index == 2 else Vector2(6050, 639)
			assert(await _walk(home, friend))
			assert(home.interact() and home.social.meetings.has(friend_id))
			assert(home.interact() and home.social.invitations.has(friend_id))
			assert(await _walk(home, door["inside"]))
		elif door_index == 0:
			assert(not home.begin_cafe_evening() and not game.white_discovered)
		assert(home.interact() and player.position.distance_to(door["outside"]) < 1.0)
		assert(not home._room_view.visible)
	assert(home.social.invitations.size() == 3 and home.ori.ownership == 0 and home.yuki.ownership == 0)
	var bread = home.entities.get_entity(City.BREAD)
	assert(bread != null and not bread.get_parameter("alive"))
	assert(bread.set_parameter("alive", true))
	for point in [Vector2(5295, 445), Vector2(5075, 315)]:
		assert(await _walk(home, point))
	assert(not home.highland.camera_owned and home.highland.camera_mode == "FOLLOW")
	assert(await _walk(home, City.DOORS[0]["outside"]))
	assert(home.interact() and player.location_id == City.CAFE_ID)
	assert(home._camera.get_screen_center_position().is_equal_approx(City.CAFE.get_center()))
	assert(not home._room_view.screen_aperture().has_point(home._camera.get_canvas_transform() * City.ROOM.get_center()))
	assert(await _walk(home, Vector2(5644, 369)))
	assert(home._camera.get_screen_center_position().is_equal_approx(City.CAFE.get_center()))
	var saved: Dictionary = home.make_snapshot()
	assert(home.apply_snapshot(saved))
	player = home.actor
	bread = home.entities.get_entity(City.BREAD)
	assert(bread != null and bread.get_parameter("alive") and player.location_id == City.CAFE_ID)
	assert(home._room_view.bounds == City.CAFE and home.highland.camera_mode == "FOLLOW")
	assert(await _walk(home, City.DOORS[0]["inside"]))
	assert(home.interact() and player.location_id == City.CITY_ID)
	assert(not home._room_view.visible and home._camera.get_screen_center_position().is_equal_approx(home.actor.position))
	for point in [Vector2(5060, 415), Vector2(4810, 433), Vector2(4560, 435), City.BOARD]:
		assert(await _walk(home, point))
	assert(home.interact() and game._away)
	assert(game.outer.ride_destination == Outer.MEADOWS)
	assert(await _wait_for_arrival(game, Island.Meadows.LOCATION_ID))
	assert(home.actor == player and home.actor.location_id == Island.Meadows.LOCATION_ID)
	assert(home.entities.get_entity(City.BREAD).get_parameter("alive"))
	assert(await _finish_public_campaign(game))
	game.queue_free()
	await process_frame
	game = _open_adventure()
	await physics_frame
	home = game.home
	assert(game._profile_valid and home.evening_stage == 4 and home.social.invitations.size() == 6)
	assert(home.actor.location_id == City.CAFE_ID and home._room_view.visible)
	assert(await _walk(home, City.DOORS[0]["inside"]))
	assert(home.interact() and home.actor.location_id == City.CITY_ID)
	assert(await _ride_to(game, City.BOARD, Island.Meadows.LOCATION_ID))
	assert(await _verify_optional_anomaly(game))
	assert(await _finish_meta_route(game))
	game.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(profile))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(profile + ".bak"))
	print("Alpha campaign: fresh island, six invitations, ordinary credits, safe restart and physical first White Void with voluntary merge passed")
	quit()


func _finish_public_campaign(game: Node) -> bool:
	var home = game.home
	# At night Oni returns to the ordinary valley lake from the coast.
	for point in [Vector2(1300, 606), Island.Meadows.CAMP_SPOT]:
		assert(await _walk(home, point))
	assert(home.interact() and home.world_clock.phase() == Island.WorldClock.Phase.NIGHT)
	for point in [Vector2(1300, 606), Vector2(1892, 606),
		Vector2(1925, 530), Vector2(1900, 437), Vector2(1896, 241),
		Vector2(1900, 128), Vector2(1900, 47), Vector2(1955, -4)]:
		assert(await _walk(home, point))
	assert(home.interact() and home.social.meetings.has("LEIA") and not home.tamagotchi_owned)
	assert(home.interact() and home.social.invitations.has("LEIA"))
	for point in [Vector2(2085, 70), Vector2(2140, 119), Vector2(2140, 223),
		Vector2(2140, 304), Vector2(2190, 355), Vector2(2192, 485), Vector2(2154, 489)]:
		assert(await _walk(home, point))
	for tick in 300:
		if home._oni_site() == "W1":
			break
		await physics_frame
	assert(home._oni_site() == "W1", "Oni at %s, clock=%s" % [
		home.entities.get_entity(Island.Visits.ONI_ID).position, home.world_clock.minute_of_day()])
	assert(home.interact() and home.social.meetings.has("ONI") and not home.social.prism_owned)
	assert(home.interact() and home.social.invitations.has("ONI"))
	# The dry stair follows Mia to her evening overlook instead of forcing
	# the lab controls or the optional alchemy gift.
	for point in [Vector2(2150, 538), Vector2(2145, 731), Vector2(2075, 748),
		Vector2(2075, 915), Vector2(2075, 973), Vector2(2075, 1022),
		Vector2(2075, 1080), Vector2(1910, 1080)]:
		assert(await _walk(home, point))
	assert(home.interact() and home.social.meetings.has("MIA") and home.flask_state == 0,
		"Mia at %s, clock=%s, prompt=%s" % [home.entities.get_entity(Island.Life.MIA_ID).position,
			home.world_clock.minute_of_day(), home._nearby_action()])
	assert(home.interact() and home.social.can_gather())
	assert(not home.flute_owned and not home.tamagotchi_owned and not home.social.prism_owned)
	assert(home.ori.ownership == 0 and home.yuki.ownership == 0 and home.flask_state == 0)
	for point in [Vector2(2075, 1080), Vector2(2075, 1020), Vector2(2075, 960),
		Vector2(2075, 910), Vector2(2075, 740), Vector2(2145, 731), Vector2(2150, 489),
		Vector2(2192, 488), Vector2(2190, 355), Vector2(2140, 304), Vector2(2140, 95),
		Vector2(1900, 95), Vector2(1900, 241), Vector2(1900, 440), Vector2(1925, 530)]:
		assert(await _walk(home, point))
	assert(await _ride_to(game, City.MEADOWS_STATION, City.CITY_ID))
	for point in [Vector2(4820, 425), Vector2(5060, 423), City.DOORS[0]["outside"]]:
		assert(await _walk(home, point))
	assert(home.interact() and home.actor.location_id == City.CAFE_ID)
	assert(await _walk(home, Island.CAFE_TALK))
	assert(home.interact() and home.evening_stage == 0)
	_press_evening_button(home, "Начать вечер")
	for tick in 220:
		if home.evening_stage == 2:
			break
		await physics_frame
	assert(home.evening_stage == 2 and home.evening_origins.size() == 6)
	assert(home.interact())
	_press_evening_button(home, "Завершить вечер")
	assert(home.evening_stage == 3 and home.ordinary_finale_voice().contains("Помоги мне"))
	assert(not game.white_discovered and not game.meta.merged)
	_press_evening_button(home, "Далее")
	_press_evening_button(home, "Продолжить игру")
	assert(home.evening_stage == 4)
	_key(KEY_ESCAPE)
	assert(paused and game._pause_menu._continue.has_focus())
	game._pause_menu._save_pressed()
	assert(game._pause_menu._status.text == "Сохранено")
	_key(KEY_ESCAPE)
	assert(not paused)
	print("Alpha ordinary route: six invitations without gifts, credits and menu save reached")
	return true


func _verify_optional_anomaly(game: Node) -> bool:
	var home = game.home
	# An optional anomaly may interrupt the scenery after real exploration
	# and a confirmed simulation recovery. Only the random roll is controlled.
	for point in [Vector2(1925, 530), Vector2(1851, 450), Vector2(1780, 457)]:
		assert(await _walk(home, point))
	home._camera.reset_smoothing()
	home._camera.force_update_scroll()
	assert(home.rare_candidate().get("id") == RareDirector.HAND,
		"RE66 staging: %s, prompt=%s, eligible=%s" % [home.actor.position, home._nearby_action(), home._rare_safe()])
	assert(game.demonstrate_overload())
	for tick in 390:
		if game._has_confirmed_overload(game.journal):
			break
		await physics_frame
	assert(game._has_confirmed_overload(game.journal))
	var social_state: Dictionary = home.social.snapshot()
	var entities_before: int = home.entities.count_live()
	game.journal.advance(RareDirector.WINDOW_SECONDS)
	game._tick_rare_encounters(0.0)
	assert(game.rare_encounters.active == RareDirector.HAND and home.rare_kind == RareDirector.HAND)
	assert(not game._away and not game.white_discovered and not game.meta.merged)
	assert(home.social.snapshot() == social_state and home.entities.count_live() == entities_before)
	assert(not home.interact())
	assert(await _walk(home, Vector2(1653, 430)))
	game._tick_rare_encounters()
	assert(game.rare_encounters.active.is_empty() and game.rare_encounters.consumed == [RareDirector.HAND])
	assert(home.rare_kind.is_empty())
	return true


func _finish_meta_route(game: Node) -> bool:
	var home = game.home
	for point in [Vector2(1860, 429), Vector2(1896, 240), Vector2(1900, 128),
		Vector2(1900, 52), Finds.FLUTE_ENTRY, Finds.FLUTE_POINT]:
		assert(await _walk(home, point))
	assert(home.interact() and home.flute_owned)
	for point in [Finds.FLUTE_ENTRY, Vector2(1900, 68), Vector2(2140, 95),
		Vector2(2140, 225), Vector2(2140, 305), Vector2(2240, 305),
		Vector2(2240, 425), Island.Lake.SHORE]:
		assert(await _walk(home, point))
	assert(home.wand_pair.duplicate == null and home.interact() and home.wand_pair.duplicate != null)
	assert(home.tick_wand_self_hack(3.0, true) and home.access.wand_mode == "DEVELOPER")
	for point in [Vector2(2240, 425), Vector2(2240, 305), Vector2(2140, 304),
		Vector2(2140, 95), Vector2(1900, 95), Vector2(1900, 240),
		Vector2(1890, 350), Vector2(1770, 355)]:
		assert(await _walk(home, point))
	assert(home.perform_music(home.Music.PHRASES["M03"]))
	assert(await _walk(home, Island.Mountain.CAMERA_POINT))
	assert(home.interact() and home.highland.camera_owned)
	assert(await _walk(home, Vector2(1770, 355)))
	for point in [Vector2(1900, 432), Vector2(1900, 604), Vector2(1300, 604)]:
		assert(await _walk(home, point))
	assert(home.perform_music(home.Music.PHRASES["M04"]), "Cannot restore Luna at %s (Z=%s)" % [
		home.actor.position, home.actor.motion.elevation])
	for point in [Vector2(1300, 374), Vector2(510, 374), Vector2(510, 535)]:
		assert(await _walk(home, point))
	assert(home.set_game_mode("WINDOWED") and home.toggle_camera_lock())
	await physics_frame
	var bounds: Rect2 = home._frame_world_bounds()
	assert(await _walk(home, Vector2(bounds.position.x + 18.0, home.actor.position.y)))
	# The actual protected menu must be reachable with TAB after walking up to the frame.
	home.keyboard = true
	_key(KEY_TAB)
	home.keyboard = false
	assert(home._frame_panel.visible and home._frame_switch.button_pressed)
	home._frame_switch.toggled.emit(false)
	assert(not home.game_frame_solid and not game._away)
	home.apply_player_input(Vector2.LEFT)
	for tick in 60:
		if game._away:
			break
		await physics_frame
	assert(game._away and game.outer.current_address == Outer.DESKTOP)
	game.outer.keyboard = false
	game.outer.actor.direction = Vector2.RIGHT
	for tick in 250:
		if game.outer.current_address == Outer.WHITE_ADDRESS:
			break
		await physics_frame
	assert(game.outer.current_address == Outer.WHITE_ADDRESS and game.white_discovered and not game.meta.merged)
	game.outer.actor.direction = Vector2.RIGHT
	for tick in 180:
		if game.outer.at_meta_encounter():
			break
		await physics_frame
	game.outer.actor.direction = Vector2.ZERO
	assert(game.outer.at_meta_encounter())
	assert(game.outer.use_route() and game.outer.use_route() and game.outer.use_route())
	assert(game.meta.merged and home.evening_stage == 4 and not game.meta.pixel_seen)
	game.outer.actor.direction = Vector2.RIGHT
	for tick in 200:
		if game.outer._at_action():
			break
		await physics_frame
	game.outer.actor.direction = Vector2.ZERO
	assert(game.outer.use_route() and not game._away)
	assert(game.save_game())
	var saved_state := Store.new().read_snapshot(profile)
	assert(saved_state["white_discovered"] and saved_state["meta"]["merged"] and saved_state["state"]["evening"]["stage"] == 4)
	return true


func _key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	root.push_input(event)


func _open_adventure() -> Node:
	var game := Scene.instantiate()
	game.profile_path = profile
	game.get_node("Home").keyboard = false
	root.add_child(game)
	return game


func _press_evening_button(home: Node, caption: String) -> void:
	for child in home._evening_panel.get_child(0).get_children():
		if child is Button and child.text == caption and child.visible:
			child.pressed.emit()
			return
	assert(false, caption)


func _ride_to(game: Node, stop: Vector2, address: String) -> bool:
	var home = game.home
	if address == Island.Meadows.LOCATION_ID:
		for point in [Vector2(5060, 415), Vector2(4810, 433), Vector2(4560, 435)]:
			if not await _walk(home, point):
				return false
	if not await _walk(home, stop) or not home.interact() or not game._away:
		return false
	return await _wait_for_arrival(game, address)


func _walk(home: Node, target: Vector2) -> bool:
	for tick in 280:
		var offset: Vector2 = target - home.actor.position
		if offset.length_squared() < 16.0:
			home.apply_player_input(Vector2.ZERO)
			if home.actor.motion.grounded:
				await physics_frame
				return true
		else:
			home.apply_player_input((offset / 12.0).limit_length())
		await physics_frame
	home.apply_player_input(Vector2.ZERO)
	push_error("Public route did not reach %s from %s" % [target, home.actor.position])
	return false


func _wait_for_arrival(game: Node, address: String) -> bool:
	for tick in 440:
		if not game._away:
			return game.home.actor.location_id == address
		await physics_frame
	return false
