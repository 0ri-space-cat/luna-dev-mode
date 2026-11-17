extends SceneTree
## P1: author-defined secrets may require *physical* occupancy of another
## zone and independent editable world parameters, without custom puzzle code.

const GAME = preload("res://scenes/runtime2d/sandbox.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _frames(count: int) -> void:
	for i in range(count):
		await physics_frame


func _run() -> void:
	var game = GAME.instantiate()
	root.add_child(game)
	await physics_frame
	var actor = game.world_registry.get_entity("DEV_ENTITY_01")
	assert(actor != null)
	assert(game.set_entity_parameter(actor.record.id, "ai_enabled", false))
	assert(game._live_level.geometry.build_from_description({
		"solids": [],
		"zones": [
			{"id": "DEV_PAD_A", "rect": [-200,-120,80,80]},
			{"id": "DEV_PAD_B", "rect": [-60,-120,80,80]}
		]
	}))
	var definitions: Array = [{
		"id": "DEV_MULTIZONE_RULE", "event": "ZONE_ENTERED",
		"zone_id": "DEV_PAD_A", "actor_id": "luna", "once": true,
		"conditions": [
			{"type": "ZONE_OCCUPIED", "zone_id": "DEV_PAD_B",
				"actor_id": "DEV_ENTITY_01"},
			{"type": "PARAMETER_EQUALS", "entity_id": "DEV_ENTITY_01",
				"parameter_id": "pushable", "value": true}
		],
		"action": {"type": "SET_PARAMETER",
			"entity_id": "DEV_ENTITY_01", "parameter_id": "speed", "value": 3.0}
	}]
	assert(game.world_rules.validate_rules(definitions))
	var room: Dictionary = game.router.locations["DEV_SANDBOX_A"]
	room["rules"] = definitions.duplicate(true)
	game.router.locations["DEV_SANDBOX_A"] = room
	assert(game.world_rules.configure_location("DEV_SANDBOX_A", definitions))
	assert(not game.world_rules.validate_rules([{
		"id": "DEV_BROKEN_RULE", "event": "ZONE_ENTERED",
		"zone_id": "DEV_PAD_A",
		"conditions": [{"type": "UNSAFE_SCRIPT", "payload": "arbitrary"}],
		"action": {"type": "ANNOUNCE", "event_id": "NO_CODE_EXECUTION"}
	}]))

	# Trigger A without any occupant on B: conditions are not satisfied.
	game.player.global_position = Vector2(-160, -80)
	await _frames(3)
	assert(is_equal_approx(float(actor.get_parameter("speed")), 2.0))
	assert(not game.world_rules.has_fired("DEV_MULTIZONE_RULE"))

	# B occupied, but the required property is still false.
	game.player.global_position = Vector2(-160, 0)
	await _frames(3)
	actor.global_position = Vector2(-20, -80)
	await _frames(3)
	assert(game._live_level.geometry.find_zone("DEV_PAD_B").get_overlapping_bodies().has(actor))
	game.player.global_position = Vector2(-160, -80)
	await _frames(3)
	assert(is_equal_approx(float(actor.get_parameter("speed")), 2.0))

	# Changing a real parameter is enough. No authored puzzle script or
	# visual/GUI logic is involved in this world-level conjunction.
	game.player.global_position = Vector2(-160, 0)
	await _frames(3)
	assert(game.set_entity_parameter(actor.record.id, "pushable", true))
	game.player.global_position = Vector2(-160, -80)
	await _frames(3)
	assert(is_equal_approx(float(actor.get_parameter("speed")), 3.0))
	assert(game.world_rules.has_fired("DEV_MULTIZONE_RULE"))

	var snapshot: Dictionary = game.make_snapshot().duplicate(true)
	assert((snapshot["rule_flags"] as Array).has("DEV_MULTIZONE_RULE"))
	assert(game.apply_snapshot(snapshot))
	assert(game.world_rules.has_fired("DEV_MULTIZONE_RULE"))
	assert(is_equal_approx(float(game.world_registry.get_entity("DEV_ENTITY_01")
		.get_parameter("speed")), 3.0))

	game.queue_free()
	print("LUNA runtime2d P1: authored multi-zone occupancy and parameter conditions passed")
	quit(0)
