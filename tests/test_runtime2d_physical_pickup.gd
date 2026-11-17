extends SceneTree
## P1 integration: an authored PICKUP prop is a real physical Entity, follows
## its holder, can be dropped on valid ground and survives save/Undo/clone.

const GAME = preload("res://scenes/runtime2d/sandbox.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game = GAME.instantiate()
	root.add_child(game)
	await physics_frame

	# Only an explicitly PICKUP-enabled object may be physically carried.
	var item = game.spawn_actor("DEV_PORTABLE_OBJECT", "object",
		"Pickup test fixture", Vector2(-132, 0))
	assert(item != null)
	assert(not game.pick_up_entity("luna", item.record.id))
	assert(item.record.set_component("PICKUP", {"enabled": true,
		"holder_id": "", "weight": 1.0,
		"world_position": [-132.0, 0.0, 0.0]}))
	assert(game.pick_up_entity("luna", item.record.id))
	assert(item.carried_by_id() == "luna")
	assert(item.collision_layer == 0 and item.collision_mask == 0)
	assert(not game.pick_up_entity("luna", item.record.id))
	assert(not game.retire_actor(item.record.id))

	# A second autonomous copy is independent and remains fully physical.
	var copy = game.clone_actor(item.record.id)
	assert(copy != null and copy.record.id != item.record.id)
	assert(copy.carried_by_id().is_empty())
	assert(copy.collision_layer == 2)
	copy.global_position = Vector2(250, 160)

	# Undo/Redo of the underlying PICKUP component remains reversible,
	# including the original grounded position when undoing a pickup.
	assert(game.command_processor.undo())
	assert(item.carried_by_id().is_empty())
	assert(item.collision_layer == 2)
	assert(item.global_position == Vector2(-132, 0))
	assert(game.command_processor.redo())
	assert(item.carried_by_id() == "luna")
	assert(item.collision_layer == 0)

	game.player.global_position = Vector2(0, 100)
	for n in range(3):
		await physics_frame
	assert(item.global_position.distance_to(
		game.player.global_position + item.HELD_OFFSET) < 2.0)
	assert(game.find_nearby_entities("luna", 100.0).is_empty())

	# The player cannot abandon a held object by entering another room.
	game.player.global_position = Vector2(260, 0)
	for n in range(2):
		await physics_frame
	assert(not game.enter_nearby_door())
	assert(game.current_location_id == "DEV_SANDBOX_A")
	game.player.global_position = Vector2(0, 100)
	for n in range(2):
		await physics_frame

	var carried_save: Dictionary = game.make_snapshot().duplicate(true)
	assert(game.apply_snapshot(carried_save))
	item = game.world_registry.get_entity("DEV_PORTABLE_OBJECT")
	assert(item != null and item.carried_by_id() == "luna")
	assert(item.collision_layer == 0)
	assert(game.drop_held_entity("luna", item.record.id))
	assert(item.carried_by_id().is_empty() and item.collision_layer == 2)
	assert(item.global_position.distance_to(game.player.global_position) >= 35.0)
	assert(game.command_processor.undo())
	assert(item.carried_by_id() == "luna")
	assert(game.command_processor.redo())
	assert(item.carried_by_id().is_empty())
	assert(item.global_position.distance_to(game.player.global_position) >= 35.0)

	var safe: Dictionary = game.make_snapshot().duplicate(true)
	var corrupt: Dictionary = safe.duplicate(true)
	for entity in corrupt["entities"]:
		if str(entity["id"]) == "DEV_PORTABLE_OBJECT":
			entity["components"]["PICKUP"]["holder_id"] = "MISSING_CARRIER"
	assert(not game.apply_snapshot(corrupt))
	assert(game.make_snapshot() == safe)
	assert(game.retire_actor(item.record.id))
	assert(game.world_registry.was_deleted("DEV_PORTABLE_OBJECT"))

	game.queue_free()
	print("LUNA runtime2d P1: physical PICKUP, Undo/Redo, cloning, saves and drop passed")
	quit(0)
