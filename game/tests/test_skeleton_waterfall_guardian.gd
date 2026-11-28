extends SceneTree

const Scene = preload("res://scenes/skeleton/adventure.tscn")
const Island = preload("res://scripts/skeleton/start_island.gd")
const Map = preload("res://scripts/skeleton/waterfall_guardian_2d.gd")
const Access = preload("res://scripts/runtime2d/access_state_2d.gd")
var path := "user://luna_waterfall_guardian_test_%d.json" % OS.get_process_id()
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
	old_save.erase("guardian_layout")
	old_save["entities"] = old_save["entities"].filter(func(body): return body["id"] != Map.ID)
	assert(game.apply_local_rollback(old_save))
	var guard = home.entities.get_entity(Map.ID)
	assert(guard != null and guard.get_parameter("alive"))
	home._move_home_travelers(Vector2(2160, 299), Island.Valley.LOCATION_ID)
	assert(await _walk([Vector2(2162, 328), Map.ENTRY]) and home.interact())
	assert(home.actor.location_id == Map.PLACE and home.access.wand_mode == Access.ORDINARY)
	assert(home.get_wand_editor_tabs(Map.ID).is_empty())
	assert(await _walk([Map.LEAVE]) and home.interact())
	assert(home.actor.location_id == Island.Valley.LOCATION_ID)
	assert(await _walk([Map.ENTRY]) and home.interact())
	assert(await _walk([Vector2(8440, 3167)]))
	home.apply_player_input(Vector2.RIGHT)
	for frame in 120:
		await physics_frame
		if home.actor.motion.grounded and home.actor.motion.elevation < -18.0:
			break
	home.apply_player_input(Vector2.ZERO)
	assert(home.actor.motion.elevation < -18.0 and not home.actor.can_swim())
	assert(home.interact() and home.actor.position.is_equal_approx(Map.ARRIVAL))
	assert(await _fight_and_edit(guard))
	assert(await _walk([Vector2(8668, 3105), Vector2(8830, 3105), Map.FAR_EXIT]) and home.interact())
	assert(home.actor.location_id == Island.Lake.LOCATION_ID and home.actor.motion.grounded)
	assert(not game.white_discovered and home.social.meetings.is_empty())
	assert(game.ecology.episodes.is_empty() and home.access.wand_mode == Access.PLAYFUL)
	game.queue_free()
	await process_frame
	for file in [path, path + ".bak"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(file))
	print("Waterfall guardian: physical branch, retreat, telegraphed hit, real HP, saved edit and independent lake arrival passed")
	quit()


func _fight_and_edit(guard: Node) -> bool:
	assert(await _walk([Vector2(8515, 3105)]))
	var director := home.waterfall_guardian
	var signaled := false
	for frame in 140:
		await physics_frame
		signaled = signaled or director._phase == "windup"
		if home.actor.get_parameter("health") < 100:
			break
	assert(signaled and director._phase == "opening", "%s at %s" % [director._phase, guard.position])
	assert(guard.position.distance_to(Map.CHOKE) < 12.0)
	assert(home.actor.get_parameter("health") == 100 - Map.DAMAGE)
	assert(director._bar.value == 100.0 and director._bar.visible)
	assert(home.access.set_wand_mode(Access.PLAYFUL))
	assert(await _walk([Vector2(8515, 3105)]))
	home.city_tools.owned.append("GRAVITY_GUN")
	assert(home.gravity_pull() and director._phase == "opening")
	home.apply_player_input(Vector2.RIGHT)
	var reached_above := false
	for frame in 95:
		await physics_frame
		reached_above = reached_above or home.actor.motion.elevation > guard.body_height()
		if home.actor.position.x >= 8633.0 and home.actor.motion.grounded:
			break
	home.apply_player_input(Vector2.ZERO)
	assert(reached_above and home.actor.position.x >= 8633.0, str(home.actor.position))
	assert(guard.get_parameter("luna_relation") == "HOSTILE")
	assert(not home.get_wand_editor_tabs(Map.ID).is_empty())
	assert(home.request_wand_parameter_edit(Map.ID, "HEALTH", 54))
	assert(home.request_wand_parameter_edit(Map.ID, "LUNA_RELATION", "FRIEND"))
	assert(game.save_game() and game.load_game())
	await physics_frame
	guard = home.entities.get_entity(Map.ID)
	assert(guard.get_parameter("health") == 54 and guard.get_parameter("luna_relation") == "FRIEND")
	assert(home.actor.get_parameter("health") == 75 and guard.collision_layer == 0)
	return true


func _walk(points: Array) -> bool:
	for point: Vector2 in points:
		for frame in 250:
			var gap: Vector2 = point - home.actor.position
			if gap.length_squared() < 9.0 and home.actor.motion.grounded:
				break
			home.apply_player_input((gap / 12.0).limit_length())
			await physics_frame
		home.apply_player_input(Vector2.ZERO)
		if home.actor.position.distance_to(point) > 3.0 or not home.actor.motion.grounded:
			push_error("Waterfall branch did not reach %s from %s at height %s" % [point, home.actor.position, home.actor.motion.elevation])
			return false
		await physics_frame
	return true
