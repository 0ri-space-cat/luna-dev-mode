extends SceneTree
const Scene = preload("res://scenes/skeleton/adventure.tscn")
const Island = preload("res://scripts/skeleton/start_island.gd")
const AM = preload("res://scripts/runtime2d/antimemetic_2d.gd")


func _initialize() -> void:
	call_deferred("_run")


func _place(home, body, point: Vector2) -> void:
	body.position = point
	body.motion.reset_on_surface(point, 0.0)
	body.location_id = home._entity_location(point)


func _run() -> void:
	var game = Scene.instantiate()
	game.profile_path = "user://luna_am_test_%d.json" % OS.get_process_id()
	game.get_node("Home").keyboard = false
	root.add_child(game)
	await physics_frame
	var home = game.home
	var giant = home.entities.get_entity(AM.GIANT)
	var joy = home.entities.get_entity(AM.JOY)
	var toffi = home.entities.get_entity(Island.City.TOFFI)
	assert(giant != null and joy != null and not giant.visible and not joy.visible)
	assert(giant.collision_layer != 0 and home.antimemetic.seen.is_empty())
	assert(not home.toggle_lantern() and home.monument_read() == "")
	# The old station encounter is gone; the ordinary meadow encounter is independent.
	_place(home, home.actor, AM.TOFFI_ROUTE[0] + Vector2(0, 30))
	assert(home._ordinary_friend_target().is_empty() and home._city_friend_action().is_empty())
	_place(home, home.actor, toffi.position + Vector2(0, 30))
	assert(home._meet_ordinary_friend())
	assert(home.social.meetings.has("TOFFI") and home.antimemetic.stage == 0 and not joy.visible)
	# The ordinary street does not reveal C6. Its floor gap is real, and
	# the foreground is a viewpoint-dependent layer, not a secret flag.
	var public_corner: Vector2 = Island.City.C6_PUBLIC_CORNER
	_place(home, home.actor, public_corner)
	home._sync_c6_facade()
	assert(home._c6_facade.visible and not Island.City.c6_behind_facade(public_corner))
	assert(not home.actor.motion._has_support(Vector2(5075, 240), 0.0, home.actor.surfaces, true))
	assert(home.antimemetic.stage == 0 and not home.flute_owned and not home.prism_active)
	# Walk the continuous side approach with actual player input.
	for point in Island.City.C6_APPROACH:
		assert(await _walk(home, point), "C6 approach blocked: %s -> %s" % [home.actor.position, point])
	home._sync_c6_facade()
	assert(not home._c6_facade.visible and AM.NICHE.has_point(home.actor.position))
	assert(home.antimemetic.stage == 0 and home._entity_location(home.actor.position) == Island.City.CITY_ID)
	# Same Toffi and giant, now on the optional continuous street.
	_place(home, toffi, AM.TOFFI_ROUTE[-1])
	home.antimemetic.route_index = AM.TOFFI_ROUTE.size() - 1
	home.crystal_observer.facing = Vector2.RIGHT
	home._tick_antimemetic(0.1)
	assert(giant.autonomous_destination.is_finite() and not giant.visible)
	assert(home._interact_toffi_secret())
	assert(home.antimemetic.stage == 1 and home.antimemetic.active and giant.visible)
	home._tick_antimemetic(0.1)
	assert(home.antimemetic.seen_giant and "emot_giant" in home.antimemetic.seen)
	home.set_luna_eyes(false)
	home._tick_antimemetic(0.1)
	assert(not home._am_gaze(giant))
	assert(home._interact_toffi_secret() and home.antimemetic.stage == 2)
	home.set_luna_eyes(true)
	assert(home.toggle_lantern() and not giant.visible and home.entities.get_entity(AM.GIANT) == giant)
	assert(not home.antimemetic.seen.is_empty())
	# Return on foot after the optional gift; no plot gate closes the exit.
	var retreat: Array = Island.City.C6_APPROACH.duplicate()
	retreat.reverse()
	for point in retreat:
		assert(await _walk(home, point), "C6 retreat blocked: %s -> %s" % [home.actor.position, point])
	assert(await _walk(home, public_corner))
	home._sync_c6_facade()
	assert(home._c6_facade.visible and home.antimemetic.stage == 2)
	# Genuine hidden fauna responds to the approved phrase without being revealed.
	_place(home, home.actor, Vector2(2135, 135))
	home.flute_owned = true
	assert(home.perform_music("UDRDLU"))
	assert(home._am_echo_id == AM.CURIOUS and not home.entities.get_entity(AM.CURIOUS).visible)
	# Monument is physical before reveal, and uses two independent channels.
	_place(home, home.actor, Vector2(2030, 110))
	home._tick_antimemetic(0.1)
	assert(home.monument_read() == "")
	assert(home.toggle_lantern())
	assert(home._monument_visible() and home.monument_read() == "")
	# Fixture setup must satisfy the same durable Oni/Prism contract as play.
	assert(home.social.observe_with_oni("W1"))
	assert(home.social.observe_with_oni("K6"))
	home.social.prism_owned = true
	assert(home.toggle_prism())
	var command: String = home.monument_read()
	assert(command == Island.Runes.encode(AM.COMMANDS[home.antimemetic.monument_index]) and command not in AM.COMMANDS and home.antimemetic.active)
	var snapshot: Dictionary = JSON.parse_string(JSON.stringify(home.make_snapshot()))
	assert(home.apply_snapshot(snapshot))
	assert(home.monument_read() == command)
	home._tick_antimemetic(0.1)
	assert(home.monument_read() == command)
	assert(home.toggle_lantern() and home.prism_active and home.monument_read() == "")
	var invalid: Dictionary = snapshot.duplicate(true)
	invalid["antimemetic"]["stage"] = 0
	assert(not home.apply_snapshot(invalid))
	# Complete Q10 above, then isolate the saved profile from HUD geometry
	# (physical profile selection is covered by the W8 integration test).
	var toffi_save: Dictionary = JSON.parse_string(JSON.stringify(home.make_snapshot()))
	toffi_save["hero_profile"] = "TOFFI"
	assert(home.apply_snapshot(toffi_save) and home.hero_profile.active == "TOFFI")
	assert(not home.antimemetic.active and home.antimemetic.stage == 2)
	_place(home, home.actor, Vector2(2135, 135))
	home._sync_antimemetic_visibility()
	var curious = home.entities.get_entity(AM.CURIOUS)
	assert(curious.visible and home._am_revealed(curious))
	assert(not home._monument_visible()) # innate vision is not the artifact
	var no_q10: Dictionary = toffi_save.duplicate(true)
	no_q10["antimemetic"] = AM.new().snapshot()
	assert(not home.apply_snapshot(no_q10) and home.hero_profile.active == "TOFFI")
	toffi_save["hero_profile"] = "LUNA"
	assert(home.apply_snapshot(toffi_save) and not home.antimemetic.active)
	_place(home, home.actor, Vector2(2135, 135))
	home._sync_antimemetic_visibility()
	assert(not home.entities.get_entity(AM.CURIOUS).visible)
	game.queue_free()
	await process_frame
	print("Q10: physical C6 approach/retreat, foreground, permanent hidden life, real gaze, M09, independent perception and saved monument")
	quit()


func _walk(home, target: Vector2) -> bool:
	for tick in 180:
		var offset: Vector2 = target - home.actor.position
		if offset.length_squared() < 16.0:
			home.apply_player_input(Vector2.ZERO)
			return true
		home.apply_player_input(offset.normalized())
		await physics_frame
	home.apply_player_input(Vector2.ZERO)
	return false
