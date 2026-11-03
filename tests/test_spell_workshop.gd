extends SceneTree
## Generic recipe creation, validation, reloading, and persistence.

const Registry = preload("res://scripts/core/parameter_registry.gd")
const World = preload("res://scripts/core/world_registry.gd")
const Commands = preload("res://scripts/core/command_processor.gd")
const Effects = preload("res://scripts/core/effect_engine.gd")
const Spells = preload("res://scripts/core/spell_service.gd")
const Workshop = preload("res://scripts/core/spell_workshop_service.gd")
const JsonStore = preload("res://scripts/core/json_store.gd")
const Hackable = preload("res://scripts/hackable_entity.gd")

const TEMP_PATH := "user://luna_workshop_test.json"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if FileAccess.file_exists(TEMP_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEMP_PATH))
	var registry = Registry.new()
	var world = World.new()
	var commands = Commands.new()
	var engine = Effects.new(world, commands)
	var spells = Spells.new(world, engine)
	var workshop = Workshop.new(registry, spells, TEMP_PATH)
	assert(workshop.available_fields().size() >= 11)
	assert(not workshop.has_library())

	var actions: Array[Dictionary] = [
		{"operation": "SET", "parameter_id": "alive", "value": true},
		{"operation": "SET", "parameter_id": "color", "value": Color("f49fc9")},
		{"operation": "ADD", "parameter_id": "speed", "value": 0.5}
	]
	var new_id: String = workshop.create_recipe("Холодильниковый кошмар", 13.0, actions)
	assert(new_id == "CUSTOM_001")
	assert(spells.contains_spell(new_id))
	assert(workshop.has_library())
	assert(workshop.list_user_spells().size() == 1)
	assert(workshop.create_recipe("Invalid spell", 13.0,
		[{"operation": "TOGGLE", "parameter_id": "speed"}]).is_empty())
	assert(workshop.list_user_spells().size() == 1)

	var saved: Dictionary = JsonStore.read_document(TEMP_PATH)
	assert(saved["ok"])
	assert(saved["data"]["recipes"][0]["effects"][1]["value"].has("color_hex"))

	var second_spells = Spells.new(world, engine)
	var reloaded = Workshop.new(registry, second_spells, TEMP_PATH)
	assert(reloaded.load_library())
	assert(reloaded.list_user_spells().size() == 1)
	assert(second_spells.contains_spell("CUSTOM_001"))
	assert(second_spells.get_spell("CUSTOM_001")["effects"][1]["value"] == Color("f49fc9"))

	# Can cast a user recipe from a fresh SpellService instance.
	var fridge = Hackable.new()
	var luna := Node3D.new()
	root.add_child(fridge)
	root.add_child(luna)
	fridge.configure("fridge", "fridge", Vector3(3, 0, 0), registry, world)
	assert(world.register_entity("fridge", fridge, "FRIDGE"))
	assert(world.register_entity("luna", luna, "LUNA"))
	assert(second_spells.cast_spell("CUSTOM_001", "luna", "fridge"))
	assert(fridge.get_parameter("alive"))
	assert(fridge.get_parameter("color") == Color("f49fc9"))
	assert(is_equal_approx(float(fridge.get_parameter("speed")), 3.1))
	assert(commands.undo())
	assert(fridge.get_parameter("alive") == false)

	# Corrupted file must not register ANY of its recipes.
	var malicious: Dictionary = saved["data"].duplicate(true)
	malicious["recipes"].append({
		"id": "CUSTOM_099", "label": "malicious", "cast_range": 10,
		"effects": [{"operation": "SCRIPT", "parameter_id": "speed", "value": 3}]
	})
	assert(JsonStore.write_document(TEMP_PATH, malicious)["ok"])
	var third_spells = Spells.new(world, engine)
	var invalid_library = Workshop.new(registry, third_spells, TEMP_PATH)
	assert(not invalid_library.load_library())
	assert(not third_spells.contains_spell("CUSTOM_001"))
	assert(not third_spells.contains_spell("CUSTOM_099"))

	# Duplicate names are acceptable, but IDs are generated distinctly.
	assert(workshop.create_recipe("Холодильниковый кошмар", 10.0,
		[{"operation": "TOGGLE", "parameter_id": "alive"}]) == "CUSTOM_002")
	assert(workshop.list_user_spells().size() == 2)

	fridge.free()
	luna.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEMP_PATH))
	print("LUNA 0.9: spell workshop persistence and validation passed")
	quit(0)
