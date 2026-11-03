extends SceneTree
## Tests reusable spell definitions, range, effect provenance and casting.

const Registry = preload("res://scripts/core/parameter_registry.gd")
const World = preload("res://scripts/core/world_registry.gd")
const Commands = preload("res://scripts/core/command_processor.gd")
const Effects = preload("res://scripts/core/effect_engine.gd")
const SpellService = preload("res://scripts/core/spell_service.gd")
const Hackable = preload("res://scripts/hackable_entity.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var registry = Registry.new()
	var world = World.new()
	var commands = Commands.new()
	var effects = Effects.new(world, commands)
	var spells = SpellService.new(world, effects)
	var luna := Node3D.new()
	var fridge = Hackable.new()
	root.add_child(luna)
	root.add_child(fridge)
	fridge.configure("fridge_001", "fridge", Vector3(3, 0, 0), registry, world)
	luna.position = Vector3(20, 0, 0)
	assert(world.register_entity("luna", luna, "LUNA"))
	assert(world.register_entity("fridge_001", fridge, "FRIDGE"))
	assert(spells.list_spell_ids() == ["AWAKEN", "PINKIFY", "QUICKEN"])
	assert(not spells.register_spell({"id": "AWAKEN", "label": "DUPLICATE", "cast_range": 9.0, "effects": [{"operation": "TOGGLE", "parameter_id": "alive"}]}))
	assert(not spells.register_spell({"id": "BAD", "label": "BAD", "cast_range": 9.0, "effects": [{"operation": "UNSAFE_EVAL", "parameter_id": "alive"}]}))
	assert(not spells.register_spell({"id": "TOO_FAR", "label": "BAD", "cast_range": 500.0, "effects": [{"operation": "TOGGLE", "parameter_id": "alive"}]}))
	assert(not spells.cast_spell("UNKNOWN", "luna", "fridge_001"))

	assert(not spells.cast_spell("AWAKEN", "luna", "fridge_001"))
	assert(fridge.get_parameter("alive") == false)
	luna.position = Vector3(0, 0, 0)
	assert(spells.cast_spell("AWAKEN", "luna", "fridge_001"))
	assert(fridge.get_parameter("alive") == true)
	assert(commands.get_recent_audit(1)[0]["source_id"] == "spell:AWAKEN")
	assert(commands.get_recent_audit(1)[0]["initiator_id"] == "luna")
	assert(spells.cast_spell("PINKIFY", "luna", "fridge_001"))
	assert(fridge.get_parameter("color") == Color("f49fc9"))
	assert(spells.cast_spell("QUICKEN", "luna", "fridge_001"))
	assert(is_equal_approx(float(fridge.get_parameter("speed")), 3.8))
	assert(spells.get_spell("PINKIFY")["symbol_id"] == "STAR")

	assert(spells.register_spell({
		"id": "CUSTOM_BOOST", "label": "CUSTOM_BOOST", "cast_range": 8.0,
		"effects": [{"operation": "MULTIPLY", "parameter_id": "speed", "value": 2.0}]
	}))
	assert(spells.cast_spell("CUSTOM_BOOST", "luna", "fridge_001"))
	assert(is_equal_approx(float(fridge.get_parameter("speed")), 5.0))
	assert(commands.can_undo())
	assert(commands.undo())
	assert(is_equal_approx(float(fridge.get_parameter("speed")), 3.8))
	assert(not spells.cast_spell("PINKIFY", "nobody", "fridge_001"))
	fridge.free()
	luna.free()
	print("LUNA 0.8: reusable spell casting and effect integration tests passed")
	quit(0)
