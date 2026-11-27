extends SceneTree

const Scene = preload("res://scenes/skeleton/adventure.tscn")
const Map = preload("res://scripts/skeleton/fairy_realm_layout.gd")
const Island = preload("res://scripts/skeleton/start_island.gd")
const Access = preload("res://scripts/runtime2d/access_state_2d.gd")
var path := "user://luna_fairy_realm_test_%d.json" % OS.get_process_id()
var game: Node
var home: Node


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	Engine.time_scale = 2.4
	_open()
	await physics_frame
	var previous: Dictionary = home.make_snapshot()
	previous.erase("fairy_realm")
	previous["entities"] = previous["entities"].filter(func(body): return body["id"] not in [Map.FOX_ID, Map.CANOPY_RESIDENT])
	assert(game.apply_local_rollback(previous))
	assert(home.entities.get_entity(Map.FOX_ID) != null)
	assert(home.entities.get_entity(Map.CANOPY_RESIDENT) != null)
	home._move_home_travelers(Vector2(1900, 145), Island.ForestBank.LOCATION_ID)
	var traveler = home.actor
	assert(await _walk([Vector2(1910, 35), Map.ENTRY]))
	assert(home.interact() and home.actor == traveler and traveler.location_id == Map.ID)
	assert(home.fairy_realm._future_time >= 0.0 and home.access.wand_mode == Access.ORDINARY)
	assert(await _walk([Vector2(7238, 318)]))
	home.apply_player_input(Vector2.RIGHT)
	for frame in 75:
		await physics_frame
	home.apply_player_input(Vector2.ZERO)
	assert(home.actor.position.x < Map.ROOT_WALLS[0]["bounds"].position.x)
	assert(await _walk([Vector2(7238, 218), Vector2(7510, 218), Map.ROOT_FAR]))
	var recorded: Array = home.fairy_realm.state["trail"]
	assert(recorded.size() > 5 and recorded.any(func(sample): return sample[1] < 240.0 and sample[3] == 1.0))
	assert(home.actor.set_parameter("size", 0.5))
	assert(await _walk([Vector2(7510, 318), Vector2(7238, 318), Map.ROOT_ENTRY]) and home.interact())
	assert(await _walk([Map.ENTRY]) and home.interact())
	assert(await _walk([Vector2(7238, 318), Vector2(7510, 318), Map.ROOT_FAR]))
	assert(home.fairy_realm.state["trail"].any(func(sample): return sample[0] > 7350 and sample[0] < 7420 and sample[3] == 0.5))
	assert(home.actor.set_parameter("size", 1.0))
	assert(home.interact() and Map.grove_index(home.actor.position) == 0)
	assert(await _choice(0, 1))
	assert(home.fairy_realm.state["turn"] == 1 and home.fairy_realm.state["grove_step"] == 0)
	assert(await _choice(0, 0) and await _choice(1, 1))
	var position: Vector2 = home.actor.position
	assert(Map.grove_index(position) == 2 and game.save_game())
	game.queue_free()
	await process_frame
	_open()
	await physics_frame
	assert(game._profile_valid and home.actor.position.is_equal_approx(position))
	assert(home.fairy_realm.state["turn"] == 1 and home.fairy_realm.state["grove_step"] == 2)
	assert(await _choice(2, 2) and await _choice(3, 3))
	assert(await _walk([Map.GROVE_EXIT + Map.GROVE_OFFSET * 3]))
	assert(await _fox_sequence())
	assert(await _canopy_sequence())

	var bad: Dictionary = home.make_snapshot()
	bad["fairy_realm"]["phase"] = "invalid"
	assert(not game.apply_local_rollback(bad) and home.fairy_realm.state["phase"] == "closed")
	assert(not game.white_discovered and home.social.meetings.is_empty())
	game.queue_free()
	await process_frame
	for file in [path, path + ".bak"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(file))
	print("Fairy Realm: physical entry, roots, recorded echo, four reordered rooms, one fox and actual impact, gaze, reload and return passed")
	quit()


func _fox_sequence() -> bool:
	var fox = home.entities.get_entity(Map.FOX_ID)
	assert(home.interact() and home.fairy_realm.state["phase"] == "demo")
	assert(home._walls.has(Map.BARRIER) and fox.position.is_equal_approx(Map.FOX_RUSH))
	assert(await _wait_phase("late", 180))
	assert(not home._walls.has(Map.BARRIER) and fox == home.entities.get_entity(Map.FOX_ID))
	assert(not fox.get_parameter("alive"))
	assert(await _walk([Map.EARLY_TO_LATE]) and home.interact())
	assert(await _walk([Map.LATE_SEAM]) and home.interact())
	assert(home.fairy_realm.state["phase"] == "late" and Map.LATE.has_point(fox.position))
	assert(await _walk([Vector2(7290, 6507), Vector2(7420, 6507), Map.EARLY_TO_LATE]) and home.interact())

	assert(home.access.set_wand_mode(Access.PLAYFUL))
	assert(await _walk([Vector2(7350, 7648)]))
	assert(not home.request_wand_parameter_edit(Map.FOX_ID, "PICKABLE", true))
	assert(home.request_wand_parameter_edit(Map.FOX_ID, "IS_ALIVE", true))
	assert(home.request_wand_parameter_edit(Map.FOX_ID, "AUTONOMY", true))
	assert(await _walk([Map.LATE_SEAM]))
	for frame in 95:
		if fox.position.distance_to(Map.LATE_SEAM) <= 52.0:
			break
		await physics_frame
	assert(fox.position.distance_to(Map.LATE_SEAM) <= 52.0, str(fox.position))
	assert(home.interact() and home.fairy_realm.state["phase"] == "replay")
	assert(home._walls.has(Map.BARRIER))
	assert(game.save_game() and game.load_game())
	fox = home.entities.get_entity(Map.FOX_ID)
	assert(fox.get_parameter("alive") and fox.get_parameter("ai_enabled") and Map.EARLY.has_point(fox.position))
	assert(home.fairy_realm.state["phase"] == "replay" and home._walls.has(Map.BARRIER))
	assert(await _walk([Vector2(7311, 6436), Vector2(7311, 6519)]))
	assert(await _wait_phase("closed", 140))
	assert(not home._walls.has(Map.BARRIER) and fox == home.entities.get_entity(Map.FOX_ID))
	assert(home.entities.query_ids({"category": "slime_fox"}, 4) == [Map.FOX_ID])
	return true


func _canopy_sequence() -> bool:
	assert(await _walk([Map.CANOPY_NEAR]) and home.interact())
	home.crystal_observer.facing = Vector2.RIGHT
	home.set_luna_eyes(true)
	assert(not home._surfaces.has(Map.CANOPY_SPAN) and home._walls.has(Map.CANOPY_DOOR))
	var fairy = home.entities.get_entity(Map.CANOPY_RESIDENT)
	var saw_closed_eyes := false
	var door_bounds: Rect2 = Map.CANOPY_DOOR["bounds"]
	for frame in 110:
		await physics_frame
		assert(home._walls.has(Map.CANOPY_DOOR))
		saw_closed_eyes = saw_closed_eyes or fairy.eyes_closed
		if fairy.position.x > door_bounds.end.x + 12.0:
			break
	assert(saw_closed_eyes and fairy.position.x > door_bounds.end.x + 12.0, str(fairy.position))
	home.crystal_observer.facing = Vector2.LEFT
	home.fairy_realm.sync_observation()
	assert(home._surfaces.has(Map.CANOPY_SPAN) and home._walls.has(Map.CANOPY_DOOR))
	home.set_luna_eyes(false)
	assert(home._surfaces.has(Map.CANOPY_SPAN) and not home._walls.has(Map.CANOPY_DOOR))
	assert(await _walk([Vector2(7331, 8724)]))
	assert(game.save_game() and game.load_game())
	assert(home.actor.motion.grounded and not home.crystal_observer.luna_eyes_open)
	assert(home.fairy_realm.state["phase"] == "closed")
	assert(await _walk([Vector2(7505, 8724), Vector2(7568, 8755)]))
	assert(home.interact() and home.actor.location_id == Island.ForestBank.LOCATION_ID)
	return true


func _open() -> void:
	game = Scene.instantiate()
	game.profile_path = path
	game.get_node("Home").keyboard = false
	root.add_child(game)
	home = game.home


func _choice(room: int, motif: int) -> bool:
	for slot in Map.THRESHOLDS.size():
		if home.fairy_realm.motif_at(room, slot) == motif:
			return await _walk([Map.THRESHOLDS[slot] + Map.GROVE_OFFSET * room]) and home.interact()
	return false


func _wait_phase(phase: String, frames: int) -> bool:
	for frame in frames:
		if home.fairy_realm.state["phase"] == phase:
			return true
		await physics_frame
	var fox = home.entities.get_entity(Map.FOX_ID)
	push_error("Expected fairy phase %s, got %s, fox at %s" % [phase, home.fairy_realm.state["phase"], fox.position])
	return false


func _walk(points: Array) -> bool:
	for point: Vector2 in points:
		var reached := false
		for frame in 310:
			var gap: Vector2 = point - home.actor.position
			if gap.length_squared() < 10.0 and home.actor.motion.grounded:
				home.apply_player_input(Vector2.ZERO)
				await physics_frame
				reached = true
				break
			home.apply_player_input((gap / 12.0).limit_length())
			await physics_frame
		if not reached:
			home.apply_player_input(Vector2.ZERO)
			push_error("Fairy route did not reach %s from %s" % [point, home.actor.position])
			return false
	return true
