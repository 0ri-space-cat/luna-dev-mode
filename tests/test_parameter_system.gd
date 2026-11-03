extends SceneTree
## Launch with:
## godot --headless --path . --script res://tests/test_parameter_system.gd

const Registry = preload("res://scripts/core/parameter_registry.gd")
const Record = preload("res://scripts/core/entity_record.gd")
const Commands = preload("res://scripts/core/command_processor.gd")
const Hackable = preload("res://scripts/hackable_entity.gd")


func _initialize() -> void:
	var registry = Registry.new()
	var fridge = Hackable.new()
	fridge.configure("fridge_test", "fridge", Vector3.ZERO, registry)
	var tree = Hackable.new()
	tree.configure("tree_test", "tree", Vector3.ZERO, registry)

	assert(registry.get_specs_for("fridge").size() == 12)
	assert(fridge.record.category == "fridge")
	assert(tree.record.category == "tree")
	assert(fridge.get_parameter("alive") == false)
	assert(fridge.get_parameter("ai_enabled") == true)
	assert(fridge.get_parameter("behavior_mode") == "WANDER")
	assert(registry.normalize("fridge", "behavior_mode", "CHASE")["ok"])
	assert(not registry.normalize("fridge", "behavior_mode", "UNDEFINED")["ok"])
	assert(tree.get_parameter("health") == 65)

	# Typed values and clamping are shared between every entity.
	var checked: Dictionary = registry.normalize("fridge", "speed", 999.0)
	assert(checked["ok"])
	assert(is_equal_approx(float(checked["value"]), 5.0))
	assert(not registry.normalize("fridge", "alive", 123)["ok"])
	assert(not registry.normalize("tree", "unknown", true)["ok"])

	# Register a fridge-only field without changing any UI script.
	assert(registry.register_parameter({
		"id": "compressor_on", "label": "COMPRESSOR_ON",
		"kind": "bool", "default": true,
		"hint": "Тестовый параметр холодильника.",
		"categories": ["fridge"]
	}))
	assert(not registry.get_spec("fridge", "compressor_on").is_empty())
	assert(registry.get_spec("tree", "compressor_on").is_empty())
	var extra_record = Record.new("fridge_extra", "fridge", "Холодильник", registry)
	assert(extra_record.get_parameter("compressor_on") == true)

	var commands = Commands.new()
	assert(commands.execute_set(fridge, "alive", true, "luna", "wand:luna"))
	assert(fridge.get_parameter("alive") == true)
	assert(fridge.record.category == "fridge")
	assert(commands.execute_set(fridge, "ai_enabled", false, "luna", "wand:luna"))
	assert(fridge.get_parameter("ai_enabled") == false)
	assert(commands.undo())
	assert(fridge.get_parameter("ai_enabled") == true)
	assert(commands.redo())
	assert(fridge.get_parameter("ai_enabled") == false)

	# One drag gesture is one undoable action, with separate audit records.
	var initial_size: float = float(fridge.get_parameter("size"))
	assert(commands.execute_set(fridge, "size", 1.3, "luna", "wand:luna", "drag_test"))
	assert(commands.execute_set(fridge, "size", 1.6, "luna", "wand:luna", "drag_test"))
	assert(is_equal_approx(float(fridge.get_parameter("size")), 1.6))
	assert(commands.undo())
	assert(is_equal_approx(float(fridge.get_parameter("size")), initial_size))
	assert(commands.redo())
	assert(is_equal_approx(float(fridge.get_parameter("size")), 1.6))

	# Yuki uses the exact same command system with a different identity.
	assert(commands.execute_set(tree, "color", Color("f49fc9"), "yuki", "terminal:yuki"))
	var audit = commands.get_recent_audit(1)
	assert(audit.size() == 1)
	assert(audit[0]["initiator_id"] == "yuki")
	assert(audit[0]["source_id"] == "terminal:yuki")
	assert(audit[0]["entity_id"] == "tree_test")
	assert(commands.undo())
	assert(tree.get_parameter("color") == Color("b790dd"))

	# Invalid types never change object state or add undo records.
	var old_health: int = int(fridge.get_parameter("health"))
	assert(not registry.normalize("fridge", "health", "a lot")["ok"])
	assert(fridge.get_parameter("health") == old_health)
	assert(commands.get_audit_log().size() >= 6)

	fridge.free()
	tree.free()
	print("LUNA 0.2: all parameter and command smoke assertions passed")
	quit(0)
