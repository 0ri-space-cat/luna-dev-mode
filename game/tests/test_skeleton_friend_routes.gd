extends SceneTree
## Actual autonomous walks across meadow and city, one body and existing doors.
const Scene = preload("res://scenes/skeleton/adventure.tscn")
const Island = preload("res://scripts/skeleton/start_island.gd")
const Routes = preload("res://scripts/skeleton/friend_routes_2d.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game = Scene.instantiate()
	game.profile_path = "user://luna_friend_routes_%d.json" % OS.get_process_id()
	game.get_node("Home").keyboard = false
	root.add_child(game)
	await physics_frame
	var home = game.home
	var toffi = home.entities.get_entity(Island.City.TOFFI)
	assert(toffi != null and toffi.location_id == Island.Meadows.LOCATION_ID)
	assert(toffi.set_parameter("speed", 2.5))
	assert(home.world_clock.set_time_of_day(12 * 60))
	assert(await _reach(toffi, Routes.SHOP_TALK, 720), "Toffi shop position: %s" % str(toffi.position))
	assert(home.entities.get_entity(Island.City.TOFFI) == toffi and Island.City.SHOP.has_point(toffi.position))
	assert(home.social.meetings.is_empty() and home.antimemetic.stage == 0)
	# The shop conversation is not a substitute for the ordinary meadow meeting.
	home.actor.position = Routes.SHOP_TALK + Vector2(0, 30)
	home.actor.motion.reset_on_surface(home.actor.position, 0.0)
	home.actor.location_id = home._entity_location(home.actor.position)
	assert(home._toffi_shop_chat() and home._ordinary_friend_target() != "TOFFI")
	home.actor.position = Island.SPAWN
	home.actor.motion.reset_on_surface(home.actor.position, 0.0)
	home.actor.location_id = home._entity_location(home.actor.position)
	var snapshot: Dictionary = JSON.parse_string(JSON.stringify(home.make_snapshot()))
	assert(home.apply_snapshot(snapshot))
	toffi = home.entities.get_entity(Island.City.TOFFI)
	assert(is_equal_approx(float(toffi.get_parameter("speed")), 2.5))
	assert(toffi.set_parameter("ai_enabled", false))
	var stopped: Vector2 = toffi.position
	assert(home.world_clock.set_time_of_day(18 * 60))
	for tick in 10:
		await physics_frame
	assert(toffi.position.distance_to(stopped) < 1.0)
	assert(toffi.set_parameter("ai_enabled", true))
	assert(await _reach(toffi, Routes.TOFFI_MEADOW, 720), "Toffi return position: %s" % str(toffi.position))
	assert(home.entities.get_entity(Island.City.TOFFI) == toffi)
	var yuki = home.entities.get_entity(Island.City.YUKI)
	var ori = home.entities.get_entity(Island.City.ORI)
	assert(await _reach(yuki, Routes.YUKI_OUTSIDE[-1], 300), "Yuki evening position: %s" % str(yuki.position))
	assert(await _reach(ori, Routes.ORI_OUTSIDE[-1], 300), "Ori evening position: %s" % str(ori.position))
	var mia = home.entities.get_entity(Island.Life.MIA_ID)
	assert(await _reach(mia, Island.Life.MIA_ROUTE[-1], 360), "Mia evening position: %s" % str(mia.position))
	assert(home.world_clock.set_time_of_day(9 * 60))
	assert(await _reach(yuki, Routes.YUKI_INSIDE[0], 300), "Yuki return position: %s" % str(yuki.position))
	assert(await _reach(ori, Routes.ORI_INSIDE[0], 300), "Ori return position: %s" % str(ori.position))
	assert(await _reach(mia, Island.Life.MIA_START, 360), "Mia return position: %s" % str(mia.position))
	assert(home.entities.get_entity(Island.City.YUKI) == yuki and home.entities.get_entity(Island.City.ORI) == ori)
	assert(home.apply_snapshot(JSON.parse_string(JSON.stringify(home.make_snapshot()))))
	game.queue_free()
	await process_frame
	print("Ordinary friend schedules, threshold travel, stable identity, save and autonomy passed")
	quit()


func _reach(body: Node, point: Vector2, ticks: int) -> bool:
	for tick in ticks:
		if body.position.distance_to(point) < 12.0:
			return true
		await physics_frame
	return false
