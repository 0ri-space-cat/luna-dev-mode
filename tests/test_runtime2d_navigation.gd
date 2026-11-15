extends SceneTree
## Authored A* navigation avoids real walls, stays bounded, and switches
## between ground and FLY plans without changing physical collision.
const GridNavigation = preload("res://scripts/runtime2d/grid_navigation_2d.gd")
const GAME = preload("res://scenes/runtime2d/sandbox.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var nav = GridNavigation.new()
	var solid := {"id":"TEST_BARRIER","kind":"WALL","rect":[-12,-60,24,120]}
	assert(nav.configure(Vector2(512, 384), [solid]))
	assert(nav.is_walkable(Vector2(-120, 0)))
	assert(not nav.is_walkable(Vector2.ZERO))
	var path: PackedVector2Array = nav.get_path(Vector2(-120, 0), Vector2(120, 0))
	assert(path.size() > 2)
	var went_around := false
	for point in path:
		if absf(point.y) > 80.0:
			went_around = true
	assert(went_around)
	assert(nav.get_path(Vector2(-120, 0), Vector2.ZERO).is_empty())
	assert(nav.get_path(Vector2(-9999, 0), Vector2.ZERO).is_empty())
	var old_revision: int = nav.revision
	assert(not nav.configure(Vector2(100000, 100000), []))
	assert(nav.revision == old_revision)
	assert(nav.get_path(Vector2(-120, 0), Vector2(120, 0)) == path)

	var flight_nav = GridNavigation.new()
	assert(flight_nav.configure(Vector2(512,384), [
		{"kind":"GROUND_ONLY","rect":[-12,-60,24,120]}
	]))
	assert(flight_nav.is_walkable(Vector2.ZERO, true))
	assert(not flight_nav.is_walkable(Vector2.ZERO, false))
	assert(flight_nav.get_path(Vector2(-120, 0), Vector2(120, 0), true).size()
		< flight_nav.get_path(Vector2(-120, 0), Vector2(120, 0), false).size())
	# Even with FLY, a true WALL remains a blocking obstacle.
	assert(nav.get_path(Vector2(-120, 0), Vector2(120, 0), true).size() > 2)

	var game = GAME.instantiate()
	root.add_child(game)
	await physics_frame
	var actor = game.world_registry.get_entity("DEV_ENTITY_01")
	assert(actor != null)
	assert(game._live_level.geometry.build_from_description({
		"solids": [solid], "zones": []
	}))
	assert(actor.navigation == game._live_level.geometry.navigation)
	assert(game.set_entity_parameter(actor.record.id, "behavior_mode", "CHASE"))
	assert(game.set_entity_parameter(actor.record.id, "target_group", "LUNA"))
	assert(game.set_entity_parameter(actor.record.id, "speed", 2.0))
	game.player.global_position = Vector2(120, 0)
	actor.global_position = Vector2(-120, 0)
	actor.behavior.avoid_obstacle()
	# First movements must follow the waypoints around the wall, not
	# repeatedly collide against its centerline.
	for i in range(10):
		await physics_frame
	assert(actor.global_position.x < 0.0)
	for i in range(240):
		await physics_frame
	assert(actor.behavior.last_target_id == "luna")
	assert(actor.global_position.x > 20.0)
	assert(actor.global_position.distance_to(game.player.global_position) < 100.0)

	game.queue_free()
	print("LUNA runtime2d: bounded A*, wall detours, FLY routing and physical chase passed")
	quit(0)
