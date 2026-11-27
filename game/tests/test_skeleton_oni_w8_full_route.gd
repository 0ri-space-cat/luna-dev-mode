extends SceneTree
const Scene = preload("res://scenes/skeleton/adventure.tscn")
const Island = preload("res://scripts/skeleton/start_island.gd")
var path := "user://luna_oni_w8_full_%d.json" % OS.get_process_id()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	Engine.time_scale = 2.0
	var game = Scene.instantiate()
	game.profile_path = path
	game.get_node("Home").keyboard = false
	root.add_child(game)
	var home = game.home
	assert(home.world_clock.set_time_of_day(150.0))
	await physics_frame
	var oni = home.entities.get_entity(Island.Visits.ONI_ID)
	assert(oni != null and oni.position.distance_to(Island.Visits.LAKE) < 20.0)
	var initial_recoveries: int = oni.recoveries
	assert(not home._w8_open)
	# No NPC placement or forced route index. From W1 she reaches the closed
	# seam on her own, and cannot cross until the actual field is absent.
	assert(await _wait_at(home, oni, Island.Visits.W8_NEAR_INDEX))
	assert(not home._w8_open and oni.location_id == Island.W8.PASSAGE)
	for tick in 24:
		await physics_frame
		assert(home.oni_route_index == Island.Visits.W8_NEAR_INDEX)
	assert(oni.recoveries == initial_recoveries)
	# Fixture positions Luna on an existing dry support, but uses the
	# genuine wand drop. The independent W8 test covers her walking approach.
	home._place_friend(home.actor, Vector2(510, 535), 0.0)
	assert(home.drop_held_wand())
	home._place_friend(home.actor, Vector2(2930, 320), 0.0)
	await physics_frame
	assert(home._w8_open)
	assert(await _wait_at(home, oni, Island.Visits.W8_STUDY_INDEX))
	assert(oni.location_id == Island.W8.REFUGE and oni.recoveries == initial_recoveries)
	assert(home.entities.get_entity(Island.Visits.ONI_ID) == oni)
	assert(not home.social.oni_profile_unlocked())
	assert(home.world_clock.set_time_of_day(720.0))
	assert(await _wait_at(home, oni, Island.Visits.W8_JUNCTION))
	assert(oni.recoveries == initial_recoveries and oni.location_id != Island.W8.REFUGE)
	assert(home.entities.get_entity(Island.Visits.ONI_ID) == oni)
	game.queue_free()
	await process_frame
	for file in [path, path + ".bak"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(file))
	print("W8: full W1 approach, closed seam, physical bridge and doorway, independent return")
	quit()


func _wait_at(home, oni, route_index: int) -> bool:
	var target: Vector2 = Island.Visits.ROUTE[route_index]
	for tick in 1000:
		if home.oni_route_index == route_index and oni.position.distance_to(target) < 7.0:
			return true
		await physics_frame
	push_error("Oni W8 route %d expected %d: %s -> %s; open=%s, recoveries=%d" % [home.oni_route_index, route_index, oni.position, target, home._w8_open, oni.recoveries])
	return false
