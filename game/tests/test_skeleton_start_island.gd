extends SceneTree

const Island = preload("res://scenes/skeleton/start_island.tscn")
const Access = preload("res://scripts/runtime2d/access_state_2d.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene = Island.instantiate()
	scene.keyboard = false
	root.add_child(scene)
	await physics_frame
	assert(scene.access.wand_mode == Access.ORDINARY)
	assert(await _walk_to(scene, Vector2(320, 255)))
	assert(not scene.request_wand_parameter_edit(scene.FRIDGE_ID, "IS_ALIVE", true))
	assert(scene.interact() and scene.has_donut)
	assert(await _walk_to(scene, Vector2(320, 480)))
	assert(scene.interact() and scene.access.wand_mode == Access.PLAYFUL)
	assert(await _walk_to(scene, Vector2(320, 374)))

	# An actual body blocks the flat walking path while the yeti sleeps.
	scene.apply_player_input(Vector2.RIGHT)
	for tick in range(160):
		await physics_frame
	scene.apply_player_input(Vector2.ZERO)
	assert(scene.actor.position.x > 690.0 and scene.actor.position.x < 740.0)
	assert(not scene.interact() and scene.has_donut)
	assert(scene.request_wand_parameter_edit(scene.BRIDGE_YETI_ID, "ASLEEP", false))
	assert(scene.interact() and not scene.has_donut)
	assert(await _walk_to(scene, Vector2(1260, 374), 250))
	assert(scene.actor.location_id == "ET_MEADOWS_MAIN")
	var yeti_position: Vector2 = scene.entities.get_entity(scene.BRIDGE_YETI_ID).position
	assert(yeti_position.y > 445.0)

	# The same ordinary wand and physical route work after a later reset and reload.
	assert(scene.access.set_wand_mode(Access.ORDINARY))
	var saved: Dictionary = JSON.parse_string(JSON.stringify(scene.make_snapshot()))
	assert(scene.apply_snapshot(saved))
	assert(scene.access.wand_mode == Access.ORDINARY)
	assert(scene.entities.get_entity(scene.BRIDGE_YETI_ID).position.is_equal_approx(yeti_position))
	assert(await _walk_to(scene, Vector2(320, 374), 350))
	assert(await _walk_to(scene, Vector2(320, 255)))
	assert(scene.interact() and scene.has_donut)
	assert(await _walk_to(scene, Vector2(320, 480)))
	assert(scene.interact() and scene.access.wand_mode == Access.PLAYFUL)
	assert(scene.has_donut)
	assert(await _walk_to(scene, Vector2(320, 374)))
	assert(await _walk_to(scene, Vector2(1260, 374), 350))
	print("P9-03: island, physical bridge, donut, saved retreat and repeatable rift passed")
	scene.queue_free()
	await process_frame
	quit()


func _walk_to(scene: Node, target: Vector2, max_ticks: int = 180) -> bool:
	for tick in range(max_ticks):
		var offset: Vector2 = target - scene.actor.position
		if offset.length_squared() < 16.0:
			scene.apply_player_input(Vector2.ZERO)
			return true
		scene.apply_player_input(offset.normalized())
		await physics_frame
	scene.apply_player_input(Vector2.ZERO)
	return false
