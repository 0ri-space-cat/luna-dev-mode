extends SceneTree
## Hidden or camera-dependent physical surfaces must affect navigation just
## like authored walls, while still respecting camera-versus-Luna distinction.
const GAME = preload("res://scenes/runtime2d/sandbox.tscn")
const GridNavigation = preload("res://scripts/runtime2d/grid_navigation_2d.gd")
const ObservationBody = preload("res://scripts/runtime2d/observation_body_2d.gd")


func _initialize() -> void:
	call_deferred("_run")


func _distance(origin: Vector2, path: PackedVector2Array) -> float:
	var total := 0.0
	var current := origin
	for point in path:
		total += current.distance_to(point)
		current = point
	return total


func _run() -> void:
	var nav = GridNavigation.new()
	assert(nav.configure(Vector2(512,384), []))
	var first_revision: int = nav.revision
	var obstacle := Rect2(-12,-60,24,120)
	assert(nav.set_dynamic_walls({"DEV_WALL": obstacle}))
	assert(nav.dynamic_wall_count() == 1 and nav.revision > first_revision)
	var around: PackedVector2Array = nav.get_path(Vector2(-120,0), Vector2(120,0))
	assert(not around.is_empty())
	var stable_revision: int = nav.revision
	assert(nav.set_dynamic_walls({"DEV_WALL": obstacle}))
	assert(nav.revision == stable_revision)
	assert(not nav.set_dynamic_walls({"BAD": Rect2(-12,0,-5,20)}))
	assert(nav.dynamic_wall_count() == 1)
	assert(nav.revision == stable_revision)
	assert(nav.set_dynamic_walls({}))
	assert(nav.dynamic_wall_count() == 0)
	var direct: PackedVector2Array = nav.get_path(Vector2(-120,0), Vector2(120,0))
	assert(_distance(Vector2(-120,0), direct) < _distance(Vector2(-120,0), around))
	assert(not nav.set_dynamic_walls({"DEV_N": "not a Rectangle"}))
	assert(nav.dynamic_wall_count() == 0)

	var game = GAME.instantiate()
	root.add_child(game)
	await physics_frame
	var live_nav = game._live_level.geometry.navigation
	var start := Vector2(-120,150)
	var destination := Vector2(120,150)
	var baseline: PackedVector2Array = live_nav.get_path(start, destination)
	assert(not baseline.is_empty())
	var law = ObservationBody.new()
	law.name = "DEV_DYNAMIC_CAMERA_WALL"
	law.position = Vector2(0,150)
	law.physical_size = Vector2(24,120)
	law.observer_source = law.CAMERA
	law.solidity_rule = law.WHEN_UNOBSERVED
	game._live_level.add_child(law)
	for i in range(2):
		await physics_frame
	assert(game.observation_at(law.global_position)["player_camera"])
	assert(not law.is_solid)
	assert(live_nav.dynamic_wall_count() == 0)

	game.camera.set_mode("LOCKED")
	game.camera.global_position = Vector2(3000,3000)
	for i in range(2):
		await physics_frame
	assert(not game.observation_at(law.global_position)["player_camera"])
	assert(law.is_solid)
	assert(live_nav.dynamic_wall_count() == 1)
	var hidden: PackedVector2Array = live_nav.get_path(start, destination)
	assert(_distance(start, hidden) > _distance(start, baseline) + 40.0)
	game.camera.global_position = game.player.global_position
	for i in range(2):
		await physics_frame
	assert(not law.is_solid)
	assert(live_nav.dynamic_wall_count() == 0)

	# A rule in room A cannot pollute the collision planner of room B.
	assert(game._enter_location("DEV_SANDBOX_B"))
	await physics_frame
	assert(game._live_level.geometry.navigation.dynamic_wall_count() == 0)
	game.queue_free()
	print("LUNA runtime2d: gaze-solid navigation, scoped rooms and safe dynamic overlays passed")
	quit(0)
