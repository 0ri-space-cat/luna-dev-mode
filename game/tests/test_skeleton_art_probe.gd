extends SceneTree

const Fixture = preload("res://scenes/skeleton/art_probe.tscn")
const ArtProbe = preload("res://scripts/skeleton/art_probe.gd")
const EXTERIOR := "DEV_ART_EXTERIOR"
const INTERIOR := "DEV_ART_INTERIOR"

var scene: ArtProbe


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	scene = Fixture.instantiate()
	scene.keyboard = false
	root.add_child(scene)
	await physics_frame
	var traveler := scene.actor
	assert(scene.current_address == EXTERIOR)
	assert(not scene.enter_nearby_door())
	assert(scene.luna_art.texture.get_size() == Vector2(240, 380))
	assert(scene.oni_art.texture.get_size() == Vector2(48, 76))
	_assert_screen_controls()

	assert(await _walk_to(Vector2(437, 208)))
	var minute := scene.world_clock.minute_of_day()
	_press_door_key()
	assert(scene.current_address == INTERIOR and scene.actor == traveler)
	assert(scene.actor.position == Vector2(53, 158) and scene.actor.motion.grounded)
	assert(scene.world_clock.minute_of_day() == minute)
	_assert_screen_controls()

	assert(await _walk_to(Vector2(91, 145)))
	for i in 5:
		assert(await _walk_to(Vector2(140 + 31 * i, 145)))
		assert(scene.actor.motion.grounded and scene.actor.motion.elevation == 6.0 * (i + 1))
	assert(await _walk_to(Vector2(348, 147)))
	assert(scene.actor.motion.grounded and scene.actor.motion.elevation == 30.0)
	await process_frame
	await process_frame
	assert(scene.luna_art.position == scene.view.point(scene.actor.position, 30.0).round())
	assert(scene.luna_shadow.position == scene.luna_art.position)

	var upper: Dictionary = JSON.parse_string(JSON.stringify(scene.make_snapshot()))
	scene.actor.jump()
	for i in 5:
		await physics_frame
	assert(scene.actor.motion.elevation > 30.0)
	assert(scene._support_below(scene.actor.position, scene.actor.motion.elevation) == 30.0)
	assert(scene.apply_snapshot(upper))
	assert(scene.actor.motion.grounded and scene.actor.motion.elevation == 30.0)
	assert(scene.world_clock.snapshot() == upper["world_clock"])

	assert(await _walk_to(Vector2(88, 145)))
	for i in 15:
		await physics_frame
	assert(scene.actor.motion.grounded and is_zero_approx(scene.actor.motion.elevation))
	assert(await _walk_to(Vector2(88, 301)))
	assert(await _walk_to(Vector2(266, 301)))
	scene.actor.direction = Vector2.UP
	for i in 30:
		await physics_frame
	scene.actor.direction = Vector2.ZERO
	assert(scene.actor.position.y >= 286.0 and is_zero_approx(scene.actor.motion.elevation))
	await process_frame
	await process_frame
	var prop: Node2D = scene.get_node("Backdrop").get_child(0)
	assert(scene.luna_art.z_index > prop.z_index)

	traveler = scene.actor
	assert(await _walk_to(Vector2(78, 301)))
	assert(await _walk_to(Vector2(52, 158)))
	_press_door_key()
	assert(scene.current_address == EXTERIOR and scene.actor == traveler)
	assert(scene.actor.position == Vector2(437, 208) and scene.actor.motion.grounded)
	assert(scene.get_tree().get_nodes_in_group("runtime2d_address_doors").size() == 1)
	print("P9-06: both views, screen controls, two-way door, stairs, shadow, depth and snapshot passed")
	scene.queue_free()
	await process_frame
	quit()


func _assert_screen_controls() -> void:
	for input in [Vector2.RIGHT, Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2(-1, 1)]:
		var world := scene.view.movement(input)
		var screen := scene.view.ground_to_screen.basis_xform(world)
		assert(is_equal_approx(world.length(), 1.0))
		assert(screen.normalized().is_equal_approx(input.normalized()))


func _press_door_key() -> void:
	var event := InputEventKey.new()
	event.physical_keycode = KEY_E
	event.pressed = true
	scene.keyboard = true
	scene._unhandled_key_input(event)
	scene.keyboard = false


func _walk_to(target: Vector2) -> bool:
	for i in 220:
		var offset := target - scene.actor.position
		if offset.length() < 3.0:
			scene.actor.direction = Vector2.ZERO
			return true
		scene.actor.direction = offset.normalized()
		await physics_frame
	scene.actor.direction = Vector2.ZERO
	push_error("Could not walk from %s to %s" % [scene.actor.position, target])
	return false
