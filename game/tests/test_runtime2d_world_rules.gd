extends SceneTree
## Tests author-defined zone reactions, bounded execution and durable flags.
## Rules are fixtures only: no real Ethernia secret is placed by these tests.
const GAME = preload("res://scenes/runtime2d/sandbox.tscn")
const WorldRules = preload("res://scripts/runtime2d/world_rule_engine_2d.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game = GAME.instantiate()
	root.add_child(game)
	await physics_frame
	var actor = game.world_registry.get_entity("DEV_ENTITY_01")
	assert(actor != null)
	assert(is_equal_approx(float(actor.get_parameter("speed")), 2.0))

	var authored: Array = [
		{"id":"DEV_WAKE_ONCE","event":"ZONE_ENTERED",
		 "zone_id":"DEV_OBSERVATION_AREA","actor_id":"luna","once":true,
		 "action":{"type":"SET_PARAMETER","entity_id":"DEV_ENTITY_01",
		           "parameter_id":"speed","value":3.0}},
		{"id":"DEV_SIGNAL","event":"ZONE_ENTERED",
		 "zone_id":"DEV_OBSERVATION_AREA","actor_id":"luna","once":false,
		 "action":{"type":"ANNOUNCE","event_id":"DEV_ZONE_ACTIVATED"}},
		{"id":"DEV_ROUTE","event":"ZONE_ENTERED",
		 "zone_id":"DEV_OBSERVATION_AREA","actor_id":"luna","once":true,
		 "action":{"type":"REDIRECT_DOOR","door_id":"DEV_DOOR_A",
		           "destination":"DEV_SANDBOX_A"}}
	]
	assert(game.world_rules.validate_rules(authored))
	# Persist fixture definitions in the runtime catalog so room re-entry
	# restores them without generating any approved secret geography.
	var room: Dictionary = game.router.locations["DEV_SANDBOX_A"]
	room["rules"] = authored.duplicate(true)
	game.router.locations["DEV_SANDBOX_A"] = room
	assert(game.world_rules.configure_location("DEV_SANDBOX_A", authored))
	assert(not game.world_rules.configure_location("DEV_SANDBOX_A", [
		{"id":"BAD_ACCESS","event":"ZONE_ENTERED","zone_id":"DEV_OBSERVATION_AREA",
		 "action":{"type":"SET_PARAMETER","entity_id":"luna",
		           "parameter_id":"access_level","value":3}}
	]))
	assert(game.world_rules.validate_rules(authored))

	var events: Array[Dictionary] = []
	game.gameplay_event.connect(func(data: Dictionary):
		events.append(data.duplicate(true))
	)
	# Stale events from the old room must not change an active location.
	game.process_event({"type":"ZONE_ENTERED","zone_id":"DEV_OBSERVATION_AREA",
		"entity_id":"luna","location_id":"DEV_SANDBOX_B"})
	assert(is_equal_approx(float(actor.get_parameter("speed")), 2.0))
	assert(not game.world_rules.has_fired("DEV_WAKE_ONCE"))
	assert(game.router.door_destinations["DEV_DOOR_A"] == "DEV_SANDBOX_B")

	# This time the REAL physics Area2D emits the event: the player crosses
	# the authored test zone, then the bounded EventBus applies all 3 rules.
	game.player.global_position = Vector2(-160,-80)
	for i in range(3):
		await physics_frame
	assert(is_equal_approx(float(actor.get_parameter("speed")), 3.0))
	assert(game.world_rules.has_fired("DEV_WAKE_ONCE"))
	assert(game.world_rules.has_fired("DEV_ROUTE"))
	assert(game.router.door_destinations["DEV_DOOR_A"] == "DEV_SANDBOX_A")
	var announced := false
	for item in events:
		if str(item.get("type", "")) == "AUTHOR_RULE_EVENT" and str(item.get("event_id", "")) == "DEV_ZONE_ACTIVATED":
			announced = true
	assert(announced)

	var saved: Dictionary = game.make_snapshot().duplicate(true)
	assert((saved["rule_flags"] as Array).has("DEV_WAKE_ONCE"))
	assert(game.set_entity_parameter(actor.record.id, "speed", 4.0))
	assert(game.apply_snapshot(saved))
	actor = game.world_registry.get_entity("DEV_ENTITY_01")
	assert(game.world_rules.has_fired("DEV_WAKE_ONCE"))
	assert(is_equal_approx(float(actor.get_parameter("speed")), 3.0))
	assert(game.set_entity_parameter(actor.record.id, "speed", 4.0))
	game.player.global_position = Vector2(0,0)
	for i in range(3):
		await physics_frame
	game.player.global_position = Vector2(-160,-80)
	for i in range(3):
		await physics_frame
	actor = game.world_registry.get_entity("DEV_ENTITY_01")
	assert(is_equal_approx(float(actor.get_parameter("speed")), 4.0))
	assert(not game.world_rules.validate_flags(["DUP", "DUP"]))
	assert(not game.world_rules.restore_flags(["DUP", "DUP"]))
	assert(game.world_rules.has_fired("DEV_WAKE_ONCE"))
	var corrupt: Dictionary = game.make_snapshot().duplicate(true)
	corrupt["rule_flags"] = ["DUP", "DUP"]
	var live: Dictionary = game.make_snapshot()
	assert(not game.apply_snapshot(corrupt))
	assert(game.make_snapshot() == live)

	# Max eight rules can execute in one event, with the rest explicitly
	# rejected. This bounds mass triggers from malicious/generated maps.
	var many: Array = []
	for i in range(12):
		many.append({"id":"DEV_MANY_%d" % i,"event":"ZONE_ENTERED",
			"zone_id":"DEV_MASS_ZONE","action":{"type":"ANNOUNCE",
				"event_id":"DEV_ACTION_%d" % i}})
	assert(game.world_rules.configure_location("DEV_SANDBOX_A", many))
	assert(game.world_rules.process_event({"type":"ZONE_ENTERED",
		"zone_id":"DEV_MASS_ZONE","entity_id":"luna",
		"location_id":"DEV_SANDBOX_A"}, game) == 8)
	game.queue_free()
	print("LUNA runtime2d: physical authored rules, one-shot save and action budgets passed")
	quit(0)
