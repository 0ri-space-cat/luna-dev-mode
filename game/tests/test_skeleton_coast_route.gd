extends SceneTree

const Start = preload("res://scenes/skeleton/start_island.tscn")
const Valley = preload("res://scripts/skeleton/valley_dry_layout.gd")
const Coast = preload("res://scripts/skeleton/coast_layout.gd")
const CoastExtra = preload("res://scripts/skeleton/coast_observation_layout.gd")
const Meadows = preload("res://scripts/skeleton/meadows_layout.gd")
const Clock = preload("res://scripts/runtime2d/world_clock_2d.gd")


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
	scene.actor.position = Vector2(2140, 120)
	scene.actor.motion.reset_on_surface(scene.actor.position, 0.0)
	await physics_frame
	# A real optional invisible support at the cascade, with a dry landing.
	var bridge_path := [Vector2(2140, 220), Vector2(2140, 285),
		Vector2(2240, 285), Vector2(2300, 285), Vector2(2380, 285)]
	for point in bridge_path:
		assert(await _walk_to(scene, point), "bridge approach %s" % point)
		assert(scene.actor.motion.grounded and scene.actor.recoveries == 0)
	assert(scene.actor.location_id == Valley.LOCATION_ID)
	var bridge_count := 0
	for surface in scene.actor.surfaces:
		if surface.get("feature_id") == Valley.RAIN_BRIDGE_ID:
			bridge_count += 1
			assert(not surface.get("safe", true))
	assert(bridge_count == 1)
	bridge_path.reverse()
	for point in bridge_path:
		assert(await _walk_to(scene, point), "bridge retreat %s" % point)
		assert(scene.actor.recoveries == 0)
	# W3 is an ordinary dry site, reachable from W1 at any phase.
	for point in [Vector2(2130, 305), Vector2(2130, 351),
			Vector2(2055, 351), Vector2(2005, 351), Valley.W3_VIEW]:
		assert(await _walk_to(scene, point), "tower shore %s" % point)
	assert(scene.actor.location_id == Valley.LOCATION_ID)
	for point in [Vector2(2005, 351), Vector2(2130, 351), Vector2(2240, 351),
			Vector2(2240, 465), Vector2(2240, 600)]:
		assert(await _walk_to(scene, point), "river path %s" % point)
		assert(scene.actor.recoveries == 0)
	# A previous schema-3 save on the overlapping old road is migrated
	# in place: same point, anchor and identity, only the valid address.
	var legacy: Dictionary = scene.make_snapshot()
	legacy["address_schema"] = 3
	for entry in legacy["entities"]:
		if entry["id"] == scene.ENTITY_ID:
			entry["location_id"] = Meadows.LOCATION_ID
	assert(scene.apply_snapshot(legacy))
	assert(scene.actor.location_id == Valley.LOCATION_ID)
	assert(scene.actor.position.distance_to(Vector2(2240, 600)) < 3.0)
	var shore_path := [Vector2(2240, 755), Coast.ENTRY, Vector2(2440, 805), Coast.BEACH_ENTRY]
	for point in shore_path:
		assert(await _walk_to(scene, point), "coast approach %s" % point)
		assert(scene.actor.motion.grounded and scene.actor.recoveries == 0)
	assert(scene.actor.location_id == Coast.LOCATION_ID)
	var saved: Dictionary = scene.make_snapshot()
	assert(scene.apply_snapshot(saved))
	assert(scene.actor.location_id == Coast.LOCATION_ID)
	assert(scene.actor.position.distance_to(Coast.BEACH_ENTRY) < 3.0)
	assert(scene.actor.motion._has_support(Vector2(2600, 990), Coast.SEA_BED, scene.actor.surfaces, false))
	assert(not scene.actor.motion._has_support(Vector2(2600, 990), 0.0, scene.actor.surfaces, false))
	# Ordinary K2 access and phase puzzle: the external path is always open.
	for point in [Vector2(2620, 795), Vector2(2620, 740), Coast.HOUSE_OUTSIDE]:
		assert(await _walk_to(scene, point), "house veranda %s" % point)
	assert(scene.world_clock.set_time_of_day(Clock.START_MINUTE))
	assert(scene.coast_house_phase == Clock.Phase.EVENING)
	assert(not scene.interact())
	assert(scene.actor.location_id == Coast.LOCATION_ID)
	assert(await _walk_to(scene, Coast.DIAL_OUTSIDE))
	for step in range(3):
		assert(scene.interact())
	assert(scene.coast_house_phase == Clock.Phase.DAY and scene.world_clock.phase() == Clock.Phase.DAY)
	assert(await _walk_to(scene, Coast.HOUSE_OUTSIDE))
	assert(scene.interact() and scene.actor.location_id == Coast.HOUSE_ID)
	assert(await _walk_to(scene, Coast.DIAL_INSIDE))
	assert(scene.interact() and scene.coast_house_phase == Clock.Phase.EVENING)
	assert(scene.world_clock.phase() == Clock.Phase.DAY)
	var house_save: Dictionary = scene.make_snapshot()
	assert(scene.apply_snapshot(house_save) and scene.actor.location_id == Coast.HOUSE_ID)
	assert(scene.coast_house_phase == Clock.Phase.EVENING)
	var bad_phase := house_save.duplicate(true)
	bad_phase["coast_house_phase"] = 9
	assert(not scene.apply_snapshot(bad_phase) and scene.coast_house_phase == Clock.Phase.EVENING)
	assert(await _walk_to(scene, Coast.HOUSE_INSIDE))
	assert(scene.interact() and scene.actor.location_id == Coast.LOCATION_ID)
	assert(not scene.interact())
	assert(scene.world_clock.set_time_of_day(Clock.EVENING_MINUTE))
	assert(scene.interact() and scene.actor.location_id == Coast.HOUSE_ID)
	assert(scene.interact() and scene.actor.location_id == Coast.LOCATION_ID)
	# No gated exit or change to outside world time. Return via the ordinary loop.
	for point in [Vector2(2620, 740), Vector2(2620, 795), Coast.BEACH_ENTRY]:
		assert(await _walk_to(scene, point))
	# K1 foam bridge is solid at every phase, without a recovery anchor.
	for point in [Vector2(2520, 930), Vector2(2520, 975), Coast.FOAM_VIEW,
			Vector2(2520, 975), Vector2(2520, 930), Coast.BEACH_ENTRY]:
		assert(await _walk_to(scene, point), "foam bridge %s" % point)
		assert(scene.actor.recoveries == 0)
	assert(not scene.actor.motion._has_support(Vector2(2520, 975), 0.0, scene.actor.surfaces, true))
	# K6 is independent of the grotto and the deeper R07 route.
	for point in [Vector2(2750, 940), Vector2(2770, 1040), Coast.CAPE_VIEW,
			Vector2(2770, 1040), Vector2(2750, 940), Coast.BEACH_ENTRY]:
		assert(await _walk_to(scene, point), "headland %s" % point)
		assert(scene.actor.location_id == Coast.LOCATION_ID and scene.actor.recoveries == 0)
	# K3 -> K5 uses the real same corridor at low tide, not a scripted door.
	assert(scene.world_clock.set_time_of_day(Clock.MORNING_MINUTE))
	assert(is_zero_approx(scene._coast_tide.surface))
	for point in [Vector2(2740, 880), Vector2(2810, 880), Coast.GROTTO_ENTRY]:
		assert(await _walk_to(scene, point), "low-tide grotto %s" % point)
	assert(scene.actor.location_id == Coast.GROTTO_ID)
	assert(await _walk_to(scene, Vector2(3010, 895)))
	scene.crystal_observer.facing = Vector2.RIGHT
	scene._sync_crystal_observation()
	assert(not scene._surfaces.has(CoastExtra.BRIDGE))
	scene.set_luna_eyes(false)
	assert(scene._surfaces.has(CoastExtra.BRIDGE))
	assert(await _walk_to(scene, CoastExtra.VIEW))
	assert(await _walk_to(scene, Vector2(3010, 895)))
	scene.set_luna_eyes(true)
	assert(await _walk_to(scene, Coast.GROTTO_ENTRY))
	# High tide floods the actual walking surface; the inner room stays dry.
	assert(scene.world_clock.set_time_of_day(Clock.START_MINUTE + 60))
	assert(scene._coast_tide.submerged_fraction(Vector2(2810, 880), 0.0, scene.actor.body_height()) > 0.9)
	assert(scene.actor._is_dry(Coast.GROTTO_ENTRY, 0.0))
	var grotto_save: Dictionary = scene.make_snapshot()
	assert(scene.apply_snapshot(grotto_save) and scene.actor.location_id == Coast.GROTTO_ID)
	assert(scene._coast_tide.surface == 30.0)
	# Natural treads rise above the mouth, ending with a one-way ordinary drop.
	for point in [Vector2(2980, 875), Vector2(2980, 820), Vector2(2980, 765),
			Vector2(2980, 710), Vector2(2860, 710), Vector2(2730, 710)]:
		assert(await _walk_to(scene, point), "upper grotto escape %s" % point)
		assert(scene.actor.recoveries == 0)
	assert(scene.actor.location_id == Coast.LOCATION_ID and is_zero_approx(scene.actor.motion.elevation))
	for point in [Vector2(2750, 825), Coast.BEACH_ENTRY]:
		assert(await _walk_to(scene, point))
	shore_path.reverse()
	for point in shore_path:
		assert(await _walk_to(scene, point), "coast retreat %s" % point)
	assert(await _walk_to(scene, Vector2(2240, 600)))
	assert(await _walk_to(scene, Vector2(2240, 425)))
	assert(scene.actor.location_id == Valley.LOCATION_ID and scene.actor.recoveries == 0)
	scene.queue_free()
	await process_frame
	print("M3.82: invisible cascade, tower shore, dry coast and schema migration passed")
	quit()


func _walk_to(scene: Node, point: Vector2) -> bool:
	for tick in range(220):
		var offset: Vector2 = point - scene.actor.position
		if offset.length_squared() < 9.0:
			scene.apply_player_input(Vector2.ZERO)
			await physics_frame
			return scene.actor.motion.grounded
		var step_length: float = scene.actor.WALK_SPEED * Engine.time_scale / Engine.physics_ticks_per_second
		scene.apply_player_input((offset / step_length).limit_length())
		await physics_frame
	scene.apply_player_input(Vector2.ZERO)
	push_error("Could not walk to %s at %s" % [point, scene.actor.position])
	return false
