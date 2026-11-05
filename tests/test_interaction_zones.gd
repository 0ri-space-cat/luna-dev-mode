extends SceneTree
## One trigger language for objects, zones and authored rules.
const PATH := "user://luna_interaction_zone_024.json"
const SaveService = preload("res://scripts/core/save_service.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	var stage = load("res://scenes/main.tscn").instantiate()
	root.add_child(stage)
	stage.save_service = SaveService.new(PATH)
	var fridge: Node3D = stage.world_registry.get_entity("fridge_001")
	var tree: Node3D = stage.world_registry.get_entity("tree_001")
	var luna: Node3D = stage.luna
	var commands = stage.command_processor
	assert(stage.interaction_service != null and stage.zone_service != null)
	assert(not stage.interaction_service.request("luna", "fridge_001", "OPEN"))
	assert(commands.execute_component(fridge, "SET_COMPONENT", "INTERACTION",
		{"verb": "OPEN", "reach": 2.5}, "luna", "wand:luna"))
	assert(commands.execute_component(tree, "SET_COMPONENT", "TRIGGER_ZONE",
		{"radius": 2.5, "watch_group": "LUNA"}, "luna", "wand:luna"))
	assert(stage.event_bus.pending_count() >= 2)
	stage.event_bus.clear_pending()
	assert(not stage.interaction_service.request("luna", "fridge_001", "OPEN"))
	assert(not stage.interaction_service.request("luna", "fridge_001", "USE"))
	var original_health: int = int(fridge.get_parameter("health"))
	assert(stage.rule_engine.register_rule({
		"id": "test:open_fridge", "owner_id": "",
		"author_id": "luna", "event_type": "entity.interacted",
		"target": "EVENT_TARGET", "repeat_limit": 1,
		"where": {"field": "payload.verb", "op": "EQ", "value": "OPEN"},
		"effects": [{"operation": "ADD", "parameter_id": "health", "value": -5}]
	}))
	luna.position = fridge.position + Vector3(0, 0, 1)
	assert(stage.interaction_service.request("luna", "fridge_001", "OPEN"))
	assert(stage.event_bus.drain(stage.rule_engine) >= 1)
	assert(fridge.get_parameter("health") == original_health - 5)
	assert(stage.rule_engine.fired_count("test:open_fridge") == 1)
	assert(commands.get_recent_audit(1)[0]["source_id"] == "rule:test:open_fridge")
	assert(stage.interaction_service.request("luna", "fridge_001", "OPEN"))
	stage.event_bus.drain(stage.rule_engine)
	assert(stage.rule_engine.fired_count("test:open_fridge") == 1)

	assert(stage.rule_engine.register_rule({
		"id": "test:tree_zone_enter", "owner_id": "tree_001",
		"event_type": "zone.entered", "target": "RULE_OWNER",
		"where": {"field": "payload.actor_id", "op": "EQ", "value": "luna"},
		"effects": [{"operation": "ADD", "parameter_id": "speed", "value": 1.0}]
	}))
	assert(stage.rule_engine.register_rule({
		"id": "test:tree_zone_exit", "owner_id": "tree_001",
		"event_type": "zone.exited", "target": "RULE_OWNER",
		"effects": [{"operation": "ADD", "parameter_id": "speed", "value": -0.5}]
	}))
	stage.event_bus.clear_pending()
	var initial_speed: float = float(tree.get_parameter("speed"))
	luna.position = Vector3(0, 0.1, 20)
	assert(stage.zone_service.scan() == 0)
	luna.position = tree.position + Vector3(0, 0, 1)
	assert(stage.zone_service.scan() == 1)
	assert(stage.zone_service.scan() == 0)
	assert(stage.event_bus.drain(stage.rule_engine) >= 1)
	assert(is_equal_approx(float(tree.get_parameter("speed")), initial_speed + 1.0))
	luna.position = Vector3(0, 0.1, 20)
	assert(stage.zone_service.scan() == 1)
	assert(stage.event_bus.drain(stage.rule_engine) >= 1)
	assert(is_equal_approx(float(tree.get_parameter("speed")), initial_speed + 0.5))

	# Undo and restore cannot create ghost triggers from stale Node refs.
	assert(commands.execute_entity_delete(stage.entity_lifecycle, "tree_001"))
	assert(stage.zone_service.scan() == 0)
	assert(commands.undo())
	assert(stage.world_registry.get_entity("tree_001") != null)
	stage.zone_service.reset()
	var fresh_tree: Node3D = stage.world_registry.get_entity("tree_001")
	assert(fresh_tree.record.has_component("TRIGGER_ZONE"))
	assert(stage.zone_service.scan() == 0)
	luna.position = fresh_tree.position + Vector3(0, 0, 1)
	assert(stage.zone_service.scan() == 1)

	stage.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	print("LUNA 0.24: interactions, zone events, rule reactions and actor lifecycle passed")
	quit(0)
