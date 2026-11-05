extends SceneTree
## Components are data: typed, copyable, undoable and version-safe.
const SaveService = preload("res://scripts/core/save_service.gd")
const PATH := "user://luna_components_026_test.json"


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
	var fridge: Node3D = world.get_entity("fridge_001")
	assert(fridge != null)
	assert(not fridge.record.has_component("INTERACTION"))
	assert(not fridge.record.set_component("ANY_SCRIPT", {"enabled": true}))
	assert(not fridge.record.set_component("INTERACTION", {"reach": 999.0}))
	assert(not fridge.record.set_component("INTERACTION", {"verb": "EXECUTE"}))
	assert(fridge.record.get_components().is_empty())

	assert(commands.execute_component(fridge, "SET_COMPONENT", "INTERACTION",
		{"verb": "OPEN", "reach": 3.5}, "luna", "wand:luna"))
	assert(fridge.record.has_component("INTERACTION"))
	assert(fridge.record.get_component("INTERACTION")["verb"] == "OPEN")
	assert(fridge.record.get_component("INTERACTION")["enabled"] == true)
	var mutable_copy: Dictionary = fridge.record.get_components()
	mutable_copy["INTERACTION"]["reach"] = 8.0
	assert(fridge.record.get_component("INTERACTION")["reach"] == 3.5)
	assert(commands.get_recent_audit(1)[0]["source_id"] == "wand:luna")
	assert(commands.undo())
	assert(not fridge.record.has_component("INTERACTION"))
	assert(commands.redo())
	assert(fridge.record.get_component("INTERACTION")["reach"] == 3.5)

	# Copy is independent; deleting the source does not erase the copy.
	var copy: Node3D = stage._duplicate_entity(fridge)
	assert(copy != null and copy.record.has_component("INTERACTION"))
	assert(copy.record.get_component("INTERACTION")["verb"] == "OPEN")
	assert(copy.record.set_component("INTERACTION", {"verb": "TALK"}))
	assert(fridge.record.get_component("INTERACTION")["verb"] == "OPEN")
	assert(commands.execute_entity_delete(stage.entity_lifecycle, "fridge_001"))
	assert(world.get_entity("fridge_001") == null)
	assert(commands.undo())
	var restored: Node3D = world.get_entity("fridge_001")
	assert(restored != null and restored.record.get_component("INTERACTION")["verb"] == "OPEN")
	assert(world.get_entity(str(copy.record.id)).record.get_component("INTERACTION")["verb"] == "TALK")

	# Typed JSON round trip. Existing saves without this field use empty data.
	var saved: Dictionary = stage.save_service.snapshot(world, stage.luna,
		stage.relationship_service, stage.elemental_status_service,
		stage.surface_field_service, stage.social_awareness, stage.rule_engine)
	assert(saved["entities"]["fridge_001"]["components"]["INTERACTION"]["reach"] == 3.5)
	assert(stage.save_service.save_world(world, stage.luna, stage.relationship_service,
		stage.elemental_status_service, stage.surface_field_service,
		stage.social_awareness, stage.rule_engine))
	assert(fridge.record.remove_component("INTERACTION") or not is_instance_valid(fridge))
	assert(stage.save_service.load_world(world, stage.luna,
		stage.relationship_service, Callable(stage, "_restore_arcane_actor"),
		stage.parameter_registry, stage.elemental_status_service,
		stage.surface_field_service, stage.social_awareness,
		Callable(stage, "_restore_saved_duplicate"), stage.rule_engine,
		Callable(stage, "_remove_saved_entity"), Callable(stage, "_restore_base_actor")))
	assert(world.get_entity("fridge_001").record.has_component("INTERACTION"))
	var bad: Dictionary = saved.duplicate(true)
	bad["entities"]["fridge_001"]["components"]["INTERACTION"]["reach"] = 77.0
	var tree: Node3D = world.get_entity("tree_001")
	tree.position = Vector3(12, 0, 12)
	assert(not stage.save_service.apply_snapshot(bad, world, stage.luna,
		stage.relationship_service, Callable(stage, "_restore_arcane_actor"),
		stage.parameter_registry, stage.elemental_status_service,
		stage.surface_field_service, stage.social_awareness,
		Callable(stage, "_restore_saved_duplicate"), stage.rule_engine,
		Callable(stage, "_remove_saved_entity"), Callable(stage, "_restore_base_actor")))
	assert(tree.position == Vector3(12, 0, 12))
	var old: Dictionary = saved.duplicate(true)
	old["entities"]["fridge_001"].erase("components")
	assert(stage.save_service.apply_snapshot(old, world, stage.luna,
		stage.relationship_service, Callable(stage, "_restore_arcane_actor"),
		stage.parameter_registry, stage.elemental_status_service,
		stage.surface_field_service, stage.social_awareness,
		Callable(stage, "_restore_saved_duplicate"), stage.rule_engine,
		Callable(stage, "_remove_saved_entity"), Callable(stage, "_restore_base_actor")))
	assert(not world.get_entity("fridge_001").record.has_component("INTERACTION"))
	stage.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	print("LUNA 0.24: typed component history, cloning and safe saves passed")
	quit(0)
