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
	# Same Toffi and giant, now on the optional continuous street.
	_place(home, home.actor, Vector2(5095, 170))
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
	game.queue_free()
	await process_frame
	print("M3.150–161: Q10, permanent hidden life, real gaze, M09, independent perception and saved monument")
	quit()
