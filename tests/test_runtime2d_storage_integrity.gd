extends SceneTree
## P0 regression: no invalid authored map or damaged save may partially
## replace the current level, active actors, routing, or last good disk save.

const GAME = preload("res://scenes/runtime2d/sandbox.tscn")
const SaveStore = preload("res://scripts/runtime2d/save_store_2d.gd")
const SAVE_TEST_PATH := "user://luna_runtime2d_p0_integrity.json"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game = GAME.instantiate()
	root.add_child(game)
	await physics_frame
	var original_level = game._live_level
	var original_state: Dictionary = game.make_snapshot().duplicate(true)
	var entered: Array[String] = []
	game.location_entered.connect(func(id: String): entered.append(id))

	# A PackedScene may exist while its authored geometry is invalid. The
	# active level, event subscribers, entities and routes must survive.
	assert(game.router.register_location("DEV_INVALID_GEOMETRY",
		"res://scenes/runtime2d/invalid_geometry_fixture.tscn",
		{"entry": Vector2(0, 0)}))
	assert(not game._enter_location("DEV_INVALID_GEOMETRY"))
	assert(game._live_level == original_level)
	assert(game.current_location_id == "DEV_SANDBOX_A")
	assert(game.make_snapshot() == original_state)
	assert(entered.is_empty())

	# A save pointing to an existing but unplayable room must also be
	# rejected *before* tearing down the running scene.
	var damaged: Dictionary = original_state.duplicate(true)
	damaged["location"] = "DEV_INVALID_GEOMETRY"
	for actor in damaged["entities"]:
		if actor["id"] == "luna":
			actor["location_id"] = "DEV_INVALID_GEOMETRY"
	assert(not game.apply_snapshot(damaged))
	assert(game.make_snapshot() == original_state)
	assert(game._live_level == original_level)
	assert(entered.is_empty())

	# The same level-shell script with zero solids still initializes its
	# navigation grid, so author rooms with no geometry file work normally.
	assert(game.router.register_location("DEV_EMPTY_GEOMETRY",
		"res://scenes/runtime2d/level_shell.tscn",
		{"entry": Vector2(0, 0)}))
	assert(game._enter_location("DEV_EMPTY_GEOMETRY"))
	assert(not game._live_level.geometry.navigation.get_path(
		Vector2(-100, 0), Vector2(100, 0)).is_empty())
	assert(game._enter_location("DEV_SANDBOX_A"))

	# Two good saves: primary becomes second, backup retains the first.
	for file_name in [SAVE_TEST_PATH, SAVE_TEST_PATH + ".bak",
			SAVE_TEST_PATH + ".tmp"]:
		if FileAccess.file_exists(file_name):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(file_name))
	var store = SaveStore.new()
	assert(store.write_snapshot({"format": 2, "marker": "FIRST"}, SAVE_TEST_PATH))
	assert(store.write_snapshot({"format": 2, "marker": "SECOND"}, SAVE_TEST_PATH))
	assert(store.read_snapshot(SAVE_TEST_PATH)["marker"] == "SECOND")
	assert(FileAccess.file_exists(SAVE_TEST_PATH + ".bak"))

	# A large or incompatible save is rejected before modifying the primary.
	assert(not store.write_snapshot({"format": "2", "marker": "BAD"}, SAVE_TEST_PATH))
	assert(not store.write_snapshot({"format": 2,
		"payload": "x".repeat(SaveStore.MAX_SAVE_BYTES)}, SAVE_TEST_PATH))
	assert(store.read_snapshot(SAVE_TEST_PATH)["marker"] == "SECOND")

	# Simulate interrupted/corrupt primary writing, then recover the
	# previous verified version from disk (not the corrupt primary).
	var corrupted = FileAccess.open(SAVE_TEST_PATH, FileAccess.WRITE)
	assert(corrupted != null)
	corrupted.store_string("{not-valid-json")
	corrupted.close()
	var recovered: Dictionary = store.read_snapshot(SAVE_TEST_PATH)
	assert(recovered.get("marker", "") == "FIRST")
	assert(store.last_error == "Recovered last valid V2 save backup")
	for file_name in [SAVE_TEST_PATH, SAVE_TEST_PATH + ".bak",
			SAVE_TEST_PATH + ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(file_name))

	game.queue_free()
	print("LUNA runtime2d P0: map preflight, atomic restore and backup recovery passed")
	quit(0)
