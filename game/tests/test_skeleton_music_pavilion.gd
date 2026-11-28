extends SceneTree

const Scene = preload("res://scenes/skeleton/adventure.tscn")
const Island = preload("res://scripts/skeleton/start_island.gd")
const Map = preload("res://scripts/skeleton/music_pavilion_2d.gd")
const M01 := "UUDDLRLR"
var path := "user://luna_music_pavilion_test_%d.json" % OS.get_process_id()
var game: Node
var home: Island


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	Engine.time_scale = 2.4
	game = Scene.instantiate()
	game.profile_path = path
	home = game.get_node("Home") as Island
	home.keyboard = false
	root.add_child(game)
	await physics_frame
	assert(not home.perform_music(M01))
	home.flute_owned = true
	assert(not home.perform_music("UUDDLRLL"))
	assert(not home.social.prism_owned)
	var height := 18.0
	var source := Island.Valley.TOWER_UPPER_VIEW
	home._move_home_travelers(source, Island.Valley.TOWER_ID, height)
	var traveler := home.actor
	assert(home.perform_music(M01) and home.actor == traveler and home.actor.location_id == Map.ID)
	assert(home._room_view.bounds == Map.ROOM)
	assert(await _walk(Map.EXIT))
	var origin := Vector3(source.x, source.y, height)
	assert(home.perform_music(M01) and home.music_pavilion.origin == origin)
	assert(game.save_game() and game.load_game() and home.music_pavilion.origin == origin)
	assert(home.interact() and home.actor.position.is_equal_approx(source))
	assert(home.actor.location_id == Island.Valley.TOWER_ID and home.actor.motion.elevation == height)

	for port in Map.PORTS:
		var address: String = port["address"]
		assert(address not in home.city_tools.visited)
		assert(home.perform_music(M01))
		assert(await _walk(port["point"]) and home.interact())
		assert(home.actor.location_id == address and home.actor.motion.grounded, address)
		await physics_frame
		assert(address in home.city_tools.visited)
	assert(home.social.meetings.is_empty() and not game.white_discovered)
	assert(home.access.wand_mode == home.AccessState.ORDINARY)
	assert(Map.ID not in home.city_tools.visited)

	var occupied := Vector2(568, 464)
	home._move_home_travelers(occupied, Island.ISLAND_ID)
	assert(home.perform_music(M01))
	var obstruction := home.spawn_entity({"id": "TEST_RETURN_STONE", "category": "prop",
		"label": "Камень", "material": "STONE"}, occupied, 0.0)
	assert(obstruction != null and await _walk(Map.EXIT) and home.interact())
	assert(home.actor.location_id == Island.ISLAND_ID and home.actor.position.distance_to(occupied) == 25.0)
	assert(home.perform_music(M01))
	var invalid := home.make_snapshot()
	invalid["music_pavilion_origin"] = [Map.CENTER.x, Map.CENTER.y, 0]
	assert(not game.apply_local_rollback(invalid) and home.actor.location_id == Map.ID)
	game.queue_free()
	await process_frame
	for file in [path, path + ".bak"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(file))
	print("Music pavilion: genuine flute phrase, six ordinary arches, repeated performance, saved return with elevation and independent progress passed")
	quit()


func _walk(point: Vector2) -> bool:
	for frame in 250:
		var gap: Vector2 = point - home.actor.position
		if gap.length_squared() < 9.0 and home.actor.motion.grounded:
			break
		home.apply_player_input((gap / 12.0).limit_length())
		await physics_frame
	home.apply_player_input(Vector2.ZERO)
	await physics_frame
	return home.actor.position.distance_to(point) <= 3.0 and home.actor.motion.grounded
