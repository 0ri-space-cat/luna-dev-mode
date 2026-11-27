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
	assert(not home.social.oni_profile_unlocked() and not home._oni_w8_near())
	# Start the existing NPC at the real near shore, then let her walk the
	# open bridge and use the doorway. The test does not place her in the room.
	var oni = home.entities.get_entity(Island.Visits.ONI_ID)
	home._place_friend(oni, Island.W8.NEAR, 0.0)
	home.oni_route_index = Island.Visits.W8_NEAR_INDEX
	assert(await _walk_to(home, Vector2(4140, 585)))
	for tick in 480:
		if home.oni_route_index == Island.Visits.W8_STUDY_INDEX and oni.position.distance_to(Island.Visits.ROUTE[Island.Visits.W8_STUDY_INDEX]) < 5.0:
			break
		await physics_frame
	assert(oni.location_id == Island.W8.REFUGE and home._oni_w8_near(), "Oni at %s, route %d, player %s" % [oni.position, home.oni_route_index, home.actor.position])
	assert(home._w8_action() == "Поговорить с Они в убежище", "Wrong W8 action: %s at %s" % [home._w8_action(), home.actor.position])
	assert(home.entities.get_entity(Island.Visits.ONI_ID) == oni and home.interact())
	assert(home.social.oni_profile_unlocked() and not home.social.prism_owned and home.social.oni_sites.is_empty(), "Social state: %s" % home.social.snapshot())
	assert(home.apply_snapshot(JSON.parse_string(JSON.stringify(home.make_snapshot()))))
	assert(home.social.oni_profile_unlocked())
	assert(home.actor.location_id == Island.W8.REFUGE and home.wand_pair.held.is_empty())
	assert(home.oni_route_index == Island.Visits.W8_STUDY_INDEX)
	assert(home.entities.get_entity(Island.Visits.ONI_ID).location_id == Island.W8.REFUGE)
	assert(await _walk_to(home, Island.W8.ENTRY))
	assert(home.interact() and home.actor.location_id == Island.W8.PASSAGE)
	assert(await _walk_to(home, Vector2(3085, 550)))
	assert(await _walk_to(home, Vector2(3085, 415)))
	# Return to the actual drop location/address on the west side.
	assert(await _walk_to(home, Vector2(2785, 415)))
	assert(home.exchange_nearby_wand(), "Wands %s at %s" % [home.wand_pair.snapshot(), home.actor.position])
	assert(not home.wand_pair.held.is_empty())
	# Daytime ordinary schedule resumes; the room exit uses the same safe
	# near-shore fallback when the retrieved wand restores the field.
	home.world_clock.set_time_of_day(12 * 60)
	for tick in 480:
		if home.entities.get_entity(Island.Visits.ONI_ID).location_id != Island.W8.REFUGE:
			break
		await physics_frame
	assert(home.entities.get_entity(Island.Visits.ONI_ID).location_id != Island.W8.REFUGE)
	# Real portrait projection, separate access and no new physical hero.
	var portrait := home.get_node("Interface/ProfilePortrait") as Control
	var bounds: Rect2 = portrait.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, portrait.size)
	var screen: Rect2 = home.get_viewport().get_visible_rect()
	home.highland.camera_owned = true
	home.highland.camera_mode = "LOCKED"
	home.highland.camera_lock = home.actor.position + (screen.get_center() - bounds.get_center()) / home._camera.zoom
	home._update_local_camera()
	home._camera.reset_smoothing()
	home._camera.force_update_scroll()
	assert(home.access.set_wand_mode("PLAYFUL"))
	assert(not home.request_profile_change("ONI"))
	assert(home.access.set_wand_mode("DEVELOPER"))
	assert(home._profile_edit_allowed())
	var original_actor = home.actor
	var components: Dictionary = original_actor.record.get_components()
	assert(not home.request_profile_change("YUKI"))
	assert(home._open_profile_panel())
	assert(home._profile_panel.preview_profile("ONI") and home.hero_profile.active == "LUNA")
	assert(not home._profile_panel.preview_profile("YUKI"))
	assert(home._profile_panel.confirm_preview() and home.hero_profile.active == "ONI")
	assert(home.actor == original_actor and home.actor.record.get_components() == components)
	home.set_luna_eyes(false)
	assert(home.hero_profile.sees_underside(false) and not home._w8_open)
	assert(not home.hero_profile.sees_underside(true))
	var profile_save: Dictionary = JSON.parse_string(JSON.stringify(home.make_snapshot()))
	var invalid_profile := profile_save.duplicate(true)
	invalid_profile["social"]["oni_deep_met"] = false
	assert(not home.apply_snapshot(invalid_profile) and home.hero_profile.active == "ONI")
	assert(home.apply_snapshot(profile_save) and home.hero_profile.active == "ONI")
	assert(home.social.oni_profile_unlocked())
	home.highland.camera_mode = "FOLLOW"
	home._update_local_camera()
	home._camera.reset_smoothing()
	home._camera.force_update_scroll()
	assert(not home.request_profile_change("LUNA"))
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
