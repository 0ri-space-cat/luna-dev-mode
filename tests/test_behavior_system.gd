extends SceneTree
## Headless behavior tests: world lookup, modes, smooth steering, and safety.

const Registry = preload("res://scripts/core/parameter_registry.gd")
const WorldRegistry = preload("res://scripts/core/world_registry.gd")
const Brain = preload("res://scripts/systems/behavior_brain.gd")
const Hackable = preload("res://scripts/hackable_entity.gd")


func _initialize() -> void:
	var parameters = Registry.new()
	var world = WorldRegistry.new()
	var fridge = Hackable.new()
	var tree = Hackable.new()
	var luna := Node3D.new()
	fridge.configure("fridge_001", "fridge", Vector3(1, 0, 0), parameters, world)
	tree.configure("tree_001", "tree", Vector3(6, 0, 0), parameters, world)
	luna.position = Vector3(4, 0, 0)
	# Node3D.global_position is only valid after the nodes enter SceneTree.
	root.add_child(fridge)
	root.add_child(tree)
	root.add_child(luna)
	assert(world.register_entity("fridge_001", fridge, "FRIDGE"))
	assert(world.register_entity("tree_001", tree, "TREE"))
	assert(world.register_entity("luna", luna, "LUNA"))
	assert(not world.register_entity("luna", luna, "LUNA"))
	assert(world.count_live() == 3)
	assert(world.get_entity("tree_001") == tree)
	var found: Array[Dictionary] = world.candidates("fridge_001", fridge.position, "TREE", 10.0)
	assert(found.size() == 1)
	assert(found[0]["id"] == "tree_001")
	assert(world.candidates("fridge_001", fridge.position, "TREE", 3.0).is_empty())
	assert(world.candidates("fridge_001", fridge.position, "LUNA", 4.0).size() == 1)
	assert(world.candidates("fridge_001", fridge.position, "ANY", 10.0).size() == 2)
	assert(fridge.set_parameter("alive", true))
	assert(fridge.set_parameter("behavior_mode", "FOLLOW"))
	assert(tree.set_parameter("behavior_mode", "FLEE"))
	assert(tree.record.category == "tree")

	var target: Array[Dictionary] = [{"id": "luna", "position": Vector3(6, 0, 0), "group": "LUNA"}]
	var props: Dictionary = fridge.record.parameters.duplicate()
	props["speed"] = 2.0
	props["behavior_mode"] = "FOLLOW"
	var brain = Brain.new(1234)
	var motion := Vector3.ZERO
	for i in range(20):
		motion = brain.calculate(0.05, Vector3.ZERO, props, target)
	assert(brain.last_decision == "FOLLOW")
	assert(brain.last_target_id == "luna")
	assert(motion.x > 0.5)
	assert(absf(motion.length() - 2.0) < 0.25)

	props["behavior_mode"] = "FLEE"
	brain = Brain.new(1234)
	var near_target: Array[Dictionary] = [{"id": "luna", "position": Vector3(1, 0, 0)}]
	for i in range(20):
		motion = brain.calculate(0.05, Vector3.ZERO, props, near_target)
	assert(brain.last_decision == "FLEE")
	assert(motion.x < -0.5)

	props["behavior_mode"] = "IDLE"
	assert(brain.calculate(0.05, Vector3.ZERO, props, target) == Vector3.ZERO)

	props["behavior_mode"] = "AUTO"
	props["luna_relation"] = "FRIEND"
	brain = Brain.new(1234)
	for i in range(20):
		motion = brain.calculate(0.05, Vector3.ZERO, props, target)
	assert(brain.last_decision == "FOLLOW")
	assert(motion.x > 0.1)

	props["luna_relation"] = "AFRAID"
	brain = Brain.new(1234)
	for i in range(20):
		motion = brain.calculate(0.05, Vector3.ZERO, props, near_target)
	assert(brain.last_decision == "FLEE")
	assert(motion.x < -0.1)

	props["ai_enabled"] = false
	assert(brain.calculate(0.05, Vector3.ZERO, props, target) == Vector3.ZERO)
	props["ai_enabled"] = true
	props["alive"] = false
	assert(brain.calculate(0.05, Vector3.ZERO, props, target) == Vector3.ZERO)

	props["alive"] = true
	props["behavior_mode"] = "WANDER"
	brain = Brain.new(4321)
	var max_length := 0.0
	var moved_ticks := 0
	for i in range(240):
		motion = brain.calculate(0.05, Vector3.ZERO, props, [])
		max_length = maxf(max_length, motion.length())
		if motion.length() > 0.2:
			moved_ticks += 1
	assert(max_length <= 2.01)
	assert(moved_ticks > 100)

	props["behavior_mode"] = "CHASE"
	motion = brain.calculate(0.05, Vector3.ZERO, props, [])
	assert(brain.last_decision == "WANDER" or brain.last_decision == "IDLE")
	world.unregister_entity("tree_001")
	assert(world.get_entity("tree_001") == null)
	assert(world.count_live() == 2)
	fridge.free()
	tree.free()
	luna.free()
	print("LUNA 0.3: world targeting and behavior tests passed")
	quit(0)
