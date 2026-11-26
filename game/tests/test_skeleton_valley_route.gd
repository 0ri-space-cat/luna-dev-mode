extends SceneTree

const Start = preload("res://scenes/skeleton/start_island.tscn")
const Lake = preload("res://scripts/skeleton/duplicate_lake_layout.gd")
const Valley = preload("res://scripts/skeleton/valley_dry_layout.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	Engine.time_scale = 3.0
	var scene = Start.instantiate()
	scene.keyboard = false
	scene.observation_fixture = true
	scene.ancient_console_enabled = true
	root.add_child(scene)
	await physics_frame
	# Start at an existing forest-bank support; walk the entire new physical
	# connector in both directions with ordinary equipment and no water skill.
	scene.actor.position = Vector2(2140, 120)
	scene.actor.motion.reset_on_surface(scene.actor.position, 0.0)
	await physics_frame
	var points := [Vector2(2140, 220), Vector2(2130, 305), Vector2(2240, 305),
		Vector2(2240, 425), Vector2(2265, 425), Vector2(2340, 425), Lake.SHORE]
	for point in points:
		assert(await _walk_to(scene, point))
		assert(scene.actor.motion.grounded and scene.actor.recoveries == 0)
		if point == Vector2(2140, 220):
			assert(scene.actor.location_id == Valley.FOREST_ID)
		elif point.x < 2280.0:
			assert(scene.actor.location_id == Valley.LOCATION_ID)
		else:
			assert(scene.actor.location_id == Lake.LOCATION_ID)
	assert(Lake.LOCATION_ID == "ET_DUPLICATE_LAKE_CAVERN" and Lake.FEATURE_ID == "ET_DUPLICATE_LAKE")
	assert(scene.wand_pair.duplicate_in_water(Lake.SHORE + Vector2(17, 0), Lake.LOCATION_ID))
	var saved: Dictionary = scene.make_snapshot()
	assert(saved["address_schema"] == 4)
	var previous_v3: Dictionary = saved.duplicate(true)
	previous_v3["address_schema"] = 3
	assert(scene.apply_snapshot(previous_v3))
	var previous_v2: Dictionary = saved.duplicate(true)
	previous_v2["address_schema"] = 2
	assert(scene.apply_snapshot(previous_v2))
	var previous: Dictionary = saved.duplicate(true)
	previous["address_schema"] = 1
	assert(scene.apply_snapshot(previous))
	# Restore the legacy name of the same cave and the duplicate wand.
	var legacy: Dictionary = saved.duplicate(true)
	legacy.erase("address_schema")
	for entry in legacy["entities"]:
		if entry["location_id"] == Lake.LOCATION_ID:
			entry["location_id"] = Lake.LEGACY_LOCATION_ID
	legacy["wand_pair"]["duplicate"]["location_id"] = Lake.LEGACY_LOCATION_ID
	assert(scene.apply_snapshot(legacy))
	assert(scene.actor.location_id == Lake.LOCATION_ID)
	assert(scene.wand_pair.duplicate.ground_location_id == Lake.LOCATION_ID)
	assert(legacy["wand_pair"]["duplicate"]["location_id"] == Lake.LEGACY_LOCATION_ID)
	assert(scene.exchange_nearby_wand())
	assert(scene.wand_pair.original.ground_location_id == Lake.LOCATION_ID)
	# A fabricated legacy address outside its old partition is not accepted.
	var invalid: Dictionary = legacy.duplicate(true)
	for entry in invalid["entities"]:
		if entry["id"] == scene.FRIDGE_ID:
			entry["location_id"] = Lake.LEGACY_LOCATION_ID
	var body = scene.actor
	assert(not scene.apply_snapshot(invalid) and scene.actor == body)
	# Walk around the same duplicate lake to the independent crystal caves.
	var crystal_path := [Vector2(2445, 550), Vector2(2735, 550),
		Vector2(2735, 420), Vector2(2850, 420), Valley.W7_ENTRY]
	for point in crystal_path:
		assert(await _walk_to(scene, point))
		assert(scene.actor.motion.grounded and scene.actor.recoveries == 0)
	assert(scene.actor.location_id == Valley.CRYSTAL_ID)
	var crystal_save: Dictionary = scene.make_snapshot()
	assert(scene.apply_snapshot(crystal_save))
	assert(scene.actor.location_id == Valley.CRYSTAL_ID)
	crystal_path.reverse()
	for point in crystal_path:
		assert(await _walk_to(scene, point))
		assert(scene.actor.motion.grounded and scene.actor.recoveries == 0)
	assert(await _walk_to(scene, Lake.SHORE))
	points.reverse()
	for point in points:
		assert(await _walk_to(scene, point))
		assert(scene.actor.motion.grounded and scene.actor.recoveries == 0)
	assert(await _walk_to(scene, Vector2(2140, 120)))
	assert(scene.actor.location_id == Valley.FOREST_ID)
	assert(scene.wand_pair.original.ground_location_id == Lake.LOCATION_ID)
	# The ordinary W1 lake has a physical dry loop, not a second duplicate pool.
	var lake_loop := [Vector2(2140, 220), Vector2(2130, 305), Vector2(2130, 351),
		Vector2(2055, 351), Vector2(2055, 485), Vector2(2190, 485),
		Vector2(2190, 425), Vector2(2240, 425)]
	for point in lake_loop:
		assert(await _walk_to(scene, point))
		assert(scene.actor.motion.grounded and scene.actor.recoveries == 0)
		if point == Vector2(2055, 485):
			assert(scene.actor.location_id == Valley.LOCATION_ID)
			var shore_save: Dictionary = scene.make_snapshot()
			assert(scene.apply_snapshot(shore_save))
			assert(scene.actor.location_id == Valley.LOCATION_ID)
	lake_loop.reverse()
	for point in lake_loop:
		assert(await _walk_to(scene, point))
		assert(scene.actor.motion.grounded and scene.actor.recoveries == 0)
	assert(scene.wand_pair.original.ground_location_id == Lake.LOCATION_ID)
	print("M3.74d: dry forest-valley, ordinary lake, crystal approach and legacy address migration passed")
	scene.queue_free()
	await process_frame
	quit()

func _walk_to(scene: Node, point: Vector2) -> bool:
	for tick in range(180):
		var offset: Vector2 = point - scene.actor.position
		if offset.length_squared() < 9.0:
			scene.apply_player_input(Vector2.ZERO)
			await physics_frame
			return scene.actor.motion.grounded
		# At accelerated time a full input can step past the waypoint. Use
		# proportional analog input for the final step, keeping real physics.
		var step_length: float = scene.actor.WALK_SPEED * Engine.time_scale / Engine.physics_ticks_per_second
		scene.apply_player_input((offset / step_length).limit_length())
		await physics_frame
	scene.apply_player_input(Vector2.ZERO)
	push_error("Could not walk to %s at %s" % [point, scene.actor.position])
	return false
