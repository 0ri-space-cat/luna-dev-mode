extends SceneTree
## 0.23: deterministic bounded selectors for rules and magic.
const SaveService = preload("res://scripts/core/save_service.gd")
const TargetResolver = preload("res://scripts/core/target_resolver.gd")
const PATH := "user://luna_selector_test_023.json"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	var stage = load("res://scenes/main.tscn").instantiate()
	root.add_child(stage)
	stage.save_service = SaveService.new(PATH)
	var world = stage.world_registry
	var rules = stage.rule_engine
	var effects = stage.effect_engine
	var commands = stage.command_processor
	var tree1: Node = world.get_entity("tree_001")
	var tree2: Node = world.get_entity("tree_002")
	var fridge: Node = world.get_entity("fridge_001")
	assert(tree1 != null and tree2 != null and fridge != null)

	var all_trees := {
		"radius": 9.0, "category": "tree", "role": "PLANT",
		"tag": "NATURE", "max_targets": 2
	}
	assert(TargetResolver.validate_selector(all_trees))
	assert(TargetResolver.select_by_properties(world, "fridge_001", all_trees) == [
		"tree_002", "tree_001"
	])
	assert(TargetResolver.select_by_properties(world, "fridge_001", {
		"radius": 9.0, "role": "PLANT", "max_targets": 1
	}) == ["tree_002"])
	assert(TargetResolver.select_by_properties(world, "fridge_001", {
		"radius": 0.5, "role": "PLANT"
	}).is_empty())
	assert(not TargetResolver.validate_selector({"radius": 13.0}))
	assert(not TargetResolver.validate_selector({"radius": 8.0, "max_targets": 9}))
	assert(not TargetResolver.validate_selector({"radius": 8.0, "script": "OS.execute"}))
	assert(not TargetResolver.validate_selector({"radius": 8.0, "role": "plant"}))
	assert(not TargetResolver.validate_selector({"radius": NAN}))
	assert(not TargetResolver.validate_selector({"radius": 4.0, "relation_direction": "TO_ORIGIN"}))

	assert(tree1.set_parameter("alive", true))
	assert(TargetResolver.select_by_properties(world, "fridge_001", {
		"radius": 9.0, "role": "CREATURE", "alive": true
	}) == ["tree_001"])
	assert(stage.relationship_service.set_attitude("fridge_001", "tree_002", "FRIEND"))
	assert(stage.relationship_service.set_attitude("tree_001", "fridge_001", "HOSTILE"))
	assert(TargetResolver.select_by_properties(world, "fridge_001", {
		"radius": 9.0, "category": "tree", "attitude": "FRIEND"
	}, stage.relationship_service) == ["tree_002"])
	assert(TargetResolver.select_by_properties(world, "fridge_001", {
		"radius": 9.0, "category": "tree",
		"attitude": "HOSTILE", "relation_direction": "TO_ORIGIN"
	}, stage.relationship_service) == ["tree_001"])
	assert(TargetResolver.select_by_properties(world, "fridge_001", {
		"radius": 9.0, "category": "tree", "attitude": "FRIEND"
	}).is_empty())

	var initial_one: float = float(tree1.get_parameter("speed"))
	var initial_two: float = float(tree2.get_parameter("speed"))
	assert(rules.register_rule({
		"id": "test:tagged_trees", "owner_id": "fridge_001",
		"event_type": "test.changed", "target": "SELECTOR",
		"selector_origin": "RULE_OWNER", "selector": all_trees,
		"repeat_limit": 1, "author_id": "luna",
		"effects": [{"operation": "ADD", "parameter_id": "speed", "value": 0.5}]
	}))
	assert(not rules.register_rule({
		"id": "test:hardcoded_selector", "owner_id": "fridge_001",
		"event_type": "test.changed", "target": "SELECTOR",
		"selector": all_trees,
		"effects": [{"operation": "ADD", "target_id": "luna",
			"parameter_id": "speed", "value": 1.0}]
	}))
	assert(stage.event_bus.enqueue({
		"type": "test.changed", "source_id": "fridge_001",
		"target_id": "tree_001", "payload": {}
	}))
	assert(stage.event_bus.drain(rules) >= 1)
	assert(is_equal_approx(float(tree1.get_parameter("speed")), initial_one + 0.5))
	assert(is_equal_approx(float(tree2.get_parameter("speed")), initial_two + 0.5))
	assert(commands.get_recent_audit(1)[0]["source_id"] == "rule:test:tagged_trees")
	assert(rules.fired_count("test:tagged_trees") == 1)
	assert(commands.undo())
	assert(is_equal_approx(float(tree1.get_parameter("speed")), initial_one))
	assert(is_equal_approx(float(tree2.get_parameter("speed")), initial_two))
	assert(commands.redo())
	assert(is_equal_approx(float(tree2.get_parameter("speed")), initial_two + 0.5))

	# A selector may safely choose ONE entity for lifecycle operations.
	assert(rules.register_rule({
		"id": "test:copy_nearest", "owner_id": "fridge_001",
		"event_type": "test.copy_nearest", "target": "SELECTOR",
		"selector": {"radius": 8.0, "role": "PLANT", "max_targets": 1},
		"effects": [{"operation": "COPY_ENTITY"}],
		"repeat_limit": 1
	}))
	assert(stage.event_bus.enqueue({
		"type": "test.copy_nearest", "source_id": "fridge_001",
		"target_id": "tree_001", "payload": {}
	}))
	assert(stage.event_bus.drain(rules) >= 1)
	assert(world.get_entity("tree_copy_0001") != null)
	assert(world.get_entity("tree_copy_0001").get_meta("copy_origin") == "tree_002")

	# A direct multi-target spell shares the same bounded, atomic resolver.
	# Mark the two originals AFTER copying; the duplicate should not be
	# selected merely because it shares their species or ancestry.
	assert(tree1.record.add_tag("NEEDS_HEALING"))
	assert(tree2.record.add_tag("NEEDS_HEALING"))
	var before_one: int = int(tree1.get_parameter("health"))
	var before_two: int = int(tree2.get_parameter("health"))
	assert(stage.spell_service.register_spell({
		"id": "PLANT_MEDICINE", "label": "PLANT_MEDICINE", "cast_range": 20.0,
		"target_selector": {"radius": 9.0, "category": "tree", "role": "PLANT",
			"tag": "NEEDS_HEALING", "max_targets": 2, "include_origin": true},
		"effects": [{"operation": "ADD", "parameter_id": "health", "value": 5}]
	}))
	assert(stage.spell_service.cast_spell("PLANT_MEDICINE", "luna", "tree_002"))
	assert(tree1.get_parameter("health") == before_one + 5)
	assert(tree2.get_parameter("health") == before_two + 5)
	assert(commands.undo())
	assert(tree1.get_parameter("health") == before_one)
	assert(tree2.get_parameter("health") == before_two)
	assert(not stage.spell_service.register_spell({
		"id": "AREA_SELECTOR", "label": "INVALID", "cast_range": 20.0,
		"target_selector": all_trees,
		"impact": {"mode": "BURST", "radius": 3.0},
		"effects": [{"operation": "ADD", "parameter_id": "health", "value": 1}]
	}))

	# Saved selector rules survive JSON (including integral float 2.0).
	stage._save_checkpoint(false)
	assert(stage.save_service.has_save())
	rules.remove_rule("test:tagged_trees")
	assert(not rules.get_rule("test:tagged_trees").has("selector"))
	stage._load_checkpoint(false)
	assert(rules.get_rule("test:tagged_trees")["target"] == "SELECTOR")
	assert(rules.get_rule("test:tagged_trees")["selector"]["role"] == "PLANT")
	assert(rules.fired_count("test:tagged_trees") == 1)

	stage.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	print("LUNA 0.23: bounded selectors, relation filters, rules, spells and JSON passed")
	quit(0)
