extends SceneTree

const Start = preload("res://scenes/skeleton/start_island.tscn")
const Lake = preload("res://scripts/skeleton/duplicate_lake_layout.gd")
const Valley = preload("res://scripts/skeleton/valley_dry_layout.gd")
const Clock = preload("res://scripts/runtime2d/world_clock_2d.gd")
const Mia = preload("res://scripts/skeleton/mia_lab_layout.gd")
const Recipes = preload("res://scripts/runtime2d/alchemy_recipes_2d.gd")
const Tunnel = preload("res://scripts/skeleton/waterfall_tunnel_layout.gd")
const Crystal = preload("res://scripts/skeleton/crystal_observation_layout.gd")

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
	assert(saved["address_schema"] == 10)
	var previous_v9: Dictionary = saved.duplicate(true)
	previous_v9["address_schema"] = 9
	assert(scene.apply_snapshot(previous_v9))
	var previous_v8: Dictionary = saved.duplicate(true)
	previous_v8["address_schema"] = 8
	assert(scene.apply_snapshot(previous_v8))
	var previous_v7: Dictionary = saved.duplicate(true)
	previous_v7["address_schema"] = 7
	assert(scene.apply_snapshot(previous_v7))
	var previous_v6: Dictionary = saved.duplicate(true)
	previous_v6["address_schema"] = 6
	assert(scene.apply_snapshot(previous_v6))
	var previous_v5: Dictionary = saved.duplicate(true)
	previous_v5["address_schema"] = 5
	assert(scene.apply_snapshot(previous_v5))
	var previous_v4: Dictionary = saved.duplicate(true)
	previous_v4["address_schema"] = 4
	assert(scene.apply_snapshot(previous_v4))
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
	assert(await _walk_to(scene, Crystal.NEAR_POINT))
	scene.crystal_observer.facing = Vector2.RIGHT
	scene._sync_crystal_observation()
	assert(not scene._surfaces.has(Crystal.BRIDGE) and scene._crystal_door_solid)
	scene.crystal_observer.facing = Vector2.LEFT
	scene._sync_crystal_observation()
	assert(scene._surfaces.has(Crystal.BRIDGE) and scene._crystal_door_solid)
	scene.set_luna_eyes(false)
	assert(scene._surfaces.has(Crystal.BRIDGE) and not scene._crystal_door_solid)
	assert(await _walk_to(scene, Crystal.FAR_POINT))
	assert(await _walk_to(scene, Crystal.ROOM_POINT))
	var closed_save: Dictionary = scene.make_snapshot()
	scene.set_luna_eyes(true)
	assert(scene._crystal_door_solid)
	assert(scene.apply_snapshot(closed_save))
	assert(not scene.crystal_observer.luna_eyes_open and not scene._crystal_door_solid)
	assert(await _walk_to(scene, Crystal.FAR_POINT))
	assert(await _walk_to(scene, Crystal.NEAR_POINT))
	scene.set_luna_eyes(true)
	assert(await _walk_to(scene, Valley.W7_ENTRY))
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
	# W3 appears in the evening and is a separate persistent interior.
	for point in [Vector2(2140, 220), Vector2(2130, 305), Vector2(2130, 351),
			Vector2(2055, 351), Vector2(2005, 351), Valley.W3_VIEW]:
		assert(await _walk_to(scene, point), "tower approach %s" % point)
	assert(scene.world_clock.set_time_of_day(Clock.START_MINUTE))
	assert(not scene.interact())
	assert(scene.world_clock.set_time_of_day(Clock.EVENING_MINUTE))
	assert(scene.interact() and scene.actor.location_id == Valley.TOWER_ID)
	for point in [Vector2(3675, 435), Vector2(3675, 320), Vector2(3675, 245),
			Vector2(3675, 185), Valley.TOWER_UPPER_VIEW]:
		assert(await _walk_to(scene, point), "tower stair %s" % point)
	assert(scene.actor.motion.elevation == 18.0)
	assert(scene.world_clock.set_time_of_day(Clock.NIGHT_MINUTE))
	var tower_save: Dictionary = scene.make_snapshot()
	assert(scene.apply_snapshot(tower_save) and scene.actor.location_id == Valley.TOWER_ID)
	for point in [Vector2(3675, 185), Vector2(3675, 245), Vector2(3675, 320),
			Vector2(3675, 400), Valley.TOWER_ENTRY]:
		assert(await _walk_to(scene, point), "tower descent %s" % point)
	assert(scene.interact() and scene.actor.location_id == Valley.LOCATION_ID)
	assert(not scene.interact())
	assert(scene.actor.recoveries == 0)
	# Visit the laboratory along the existing valley road, no quest gates.
	for point in [Vector2(2055, 351), Vector2(2130, 351), Vector2(2240, 351),
			Vector2(2240, 525), Vector2(2140, 525), Vector2(2140, 730), Mia.STATION]:
		assert(await _walk_to(scene, point), "Mia approach %s" % point)
	assert(Recipes.RECIPES.size() == 56 and Recipes.NAMES.size() == 44)
	assert(Recipes.resolve(["Limbo", "Lumo"]) == "ALC-R30")
	assert(Recipes.resolve(["Pyro", "Lumo"]) == "ALC-R08")
	assert(Recipes.resolve(["Lumo", "Lumo"]).is_empty())
	assert(scene.interact() and scene._alchemy_panel.visible)
	scene._apply_lab_effect("ALC-R08")
	assert(scene._alchemy_light.enabled and not scene._alchemy_panel.visible)
	var glow_save: Dictionary = scene.make_snapshot()
	assert(scene.apply_snapshot(glow_save) and scene._alchemy_light.enabled)
	scene._apply_lab_effect("ALC-R09")
	assert(not scene._alchemy_light.enabled)
	scene._apply_lab_effect("ALC-R30")
	assert(scene.world_clock.phase() == Clock.Phase.NIGHT)
	# The second cave approach is a walkable elevated route, not a puzzle flag.
	for point in [Vector2(2075, 875), Vector2(2075, 950), Vector2(2075, 1010),
			Vector2(2075, 1080), Mia.UPPER_VIEW, Vector2(1725, 1080),
			Vector2(1725, 1010), Vector2(1725, 950), Vector2(1725, 880)]:
		assert(await _walk_to(scene, point), "Mia cave %s" % point)
	assert(scene.actor.motion.elevation == 0.0 and scene.actor.recoveries == 0)
	assert(not scene.actor._is_dry(Vector2(1820, 870), -24.0))
	# Bubble is a temporary overlay, with no permanent SWIM or water mutation.
	for point in [Vector2(1725, 950), Vector2(1725, 1010), Vector2(1725, 1080),
			Vector2(2075, 1080), Vector2(2075, 1010), Vector2(2075, 950),
			Vector2(2075, 875), Mia.STATION]:
		assert(await _walk_to(scene, point))
	assert(not scene.actor.can_swim())
	scene._apply_lab_effect("ALC-R21")
	assert(scene.actor.can_swim() and not scene._bubble_started)
	var bubble_save: Dictionary = scene.make_snapshot()
	assert(scene.apply_snapshot(bubble_save) and scene.actor.can_swim())
	for point in [Vector2(2140, 730), Vector2(2140, 525), Vector2(2240, 525),
			Vector2(2240, 351), Vector2(2125, 351)]:
		assert(await _walk_to(scene, point))
	# Descend into actual W1 water. Enter only when immersed.
	scene.actor.direction = Vector2.DOWN
	for tick in range(180):
		await physics_frame
		if scene._tunnel_action() == "Нырнуть в тоннель":
			break
	scene.actor.direction = Vector2.ZERO
	assert(scene._bubble_started and scene.interact())
	assert(scene.actor.location_id == Tunnel.LOCATION_ID)
	var wet_base: Dictionary = scene.actor.water_snapshot()
	assert(not wet_base["swim_enabled"])
	# Reach the opposite shelf through real water with the same temporary skill.
	scene.actor.direction = Vector2.RIGHT
	for tick in range(400):
		await physics_frame
		if scene.actor.position.x >= Tunnel.EAST_EXIT.x - 8.0:
			break
	scene.actor.direction = Vector2.ZERO
	assert(Tunnel.EAST.has_point(scene.actor.position), str(scene.actor.position))
	assert(scene.actor.motion.grounded)
	assert(scene.interact() and scene.actor.location_id == Lake.LOCATION_ID)
	assert(scene.actor.position.distance_to(Lake.SHORE) < 3.0)
	scene._clear_bubble()
	assert(not scene.actor.can_swim())
	print("M3.87: physical W5 and temporary bubble passed")
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
