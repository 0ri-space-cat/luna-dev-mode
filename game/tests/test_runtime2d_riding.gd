extends SceneTree
## Real RIDEABLE object transfer: passenger follows a moving physical Entity,
## cannot enter doors while mounted, and dismounts only onto safe ground.
const GAME = preload("res://scenes/runtime2d/sandbox.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game = GAME.instantiate()
	root.add_child(game)
	await physics_frame
	var carrier = game.world_registry.get_entity("DEV_ENTITY_01")
	assert(carrier != null)
	assert(game.set_entity_parameter(carrier.record.id, "ai_enabled", false))
	carrier.global_position = Vector2(-100,100)
	game.player.global_position = Vector2(-88,100)
	assert(not game.mount_actor("luna", carrier.record.id))
	assert(game.set_entity_parameter(carrier.record.id, "rideable", true))
	assert(game.mount_actor("luna", carrier.record.id))
	assert(game.player.riding_id == carrier.record.id)
	assert(game.player.collision_layer == 0)
	assert(not game.retire_actor(carrier.record.id))
	assert(not game.enter_nearby_door()) # No cross-room orphan passengers.

	var copy = game.clone_actor("luna")
	assert(copy != null and copy.riding_id.is_empty())
	assert(copy.record.id != game.player.record.id)
	copy.global_position = Vector2(140,160) # Independent clone should not block the test route.

	carrier.set_external_drive(Vector2.RIGHT)
	var start_x: float = carrier.global_position.x
	for i in range(16):
		await physics_frame
	assert(carrier.global_position.x > start_x + 20.0)
	assert(game.player.global_position.distance_to(
		carrier.global_position + game.player.seat_offset) < 10.0)
	carrier.clear_external_drive()

	var mounted_snapshot: Dictionary = game.make_snapshot().duplicate(true)
	assert(game.apply_snapshot(mounted_snapshot))
	var restored_player = game.player
	var restored_carrier = game.world_registry.get_entity("DEV_ENTITY_01")
	assert(restored_player.riding_id == restored_carrier.record.id)
	assert(restored_player.collision_layer == 0)
	assert(restored_carrier.get_parameter("rideable"))

	# Unmount must find genuine navigable ground and avoid other actors.
	await physics_frame
	assert(game.dismount_actor("luna"))
	assert(restored_player.riding_id.is_empty())
	assert(restored_player.collision_layer == 2)
	assert(restored_player.global_position.distance_to(restored_carrier.global_position) >= 35.0)

	var healthy: Dictionary = game.make_snapshot().duplicate(true)
	var damaged: Dictionary = healthy.duplicate(true)
	for item in damaged["entities"]:
		if item["id"] == "luna":
			item["ride_id"] = "DEV_ENTITY_01"
		if item["id"] == "DEV_ENTITY_01":
			item["parameters"]["rideable"] = false
	assert(not game.apply_snapshot(damaged))
	assert(game.make_snapshot() == healthy)
	damaged = healthy.duplicate(true)
	for item in damaged["entities"]:
		if item["id"] == "luna":
			item["ride_id"] = "DEV_ENTITY_01"
		if item["id"] == "DEV_ENTITY_01":
			item["ride_id"] = "luna"
	assert(not game.apply_snapshot(damaged))
	assert(game.make_snapshot() == healthy)

	assert(game.retire_actor("DEV_ENTITY_01"))
	assert(game.world_registry.get_entity("DEV_ENTITY_01") == null)
	assert(game.player.riding_id.is_empty())
	game.queue_free()
	print("LUNA runtime2d: moving mount, passenger save, safe landing and invalid links passed")
	quit(0)
