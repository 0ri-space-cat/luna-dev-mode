extends SceneTree
const Scene = preload("res://scenes/skeleton/adventure.tscn")
const Island = preload("res://scripts/skeleton/start_island.gd")
const Finds = preload("res://scripts/skeleton/secret_finds_layout.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game = Scene.instantiate()
	game.profile_path = "user://luna_finds_%d.json" % OS.get_process_id()
	game.get_node("Home").keyboard = false
	root.add_child(game)
	await physics_frame
	var home = game.home
	assert(home.access.wand_mode == home.AccessState.ORDINARY)
	_place(home, Vector2(4550, 515))
	assert(not home._take_city_tool("GRAVITY_GUN"))
	_place(home, Finds.GRAVITY_ENTRY)
	assert(await _walk_to(home, Finds.GRAVITY_POINT))
	assert(home.actor.motion.grounded and is_equal_approx(home.actor.motion.elevation, Finds.GRAVITY_HEIGHT))
	assert(home.interact() and "GRAVITY_GUN" in home.city_tools.owned)
	assert(not home._take_city_tool("GRAVITY_GUN"))
	assert(await _walk_to(home, Finds.GRAVITY_ENTRY))
	_place(home, Vector2(1895, 125))
	assert(not home._take_flute())
	_place(home, Finds.FLUTE_ENTRY)
	assert(await _walk_to(home, Finds.FLUTE_POINT))
	assert(home.actor.motion.grounded and is_equal_approx(home.actor.motion.elevation, Finds.FLUTE_HEIGHT))
	assert(home.interact() and home.flute_owned)
	assert(await _walk_to(home, Finds.FLUTE_ENTRY))
	assert(home.actor.recoveries == 0 and home.access.wand_mode == home.AccessState.ORDINARY)
	assert(home.social.meetings.is_empty() and home.social.invitations.is_empty())
	assert(home.apply_snapshot(JSON.parse_string(JSON.stringify(home.make_snapshot()))))
	assert(home.flute_owned and "GRAVITY_GUN" in home.city_tools.owned)
	game.queue_free()
	await process_frame
	print("Independent elevated finds, physical approach and return, one original each and persistence passed")
	quit()


func _place(home: Node, point: Vector2) -> void:
	home.actor.position = point
	home.actor.motion.reset_on_surface(point, 0.0)
	home.actor.location_id = home._entity_location(point)
	home.apply_player_input(Vector2.ZERO)


func _walk_to(home: Node, target: Vector2) -> bool:
	for tick in 220:
		var offset: Vector2 = target - home.actor.position
		if offset.length_squared() < 16.0:
			home.apply_player_input(Vector2.ZERO)
			for settle in 30:
				if home.actor.motion.grounded:
					return true
				await physics_frame
			return false
		home.apply_player_input(offset.normalized())
		await physics_frame
	home.apply_player_input(Vector2.ZERO)
	push_error("Find approach: %s at %s, Z=%s" % [target, home.actor.position, home.actor.motion.elevation])
	return false
