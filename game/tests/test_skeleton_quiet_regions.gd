extends SceneTree
## Walk new ordinary extensions of existing locations, then exercise the
## real profile migration and edit roundtrip without secret permissions.
const Scene = preload("res://scenes/skeleton/adventure.tscn")
const Island = preload("res://scripts/skeleton/start_island.gd")
const Quiet = preload("res://scripts/skeleton/quiet_regions_layout.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game = Scene.instantiate()
	game.profile_path = "user://luna_quiet_regions_%d.json" % OS.get_process_id()
	game.get_node("Home").keyboard = false
	root.add_child(game)
	await physics_frame
	var home = game.home
	assert(home.access.wand_mode == home.AccessState.ORDINARY)
	assert(not Quiet.LAKE.intersects(Island.AncientConsole.CLEARING))
	assert(not Quiet.LAKE.intersects(Island.Lake.POOL))
	assert(not Quiet.EDGE.intersects(Island.Coast.HOUSE_ROOM))
	assert(not Quiet.EDGE.intersects(Island.Edge.D5))
	# Entry positions are on pre-existing physical routes; the walks use input.
	# The Edge test starts inside the already discovered region, not on an L0 route.
	for region in Quiet.REGIONS:
		var entry: Vector2 = region["entry"]
		var view: Vector2 = region["view"]
		_place(home, entry)
		assert(home.actor.motion._has_support(entry, 0.0, home._decks, true))
		assert(home._entity_location(entry) == region["address"])
		assert(await _walk_to(home, view), str(region["address"]) + " outbound")
		assert(home.actor.location_id == region["address"])
		assert(home.actor.recoveries == 0)
		assert(await _walk_to(home, entry), str(region["address"]) + " return")
	assert(home.social.meetings.is_empty() and home.social.invitations.is_empty())
	assert(home.access.wand_mode == home.AccessState.ORDINARY)
	_place(home, Island.SPAWN)
	var old: Dictionary = JSON.parse_string(JSON.stringify(home.make_snapshot()))
	old["address_schema"] = 16
	old.erase("quiet_regions_layout")
	old["entities"] = old["entities"].filter(func(record): return not Quiet.FAUNA.has(record["id"]))
	assert(home.apply_snapshot(old))
	for identity in Quiet.FAUNA:
		var animal = home.get_natural_fauna(identity)
		assert(animal != null and animal.get_parameter("alive"))
		assert(animal.record.category == Quiet.FAUNA[identity]["category"])
		assert(animal.set_parameter("speed", 1.3))
	var saved: Dictionary = JSON.parse_string(JSON.stringify(home.make_snapshot()))
	assert(saved["address_schema"] == Island.ADDRESS_SCHEMA and saved["quiet_regions_layout"] == 2)
	assert(home.apply_snapshot(saved))
	for identity in Quiet.FAUNA:
		assert(is_equal_approx(float(home.get_natural_fauna(identity).get_parameter("speed")), 1.3))
	assert(game.mark_safe_state())
	# The immediately previous profile keeps its edited animals, adding only
	# the new lake residents. Old records cannot be silently repaired by v2.
	var v1 := saved.duplicate(true)
	v1["address_schema"] = 17
	v1["quiet_regions_layout"] = 1
	v1["entities"] = v1["entities"].filter(func(record): return record["id"] not in Quiet.V2_FAUNA_IDS)
	assert(home.apply_snapshot(v1))
	assert(is_equal_approx(float(home.get_natural_fauna("F_QUIET_FOX").get_parameter("speed")), 1.3))
	assert(home.get_natural_fauna("W_QUIET_LIZARD") != null)
	var malformed := v1.duplicate(true)
	malformed["entities"] = malformed["entities"].filter(func(record): return record["id"] != "F_QUIET_FOX")
	assert(not home.apply_snapshot(malformed))
	var invalid := saved.duplicate(true)
	invalid["entities"] = invalid["entities"].filter(func(record): return record["id"] != "F_QUIET_FOX")
	assert(not home.apply_snapshot(invalid))
	assert(home.get_natural_fauna("F_QUIET_FOX") != null)
	game.queue_free()
	await process_frame
	print("Quiet regional ground: six local walks, persistent fauna, both old layouts and recovery passed")
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
			return true
		home.apply_player_input(offset.normalized())
		await physics_frame
	home.apply_player_input(Vector2.ZERO)
	return false
