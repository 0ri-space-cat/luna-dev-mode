extends SceneTree
## Command history remains meaningful after a Node is rebuilt from its ID.
const PATH := "user://luna_history_recreation.json"
const SaveService = preload("res://scripts/core/save_service.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	var stage = load("res://scenes/main.tscn").instantiate()
	root.add_child(stage)
	stage.save_service = SaveService.new(PATH)
	var world = stage.world_registry
	var commands = stage.command_processor
	var original: Node3D = world.get_entity("tree_001")
	assert(commands.world_registry == world)
	assert(original.get_parameter("health") == 65)
	assert(commands.execute_set(original, "health", 80))
	assert(commands.execute_component(original, "SET_COMPONENT", "INTERACTION",
		{"verb": "TALK"}, "luna", "wand:luna"))
	assert(commands.execute_entity_delete(stage.entity_lifecycle, "tree_001"))
	assert(world.get_entity("tree_001") == null)
	assert(commands.undo())
	var restored: Node3D = world.get_entity("tree_001")
	assert(restored != null and restored != original)
	assert(restored.get_parameter("health") == 80)
	assert(restored.record.has_component("INTERACTION"))
	assert(commands.undo())
	assert(not restored.record.has_component("INTERACTION"))
	assert(commands.undo())
	assert(restored.get_parameter("health") == 65)
	assert(commands.redo())
	assert(restored.get_parameter("health") == 80)
	assert(commands.redo())
	assert(restored.record.has_component("INTERACTION"))
	assert(commands.redo())
	assert(world.get_entity("tree_001") == null)
	assert(commands.undo())
	assert(world.get_entity("tree_001") != null)

	stage.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	print("LUNA 0.25: historic parameter and component commands survive entity recreation")
	quit(0)
