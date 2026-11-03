extends SceneTree
## Elemental gameplay: damage over time, slow/stun, counter-magic, restoration.

const Registry = preload("res://scripts/core/parameter_registry.gd")
const World = preload("res://scripts/core/world_registry.gd")
const Commands = preload("res://scripts/core/command_processor.gd")
const Effects = preload("res://scripts/core/effect_engine.gd")
const Statuses = preload("res://scripts/core/elemental_status_service.gd")
const Spells = preload("res://scripts/core/spell_service.gd")
const SaveService = preload("res://scripts/core/save_service.gd")
const Hackable = preload("res://scripts/hackable_entity.gd")

const TEST_PATH := "user://luna_status_test.json"
var reactions: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _record_reaction(info: Dictionary) -> void:
	reactions.append(str(info["reaction"]))


func _run() -> void:
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	var registry = Registry.new()
	var world = World.new()
	var commands = Commands.new()
	var effects = Effects.new(world, commands)
	var conditions = Statuses.new(world, effects)
	var spells = Spells.new(world, effects, conditions)
	conditions.reaction_triggered.connect(_record_reaction)
	var luna := Node3D.new()
	var fridge = Hackable.new()
	var tree = Hackable.new()
	root.add_child(luna)
	root.add_child(fridge)
	root.add_child(tree)
	luna.position = Vector3(0, 0, 3)
	fridge.configure("fridge", "fridge", Vector3.ZERO, registry, world, null, {}, conditions)
	tree.configure("tree", "tree", Vector3(1.5, 0, 0), registry, world, null, {}, conditions)
	assert(world.register_entity("luna", luna, "LUNA"))
	assert(world.register_entity("fridge", fridge, "FRIDGE"))
	assert(world.register_entity("tree", tree, "TREE"))
	assert(fridge.elemental_statuses == conditions)
	assert(not conditions.apply_element("unknown", "FIRE"))
	assert(not conditions.apply_element("fridge", "POISON"))
	assert(conditions.movement_factor("fridge") == 1.0)

	# A fiery explosion attaches BURN to every valid target, after impact only.
	assert(spells.cast_spell("FIREBALL", "luna", "fridge"))
	assert(conditions.get_state("fridge").is_empty())
	assert(spells.resolve_impact("FIREBALL", "luna", "fridge"))
	assert(fridge.get_parameter("health") == 76)
	assert(tree.get_parameter("health") == 41)
	assert(conditions.has_status("fridge", "BURN"))
	assert(conditions.has_status("tree", "BURN"))
	conditions.advance(1.0)
	assert(fridge.get_parameter("health") == 74)
	assert(tree.get_parameter("health") == 39)
	assert(commands.get_recent_audit(1)[0]["source_id"] == "element:BURN")

	# Ice quenches burning, then makes an actor visibly slower in physics.
	assert(spells.resolve_impact("FROST_SHARD", "luna", "fridge"))
	assert(fridge.get_parameter("health") == 64)
	assert(not conditions.has_status("fridge", "BURN"))
	assert(conditions.has_status("fridge", "CHILL"))
	assert(is_equal_approx(conditions.movement_factor("fridge"), 0.45))
	assert(reactions.has("QUENCH"))

	# Electricity interacts with ice: longer total stun, consuming the chill.
	assert(spells.resolve_impact("ARC_BOLT", "luna", "fridge"))
	assert(not conditions.has_status("fridge", "CHILL"))
	assert(conditions.has_status("fridge", "SHOCK"))
	assert(is_equal_approx(conditions.get_state("fridge")["SHOCK"]["remaining"], 2.5))
	assert(conditions.movement_factor("fridge") == 0.0)
	assert(reactions.has("SUPERCONDUCT"))
	conditions.advance(1.0)
	conditions.advance(1.0)
	assert(conditions.has_status("fridge", "SHOCK"))
	conditions.advance(0.6)
	assert(not conditions.has_status("fridge", "SHOCK"))
	assert(conditions.movement_factor("fridge") == 1.0)

	# Electricity + fire accelerates the existing burn pulse rate.
	var tree_health: int = tree.get_parameter("health")
	assert(conditions.apply_element("tree", "STORM"))
	assert(reactions.has("OVERLOAD"))
	assert(is_equal_approx(conditions.get_state("tree")["BURN"]["interval"], 0.5))
	conditions.advance(0.5)
	assert(tree.get_parameter("health") == tree_health - 2)

	# Fire on ice creates STEAM: the cold is gone, burn returns shortened.
	assert(conditions.apply_element("fridge", "FROST"))
	assert(conditions.apply_element("fridge", "FIRE"))
	assert(reactions.has("STEAM"))
	assert(not conditions.has_status("fridge", "CHILL"))
	assert(is_equal_approx(conditions.get_state("fridge")["BURN"]["remaining"], 2.5))

	# Save/restore typed elemental state, including timer progress.
	var save = SaveService.new(TEST_PATH)
	assert(save.save_world(world, luna, null, conditions))
	var persisted: Dictionary = save.snapshot(world, luna, null, conditions)
	assert(persisted["elemental_statuses"]["entities"].has("tree"))
	conditions.import_data({})
	assert(not conditions.has_status("fridge", "BURN"))
	assert(save.load_world(world, luna, null, Callable(), null, conditions))
	assert(conditions.has_status("fridge", "BURN"))
	assert(conditions.get_state("tree")["BURN"]["interval"] == 0.5)

	# A malformed status payload cannot corrupt the existing scene or states.
	var invalid: Dictionary = persisted.duplicate(true)
	invalid["elemental_statuses"]["entities"]["tree"]["BURN"]["remaining"] = "forever"
	var old_health: int = tree.get_parameter("health")
	assert(not save.apply_snapshot(invalid, world, luna, null, Callable(), null, conditions))
	assert(tree.get_parameter("health") == old_health)
	assert(conditions.has_status("tree", "BURN"))
	assert(conditions.validate_data({})) # Legacy save with no statuses.

	fridge.free()
	tree.free()
	luna.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	print("LUNA 0.13: elemental status, interactions and saves passed")
	quit(0)
