extends SceneTree
## Directed social links, AI attitude, typed effects and durable save.

const Relationships = preload("res://scripts/core/relationship_service.gd")
const Registry = preload("res://scripts/core/parameter_registry.gd")
const World = preload("res://scripts/core/world_registry.gd")
const Commands = preload("res://scripts/core/command_processor.gd")
const Effects = preload("res://scripts/core/effect_engine.gd")
const Rules = preload("res://scripts/core/rule_engine.gd")
const Brain = preload("res://scripts/systems/behavior_brain.gd")
const SaveService = preload("res://scripts/core/save_service.gd")
const Hackable = preload("res://scripts/hackable_entity.gd")

const TEST_PATH := "user://luna_social_test_v1.json"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var relations = Relationships.new()
	assert(relations.get_attitude("tree", "fridge") == "NEUTRAL")
	assert(relations.set_attitude("tree", "fridge", "FRIEND", "luna", "wand:luna"))
	assert(relations.get_attitude("tree", "fridge") == "FRIEND")
	assert(relations.get_attitude("fridge", "tree") == "NEUTRAL")
	assert(not relations.set_attitude("tree", "tree", "HOSTILE"))
	assert(not relations.set_attitude("tree", "fridge", "IMPOSSIBLE"))
	assert(relations.get_recent_audit(1)[0]["initiator_id"] == "luna")
	assert(relations.get_recent_audit(1)[0]["source_id"] == "wand:luna")
	var invalid: Dictionary = {"tree": {"fridge": "ALIEN"}}
	assert(not relations.import_data(invalid))
	assert(relations.get_attitude("tree", "fridge") == "FRIEND")
	assert(relations.set_attitude("tree", "fridge", "NEUTRAL"))
	assert(relations.get_attitude("tree", "fridge") == "NEUTRAL")
	assert(relations.export_data().is_empty())

	var registry = Registry.new()
	var world = World.new()
	var commands = Commands.new()
	var effects = Effects.new(world, commands, relations)
	var rules = Rules.new(effects)
	var tree = Hackable.new()
	var fridge = Hackable.new()
	var luna := Node3D.new()
	root.add_child(tree)
	root.add_child(fridge)
	root.add_child(luna)
	tree.configure("tree_001", "tree", Vector3(0, 0, 0), registry, world, relations)
	fridge.configure("fridge_001", "fridge", Vector3(3, 0, 0), registry, world, relations)
	luna.position = Vector3(-2, 0, 0)
	assert(world.register_entity("tree_001", tree, "TREE"))
	assert(world.register_entity("fridge_001", fridge, "FRIDGE"))
	assert(world.register_entity("luna", luna, "LUNA"))

	assert(effects.apply(
		{"operation": "SET_RELATION", "subject_id": "tree_001", "value": "HOSTILE"},
		"fridge_001", "luna", "spell:make_enemy"
	))
	assert(relations.get_attitude("tree_001", "fridge_001") == "HOSTILE")
	assert(relations.get_attitude("fridge_001", "tree_001") == "NEUTRAL")
	assert(relations.get_recent_audit(1)[0]["source_id"] == "spell:make_enemy")
	assert(not effects.apply(
		{"operation": "SET_RELATION", "subject_id": "tree_001", "value": "INVALID"},
		"fridge_001", "luna", "spell:bad"
	))
	assert(relations.get_attitude("tree_001", "fridge_001") == "HOSTILE")

	assert(rules.register_rule({
		"id": "be_friends_when_spotted",
		"owner_id": "fridge_001",
		"event_type": "entity.target_acquired",
		"target": "EVENT_TARGET",
		"effects": [
			{"operation": "SET_RELATION", "subject_id": "fridge_001", "value": "FRIEND"}
		]
	}))
	assert(rules.process_event({
		"type": "entity.target_acquired",
		"source_id": "fridge_001",
		"target_id": "tree_001",
		"payload": {}
	}) == 1)
	assert(relations.get_attitude("fridge_001", "tree_001") == "FRIEND")
	assert(relations.get_attitude("tree_001", "fridge_001") == "HOSTILE")

	# Target-specific attitude drives AUTO. Both directions are distinct.
	var properties: Dictionary = tree.record.parameters.duplicate()
	properties["alive"] = true
	properties["ai_enabled"] = true
	properties["behavior_mode"] = "AUTO"
	properties["target_relation"] = relations.get_attitude("tree_001", "fridge_001")
	var brain = Brain.new(101)
	var targets: Array[Dictionary] = [{"id": "fridge_001", "position": Vector3(3, 0, 0)}]
	var motion := Vector3.ZERO
	for i in range(20):
		motion = brain.calculate(0.05, Vector3.ZERO, properties, targets)
	assert(brain.last_decision == "CHASE")
	assert(motion.x > 0.1)

	# Social links and entity parameters survive the same save/load cycle.
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	var save = SaveService.new(TEST_PATH)
	assert(tree.set_parameter("alive", true))
	assert(save.save_world(world, luna, relations))
	assert(save.snapshot(world, luna, relations)["relationships"]["tree_001"]["fridge_001"] == "HOSTILE")
	assert(relations.set_attitude("tree_001", "fridge_001", "AFRAID"))
	assert(relations.set_attitude("fridge_001", "tree_001", "NEUTRAL"))
	tree.set_parameter("alive", false)
	assert(save.load_world(world, luna, relations))
	assert(tree.get_parameter("alive") == true)
	assert(relations.get_attitude("tree_001", "fridge_001") == "HOSTILE")
	assert(relations.get_attitude("fridge_001", "tree_001") == "FRIEND")

	var corrupt: Dictionary = save.snapshot(world, luna, relations)
	corrupt["relationships"]["tree_001"]["fridge_001"] = "NOT_A_RELATION"
	tree.set_parameter("alive", false)
	assert(not save.apply_snapshot(corrupt, world, luna, relations))
	assert(tree.get_parameter("alive") == false)
	assert(relations.get_attitude("tree_001", "fridge_001") == "HOSTILE")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	tree.free()
	fridge.free()
	luna.free()
	print("LUNA 0.6: directed social graph, rules and save tests passed")
	quit(0)
