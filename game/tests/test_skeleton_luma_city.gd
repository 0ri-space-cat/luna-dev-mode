extends SceneTree

const Scene = preload("res://scenes/skeleton/adventure.tscn")
const Island = preload("res://scripts/skeleton/start_island.gd")
const City = preload("res://scripts/skeleton/luma_city_layout.gd")
const Outer = preload("res://scripts/skeleton/outer_routes_fixture.gd")
const RareDirector = preload("res://scripts/runtime2d/rare_encounter_director_2d.gd")
const PROFILE := "user://luna_city_regression.json"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	Engine.time_scale = 2.0
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PROFILE))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PROFILE + ".bak"))
	var game = Scene.instantiate()
	game.profile_path = PROFILE
	game.get_node("Home").keyboard = false
	root.add_child(game)
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
	# Dedicated compatibility case after the ordinary route. Begin with the
	# camera eligible here; the camera's physical pickup has its own regression.
	home.highland.camera_owned = true
	assert(home.toggle_camera_lock())
	var lock: Vector2 = home.highland.camera_lock
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
	assert(home._room_view.bounds == City.CAFE and home.highland.camera_mode == "LOCKED")
	assert(await _walk(home, City.DOORS[0]["inside"]))
	assert(home.interact() and player.location_id == City.CITY_ID)
	assert(not home._room_view.visible and home._camera.get_screen_center_position().is_equal_approx(lock))
	assert(home.toggle_camera_lock())
	for point in [Vector2(5060, 415), Vector2(4810, 433), Vector2(4560, 435), City.BOARD]:
		assert(await _walk(home, point))
	assert(home.interact() and game._away)
	assert(game.outer.ride_destination == Outer.MEADOWS)
	assert(await _wait_for_arrival(game, Island.Meadows.LOCATION_ID))
	assert(home.actor == player and home.actor.location_id == Island.Meadows.LOCATION_ID)
	assert(home.entities.get_entity(City.BREAD).get_parameter("alive"))
	# An optional anomaly may interrupt the scenery after real exploration
	# and a confirmed simulation recovery. Only the random roll is controlled.
	for point in [Vector2(1925, 530), Vector2(1851, 442), Vector2(1774, 432)]:
		assert(await _walk(home, point))
	assert(home.rare_candidate().get("id") == RareDirector.HAND)
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
	assert(await _walk(home, Vector2(1682, 432)))
	await process_frame
	assert(game.rare_encounters.active.is_empty() and game.rare_encounters.consumed == [RareDirector.HAND])
	assert(home.rare_kind.is_empty())
	game.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PROFILE))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PROFILE + ".bak"))
	print("Public route: start, ordinary transport and invitations, fixed roombox, and optional anomaly passed")
	quit()


func _walk(home: Node, target: Vector2) -> bool:
	for tick in 280:
		var offset: Vector2 = target - home.actor.position
		if offset.length_squared() < 16.0:
			home.apply_player_input(Vector2.ZERO)
			await physics_frame
			return home.actor.motion.grounded
		home.apply_player_input(offset.normalized())
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
