extends SceneTree
## v0.9: effect chains must be all-or-nothing, including relationships.

const Registry = preload("res://scripts/core/parameter_registry.gd")
const World = preload("res://scripts/core/world_registry.gd")
const Commands = preload("res://scripts/core/command_processor.gd")
const Relations = preload("res://scripts/core/relationship_service.gd")
const Effects = preload("res://scripts/core/effect_engine.gd")
const Spells = preload("res://scripts/core/spell_service.gd")
const Hackable = preload("res://scripts/hackable_entity.gd")

var events := 0


func _initialize() -> void:
	call_deferred("_run")


func _on_changed(_change: Dictionary) -> void:
	events += 1


func _run() -> void:
	var registry = Registry.new()
	var world = World.new()
	var commands = Commands.new()
	var relations = Relations.new()
	var effects = Effects.new(world, commands, relations)
	var spells = Spells.new(world, effects)
	var fridge = Hackable.new()
	var tree = Hackable.new()
	var luna := Node3D.new()
	root.add_child(fridge)
	root.add_child(tree)
	root.add_child(luna)
	fridge.configure("fridge", "fridge", Vector3(1, 0, 0), registry, world, relations)
	tree.configure("tree", "tree", Vector3(3, 0, 0), registry, world, relations)
	assert(world.register_entity("fridge", fridge, "FRIDGE"))
	assert(world.register_entity("tree", tree, "TREE"))
	assert(world.register_entity("luna", luna, "LUNA"))
	commands.parameter_changed.connect(_on_changed)

	var initial_speed: float = float(fridge.get_parameter("speed"))
	var tx: Array = [
		{"operation": "ADD", "parameter_id": "speed", "value": 0.5},
		{"operation": "MULTIPLY", "parameter_id": "speed", "value": 1.5},
		{"operation": "SET", "parameter_id": "alive", "value": true}
	]
	assert(effects.apply_batch(tx, "fridge", "luna", "spell:COMBO"))
	assert(is_equal_approx(float(fridge.get_parameter("speed")), 4.7))
	assert(fridge.get_parameter("alive") == true)
	assert(events == 3)
	assert(commands.get_recent_audit(1)[0]["source_id"] == "spell:COMBO")
	assert(commands.undo()) # Undo the whole three-effect spell as ONE action.
	assert(is_equal_approx(float(fridge.get_parameter("speed")), initial_speed))
	assert(fridge.get_parameter("alive") == false)
	assert(events == 6)
	assert(not commands.can_undo())
	assert(commands.redo())
	assert(is_equal_approx(float(fridge.get_parameter("speed")), 4.7))
	assert(fridge.get_parameter("alive") == true)

	# Invalid tail cannot leave a half-cast spell.
	var before_events := events
	var before_audit := commands.get_audit_log().size()
	var bad: Array = [
		{"operation": "SET", "parameter_id": "alive", "value": false},
		{"operation": "SET", "parameter_id": "health", "value": "many"}
	]
	assert(not effects.apply_batch(bad, "fridge", "luna", "spell:BROKEN"))
	assert(fridge.get_parameter("alive") == true)
	assert(events == before_events)
	assert(commands.get_audit_log().size() == before_audit)

	# Social changes are part of the SAME transaction and undo group.
	var mixed: Array = [
		{"operation": "SET", "parameter_id": "health", "value": 33},
		{"operation": "SET_RELATION", "subject_id": "tree", "value": "FRIEND"},
		{"operation": "ADD", "parameter_id": "health", "value": 7}
	]
	assert(effects.apply_batch(mixed, "fridge", "luna", "spell:FRIENDSHIP"))
	assert(fridge.get_parameter("health") == 40)
	assert(relations.get_attitude("tree", "fridge") == "FRIEND")
	assert(commands.undo())
	assert(fridge.get_parameter("health") == 100)
	assert(relations.get_attitude("tree", "fridge") == "NEUTRAL")
	assert(commands.redo())
	assert(fridge.get_parameter("health") == 40)
	assert(relations.get_attitude("tree", "fridge") == "FRIEND")

	var invalid_social: Array = [
		{"operation": "SET", "parameter_id": "health", "value": 1},
		{"operation": "SET_RELATION", "subject_id": "tree", "value": "DANCING"}
	]
	assert(not effects.apply_batch(invalid_social, "fridge", "luna", "spell:BAD_SOCIAL"))
	assert(fridge.get_parameter("health") == 40)
	assert(relations.get_attitude("tree", "fridge") == "FRIEND")

	# Another system changed the state after a preview: stale plans are rejected.
	var planned: Dictionary = effects.preview_batch(
		[{"operation": "SET", "parameter_id": "health", "value": 21}], "fridge")
	assert(planned["ok"])
	assert(fridge.set_parameter("health", 60))
	var stored: Array[Dictionary] = planned["steps"]
	assert(not commands.execute_batch(stored, "luna", "stale:preview"))
	assert(fridge.get_parameter("health") == 60)

	# A custom multi-effect spell uses the same transaction code.
	assert(spells.register_spell({
		"id": "LIVE_AND_FAST", "label": "LIVE_AND_FAST", "cast_range": 15.0,
		"effects": [
			{"operation": "SET", "parameter_id": "alive", "value": true},
			{"operation": "SET", "parameter_id": "speed", "value": 2.3}
		]
	}))
	assert(spells.cast_spell("LIVE_AND_FAST", "luna", "fridge"))
	assert(is_equal_approx(float(fridge.get_parameter("speed")), 2.3))
	assert(commands.undo())
	assert(is_equal_approx(float(fridge.get_parameter("speed")), 4.7))

	fridge.free()
	tree.free()
	luna.free()
	print("LUNA 0.9: atomic transactions and mixed effects passed")
	quit(0)
