extends SceneTree

const Room = preload("res://scenes/skeleton/underside_fixture.tscn")
const Camera = preload("res://scripts/runtime2d/camera_follow_lock_2d.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene = Room.instantiate()
	scene.keyboard = false
	root.add_child(scene)
	await physics_frame
	assert(scene.held_wand() == scene.FIRST_WAND and not scene.underside)
	assert(scene.interact_with_wand() and scene.held_wand().is_empty())

	# A second, dropped wand independently keeps the near edge projected.
	assert(await _walk_to(scene, Vector2(410, 220)))
	assert(scene.fields[scene.FIRST_WAND].is_underside_at(scene.actor.position, scene.LOCATION_ID))
	assert(not scene.fields[scene.SECOND_WAND].is_underside_at(scene.actor.position, scene.LOCATION_ID))
	assert(not scene.underside)
	assert(await _walk_to(scene, Vector2(532, 220)))
	assert(await _on_floor(scene))
	assert(scene.underside)

	# Move that same wand below the far side so its field cuts across the span.
	assert(await _walk_to(scene, scene.SECOND_POINT))
	assert(scene.interact_with_wand() and scene.held_wand() == scene.SECOND_WAND)
	assert(not scene.underside)
	assert(await _walk_to(scene, Vector2(755, 310)))
	assert(scene.interact_with_wand())
	assert(await _west_ledge(scene))
	assert(scene.underside)
	scene.camera.set_mode(Camera.LOCKED)
	scene.eyes_open = false
	assert(await _walk_to(scene, Vector2(558, 220)))
	assert(_on_ledge(scene) and scene.underside)
	var saved: Dictionary = JSON.parse_string(JSON.stringify(scene.make_snapshot()))

	assert(await _walk_to(scene, Vector2(673, 220)))
	assert(not scene.underside and await _on_floor(scene))
	assert(scene.actor.recoveries == 0)

	var broken := saved.duplicate(true)
	broken["wands"][scene.FIRST_WAND]["radius"] = []
	var current: Dictionary = scene.make_snapshot()
	assert(not scene.apply_snapshot(broken) and scene.make_snapshot() == current)
	assert(scene.apply_snapshot(saved))
	assert(scene.camera.mode == Camera.LOCKED and not scene.eyes_open)
	assert(scene.underside and _on_ledge(scene))
	scene.camera.set_mode(Camera.FOLLOW)
	scene.eyes_open = true
	await physics_frame
	assert(scene.underside and _on_ledge(scene))

	# Keep both fields away from the gap, then walk across and return to the first wand.
	assert(await _walk_to(scene, Vector2(673, 220)))
	assert(await _on_floor(scene))
	assert(await _walk_to(scene, Vector2(755, 310)))
	assert(scene.interact_with_wand())
	assert(await _walk_to(scene, Vector2(920, 366)))
	assert(scene.interact_with_wand())
	assert(await _west_ledge(scene))
	assert(await _walk_to(scene, Vector2(730, 220)))
	assert(_on_ledge(scene))
	assert(await _walk_to(scene, scene.START_POINT))
	assert(_on_ledge(scene))
	assert(scene.interact_with_wand() and scene.held_wand() == scene.FIRST_WAND)
	assert(not scene.underside and scene.actor.recoveries == 0)
	print("P9-05: overlapping wand fields, physical underside, save, fall and two-way return passed")
	scene.queue_free()
	await process_frame
	quit()


func _west_ledge(scene: Node) -> bool:
	assert(await _walk_to(scene, Vector2(410, 300)))
	assert(await _walk_to(scene, Vector2(410, 220)))
	scene.actor.jump()
	for tick in range(65):
		if _on_ledge(scene):
			return true
		await physics_frame
	return false


func _on_ledge(scene: Node) -> bool:
	return scene.actor.motion.grounded and is_equal_approx(scene.actor.motion.elevation, scene.LEDGE_Z)


func _on_floor(scene: Node) -> bool:
	for tick in range(60):
		if scene.actor.motion.grounded and is_zero_approx(scene.actor.motion.elevation):
			return true
		await physics_frame
	return false


func _walk_to(scene: Node, target: Vector2) -> bool:
	for tick in range(245):
		var delta: Vector2 = target - scene.actor.position
		if delta.length_squared() < 16.0:
			scene.actor.direction = Vector2.ZERO
			await physics_frame
			return true
		scene.actor.direction = delta.normalized()
		await physics_frame
	scene.actor.direction = Vector2.ZERO
	return false
