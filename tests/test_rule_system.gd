extends SceneTree
## Headless integration tests of bounded events, rules, effects and undo.

const Registry = preload("res://scripts/core/parameter_registry.gd")
const WorldRegistry = preload("res://scripts/core/world_registry.gd")
const Commands = preload("res://scripts/core/command_processor.gd")
const Bus = preload("res://scripts/core/event_bus.gd")
const EffectEngine = preload("res://scripts/core/effect_engine.gd")
const RuleEngine = preload("res://scripts/core/rule_engine.gd")
const Hackable = preload("res://scripts/hackable_entity.gd")

var bus


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var registry = Registry.new()
	var world = WorldRegistry.new()
	var commands = Commands.new()
	bus = Bus.new()
	var effects = EffectEngine.new(world, commands)
	var rules = RuleEngine.new(effects)
	var fridge = Hackable.new()
	var tree = Hackable.new()
	fridge.configure("fridge_test", "fridge", Vector3.ZERO, registry, world)
	tree.configure("tree_test", "tree", Vector3(3, 0, 0), registry, world)
	root.add_child(fridge)
	root.add_child(tree)
	assert(world.register_entity("fridge_test", fridge, "FRIDGE"))
	assert(world.register_entity("tree_test", tree, "TREE"))

	assert(effects.apply(
		{"operation": "SET", "parameter_id": "color", "value": Color("8ed7bd")},
		"tree_test", "luna", "spell:paint"
	))
	assert(tree.get_parameter("color") == Color("8ed7bd"))
	var audit = commands.get_recent_audit(1)
	assert(audit[0]["source_id"] == "spell:paint")
	assert(audit[0]["initiator_id"] == "luna")
	assert(commands.undo())
	assert(tree.get_parameter("color") == Color("b790dd"))
	assert(commands.redo())
	assert(tree.get_parameter("color") == Color("8ed7bd"))

	assert(effects.apply({"operation": "ADD", "parameter_id": "speed", "value": 10.0}, "tree_test", "luna", "debug"))
	assert(is_equal_approx(float(tree.get_parameter("speed")), 5.0))
	assert(effects.apply({"operation": "TOGGLE", "parameter_id": "alive"}, "tree_test", "luna", "debug"))
	assert(tree.get_parameter("alive") == true)
	assert(not effects.apply({"operation": "TOGGLE", "parameter_id": "color"}, "tree_test", "luna", "debug"))
	assert(not effects.apply({"operation": "UNSAFE_EVAL", "parameter_id": "health"}, "tree_test", "luna", "debug"))
	assert(not effects.apply({"operation": "SET", "parameter_id": "unknown", "value": 5}, "tree_test", "luna", "debug"))

	assert(rules.register_rule({
		"id": "on_tree_spotted",
		"owner_id": "fridge_test",
		"event_type": "entity.target_acquired",
		"target": "EVENT_TARGET",
		"conditions": [{"field": "group", "equals": "TREE"}],
		"effects": [{"operation": "SET", "parameter_id": "color", "value": Color("f49fc9")}]
	}))
	assert(not rules.register_rule({"id": "on_tree_spotted", "owner_id": "", "event_type": "any", "target": "RULE_OWNER", "effects": [{"operation": "SET", "parameter_id": "health", "value": 2}]}))
	assert(bus.enqueue({"type": "entity.target_acquired", "source_id": "fridge_test", "target_id": "tree_test", "payload": {"group": "TREE"}}))
	assert(bus.drain(rules) == 1)
	assert(tree.get_parameter("color") == Color("f49fc9"))
	var last = commands.get_recent_audit(1)
	assert(last[0]["source_id"] == "rule:on_tree_spotted")
	assert(last[0]["initiator_id"] == "entity:fridge_test")
	assert(bus.enqueue({"type": "entity.target_acquired", "source_id": "fridge_test", "target_id": "tree_test", "payload": {"group": "LUNA"}}))
	assert(bus.drain(rules) == 1)
	assert(tree.get_parameter("color") == Color("f49fc9"))

	# A self-reinforcing rule is bounded by MAX_DEPTH rather than crashing.
	assert(rules.register_rule({
		"id": "recursive_size",
		"owner_id": "fridge_test",
		"event_type": "parameter.changed",
		"target": "EVENT_SOURCE",
		"conditions": [{"field": "parameter_id", "equals": "size"}],
		"effects": [{"operation": "ADD", "parameter_id": "size", "value": 0.1}]
	}))
	commands.parameter_changed.connect(_on_changed)
	assert(effects.apply({"operation": "SET", "parameter_id": "size", "value": 0.5}, "fridge_test", "luna", "test:recursive"))
	var processed: int = bus.drain(rules)
	assert(processed > 1)
	assert(processed <= Bus.MAX_PER_DRAIN)
	assert(bus.dropped_count >= 1)
	assert(bus.pending_count() == 0)
	assert(float(fridge.get_parameter("size")) <= 2.0)

	commands.parameter_changed.disconnect(_on_changed)
	rules.remove_rule("recursive_size")
	assert(rules.count_rules() == 1)
	fridge.free()
	tree.free()
	print("LUNA 0.4: effects, rules, provenance and recursion tests passed")
	quit(0)


func _on_changed(change: Dictionary) -> void:
	if str(change.get("action", "")) == "SET":
		bus.enqueue({
			"type": "parameter.changed",
			"source_id": str(change["entity_id"]),
			"target_id": str(change["entity_id"]),
			"payload": {"parameter_id": change["parameter_id"]}
		})
