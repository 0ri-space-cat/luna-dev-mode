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
	assert(Store.new().read_snapshot(path)["white_discovered"])
	assert(game.save_game())
	assert(game._return_to_home() and home.actor == traveler and home.game_frame_solid)
	assert(game.apply_local_rollback(early) and game.white_discovered)
	_place(home, Island.AncientConsole.RETURN_POINT)
	assert(home.interact())
	home.ancient_console._submit("TELEPORT " + Routes.WHITE_ADDRESS)
	assert(game._away and game.outer.current_address == Routes.WHITE_ADDRESS and game.outer.actor == home.actor)
	assert(game._return_to_home())
	assert(home.actor.position.distance_to(Island.AncientConsole.RETURN_POINT) < 1.0)
	game.queue_free()
	await process_frame
	game = Scene.instantiate()
	game.profile_path = path
	root.add_child(game)
	await physics_frame
	assert(game._profile_valid and game.white_discovered)
	game.queue_free()
	await process_frame
	for file in [path, path + ".bak"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(file))
	print("Protected window, physical desktop, persisted discovery and console repeat passed")
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
