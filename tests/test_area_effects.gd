extends SceneTree
## ON_HIT BURST shares a typed target selector and one atomic effect batch.

const Registry = preload("res://scripts/core/parameter_registry.gd")
const World = preload("res://scripts/core/world_registry.gd")
const Commands = preload("res://scripts/core/command_processor.gd")
const Effects = preload("res://scripts/core/effect_engine.gd")
const Resolver = preload("res://scripts/core/target_resolver.gd")
const Spells = preload("res://scripts/core/spell_service.gd")
const Workshop = preload("res://scripts/core/spell_workshop_service.gd")
const Grammar = preload("res://scripts/core/arcane_grammar.gd")
const Hackable = preload("res://scripts/hackable_entity.gd")

const PATH := "user://luna_burst_test.json"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	var registry = Registry.new()
	var world = World.new()
	var commands = Commands.new()
	var effects = Effects.new(world, commands)
	var spells = Spells.new(world, effects)
	var luna := Node3D.new()
	var fridge = Hackable.new()
	var near_tree = Hackable.new()
	var far_tree = Hackable.new()
	root.add_child(luna)
	root.add_child(fridge)
	root.add_child(near_tree)
	root.add_child(far_tree)
	fridge.configure("fridge", "fridge", Vector3.ZERO, registry, world)
	near_tree.configure("near_tree", "tree", Vector3(1.5, 0, 0), registry, world)
	far_tree.configure("far_tree", "tree", Vector3(8, 0, 0), registry, world)
	luna.position = Vector3(0, 0, 3)
	assert(world.register_entity("luna", luna, "LUNA"))
	assert(world.register_entity("fridge", fridge, "FRIDGE"))
	assert(world.register_entity("near_tree", near_tree, "TREE"))
	assert(world.register_entity("far_tree", far_tree, "TREE"))
	var ids: Array[String] = Resolver.around(world, "fridge", 2.5)
	assert(ids.has("fridge"))
	assert(ids.has("near_tree"))
	assert(not ids.has("far_tree"))
	assert(not ids.has("luna"))
	assert(ids[0] == "fridge")
	assert(Resolver.around(world, "fridge", -1.0).is_empty())

	var fireball: Dictionary = spells.get_spell("FIREBALL")
	assert(fireball["impact"]["mode"] == "BURST")
	assert(is_equal_approx(float(fireball["impact"]["radius"]), 2.5))
	assert(spells.cast_spell("FIREBALL", "luna", "fridge"))
	assert(fridge.get_parameter("health") == 100)
	assert(near_tree.get_parameter("health") == 65)
	assert(spells.resolve_impact("FIREBALL", "luna", "fridge"))
	assert(fridge.get_parameter("health") == 76)
	assert(near_tree.get_parameter("health") == 41)
	assert(far_tree.get_parameter("health") == 65)
	assert(commands.undo())
	assert(fridge.get_parameter("health") == 100)
	assert(near_tree.get_parameter("health") == 65)
	assert(commands.redo())
	assert(fridge.get_parameter("health") == 76)
	assert(near_tree.get_parameter("health") == 41)

	# If a single ON_HIT operation is invalid, no affected actor changes.
	var before_events := commands.get_audit_log().size()
	assert(not effects.apply_to_targets([
		{"operation": "ADD", "parameter_id": "health", "value": -8},
		{"operation": "SET", "parameter_id": "color", "value": "INVALID"}
	], ids, "luna", "test:bad_burst"))
	assert(fridge.get_parameter("health") == 76)
	assert(near_tree.get_parameter("health") == 41)
	assert(commands.get_audit_log().size() == before_events)

	assert(not spells.register_spell({
		"id": "BAD_BURST", "label": "INVALID", "cast_range": 5.0,
		"manifestation": Grammar.make("ORB", "FIRE"),
		"impact": {"mode": "BURST", "radius": 99.0},
		"effects": [{"operation": "ADD", "parameter_id": "health", "value": -5}]
	}))
	var workshop = Workshop.new(registry, spells, PATH)
	var new_name: String = workshop.create_recipe(
		"Снежный взрыв", 11.0,
		[{"operation": "ADD", "parameter_id": "health", "value": -7}],
		Grammar.make("ORB", "FROST"),
		{"mode": "BURST", "radius": 1.5}
	)
	assert(new_name == "CUSTOM_001")
	var refreshed_spells = Spells.new(world, effects)
	var refreshed = Workshop.new(registry, refreshed_spells, PATH)
	assert(refreshed.load_library())
	assert(refreshed_spells.get_spell("CUSTOM_001")["impact"]["mode"] == "BURST")
	assert(is_equal_approx(float(refreshed_spells.get_spell("CUSTOM_001")["impact"]["radius"]), 1.5))
	fridge.free()
	near_tree.free()
	far_tree.free()
	luna.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	print("LUNA 0.12: atomic area effects and saved explosions passed")
	quit(0)
