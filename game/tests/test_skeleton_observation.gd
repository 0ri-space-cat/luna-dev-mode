extends SceneTree

const Room = preload("res://scenes/skeleton/observation_fixture.tscn")
const FollowCamera = preload("res://scripts/runtime2d/camera_follow_lock_2d.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene = Room.instantiate()
	scene.keyboard = false
	root.add_child(scene)
	await physics_frame

	# The first invisible span is walkable with either observer active.
	_place(scene, Vector2(390, 165))
	assert(scene.camera.mode == FollowCamera.FOLLOW and scene.observer.luna_eyes_open)
	assert(await _walk_to(scene, Vector2(740, 165)))
	assert(_on_upper(scene))

	# Looking at the second crossing removes support. The lower path reaches the right bank.
	_place(scene, Vector2(390, 275))
	scene.observer.facing = Vector2.RIGHT
	scene._sync_observation()
	assert(not scene._surfaces.has(scene.GAZE_BRIDGE))
	assert(await _walk_to(scene, Vector2(530, 275)))
	assert(await _reach_lower(scene))
	assert(await _walk_to(scene, Vector2(750, 275)))
	assert(await _jump_to_upper(scene))
	scene.observer.luna_eyes_open = false
	assert(await _walk_to(scene, Vector2(390, 275)))
	assert(_on_upper(scene))

	# Closed eyes leave camera observation intact. Even a clipped edge counts.
	_place(scene, Vector2(390, 385))
	assert(not scene._surfaces.has(scene.CAMERA_BRIDGE))
	scene.camera.set_mode(FollowCamera.LOCKED)
	var half_width: float = scene.camera.world_view_rect().size.x * 0.5
	scene.camera.position = Vector2(410.0 - half_width + 5.0, 385.0 - scene.BRIDGE_Z)
	scene._sync_observation()
	assert(not scene.camera.contains_world_point(Vector2(565, 385 - scene.BRIDGE_Z)))
	assert(not scene._surfaces.has(scene.CAMERA_BRIDGE))

	# Locking at the left approach keeps the whole span out of the viewport.
	scene.camera.set_mode(FollowCamera.FOLLOW)
	assert(await _walk_to(scene, scene.WEST_LOCK))
	scene.observer.luna_eyes_open = true
	scene.camera.toggle_mode()
	scene._sync_observation()
	var locked_position: Vector2 = scene.camera.position
	assert(await _walk_to(scene, Vector2(525, 385)))
	assert(scene.camera.position.is_equal_approx(locked_position) and _on_upper(scene))
	var checkpoint: Dictionary = JSON.parse_string(JSON.stringify(scene.make_snapshot()))

	# Restoring FOLLOW while on the bridge leads to a real fall and a left exit.
	scene.camera.set_mode(FollowCamera.FOLLOW)
	assert(await _reach_lower(scene))
	assert(await _walk_to(scene, Vector2(385, 385)))
	assert(await _jump_to_upper(scene))

	assert(scene.apply_snapshot(checkpoint))
	await physics_frame
	await physics_frame
	assert(scene.camera.mode == FollowCamera.LOCKED and scene.observer.luna_eyes_open)
	assert(_on_upper(scene))
	assert(await _walk_to(scene, Vector2(745, 385)))
	assert(_on_upper(scene))
	assert(scene.actor.recoveries == 0)
	print("P9-05: three physical laws, clipped viewport, two safe exits and locked save passed")
	scene.queue_free()
	await process_frame
	quit()


func _place(scene: Node, point: Vector2) -> void:
	scene.actor.position = point
	assert(scene.actor.motion.start_on_safe_support(point, scene.BRIDGE_Z, scene._surfaces))
	scene._sync_observation()


func _on_upper(scene: Node) -> bool:
	return scene.actor.motion.grounded and is_equal_approx(scene.actor.motion.elevation, scene.BRIDGE_Z)


func _reach_lower(scene: Node) -> bool:
	for tick in range(70):
		if scene.actor.motion.grounded and is_zero_approx(scene.actor.motion.elevation):
			return true
		await physics_frame
	return false


func _jump_to_upper(scene: Node) -> bool:
	scene.actor.jump()
	for tick in range(75):
		if _on_upper(scene):
			return true
		await physics_frame
	return false


func _walk_to(scene: Node, target: Vector2) -> bool:
	for tick in range(210):
		var delta: Vector2 = target - scene.actor.position
		if delta.length_squared() < 16.0:
			scene.actor.direction = Vector2.ZERO
			await physics_frame
			return true
		scene.actor.direction = delta.normalized()
		await physics_frame
	scene.actor.direction = Vector2.ZERO
	return false
