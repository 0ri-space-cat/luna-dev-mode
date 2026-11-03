extends SceneTree
## Graybox 0.19: composable player rules, priority, safeguards and checkpoints.
const Registry = preload("res://scripts/core/parameter_registry.gd")
const World = preload("res://scripts/core/world_registry.gd")
const Commands = preload("res://scripts/core/command_processor.gd")
const Effects = preload("res://scripts/core/effect_engine.gd")
const RuleEngine = preload("res://scripts/core/rule_engine.gd")
const EventBus = preload("res://scripts/core/event_bus.gd")
const SaveService = preload("res://scripts/core/save_service.gd")
const Hackable = preload("res://scripts/hackable_entity.gd")
const PATH := "user://luna_rules_019_test.json"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	var registry = Registry.new()
	var world = World.new()
	var commands = Commands.new()
	var effects = Effects.new(world, commands)
	var rules = RuleEngine.new(effects)
	var bus = EventBus.new()
	var player := Node3D.new()
	root.add_child(player)
	assert(world.register_entity("luna", player, "LUNA"))
	var fridge = Hackable.new()
	var tree = Hackable.new()
	root.add_child(fridge)
	root.add_child(tree)
	fridge.configure("fridge_test", "fridge", Vector3.ZERO, registry, world)
	tree.configure("tree_test", "tree", Vector3(2, 0, 0), registry, world)
	assert(world.register_entity("fridge_test", fridge, "FRIDGE"))
	assert(world.register_entity("tree_test", tree, "TREE"))

	var complex_rule := {
		"id": "luna:guard_tree", "owner_id": "fridge_test",
		"event_type": "entity.target_acquired", "target": "EVENT_TARGET",
		"author_id": "luna", "priority": 10, "repeat_limit": 2,
		"where": {"all": [
			{"field": "payload.group", "op": "EQ", "value": "TREE"},
			{"any": [
				{"field": "payload.alert", "op": "GT", "value": 2},
				{"not": {"field": "payload.friendly", "op": "EQ", "value": true}}
			]}
		]},
		"effects": [{"operation": "ADD", "parameter_id": "health", "value": -10}]
	}
	assert(rules.register_rule(complex_rule))
	assert(not rules.register_rule(complex_rule))
	var invalid: Dictionary = complex_rule.duplicate(true)
	invalid["id"] = "bad:eval"
	invalid["effects"] = [{"operation": "UNSAFE_EVAL", "parameter_id": "health"}]
	assert(not rules.register_rule(invalid))
	invalid = complex_rule.duplicate(true)
	invalid["id"] = "bad:condition"
	invalid["where"] = {"not": {"field": "payload.group", "op": "RUN_CODE", "value": "TREE"}}
	assert(not rules.register_rule(invalid))
	assert(rules.count_rules() == 1)

	# Both predicates must cooperate; nothing executes on a false match.
	assert(bus.enqueue({"type": "entity.target_acquired", "source_id": "fridge_test",
		"target_id": "tree_test", "payload": {"group": "TREE", "friendly": true, "alert": 1}}))
	assert(bus.drain(rules) == 1)
	assert(tree.get_parameter("health") == 65)
	assert(rules.fired_count("luna:guard_tree") == 0)

	assert(bus.enqueue({"type": "entity.target_acquired", "source_id": "fridge_test",
		"target_id": "tree_test", "payload": {"group": "TREE", "friendly": true, "alert": 3}}))
	assert(bus.drain(rules) == 1)
	assert(tree.get_parameter("health") == 55)
	assert(bus.enqueue({"type": "entity.target_acquired", "source_id": "fridge_test",
		"target_id": "tree_test", "payload": {"group": "TREE", "friendly": false, "alert": 0}}))
	assert(bus.drain(rules) == 1)
	assert(tree.get_parameter("health") == 45)
	assert(rules.fired_count("luna:guard_tree") == 2)
	assert(bus.enqueue({"type": "entity.target_acquired", "source_id": "fridge_test",
		"target_id": "tree_test", "payload": {"group": "TREE", "friendly": false, "alert": 9}}))
	assert(bus.drain(rules) == 1)
	assert(tree.get_parameter("health") == 45) # Lifetime quota exhausted.

	# Priority is deterministic. Both changes keep real provenance.
	assert(rules.register_rule({
		"id": "high", "owner_id": "fridge_test", "event_type": "entity.target_acquired",
		"target": "EVENT_TARGET", "priority": 50,
		"effects": [{"operation": "SET", "parameter_id": "color", "value": Color("87bfe8")}]
	}))
	assert(rules.register_rule({
		"id": "low", "owner_id": "fridge_test", "event_type": "entity.target_acquired",
		"target": "EVENT_TARGET", "priority": -50,
		"effects": [{"operation": "SET", "parameter_id": "color", "value": Color("f49fc9")}]
	}))
	assert(bus.enqueue({"type": "entity.target_acquired", "source_id": "fridge_test",
		"target_id": "tree_test", "payload": {"group": "OTHER"}}))
	assert(bus.drain(rules) == 1)
	assert(tree.get_parameter("color") == Color("f49fc9"))
	var audit: Array[Dictionary] = commands.get_recent_audit(2)
	assert(audit[0]["source_id"] == "rule:low")
	assert(audit[1]["source_id"] == "rule:high")
	assert(rules.get_rule("high")["priority"] == 50)
	assert(rules.replace_rule({
		"id": "high", "owner_id": "fridge_test", "event_type": "entity.target_acquired",
		"target": "EVENT_TARGET", "enabled": false,
		"effects": [{"operation": "SET", "parameter_id": "color", "value": Color("87bfe8")}]
	}))
	assert(rules.get_rule("high")["enabled"] == false)

	# JSON stores plain data, no nodes; Color gets an explicit typed envelope.
	var save = SaveService.new(PATH)
	assert(save.save_world(world, player, null, null, null, null, rules))
	var snapshot: Dictionary = save.snapshot(world, player, null, null, null, null, rules)
	assert(snapshot["rules"]["version"] == 1)
	assert(snapshot["rules"]["rules"].size() == 3)
	for rule in snapshot["rules"]["rules"]:
		if rule["id"] == "low":
			assert(rule["effects"][0]["value"]["type"] == "color")
	assert(snapshot["rules"]["fired"]["luna:guard_tree"] == 2)

	rules.remove_rule("low")
	tree.set_parameter("health", 100)
	tree.set_parameter("color", Color("b790dd"))
	var restored_ok: bool = save.load_world(world, player, null, Callable(), null,
		null, null, null, Callable(), rules)
	if not restored_ok:
		push_error("RULE CHECKPOINT RESTORE FAILED: %s" % save.last_error)
		quit(1)
		return
	assert(restored_ok)
	assert(rules.count_rules() == 3)
	assert(rules.fired_count("luna:guard_tree") == 2)
	assert(rules.get_rule("low")["effects"][0]["value"] == Color("f49fc9"))
	assert(tree.get_parameter("health") == 45)
	assert(tree.get_parameter("color") == Color("f49fc9"))

	# Invalid rule syntax blocks the entire load before touching any Entity.
	var broken: Dictionary = snapshot.duplicate(true)
	broken["rules"]["rules"][0]["where"] = {"any": []}
	tree.set_parameter("health", 32)
	assert(not save.apply_snapshot(broken, world, player, null, Callable(), null,
		null, null, null, Callable(), rules))
	assert(tree.get_parameter("health") == 32)
	assert(rules.count_rules() == 3)

	# Compatibility: older saves (no rules section) preserve built-in rules.
	var old_snapshot: Dictionary = snapshot.duplicate(true)
	old_snapshot.erase("rules")
	assert(save.apply_snapshot(old_snapshot, world, player, null, Callable(), null,
		null, null, null, Callable(), rules))
	assert(rules.count_rules() == 3)

	fridge.free()
	tree.free()
	player.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	print("LUNA 0.19: composable rules, caps, provenance and checkpoint safety passed")
	quit(0)
