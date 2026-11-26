extends SceneTree

const Start = preload("res://scenes/skeleton/start_island.tscn")
const Meadows = preload("res://scripts/skeleton/meadows_layout.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene = Start.instantiate()
	scene.keyboard = false
	root.add_child(scene)
	await physics_frame

	# Enter from the M3.44 island landing with an old-format snapshot.
	scene.actor.position = Vector2(1150, 374)
	scene.actor.motion.reset_on_surface(scene.actor.position, 0.0)
	var old: Dictionary = scene.make_snapshot()
	old.erase("meadows")
	old["entities"] = old["entities"].filter(func(entry): return entry["location_id"] != Meadows.LOCATION_ID)
	assert(scene.apply_snapshot(old))
	var fox = scene.entities.get_entity(Meadows.FOX_ID)
	var trollik = scene.entities.get_entity(Meadows.TROLLIK_ID)
	assert(fox != null and fox.get_parameter("alive") and fox.location_id == Meadows.LOCATION_ID)
	assert(trollik != null and trollik.get_parameter("behavior_mode") == "CHASE")
	assert(scene.entities.get_entity(Meadows.PLANK_ID).record.display_name == "Упавшая ветвь")

	# Walk from the junction to the east bank via the dry lookout route.
	assert(await _walk_to(scene, Vector2(1300, 374)))
	assert(scene.actor.location_id == Meadows.LOCATION_ID)
	assert(await _walk_to(scene, Vector2(1300, 610)))
	assert(await _walk_to(scene, Vector2(1910, 610), 230))
	assert(await _walk_to(scene, Vector2(1910, 350)))
	assert(await _walk_to(scene, Vector2(1640, 350)))
	assert(scene.ice_remaining == 0.0 and scene.actor.recoveries == 0)

	# Jump against the flow-facing gap and land on the other bank.
	scene.apply_player_input(Vector2.LEFT, true)
	assert(await _walk_to(scene, Vector2(1485, 350)))
	assert(await _until_grounded(scene))
	assert(scene.actor.recoveries == 0)

	# Freeze from the west bank using the ordinary wand, then load while on the ice.
	scene.freeze_selected = true
	assert(scene.interact() and scene.ice_remaining > 0.0)
	assert(await _walk_to(scene, Vector2(1570, 350)))
	assert(scene.actor.motion.grounded)
	var frozen: Dictionary = JSON.parse_string(JSON.stringify(scene.make_snapshot()))
	assert(scene.apply_snapshot(frozen))
	assert(scene.actor.motion.grounded and scene.ice_remaining > 0.0)
	assert(await _walk_to(scene, Vector2(1650, 350)))
	assert(scene.actor.recoveries == 0)

	# A final fraction of the saved timer melts underfoot and returns to the dry anchor.
	frozen["meadows"]["ice_remaining"] = 0.05
	assert(scene.apply_snapshot(frozen))
	for tick in range(100):
		await physics_frame
	assert(scene.ice_remaining == 0.0 and scene.actor.recoveries == 1)
	assert(scene.actor.position.x < Meadows.CREEK.position.x and scene.actor.motion.grounded)
	assert(await _check_plank(scene))
	assert(await _walk_to(scene, Vector2(1370, 374)))
	assert(await _walk_to(scene, Vector2(1145, 374)))
	assert(scene.actor.location_id == scene.ISLAND_ID)
	print("P9-03: linked meadows, dry loop, jump, ice, portable branch, legacy label migration and bank recovery passed")
	scene.queue_free()
	await process_frame
	quit()


func _check_plank(scene: Node) -> bool:
	scene.freeze_selected = false
	assert(await _walk_to(scene, Vector2(1435, 388)))
	assert(scene.interact())
	var plank = scene.entities.get_entity(Meadows.PLANK_ID)
	assert(plank.is_carried())
	assert(await _walk_to(scene, Vector2(1509, 408)))
	assert(scene.interact() and not plank.is_carried())
	assert(scene.actor.position.x < Meadows.CREEK.position.x)
	assert(scene.ice_remaining == 0.0)
	assert(await _walk_to(scene, Vector2(1570, 408)))
	assert(scene.actor.motion.grounded)

	var saved: Dictionary = JSON.parse_string(JSON.stringify(scene.make_snapshot()))
	# Simulate an M3.60 save of the same physical object on the creek.
	for entry in saved["entities"]:
		if entry["id"] == Meadows.PLANK_ID:
			entry["label"] = "Доска"
	assert(scene.apply_snapshot(saved))
	assert(scene.entities.get_entity(Meadows.PLANK_ID).record.display_name == "Упавшая ветвь")
	assert(await _walk_to(scene, Vector2(1650, 408)))
	assert(await _walk_to(scene, Vector2(1488, 408)))
	assert(scene.actor.recoveries == 0)

	assert(await _walk_to(scene, Vector2(1565, 408)))
	assert(scene.interact())
	plank = scene.entities.get_entity(Meadows.PLANK_ID)
	assert(plank.is_carried())
	for tick in range(100):
		await physics_frame
	assert(scene.actor.recoveries == 1 and plank.is_carried())
	assert(scene.actor.position.x < Meadows.CREEK.position.x)
	return true


func _walk_to(scene: Node, target: Vector2, max_ticks: int = 150) -> bool:
	for tick in range(max_ticks):
		var offset: Vector2 = target - scene.actor.position
		if offset.length_squared() < 16.0:
			scene.apply_player_input(Vector2.ZERO)
			return true
		scene.apply_player_input(offset.normalized())
		await physics_frame
	scene.apply_player_input(Vector2.ZERO)
	return false


func _until_grounded(scene: Node) -> bool:
	for tick in range(90):
		if scene.actor.motion.grounded:
			return true
		await physics_frame
	return false
