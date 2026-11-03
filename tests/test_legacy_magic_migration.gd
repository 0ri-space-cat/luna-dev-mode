extends SceneTree
## Existing player recipes must survive the approved renaming of magic fields.

const Grammar = preload("res://scripts/core/arcane_grammar.gd")
const JsonStore = preload("res://scripts/core/json_store.gd")
const Registry = preload("res://scripts/core/parameter_registry.gd")
const World = preload("res://scripts/core/world_registry.gd")
const Commands = preload("res://scripts/core/command_processor.gd")
const Effects = preload("res://scripts/core/effect_engine.gd")
const Spells = preload("res://scripts/core/spell_service.gd")
const Workshop = preload("res://scripts/core/spell_workshop_service.gd")

const TEST_PATH := "user://luna_legacy_arcane_test.json"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	var legacy: Dictionary = {
		"form": "ORB", "essence": "FIRE", "delivery": "PROJECTILE",
		"speed": 12.0, "size": 0.4
	}
	assert(Grammar.valid(legacy))
	assert(Grammar.normalize(legacy)["create"] == "ENERGY")
	var bad_type: Dictionary = legacy.duplicate(true)
	bad_type["speed"] = "faster"
	assert(not Grammar.valid(bad_type))
	var bad_release: Dictionary = legacy.duplicate(true)
	bad_release["delivery"] = "INSTANT"
	assert(not Grammar.valid(bad_release))

	var raw: Dictionary = {
		"version": 1,
		"recipes": [{
			"id": "CUSTOM_001",
			"label": "СТАРЫЙ ОГНЕННЫЙ ШАР",
			"cast_range": 12.0,
			"manifestation": legacy,
			"effects": [{"operation": "ADD", "parameter_id": "health", "value": -8}]
		}]
	}
	assert(JsonStore.write_document(TEST_PATH, raw)["ok"])
	var registry = Registry.new()
	var world = World.new()
	var commands = Commands.new()
	var effects = Effects.new(world, commands)
	var spells = Spells.new(world, effects)
	var workshop = Workshop.new(registry, spells, TEST_PATH)
	assert(workshop.load_library())
	var manifest: Dictionary = spells.get_spell("CUSTOM_001")["manifestation"]
	assert(manifest["create"] == "ENERGY")
	assert(manifest["shape"] == "ORB")
	assert(manifest["element"] == "FIRE")
	assert(manifest["behavior"] == "SEEK")
	assert(manifest["release"] == "PROJECTILE")
	assert(not manifest.has("form"))
	assert(workshop.save_library())
	var saved: Dictionary = JsonStore.read_document(TEST_PATH)
	assert(saved["ok"])
	assert(saved["data"]["recipes"][0]["manifestation"]["shape"] == "ORB")

	# Reject damaged saves without silently dropping magic or registering
	# otherwise valid effects as a different instant spell.
	var corrupt: Dictionary = saved["data"].duplicate(true)
	corrupt["recipes"][0]["manifestation"] = bad_release
	assert(JsonStore.write_document(TEST_PATH, corrupt)["ok"])
	var fresh_spells = Spells.new(world, effects)
	var fresh_workshop = Workshop.new(registry, fresh_spells, TEST_PATH)
	assert(not fresh_workshop.load_library())
	assert(not fresh_spells.contains_spell("CUSTOM_001"))

	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	print("LUNA 0.11: legacy magic recipe migration passed")
	quit(0)
