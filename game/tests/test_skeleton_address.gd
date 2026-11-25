extends SceneTree

const Fixture = preload("res://scenes/skeleton/address_fixture.tscn")
const Access = preload("res://scripts/runtime2d/access_state_2d.gd")
const HALL := "DEV_ADDRESS_HALL"
const INTERIOR := "DEV_ADDRESS_ROOM"
const OUT := "DEV_ADDRESS_OUT"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene = Fixture.instantiate()
	scene.keyboard = false
	root.add_child(scene)
	await physics_frame
	var traveler = scene.actor
	assert(scene.current_address == HALL)
	assert(scene.actor.position == Vector2(498, 330))

	# Known addresses, wand edit authority and traversal authority are independent.
	assert(scene.request_door_address(HALL))
	var routes: Dictionary = scene.router.snapshot_routes()
	assert(not scene.request_door_address(INTERIOR))
	assert(not scene.request_door_address("dev_address_hall"))
	assert(scene.router.snapshot_routes() == routes)
	assert(scene.access.set_wand_mode(Access.ORDINARY))
	assert(not scene.request_door_address(HALL))
	assert(scene.access.set_wand_mode(Access.DEVELOPER))
	assert(scene.request_door_address(INTERIOR))
	assert(not scene.enter_nearby_door())
	assert(scene.actor == traveler and scene.current_address == HALL)
	assert(scene.access.set_avatar_access_level(1))

	# Missing and geometrically unsafe arrivals leave the occupied room untouched.
	var old_room = scene._room
	var safe: Dictionary = scene.make_snapshot()
	var entries: Dictionary = scene.router.locations[INTERIOR]["entries"]
	var real_point: Vector2 = entries["entry"]
	scene._room.door.destination_entry_id = "missing"
	assert(not scene.enter_nearby_door())
	scene._room.door.destination_entry_id = "entry"
	entries["entry"] = Vector2(655, 220)
	assert(not scene.enter_nearby_door())
	entries["entry"] = Vector2(881, 330)
	assert(not scene.enter_nearby_door())
	entries["entry"] = real_point
	assert(scene._room == old_room and scene.make_snapshot() == safe)

	# Movement and genuine support come from the mounted destination scene.
	scene.actor.apply_impulse(Vector2(20, 0))
	assert(scene.enter_nearby_door())
	assert(scene.current_address == INTERIOR and scene.actor == traveler)
	assert(scene.actor.position == real_point and scene.actor.motion.grounded)
	assert(scene.actor.motion.elevation == 48.0)
	for tick in range(4):
		await physics_frame
	assert(scene.actor.position == real_point)

	# A restore resumes the interior even if entry rights were lost there.
	assert(scene.access.set_avatar_access_level(0))
	assert(scene.access.set_wand_mode(Access.ORDINARY))
	var occupied: Dictionary = JSON.parse_string(JSON.stringify(scene.make_snapshot()))
	assert(scene.enter_nearby_door() and scene.current_address == HALL)
	assert(scene.actor.motion.elevation == 0.0)
	assert(not scene.enter_nearby_door())
	var hall_state: Dictionary = scene.make_snapshot()
	var broken := occupied.duplicate(true)
	broken["actor"]["position"] = [674, 107]
	assert(not scene.apply_snapshot(broken))
	assert(scene.make_snapshot() == hall_state)
	await physics_frame
	assert(scene.actor.motion.grounded)

	assert(scene.apply_snapshot(occupied))
	assert(scene.current_address == INTERIOR and scene.actor.entity_id == scene.ENTITY_ID)
	assert(scene.actor.position == real_point and scene.actor.motion.elevation == 48.0)
	assert(scene.access.wand_mode == Access.ORDINARY and scene.access.avatar_access_level == 0)
	assert(scene.router.snapshot_routes()[OUT] == INTERIOR)
	assert(scene.enter_nearby_door() and scene.current_address == HALL)
	assert(scene.actor.position == Vector2(498, 330))
	assert(not scene.enter_nearby_door())
	assert(scene.get_tree().get_nodes_in_group("runtime2d_address_doors").size() == 1)
	print("P9-05: exact door address, distinct rights, safe 2D+Z arrival and return after reload passed")
	scene.queue_free()
	await process_frame
	quit()
