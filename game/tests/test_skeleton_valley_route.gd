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
	assert(saved["address_schema"] == 2)
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
	points.reverse()
	for point in points:
		assert(await _walk_to(scene, point))
		assert(scene.actor.motion.grounded and scene.actor.recoveries == 0)
	assert(await _walk_to(scene, Vector2(2140, 120)))
	assert(scene.actor.location_id == Valley.FOREST_ID)
	assert(scene.wand_pair.original.ground_location_id == Lake.LOCATION_ID)
	# The removed road really has no support in the integrated map. Restore
	# a schema-1 save with Luna, a carried branch, both wands and recovery
	# anchors on the former strip, without altering the source dictionary.
	var old_point := Vector2(2140, 605)
	assert(not scene.actor.motion._has_support(old_point, 0.0, scene._decks, false))
	var old: Dictionary = scene.make_snapshot()
	old["address_schema"] = 1
	for entry in old["entities"]:
		if entry["id"] in [scene.ENTITY_ID, scene.Meadows.PLANK_ID]:
			entry["position"] = [old_point.x, old_point.y]
			entry["location_id"] = scene.Meadows.LOCATION_ID
			entry["motion"]["anchor"] = [old_point.x, old_point.y, 0.0]
			if entry["id"] == scene.Meadows.PLANK_ID:
				entry["attachment"]["carrier_id"] = scene.ENTITY_ID
				entry["attachment"]["carried"] = true
				entry["motion"]["elevation"] = scene.actor.body_height()
				entry["motion"]["grounded"] = false
	old["wand_pair"]["held"] = ""
	for wand in [old["island"]["projection"], old["wand_pair"]["duplicate"]]:
		wand["carried"] = false
		wand["position"] = [old_point.x + 20.0, old_point.y]
		wand["location_id"] = scene.Meadows.LOCATION_ID
	old["island"]["projection"]["position"][0] += 10.0
	var before := old.duplicate(true)
	var corrupt := old.duplicate(true)
	for entry in corrupt["entities"]:
		if entry["id"] == scene.ENTITY_ID:
			entry["location_id"] = Lake.LOCATION_ID
	var previous_actor = scene.actor
	assert(not scene.apply_snapshot(corrupt) and scene.actor == previous_actor)
	assert(scene.apply_snapshot(old))
	assert(old == before and scene.make_snapshot()["address_schema"] == 2)
	assert(scene.actor.location_id == Valley.LOCATION_ID and scene.actor.motion.grounded)
	assert(scene.actor.position != old_point and scene.actor.recoveries == 0)
	assert(scene.actor.has_passenger() and scene.actor._rider.entity_id == scene.Meadows.PLANK_ID)
	assert(scene.actor.position == scene.actor._rider.position)
	assert(scene.wand_pair.original.ground_location_id == Valley.LOCATION_ID)
	assert(scene.wand_pair.duplicate.ground_location_id == Valley.LOCATION_ID)
	assert(scene.wand_pair.original.ground_position != scene.wand_pair.duplicate.ground_position)
	assert(scene.exchange_nearby_wand())
	var migrated: Dictionary = scene.make_snapshot()
	assert(scene.apply_snapshot(migrated))
	assert(scene.actor.has_passenger() and scene.actor.motion.grounded)
	assert(scene.actor.motion._has_support(scene.actor.position, 0.0, scene._decks, true))
	print("M3.74: dry forest-valley route, canonical address and removed-road saves passed")
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
