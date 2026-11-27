extends SceneTree
const Scene = preload("res://scenes/skeleton/adventure.tscn")
const Island = preload("res://scripts/skeleton/start_island.gd")
const Edge = preload("res://scripts/skeleton/forgotten_edge_layout.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game = Scene.instantiate()
	game.profile_path = "user://luna_refuge_%d.json" % OS.get_process_id()
	game.get_node("Home").keyboard = false
	root.add_child(game)
	await physics_frame
	var home = game.home
	assert(home._entity_location(Edge.LEGACY_NOTE) != Edge.REFUGE)
	assert(home._entity_location(Edge.NOTE) == Edge.REFUGE)
	assert(Edge.BANK not in home._ordinary_public_addresses() and Edge.REFUGE not in home._ordinary_public_addresses())
	_place(home, Island.Valley.W7_ENTRY)
	assert(await _walk_to(home, Vector2(2930, 320)))
	assert(await _walk_to(home, Vector2(2930, -2)))
	home._update_local_camera()
	home._camera.reset_smoothing()
	home._sync_mountain_bridge()
	assert(not home._surfaces.has(Edge.BRIDGE))
	home.set_luna_eyes(false)
	home._sync_mountain_bridge()
	assert(not home._surfaces.has(Edge.BRIDGE))
	home.set_luna_eyes(true)
	home.highland.camera_owned = true
	home.highland.camera_mode = "LOCKED"
	home.highland.camera_lock = Vector2(900, 350)
	home._update_local_camera()
	home._camera.reset_smoothing()
	home._sync_mountain_bridge()
	assert(home._surfaces.has(Edge.BRIDGE))
	assert(await _walk_to(home, Vector2(3300, -2)))
	assert(home.actor.location_id == Edge.BANK)
	assert(await _walk_to(home, Vector2(3350, 70)))
	assert(await _walk_to(home, Edge.NOTE))
	assert(home.actor.location_id == Edge.REFUGE and home.actor.recoveries == 0)
	assert(home.interact() and home.get_node("Interface/SaveNotice").text.contains("GAME_FRAME"))
	assert(not home.get_node("Interface/SaveNotice").text.contains("META_WHITE_VOID"))
	var old: Dictionary = JSON.parse_string(JSON.stringify(home.make_snapshot()))
	old["address_schema"] = 18
	for record in old["entities"]:
		if record["id"] == Island.ENTITY_ID:
			record["position"] = [Edge.LEGACY_NOTE.x, Edge.LEGACY_NOTE.y]
			record["location_id"] = Edge.REFUGE
			record["motion"]["anchor"] = [Edge.LEGACY_NOTE.x, Edge.LEGACY_NOTE.y, 0.0]
	assert(home.apply_snapshot(old))
	assert(home.actor.position.distance_to(Edge.NOTE) < 1.0 and home.actor.location_id == Edge.REFUGE)
	assert(home.apply_snapshot(JSON.parse_string(JSON.stringify(home.make_snapshot()))))
	assert(await _walk_to(home, Vector2(3350, 70)))
	assert(await _walk_to(home, Vector2(3300, -2)))
	assert(await _walk_to(home, Vector2(2930, -2)))
	assert(await _walk_to(home, Vector2(2930, 320)))
	assert(home.actor.recoveries == 0)
	# W8 is separate from Q22 and cannot be opened by camera or personal gaze.
	assert(Island.W8.REFUGE not in home._ordinary_public_addresses())
	_place(home, Vector2(2785, 415))
	assert(home.drop_held_wand() and home.wand_pair.held.is_empty())
	# One nearby second field is sufficient to keep the ordinary seam solid.
	assert(home.wand_pair.original.pick_up_from(home.actor.position, 54.0, home._entity_location(home.actor.position)))
	home.wand_pair.held = home.WandPair.ORIGINAL
	assert(home.wand_pair.duplicate_in_water(Island.W8.NEAR, Island.W8.PASSAGE))
	assert(home.drop_held_wand())
	assert(await _walk_to(home, Vector2(3085, 415)))
	assert(await _walk_to(home, Island.W8.NEAR))
	assert(not home._w8_open and not home._surfaces.has(Island.W8.BRIDGE))
	assert(home.exchange_nearby_wand() and home.wand_pair.held == home.WandPair.DUPLICATE)
	assert(await _walk_to(home, Vector2(3085, 415)))
	assert(await _walk_to(home, Vector2(2840, 415)))
	assert(home.drop_held_wand())
	assert(await _walk_to(home, Vector2(3085, 415)))
	assert(await _walk_to(home, Island.W8.NEAR))
	# Still inside the field of the nearer dropped wand at y=540.
	assert(not home._w8_open)
	assert(await _walk_to(home, Vector2(3085, 550)))
	# Move the second wand back farther west to make a genuine two-field crossing.
	assert(await _walk_to(home, Vector2(3085, 415)))
	assert(await _walk_to(home, Vector2(2840, 415)))
	assert(home.exchange_nearby_wand())
	assert(await _walk_to(home, Vector2(2785, 400)))
	assert(home.drop_held_wand())
	assert(await _walk_to(home, Vector2(3085, 415)))
	assert(await _walk_to(home, Vector2(3085, 550)))
	assert(home._w8_open, "Both fields clear at %s" % home.actor.position)
	assert(await _walk_to(home, Island.W8.FAR))
	assert(home.interact() and home.actor.location_id == Island.W8.REFUGE)
	assert(await _walk_to(home, Island.W8.NOTE))
	assert(home.interact() and not home.get_node("Interface/SaveNotice").text.contains("META_WHITE_VOID"))
	assert(home.apply_snapshot(JSON.parse_string(JSON.stringify(home.make_snapshot()))))
	assert(home.actor.location_id == Island.W8.REFUGE and home.wand_pair.held.is_empty())
	assert(await _walk_to(home, Island.W8.ENTRY))
	assert(home.interact() and home.actor.location_id == Island.W8.PASSAGE)
	assert(await _walk_to(home, Vector2(3085, 550)))
	assert(await _walk_to(home, Vector2(3085, 415)))
	assert(await _walk_to(home, Vector2(2810, 415)))
	assert(home.exchange_nearby_wand())
	assert(not home.wand_pair.held.is_empty())
	game.queue_free()
	await process_frame
	print("Relocated Q22: physical waterfall approach, camera span, old save and return passed")
	quit()


func _place(home: Node, point: Vector2) -> void:
	home.actor.position = point
	home.actor.motion.reset_on_surface(point, 0.0)
	home.actor.location_id = home._entity_location(point)
	home.apply_player_input(Vector2.ZERO)


func _walk_to(home: Node, target: Vector2) -> bool:
	for tick in 250:
		var offset: Vector2 = target - home.actor.position
		if offset.length_squared() < 16.0:
			home.apply_player_input(Vector2.ZERO)
			await physics_frame
			return home.actor.motion.grounded
		home.apply_player_input(offset.normalized())
		await physics_frame
	home.apply_player_input(Vector2.ZERO)
	push_error("Q22 approach failed: %s at %s" % [target, home.actor.position])
	return false
