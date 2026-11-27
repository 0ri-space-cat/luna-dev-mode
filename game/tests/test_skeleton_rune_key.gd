extends SceneTree
const Scene = preload("res://scenes/skeleton/adventure.tscn")
const Runes = preload("res://scripts/runtime2d/latin_runes_2d.gd")
const Layout = preload("res://scripts/skeleton/rune_room_layout.gd")
const Island = preload("res://scripts/skeleton/start_island.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	assert(Runes.MASKS.size() == 26)
	var seen := {}
	for index in 26:
		assert(not seen.has(Runes.MASKS[index]))
		seen[Runes.MASKS[index]] = true
	var encoded := Runes.encode(Runes.ALPHABET)
	assert(encoded.length() == 26 and encoded != Runes.ALPHABET)
	assert(Runes.encode("CAT") == Runes.encode("CAT") and Runes.encode("CAT") != "CAT")
	assert(Runes.encode("Привет").is_empty() and Runes.encode("↑→").is_empty())
	assert(Layout.TEMPLE_COMMAND == "SPAWN CAT")
	for command in Island.AM.COMMANDS:
		assert(not command.begins_with("SPAWN") and not Runes.encode(command).is_empty())
	var game = Scene.instantiate()
	game.profile_path = "user://luna_runes_%d.json" % OS.get_process_id()
	game.get_node("Home").keyboard = false
	root.add_child(game)
	await physics_frame
	var home = game.home
	home.actor.position = Layout.KEY_ENTRY
	home.actor.motion.reset_on_surface(Layout.KEY_ENTRY, 0.0)
	home.actor.location_id = home._entity_location(Layout.KEY_ENTRY)
	assert(await _walk_to(home, Vector2(2090, -306)))
	assert(await _walk_to(home, Layout.KEY_VIEW))
	assert(Layout.KEY_ROOM.has_point(home.actor.position) and not home.prism_active and not home.social.prism_owned)
	assert(home.apply_snapshot(JSON.parse_string(JSON.stringify(home.make_snapshot()))))
	assert(await _walk_to(home, Vector2(2090, -306)))
	assert(await _walk_to(home, Layout.KEY_ENTRY))
	assert(home.actor.recoveries == 0)
	game.queue_free()
	await process_frame
	print("One 26-glyph Latin key, no auto-translation, one SPAWN inscription, physical key room passed")
	quit()


func _walk_to(home, target: Vector2) -> bool:
	for tick in 180:
		var offset: Vector2 = target - home.actor.position
		if offset.length_squared() < 16.0:
			home.apply_player_input(Vector2.ZERO)
			return true
		home.apply_player_input(offset.normalized())
		await physics_frame
	home.apply_player_input(Vector2.ZERO)
	return false
