extends SceneTree
const Scene = preload("res://scenes/skeleton/adventure.tscn")
const Island = preload("res://scripts/skeleton/start_island.gd")
const Outer = preload("res://scripts/skeleton/outer_routes_fixture.gd")
const Route = preload("res://scripts/skeleton/interior_backdrop_2d.gd")
const Door = preload("res://scripts/runtime2d/doorway_2d.gd")
const Store = preload("res://scripts/runtime2d/save_store_2d.gd")
var path := "user://luna_backdrop_test_%d.json" % OS.get_process_id()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game = Scene.instantiate()
	game.profile_path = path
	game.get_node("Home").keyboard = false
	root.add_child(game)
	await physics_frame
	var home = game.home
	assert(home.backdrop_route == null and not game._start_backdrop_void())
	var body = home.actor
	# Test-only threshold on existing permanent ground; no live room selected.
	var source := Vector2(410, 420)
	body.position = source
	body.motion.reset_on_surface(source, 0.0)
	body.location_id = Island.ISLAND_ID
	home.highland.camera_owned = true
	home.highland.camera_mode = "LOCKED"
	home.highland.camera_lock = Vector2(350, 370)
	home._camera.zoom = Vector2(4.0, 4.0)
	home._update_local_camera()
	home._camera.reset_smoothing()
	home._camera.force_update_scroll()
	var door := Door.new()
	door.entity_id = "TEST_ONLY_BACKDROP_DOOR"
	door.position = Vector2(425, 420)
	home.add_child(door)
	var route := Route.new()
	var hud := home.get_node("Interface/Status") as Control
	assert(route.configure(Island.ISLAND_ID, door, home._camera, hud, Rect2(350, 385, 75, 70), Vector2.RIGHT))
	home.backdrop_route = route
	assert(route.begin(body, home.world_clock))
	assert(not route.can_edit_hud(body, home.access, hud))
	assert(not game._start_backdrop_void())
	# A real departure followed by a discontinuous jump cannot grant backdrop access.
	assert(await _walk(home, route, Vector2(450, 420)))
	assert(route.on_backdrop())
	body.position = Vector2(550, 420)
	assert(not route.on_backdrop() and not route.observe(body))
	assert(not route.ready_for_void(body) and not route.can_edit_hud(body, home.access, hud))
	body.position = source
	body.motion.reset_on_surface(source, 0.0)
	body.location_id = Island.ISLAND_ID
	assert(route.begin(body, home.world_clock))
	assert(await _walk(home, route, Vector2(450, 420)))
	assert(route.on_backdrop() and not route.ready_for_void(body))
	assert(not route.can_use_reverse_door(body, Callable()))
	# Stay on the backdrop, without cutting back through the test room.
	assert(await _walk(home, route, Vector2(450, 300)))
	# Approach the real projected HUD, not a duplicate world-space target.
	var hud_rect: Rect2 = hud.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, hud.size)
	var hud_world: Vector2 = home._camera.get_canvas_transform().affine_inverse() * hud_rect.get_center()
	assert(await _walk(home, route, hud_world))
	assert(not route.can_edit_hud(body, home.access, hud))
	assert(home.access.set_wand_mode("DEVELOPER"))
	assert(route.can_edit_hud(body, home.access, hud))
	assert(not route.can_edit_hud(body, home.access, home.get_node("Interface/Controls")))
	var screen: Rect2 = home.get_viewport().get_visible_rect()
	var transform: Transform2D = home._camera.get_canvas_transform()
	var outside: Vector2 = transform.affine_inverse() * Vector2(screen.end.x + 300.0, screen.get_center().y)
	assert(await _walk(home, route, outside))
	assert(route.ready_for_void(body) and game._start_backdrop_void())
	assert(game._away and game.outer.actor == body and game.outer.current_address == Outer.BLACK_VOID)
	assert(game.outer.hosted_entry == Outer.BACKDROP_ENTRY and not game.white_discovered and game.journal.applied == 0)
	assert(game.save_game())
	assert(Store.new().read_snapshot(path)["guest_entry"] == Outer.BACKDROP_ENTRY)
	game.queue_free()
	await process_frame
	game = Scene.instantiate()
	game.profile_path = path
	game.get_node("Home").keyboard = false
	root.add_child(game)
	await physics_frame
	assert(game._profile_valid and game._away and game.outer.hosted_entry == Outer.BACKDROP_ENTRY)
	assert(game._return_to_home() and game.home.actor.position.distance_to(source) < 1.0)
	assert(not game.white_discovered and game.journal.applied == 0)
	_check_public_room_camera(game.home)
	game.queue_free()
	await process_frame
	for file in [path, path + ".bak"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(file))
	print("Special interior adapter: real door, HUD, static viewport crossing, distinct Black Void provenance and safe reload")
	quit()


func _check_public_room_camera(home: Node) -> void:
	var city = Island.City
	var porch: Vector2 = city.DOORS[0]["outside"]
	home.highland.camera_owned = true
	home.highland.camera_mode = "FOLLOW"
	home._move_home_travelers(porch + Vector2(-48, 0), city.CITY_ID)
	assert(home.toggle_camera_lock())
	var outside_frame: Vector2 = home.highland.camera_lock
	home._move_home_travelers(porch, city.CITY_ID)
	assert(home.interact() and home.actor.location_id == city.CAFE_ID)
	assert(home._room_view.visible and home._camera.get_screen_center_position().is_equal_approx(city.CAFE.get_center()))
	assert(home.interact() and home.actor.location_id == city.CITY_ID)
	assert(not home._room_view.visible and home._camera.get_screen_center_position().is_equal_approx(outside_frame))


func _walk(home, route, target: Vector2) -> bool:
	for tick in 250:
		var delta: Vector2 = target - home.actor.position
		if delta.length_squared() < 9.0:
			home.apply_player_input(Vector2.ZERO)
			route.observe(home.actor)
			return true
		home.apply_player_input(delta.normalized())
		await physics_frame
		route.observe(home.actor)
	home.apply_player_input(Vector2.ZERO)
	return false
