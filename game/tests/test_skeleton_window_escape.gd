extends SceneTree
const Scene = preload("res://scenes/skeleton/adventure.tscn")
const Island = preload("res://scripts/skeleton/start_island.gd")
const Routes = preload("res://scripts/skeleton/outer_routes_fixture.gd")
const Access = preload("res://scripts/runtime2d/access_state_2d.gd")
const Store = preload("res://scripts/runtime2d/save_store_2d.gd")
var path := "user://luna_window_escape_%d.json" % OS.get_process_id()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game = Scene.instantiate()
	game.profile_path = path
	game.get_node("Home").keyboard = false
	root.add_child(game)
	await physics_frame
	var home = game.home
	var traveler = home.actor
	assert(not game.white_discovered and not game._visit_white_void())
	assert(home.set_game_mode("WINDOWED") and not home.set_game_frame_solid(false))
	assert(not game._start_desktop_visit())
	var early: Dictionary = home.make_snapshot()
	_place(home, Vector2(510, 535))
	home.highland.camera_owned = true
	home._update_local_camera()
	home._camera.reset_smoothing()
	assert(home.toggle_camera_lock())
	await physics_frame
	var bounds: Rect2 = home._frame_world_bounds()
	assert(bounds.has_point(traveler.position), "Window bounds %s, Luna %s, camera %s, viewport %s" % [bounds, traveler.position, home.highland.camera_lock, home.get_viewport().get_visible_rect()])
	var edge := Vector2(bounds.position.x + 18.0, traveler.position.y)
	assert(await _walk_home(home, edge))
	assert(not home.set_game_frame_solid(false))
	assert(home.access.set_wand_mode(Access.DEVELOPER))
	assert(home._frame_edit_allowed())
	home.apply_player_input(Vector2.LEFT)
	for tick in 24:
		await physics_frame
		assert(not game._away and bounds.grow(1.0).has_point(traveler.position), "Solid frame tick %d: Luna=%s, bounds=%s" % [tick, traveler.position, bounds])
	home.apply_player_input(Vector2.ZERO)
	assert(home.set_game_frame_solid(false))
	assert(not game._start_desktop_visit())
	home.apply_player_input(Vector2.LEFT)
	for tick in 50:
		await physics_frame
		if game._away:
			break
	assert(game._away and game.outer.current_address == Routes.DESKTOP and game.outer.actor == traveler, "Frame crossing: %s, solid=%s, gate=%s" % [traveler.position, home.game_frame_solid, home._frame_edit_allowed()])
	assert(not game.white_discovered and not game._discover_white_from_desktop())
	assert(game.save_game())
	var desktop_save: Dictionary = Store.new().read_snapshot(path)
	assert(desktop_save["guest_entry"] == Routes.DESKTOP and not desktop_save["white_discovered"])
	game.outer.keyboard = false
	game.outer.actor.direction = Vector2.RIGHT
	for tick in 240:
		await physics_frame
		if game.outer.current_address == Routes.WHITE_ADDRESS:
			break
	assert(game.outer.current_address == Routes.WHITE_ADDRESS and game.white_discovered and game.outer.actor == traveler, "Desktop exit: %s / %s" % [game.outer.current_address, traveler.position])
	assert(not game.outer.get_node("Interface").visible)
	assert(is_instance_valid(game.outer.white_presentation) and game.outer.white_presentation.intro_remaining > 0.0)
	assert(not game.meta.pixel_seen and not game.meta.merged)
	assert(Store.new().read_snapshot(path)["white_discovered"])
	assert(game.save_game())
	game.outer.actor.direction = Vector2.ZERO
	# Observe the actual scene create shared, temporary supports. Neither
	# their presence nor their expiry changes story progress.
	for tick in 120:
		await physics_frame
		if game.outer.white_presentation.steps.active_count() > 0:
			break
	assert(game.outer.white_presentation.steps.active_count() > 0)
	var surface: Dictionary = game.outer.white_presentation.steps.live_surfaces()[0]
	assert(game.outer._surfaces.has(surface) and not surface["safe"])
	var original_position: Vector2 = traveler.position
	var original_motion: Dictionary = traveler.motion.snapshot()
	# Isolate the save contract from movement timing (real landing is covered
	# by the elevation regression). No persistent new support is introduced.
	traveler.position = surface["bounds"].get_center()
	traveler.motion.elevation = float(surface["height"])
	traveler.motion.grounded = true
	traveler.motion.vertical_speed = 0.0
	var transient_save: Dictionary = game.outer.make_snapshot()
	assert(not transient_save["actor"]["motion"]["grounded"])
	assert(traveler.motion.grounded and transient_save["actor"]["motion"]["anchor"] == original_motion["anchor"])
	assert(game.save_game() and game.load_game())
	assert(game._away and not game.meta.merged and not game.meta.pixel_seen)
	assert(not traveler.motion.grounded and traveler.position == surface["bounds"].get_center())
	for tick in 90:
		await physics_frame
		if traveler.motion.grounded:
			break
	assert(traveler.motion.grounded and is_zero_approx(traveler.motion.elevation))
	assert(not is_instance_valid(game.outer.white_presentation) or game.outer.white_presentation.steps.active_count() == 0)
	# Return to the pre-test position on the actual floor, for the original
	# independent voluntary encounter and movement assertions.
	traveler.position = original_position
	traveler.motion.reset_on_surface(original_position, 0.0)
	# A physical approach, not a menu or automatic story flag.
	assert(not game._commit_meta_event("MERGE") and not game.meta.merged)
	assert(not game.outer.pixel_repeat and not game.outer.use_route())
	game.outer.actor.direction = Vector2.RIGHT
	for tick in 180:
		await physics_frame
		if game.outer.at_meta_encounter():
			break
	game.outer.actor.direction = Vector2.ZERO
	assert(game.outer.at_meta_encounter(), "Proto approach")
	assert(game.outer.use_route() and not game.meta.merged)
	assert(game.outer.use_route() and not game.meta.merged)
	assert(game.outer.decline_meta() and not game.meta.merged)
	assert(game.outer.use_route() and game.outer.use_route())
	assert(game.save_game() and game.load_game())
	assert(not game.meta.merged and game.outer._meta_stage == 0)
	assert(game.outer.use_route() and game.outer.use_route() and game.outer.use_route())
	assert(game.meta.merged and not game.meta.pixel_seen and not game.outer.pixel_repeat)
	assert(game.outer.white_presentation.merge_remaining > 0.0)
	assert(not game.outer.use_route() and not game._commit_meta_event("MERGE"))
	assert(game.outer.actor == traveler and not game.outer.get_node("Interface").visible)
	assert(Store.new().read_snapshot(path)["meta"] == {"merged": true, "pixel_seen": false})
	assert(game._return_to_home() and home.actor == traveler and home.game_frame_solid)
	assert(game.apply_local_rollback(early) and game.white_discovered and game.meta.merged)
	_place(home, Island.AncientConsole.RETURN_POINT)
	assert(home.interact())
	home.ancient_console._submit("TELEPORT " + Routes.WHITE_ADDRESS)
	assert(game._away and game.outer.current_address == Routes.WHITE_ADDRESS and game.outer.actor == home.actor)
	assert(game.outer.pixel_repeat and not game.meta.pixel_seen)
	assert(Store.new().read_snapshot(path)["guest"]["pixel_repeat"])
	game.outer.keyboard = false
	game.outer.actor.direction = Vector2.RIGHT
	for tick in 180:
		await physics_frame
		if game.outer.at_meta_encounter():
			break
	game.outer.actor.direction = Vector2.ZERO
	assert(game.outer.at_meta_encounter() and game.outer.use_route() and not game.meta.pixel_seen)
	assert(game.outer.use_route() and game.meta.pixel_seen and game._away)
	assert(game.outer.white_presentation.farewell_active)
	assert(not game.outer.use_route())
	for tick in 120:
		await physics_frame
		if not game._away:
			break
	assert(not game._away)
	assert(home.actor.position.distance_to(Island.AncientConsole.RETURN_POINT) < 1.0)
	game.queue_free()
	await process_frame
	game = Scene.instantiate()
	game.profile_path = path
	root.add_child(game)
	await physics_frame
	assert(game._profile_valid and game.white_discovered and game.meta.merged and game.meta.pixel_seen)
	var home2 = game.home
	_place(home2, Island.AncientConsole.RETURN_POINT)
	assert(home2.interact())
	home2.ancient_console._submit("TELEPORT " + Routes.WHITE_ADDRESS)
	assert(game._away and not game.outer.pixel_repeat)
	assert(game._return_to_home())
	# Meta-first ordering: the separate friend-evening regression obtains
	# every invitation through contact. Here seed that completed social
	# contract, then exercise the real gathering and ordinary credits.
	assert(home2.evening_stage == 0 and not home2.social.can_gather())
	for friend in home2.Social.FRIENDS:
		if friend == "ONI":
			assert(home2.social.observe_with_oni("W1"))
		else:
			assert(home2.social.complete(friend))
		assert(home2.social.invite(friend))
	assert(not home2.social.prism_owned)
	_place(home2, Island.CAFE_TALK)
	assert(home2.begin_cafe_evening())
	home2._tick_cafe(2.0)
	assert(home2.evening_stage == 2 and home2.finish_cafe_evening())
	assert(home2.ordinary_finale_voice().contains("Помоги мне") and home2.ordinary_finale_voice().contains("отголосок"))
	home2._finish_ordinary_credits()
	assert(home2.evening_stage == 4 and game.meta.merged and game.meta.pixel_seen and game.white_discovered)
	assert(game.save_game())
	var final_save: Dictionary = Store.new().read_snapshot(path)
	assert(final_save["state"]["evening"]["stage"] == 4 and final_save["meta"]["merged"] and final_save["meta"]["pixel_seen"])
	game.queue_free()
	await process_frame
	for file in [path, path + ".bak"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(file))
	print("Protected window, physical desktop, voluntary merge, preserved memory, one-time Pixel console repeat passed")
	quit()


func _place(home, point: Vector2) -> void:
	home.actor.position = point
	home.actor.motion.reset_on_surface(point, 0.0)
	home.actor.location_id = home._entity_location(point)
	home.apply_player_input(Vector2.ZERO)


func _walk_home(home, target: Vector2) -> bool:
	for tick in 240:
		var offset: Vector2 = target - home.actor.position
		if offset.length_squared() < 16.0:
			home.apply_player_input(Vector2.ZERO)
			return true
		home.apply_player_input(offset.normalized())
		await physics_frame
	home.apply_player_input(Vector2.ZERO)
	return false
