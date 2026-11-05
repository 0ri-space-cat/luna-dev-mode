extends SceneTree
## 0.25: abilities are portable data, with one execution engine and real undo.
const PATH := "user://luna_abilities_025.json"
const SaveService = preload("res://scripts/core/save_service.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	var stage = load("res://scenes/main.tscn").instantiate()
	root.add_child(stage)
	stage.save_service = SaveService.new(PATH)
	var abilities = stage.ability_service
	var commands = stage.command_processor
	var world = stage.world_registry
	var tree: Node3D = world.get_entity("tree_001")
	var fridge: Node3D = world.get_entity("fridge_001")
	assert(tree != null and fridge != null)
	assert(not abilities.grant("tree_001", "UNKNOWN"))
	assert(not abilities.register_ability({
		"id": "UNSAFE", "effects": [{"operation": "EVAL", "code": "bad"}]
	}))
	assert(abilities.register_ability({
		"id": "HEAL", "range": 6.0, "cooldown_ms": 5000,
		"effects": [{"operation": "ADD", "parameter_id": "health", "value": 5}]
	}))
	assert(not abilities.register_ability({
		"id": "HEAL", "effects": [{"operation": "TOGGLE", "parameter_id": "alive"}]
	}))
	assert(abilities.grant("tree_001", "HEAL", "luna", "wand:luna"))
	assert(tree.record.has_component("ABILITY_SET"))
	assert(tree.record.get_component("ABILITY_SET")["ids"] == ["HEAL"])
	assert(commands.get_recent_audit(1)[0]["source_id"] == "wand:luna")
	assert(not abilities.grant("tree_001", "HEAL"))
	assert(not abilities.activate("fridge_001", "HEAL", "tree_001"))

	var original_health: int = int(fridge.get_parameter("health"))
	assert(abilities.activate("tree_001", "HEAL", "fridge_001"))
	assert(fridge.get_parameter("health") == original_health + 5)
	assert(commands.get_recent_audit(1)[0]["source_id"] == "ability:HEAL")
	assert(commands.get_recent_audit(1)[0]["initiator_id"] == "tree_001")
	assert(not abilities.activate("tree_001", "HEAL", "fridge_001"))
	assert(commands.undo())
	assert(fridge.get_parameter("health") == original_health)
	assert(commands.redo())
	assert(fridge.get_parameter("health") == original_health + 5)

	# Copied tree inherits the ability without sharing mutable component data.
	var clone: Node3D = stage._duplicate_entity(tree)
	assert(clone != null)
	var clone_id: String = str(clone.record.id)
	assert(clone.record.get_component("ABILITY_SET")["ids"] == ["HEAL"])
	assert(abilities.activate(clone_id, "HEAL", "fridge_001"))
	assert(fridge.get_parameter("health") == original_health + 10)
	assert(abilities.revoke("tree_001", "HEAL"))
	assert(not tree.record.has_component("ABILITY_SET"))
	assert(clone.record.has_component("ABILITY_SET"))
	assert(not abilities.activate("tree_001", "HEAL", "fridge_001"))
	assert(commands.undo())
	assert(tree.record.get_component("ABILITY_SET")["ids"] == ["HEAL"])

	stage._save_checkpoint(false)
	assert(stage.save_service.has_save())
	assert(tree.record.remove_component("ABILITY_SET"))
	stage._load_checkpoint(false)
	assert(world.get_entity("tree_001").record.get_component("ABILITY_SET")["ids"] == ["HEAL"])
	assert(world.get_entity(clone_id).record.get_component("ABILITY_SET")["ids"] == ["HEAL"])
	assert(abilities.activate("tree_001", "HEAL", "fridge_001"))
	assert(not abilities.activate("tree_001", "HEAL", "fridge_001"))

	stage.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	print("LUNA 0.25: portable abilities, undo, independent copies and cooldown recovery passed")
	quit(0)
