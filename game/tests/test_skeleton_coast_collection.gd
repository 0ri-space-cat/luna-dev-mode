extends SceneTree
const Start = preload("res://scenes/skeleton/start_island.tscn")
const Island = preload("res://scripts/skeleton/start_island.gd")
const Cove = preload("res://scripts/skeleton/shell_collection_2d.gd")
const Coast = preload("res://scripts/skeleton/coast_layout.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	Engine.time_scale = 3.0
	var home = Start.instantiate()
	home.keyboard = false
	home.observation_fixture = true
	root.add_child(home)
	await physics_frame
	var legacy: Dictionary = home.make_snapshot()
	legacy.erase("shell_collection")
	assert(home.apply_snapshot(legacy) and not home.shell_collection_ready)
	# Use the real starter rift, not a privileged fixture or direct access mutation.
	assert(home.access.wand_mode == "ORDINARY")
	assert(await _walk(home, Island.RIFT_SPOT + Vector2(0, -44)))
	assert(home.interact() and home.access.wand_mode == "PLAYFUL")
	_place(home, Coast.BEACH_ENTRY)
	for point in [Vector2(2440, 830), Vector2(2375, 830), Cove.ENTRY]:
		assert(await _walk(home, point), "Cove route: %s / %s" % [point, home.actor.position])
	await physics_frame
	assert(home.shell_collection_ready and home.actor.recoveries == 0)
	for index in range(1, Cove.REQUIRED + 1):
		assert(home.entities.get_entity(Cove.natural_id(index)) != null)
	assert(Cove.identical_count(home.entities) == 0)
	# Place a single found shell at the collection mat, then exercise the same
	# repeatable Copy request used by the ordinary editor. Each body is real.
	var source = home.entities.get_entity(Cove.natural_id(1))
	source.position = Cove.TRAY.get_center()
	source.motion.reset_on_surface(source.position, 0.0)
	source.location_id = Coast.LOCATION_ID
	_place(home, source.position + Vector2(0, -32))
	var copies: Array[String] = []
	for index in range(29):
		var identity: String = home.request_wand_copy(source.entity_id)
		assert(not identity.is_empty(), "Copy %d failed: mode=%s policy=%s entities=%d" % [index, home.access.wand_mode, home.wand_policy.last_error, home.entities.count_live()])
		copies.append(identity)
	assert(Cove.identical_count(home.entities) == 30)
	var altered = home.entities.get_entity(copies[-1])
	assert(altered.set_parameter("mass", 0.4))
	assert(Cove.identical_count(home.entities) == 29)
	assert(altered.set_parameter("mass", source.get_parameter("mass")))
	_place(home, Cove.OCTOPUS_POINT + Vector2(-35, 0))
	assert(home.interact() and home.shell_collection_delivered)
	var saved: Dictionary = JSON.parse_string(JSON.stringify(home.make_snapshot()))
	assert(home.apply_snapshot(saved) and home.shell_collection_delivered)
	assert(Cove.identical_count(home.entities) == 30)
	assert(home.interact() and home.shell_collection_delivered)
	var bad: Dictionary = saved.duplicate(true)
	bad["entities"] = bad["entities"].filter(func(entry): return entry["id"] != Cove.natural_id(2))
	assert(not home.apply_snapshot(bad))
	assert(home.entities.get_entity(Cove.natural_id(2)) != null)
	home.queue_free()
	await process_frame
	print("K1: real dry route, 30 independent shells, repeatable Copy, identical matching and persistent delivery passed")
	quit()


func _place(home: Node, point: Vector2) -> void:
	home.actor.position = point
	home.actor.motion.reset_on_surface(point, 0.0)
	home.actor.location_id = home._entity_location(point)
	home.apply_player_input(Vector2.ZERO)


func _walk(home: Node, point: Vector2) -> bool:
	for tick in range(200):
		var offset: Vector2 = point - home.actor.position
		if offset.length_squared() < 9.0:
			home.apply_player_input(Vector2.ZERO)
			await physics_frame
			return home.actor.motion.grounded
		var step_length: float = home.actor.WALK_SPEED * Engine.time_scale / Engine.physics_ticks_per_second
		home.apply_player_input((offset / step_length).limit_length())
		await physics_frame
	home.apply_player_input(Vector2.ZERO)
	return false
