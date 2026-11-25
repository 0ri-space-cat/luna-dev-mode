extends SceneTree

const Room = preload("res://scenes/skeleton/rule_fixture.tscn")
const Clock = preload("res://scripts/runtime2d/world_clock_2d.gd")
const LEFT := Vector2(260, 264)
const CENTRE := Vector2(299, 264)
const RIGHT := Vector2(333, 264)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene = Room.instantiate()
	scene.keyboard = false
	root.add_child(scene)
	await physics_frame
	var firings: Array[String] = []
	scene.rules.rule_fired.connect(func(rule_id: String, _location: String): firings.append(rule_id))

	# Night contact reaches the rule engine but fails its time condition.
	assert(await _walk_to(scene, CENTRE))
	assert(scene.events.processed_count == 1 and _plate_is_inactive(scene))
	var checkpoint: Dictionary = JSON.parse_string(JSON.stringify(scene.make_snapshot()))
	checkpoint["world_clock"]["day_minute"] = Clock.START_MINUTE
	assert(scene.apply_snapshot(checkpoint))
	await physics_frame
	assert(scene._plate_occupied and _plate_is_inactive(scene))

	# Crossing in the air neither presses the plate nor consumes its one-shot rule.
	assert(await _walk_to(scene, LEFT))
	scene.apply_player_input(Vector2.RIGHT, true)
	assert(await _walk_to(scene, RIGHT))
	for tick in range(65):
		await physics_frame
	assert(scene.actor.motion.grounded and _plate_is_inactive(scene))

	# A real daytime step changes the same parameter that the wand edits.
	assert(await _walk_to(scene, CENTRE))
	assert(scene.rules.has_fired(scene.RULE_ID))
	var fridge = scene.entities.get_entity(scene.TARGET_ID)
	assert(fridge.get_parameter("alive"))
	var start: Vector2 = fridge.position
	for tick in range(12):
		await physics_frame
	assert(fridge.position.distance_to(start) > 8.0)
	assert(firings == [scene.RULE_ID])

	# Turning it off and loading a save inside the plate cannot replay the action.
	assert(scene.request_wand_parameter_edit(scene.TARGET_ID, "IS_ALIVE", false))
	var fired: Dictionary = JSON.parse_string(JSON.stringify(scene.make_snapshot()))
	var invalid := fired.duplicate(true)
	invalid["rule_flags"].append(scene.RULE_ID)
	assert(not scene.apply_snapshot(invalid))
	assert(scene.rules.has_fired(scene.RULE_ID))
	assert(scene.apply_snapshot(fired))
	assert(await _walk_to(scene, LEFT))
	assert(await _walk_to(scene, CENTRE))
	assert(not scene.entities.get_entity(scene.TARGET_ID).get_parameter("alive"))
	assert(firings == [scene.RULE_ID])

	# Restoring a checkpoint before the action restores the rule's original state.
	assert(scene.apply_snapshot(checkpoint))
	assert(_plate_is_inactive(scene))
	assert(await _walk_to(scene, LEFT))
	assert(await _walk_to(scene, CENTRE))
	assert(firings.size() == 2 and scene.rules.has_fired(scene.RULE_ID))
	print("P9-04: grounded event, time condition, live parameter, one-shot save and rewind passed")
	scene.queue_free()
	await process_frame
	quit()


func _plate_is_inactive(scene: Node) -> bool:
	return not scene.rules.has_fired(scene.RULE_ID) \
		and not scene.entities.get_entity(scene.TARGET_ID).get_parameter("alive")


func _walk_to(scene: Node, target: Vector2) -> bool:
	for tick in range(100):
		var offset: Vector2 = target - scene.actor.position
		if offset.length_squared() < 16.0:
			scene.apply_player_input(Vector2.ZERO)
			await physics_frame
			return true
		scene.apply_player_input(offset.normalized())
		await physics_frame
	scene.apply_player_input(Vector2.ZERO)
	return false
