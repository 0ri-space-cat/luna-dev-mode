extends SceneTree
const Scene = preload("res://scenes/skeleton/adventure.tscn")
const Island = preload("res://scripts/skeleton/start_island.gd")
const Mountain = preload("res://scripts/skeleton/mountain_layout.gd")


func _initialize() -> void:
	call_deferred("_run")


func _place(home, body, point: Vector2, height: float = 0.0) -> void:
	body.position = point
	body.motion.reset_on_surface(point, height)
	body.location_id = home._entity_location(point)


func _run() -> void:
	var game = Scene.instantiate()
	game.profile_path = "user://luna_highland_test_%d.json" % OS.get_process_id()
	game.get_node("Home").keyboard = false
	root.add_child(game)
	await physics_frame
	var home = game.home
	assert(home._entity_location(Mountain.ENTRY) == Mountain.MOUNTAIN)
	assert(home._entity_location(Vector2(1725, 880)) == Island.Valley.LOCATION_ID)
	assert(not Mountain.H2.intersects(Island.MiaLab.DEEP))
	assert(not home.toggle_camera_lock() and not home.cycle_compass())
	assert(not home.actor.fits_walls_at(Vector2(1770, 312), 0.0, 11.0))
	assert(home.actor.fits_walls_at(Vector2(1770, 312), 0.0, 5.5))
	_place(home, home.actor, Mountain.CAMERA_POINT)
	assert(home.interact() and home.highland.camera_owned)
	_place(home, home.actor, Mountain.COMPASS)
	assert(home.interact() and home.highland.compass_owned)
	assert(home.cycle_compass() and home.actor.world_gravity_multiplier == 0.5)
	assert(home.actor.get_parameter("gravity_scale") == 1.0)
	_place(home, home.actor, Mountain.WIND.get_center())
	home._sync_highland_forces()
	assert(home.actor.environmental_wind.z > 0.0)
	var ray = home.entities.get_entity(Mountain.RAY_ID)
	assert(ray != null and ray.can_fly() and ray.get_parameter("rideable"))
	_place(home, home.actor, Vector2(1945, 1610), 18.0)
	home._update_local_camera()
	home._camera.reset_smoothing()
	home._sync_mountain_bridge()
	assert(not home._surfaces.has(Mountain.CAMERA_BRIDGE))
	home.set_luna_eyes(false)
	home._sync_mountain_bridge()
	assert(not home._surfaces.has(Mountain.CAMERA_BRIDGE))
	_place(home, home.actor, Mountain.ENTRY)
	home._update_local_camera()
	home._camera.reset_smoothing()
	assert(home.toggle_camera_lock())
	home.highland.camera_lock = Vector2(900, 350)
	home._update_local_camera()
	home._camera.reset_smoothing()
	_place(home, home.actor, Vector2(1945, 1610), 18.0)
	home._sync_mountain_bridge()
	assert(home._surfaces.has(Mountain.CAMERA_BRIDGE) and home.actor.accepts_player_input())
	var state: Dictionary = JSON.parse_string(JSON.stringify(home.make_snapshot()))
	assert(home.apply_snapshot(state) and home.highland.camera_mode == "LOCKED")
	assert(home.return_to_luna() and home.highland.camera_mode == "FOLLOW")
	assert(not home._surfaces.has(Mountain.CAMERA_BRIDGE))
	_place(home, home.actor, Vector2(2100, 1890))
	assert(not home.social.prism_owned and not home.prism_active)
	assert(home._highland_action() == "Рассмотреть старые рисунки" and home.interact())
	assert(home.get_node("Interface/SaveNotice").text.contains("две перекрывающиеся"))
	assert(not home.social.prism_owned and not home.prism_active)
	# Oracle needs a real available entity, not only its position.
	var oracle = home.entities.get_entity(Mountain.ORACLE_ID)
	_place(home, home.actor, oracle.position + Vector2(-15, 0), oracle.motion.elevation)
	assert(home._highland_action() == "Поговорить с Оракулом")
	assert(oracle.set_parameter("ai_enabled", false))
	assert(home._highland_action() != "Поговорить с Оракулом")
	assert(oracle.set_parameter("ai_enabled", true))
	_place(home, home.actor, Vector2(2100, 1890))
	home.flute_owned = true
	assert(home.perform_music("DULRDU") and home._mountain_echo > 0.0)
	var bad: Dictionary = state.duplicate(true)
	bad["highland"]["camera_owned"] = false
	assert(not home.apply_snapshot(bad))
	game.queue_free()
	await process_frame
	print("M3.162–173 mountain geography, camera, compass, wind, ray and saved observer")
	quit()
