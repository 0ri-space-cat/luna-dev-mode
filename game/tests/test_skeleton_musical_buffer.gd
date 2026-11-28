extends SceneTree

const Scene = preload("res://scenes/skeleton/adventure.tscn")
const Island = preload("res://scripts/skeleton/start_island.gd")
const Routes = preload("res://scripts/skeleton/outer_routes_fixture.gd")
const M08 := "DDRLUR"
var path := "user://luna_musical_buffer_test_%d.json" % OS.get_process_id()
var game: Node
var home: Island


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	Engine.time_scale = 2.0
	_open()
	await physics_frame
	var source := Vector2(520, 422)
	home._move_home_travelers(source, Island.ISLAND_ID)
	assert(not home.perform_music(M08))
	home.flute_owned = true
	assert(not home.perform_music("DDRLRU"))
	var traveler := home.actor
	assert(home.perform_music(M08) and game._away and game.outer.actor == traveler)
	assert(game.outer.current_address == Routes.BUFFER and game.outer.ride_destination == "")
	assert(game.save_game() and game.outer.use_route())
	assert(not game._away and home.actor == traveler and home.actor.position.is_equal_approx(source))
	assert(game.load_game() and game._away and game.outer.current_address == Routes.BUFFER)
	game.queue_free()
	await process_frame
	_open()
	await physics_frame
	assert(game._profile_valid and game._away and game.outer.current_address == Routes.BUFFER)
	assert(game.outer.use_route() and home.actor.position.is_equal_approx(source))
	assert(home.flute_owned and not game.white_discovered)

	assert(home.perform_music(M08))
	Input.action_press("ui_up")
	var saw_crack := false
	var saw_subspace := false
	for frame in 260:
		await physics_frame
		if not game._away:
			break
		assert(game.outer.current_address != Routes.BLACK_VOID)
		saw_crack = saw_crack or game.outer.cracking
		saw_subspace = saw_subspace or game.outer.current_address == Routes.SUBSPACE
	Input.action_release("ui_up")
	assert(saw_crack and saw_subspace and not game._away)
	assert(home.actor.location_id == Island.Edge.ID and home.actor.motion.grounded)
	assert(home.flute_owned and not game.white_discovered and home.social.meetings.is_empty())
	game.queue_free()
	await process_frame
	for file in [path, path + ".bak"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(file))
	print("Musical buffer: independent M08, same traveler, manual and persistent return, deliberate P01 to Forgotten Edge passed")
	quit()


func _open() -> void:
	game = Scene.instantiate()
	game.profile_path = path
	home = game.get_node("Home") as Island
	home.keyboard = false
	root.add_child(game)
