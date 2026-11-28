extends SceneTree

const Scene = preload("res://scenes/skeleton/adventure.tscn")
const Island = preload("res://scripts/skeleton/start_island.gd")
const Map = preload("res://scripts/skeleton/forest_depths_2d.gd")
const Access = preload("res://scripts/runtime2d/access_state_2d.gd")
var path := "user://luna_forest_depths_test_%d.json" % OS.get_process_id()
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
	var old_save := home.make_snapshot()
	old_save.erase("forest_depths")
	assert(game.apply_local_rollback(old_save))
	assert(await _garden())
	assert(await _awake_visit())
	assert(await _sleep_visit())
	game.queue_free()
	await process_frame
	for file in [path, path + ".bak"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(file))
	print("Forest Depths: physical ruins gate and bypass, musical and address visits, sleep fall and awakening, one geometry and one saved profile passed")
	quit()


func _garden() -> bool:
	var old_floor_position := Vector2(2010, -252)
	home._move_home_travelers(old_floor_position, Island.ForestBank.LOCATION_ID)
	assert(game.save_game() and game.load_game() and home.actor.position.is_equal_approx(old_floor_position))
	home._move_home_travelers(Vector2(1900, 120), Island.ForestBank.LOCATION_ID)
	assert(await _walk([Vector2(1850, -83), Vector2(1850, -160), Vector2(1558, -160), Vector2(1558, -318)]))
	home.apply_player_input(Vector2.RIGHT)
	for frame in 38:
		await physics_frame
	home.apply_player_input(Vector2.ZERO)
	assert(home.actor.position.x < Map.ARCH["bounds"].position.x and home._walls.has(Map.ARCH))
	assert(not home.perform_music(Island.Music.PHRASES["M05"]))
	assert(home.actor.set_parameter("size", 0.5))
	assert(await _walk([Vector2(1605, -233.5), Vector2(1670, -233.5), Vector2(1670, -319)]))
	assert(home.actor.set_parameter("size", 1.0) and home._walls.has(Map.ARCH))
	home.flute_owned = true
	assert(not home.perform_music("LLUR"))
	assert(home.perform_music(Island.Music.PHRASES["M05"]))
	assert(not home._walls.has(Map.ARCH) and game.save_game() and game.load_game())
	assert(not home._walls.has(Map.ARCH) and home.forest_depths.gate_open)
	assert(await _walk([Vector2(1595, -319), Vector2(1710, -315), Map.SHRINE]))
	return true


func _awake_visit() -> bool:
	assert(home.perform_music(Island.Music.PHRASES["M10"]))
	assert(home.actor.position.is_equal_approx(Map.ARRIVAL) and home.actor.location_id == Map.ID)
	assert(not home.forest_dream_active() and home.flute_owned)
	assert(game.save_game() and game.load_game() and home.interact())
	assert(home.actor.position.distance_to(Map.SHRINE) <= 4.0)
	assert(await _walk([Vector2(1558, -319), Vector2(1558, -160), Vector2(1850, -160), Vector2(1850, 48), Vector2(2310, 92), Island.AncientConsole.RETURN_POINT]))
	assert(home.access.set_wand_mode(Access.PLAYFUL) and home.interact())
	assert(home.ancient_console.is_open())
	home.ancient_console.field.text_submitted.emit("TELEPORT " + Map.ID)
	assert(not home.ancient_console.is_open() and not home.forest_dream_active())
	assert(home.actor.position.is_equal_approx(Map.ARRIVAL) and home.actor.location_id == Map.ID)
	assert(home.interact() and home.actor.position.distance_to(Island.AncientConsole.RETURN_POINT) <= 4.0)
	return true


func _sleep_visit() -> bool:
	assert(await _walk([Vector2(2230, 81), Vector2(2155, 45), Map.CAMP]))
	assert(home.interact())
	var dreams := home.forest_depths
	assert(home.forest_dream_active() and home.actor.position.is_equal_approx(Map.ARRIVAL))
	assert(dreams.address_glimpse() == Map.ID)
	await physics_frame
	assert(not home.get_node("Interface/Controls").visible)
	assert(not home.toggle_prism() and not home.perform_music(Island.Music.PHRASES["M10"]))
	assert(not home.request_wand_parameter_edit(Island.ENTITY_ID, "SCALE", 0.5))
	home.apply_player_input(Vector2.RIGHT)
	for frame in 135:
		await physics_frame
		if Map.DREAM_BANK.has_point(home.actor.position):
			break
	home.apply_player_input(Vector2.ZERO)
	assert(Map.DREAM_BANK.has_point(home.actor.position) and home.actor.location_id == Map.ID, str(home.actor.position))
	assert(home.actor.recoveries == 0 and home.forest_dream_active())
	assert(game.save_game() and game.load_game() and home.forest_dream_active())
	assert(await _walk([Vector2(8620, 1150), Vector2(8710, 1150), Vector2(8722, 1214),
		Vector2(8900, 1224), Map.SQUARE]))
	assert(home.interact() and not home.forest_dream_active() and home.actor.position.is_equal_approx(Map.CAMP))
	assert(home.flute_owned and home.access.wand_mode == Access.PLAYFUL)
	assert(home.social.meetings.is_empty() and not game.white_discovered)
	var invalid: Dictionary = home.make_snapshot()
	invalid["forest_depths"]["asleep"] = true
	assert(not game.apply_local_rollback(invalid) and home.actor.position.is_equal_approx(Map.CAMP))
	return true


func _walk(points: Array) -> bool:
	for point: Vector2 in points:
		for frame in 310:
			var gap: Vector2 = point - home.actor.position
			if gap.length_squared() < 9.0 and home.actor.motion.grounded:
				break
			home.apply_player_input((gap / 12.0).limit_length())
			await physics_frame
		home.apply_player_input(Vector2.ZERO)
		if home.actor.position.distance_to(point) > 3.0 or not home.actor.motion.grounded:
			push_error("Forest route did not reach %s from %s" % [point, home.actor.position])
			return false
		await physics_frame
	return true
