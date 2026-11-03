extends SceneTree
## Typed Entity classification commands join history, provenance and EventBus.
const SaveService = preload("res://scripts/core/save_service.gd")
const PATH := "user://luna_trait_commands_test.json"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	var stage = load("res://scenes/main.tscn").instantiate()
	root.add_child(stage)
	stage.save_service = SaveService.new(PATH)
	var tree: Node = stage.world_registry.get_entity("tree_001")
	assert(tree != null)
	var commands = stage.command_processor
	assert(not commands.execute_trait(tree, "EVAL", "EVIL"))
	assert(not commands.execute_trait(tree, "ADD_TAG", "bad tag"))
	assert(tree.record.get_tags() == ["NATURE"])

	assert(commands.execute_trait(tree, "ADD_ROLE", "TRADER", "luna", "wand:luna"))
	assert(tree.record.has_role("TRADER"))
	assert(stage.world_registry.query_ids({"role":"TRADER"}) == ["tree_001"])
	var audit: Dictionary = commands.get_recent_audit(1)[0]
	assert(audit["source_id"] == "wand:luna")
	assert(audit["initiator_id"] == "luna")
	assert(audit["action"] == "TRAIT_SET")
	assert(audit["parameter_id"] == "ROLES_TAGS")
	assert(commands.undo())
	assert(not tree.record.has_role("TRADER"))
	assert(commands.get_recent_audit(1)[0]["action"] == "UNDO_TRAITS")
	assert(commands.redo())
	assert(tree.record.has_role("TRADER"))
	assert(commands.get_recent_audit(1)[0]["action"] == "REDO_TRAITS")

	# A real rule can respond to the same event without special-cased tree code.
	stage.event_bus.clear_pending()
	assert(stage.rule_engine.register_rule({
		"id": "luna:celebrate_tags", "owner_id": "tree_001", "author_id": "luna",
		"event_type": "entity.traits_changed", "target": "RULE_OWNER",
		"where": {"all":[
			{"field": "payload.initiator_id", "op": "EQ", "value": "luna"},
			{"field": "payload.command_source_id", "op": "EQ", "value": "wand:luna"}
		]},
		"effects": [{"operation":"ADD", "parameter_id":"speed", "value":0.5}],
		"repeat_limit": 1
	}))
	var previous_speed: float = float(tree.get_parameter("speed"))
	assert(commands.execute_trait(tree, "ADD_TAG", "FRUIT_BEARING", "luna", "wand:luna"))
	assert(tree.record.has_tag("FRUIT_BEARING"))
	assert(stage.event_bus.pending_count() == 1)
	assert(stage.event_bus.drain(stage.rule_engine) >= 1)
	assert(is_equal_approx(float(tree.get_parameter("speed")), previous_speed + 0.5))
	assert(stage.rule_engine.fired_count("luna:celebrate_tags") == 1)
	assert(commands.get_recent_audit(1)[0]["source_id"] == "rule:luna:celebrate_tags")

	# Role/tag changes and reactive rules survive a checkpoint.
	assert(stage.save_service.save_world(stage.world_registry, stage.luna,
		stage.relationship_service, stage.elemental_status_service,
		stage.surface_field_service, stage.social_awareness, stage.rule_engine))
	assert(commands.execute_trait(tree, "REMOVE_ROLE", "TRADER"))
	assert(not tree.record.has_role("TRADER"))
	assert(stage.save_service.load_world(stage.world_registry, stage.luna,
		stage.relationship_service, Callable(stage, "_restore_arcane_actor"),
		stage.parameter_registry, stage.elemental_status_service,
		stage.surface_field_service, stage.social_awareness,
		Callable(stage, "_restore_saved_duplicate"), stage.rule_engine))
	assert(tree.record.has_role("TRADER"))
	assert(tree.record.has_tag("FRUIT_BEARING"))
	assert(stage.rule_engine.get_rule("luna:celebrate_tags")["author_id"] == "luna")
	assert(stage.rule_engine.fired_count("luna:celebrate_tags") == 1)

	stage.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	print("LUNA 0.20: command provenance, trait undo/redo and reactive rules passed")
	quit(0)
