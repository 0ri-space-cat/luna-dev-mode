extends SceneTree
## 0.21 integration: deletions are reversible world facts, not lost nodes.
const SaveService = preload("res://scripts/core/save_service.gd")
const PATH := "user://luna_lifecycle_test_021.json"

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	var stage = load("res://scenes/main.tscn").instantiate()
	root.add_child(stage)
	stage.save_service = SaveService.new(PATH)
	var commands = stage.command_processor
	var life = stage.entity_lifecycle
	var world = stage.world_registry
	var fridge: Node3D = world.get_entity("fridge_001") as Node3D
	assert(fridge != null)
	assert(not life.validate_blueprint({"id": "luna", "category": "tree"}))
	assert(not commands.execute_entity_delete(life, "luna"))
	assert(fridge.set_parameter("alive", true))
	assert(fridge.set_parameter("health", 37))
	assert(fridge.record.add_role("TRADER"))
	assert(fridge.record.add_tag("FOOD"))
	assert(stage.relationship_service.set_attitude("fridge_001", "luna", "FRIEND"))
	assert(stage.relationship_service.set_attitude("tree_001", "fridge_001", "HOSTILE"))
	assert(stage.elemental_status_service.apply_element("fridge_001", "FROST"))
	assert(stage.social_awareness.observe_damage("luna", ["fridge_001"]) > 0)
	assert(not stage.social_awareness.get_alert("fridge_001").is_empty())
	var previous_position: Vector3 = fridge.position
	var life_snapshot: Dictionary = life.capture("fridge_001")
	assert(life_snapshot["parameters"]["health"] == 37)

	# DELETE records stable identity, removes all references, leaves the tree.
	assert(commands.execute_entity_delete(life, "fridge_001", "luna", "wand:luna"))
	assert(world.get_entity("fridge_001") == null)
	assert(world.was_deleted("fridge_001"))
	assert(world.get_entity("tree_001") != null)
	assert(stage.relationship_service.get_attitude("fridge_001", "luna") == "NEUTRAL")
	assert(stage.relationship_service.get_attitude("tree_001", "fridge_001") == "NEUTRAL")
	assert(stage.elemental_status_service.get_state("fridge_001").is_empty())
	assert(stage.social_awareness.get_alert("fridge_001").is_empty())
	assert(commands.get_recent_audit(1)[0]["source_id"] == "wand:luna")
	assert(commands.get_recent_audit(1)[0]["action"] == "ENTITY_DELETE")

	# Undo creates a fresh Node with the SAME ID and restores only its data.
	assert(commands.undo())
	var restored: Node3D = world.get_entity("fridge_001") as Node3D
	assert(restored != null and restored != fridge)
	assert(not world.was_deleted("fridge_001"))
	assert(restored.position == previous_position)
	assert(restored.get_parameter("alive") == true)
	assert(restored.get_parameter("health") == 37)
	assert(restored.record.has_role("TRADER"))
	assert(restored.record.has_tag("FOOD"))
	assert(stage.relationship_service.get_attitude("fridge_001", "luna") == "FRIEND")
	assert(stage.relationship_service.get_attitude("tree_001", "fridge_001") == "HOSTILE")
	assert(stage.elemental_status_service.has_status("fridge_001", "CHILL"))
	assert(not stage.social_awareness.get_alert("fridge_001").is_empty())
	assert(commands.get_recent_audit(1)[0]["action"] == "ENTITY_UNDO_DELETE")
	assert(commands.redo())
	assert(world.get_entity("fridge_001") == null)

	# A deletion survives a full checkpoint and loading even if a base object
	# was recreated after saving (e.g. after loading another save).
	stage._save_checkpoint(false)
	var packed: Dictionary = stage.save_service.snapshot(world, stage.luna,
		stage.relationship_service, stage.elemental_status_service,
		stage.surface_field_service, stage.social_awareness, stage.rule_engine)
	assert(packed["deleted_entities"].has("fridge_001"))
	assert(not packed["entities"].has("fridge_001"))
	var fake: Node = stage._restore_base_actor("fridge_001", "fridge", previous_position)
	assert(fake != null)
	assert(world.get_entity("fridge_001") != null)
	stage._load_checkpoint(false)
	assert(world.get_entity("fridge_001") == null)
	assert(world.was_deleted("fridge_001"))

	# Broken tombstones are rejected before mutating any live actor.
	var invalid: Dictionary = packed.duplicate(true)
	invalid["deleted_entities"].append("luna")
	var tree: Node3D = world.get_entity("tree_001") as Node3D
	tree.position = Vector3(6, 0, 5)
	assert(not stage.save_service.apply_snapshot(invalid, world, stage.luna,
		stage.relationship_service, Callable(stage, "_restore_arcane_actor"),
		stage.parameter_registry, stage.elemental_status_service,
		stage.surface_field_service, stage.social_awareness,
		Callable(stage, "_restore_saved_duplicate"), stage.rule_engine,
		Callable(stage, "_remove_saved_entity"), Callable(stage, "_restore_base_actor")))
	assert(tree.position == Vector3(6, 0, 5))

	# Restoring a checkpoint containing the base original recreates it after
	# deletion, without requiring a new world or changing its stable ID.
	assert(life.restore_entity(life_snapshot) != null)
	assert(world.get_entity("fridge_001") != null)
	stage._save_checkpoint(false)
	assert(commands.execute_entity_delete(life, "fridge_001"))
	assert(world.get_entity("fridge_001") == null)
	stage._load_checkpoint(false)
	assert(world.get_entity("fridge_001") != null)
	assert(not world.was_deleted("fridge_001"))
	assert(world.get_entity("fridge_001").get_parameter("health") == 37)
	assert(world.get_entity("fridge_001").record.has_role("TRADER"))

	# COPY is also a real creation command with stable undo/redo identity.
	var source: Node3D = world.get_entity("tree_001") as Node3D
	var copy: Node3D = stage._duplicate_entity(source)
	assert(copy != null)
	var copy_id: String = str(copy.record.id)
	assert(copy_id.begins_with("tree_copy_"))
	assert(commands.get_recent_audit(1)[0]["action"] == "ENTITY_CREATE")
	assert(commands.undo())
	assert(world.get_entity(copy_id) == null)
	assert(world.was_deleted(copy_id))
	assert(commands.redo())
	var redo_copy: Node3D = world.get_entity(copy_id) as Node3D
	assert(redo_copy != null and redo_copy != copy)
	assert(redo_copy.record.category == "tree")
	assert(redo_copy.get_meta("copy_origin") == "tree_001")
	assert(not world.was_deleted(copy_id))

	# Source can disappear without destroying its copies; references stay
	# plain IDs and cannot turn into dangling Node pointers.
	assert(commands.execute_entity_delete(life, "tree_001"))
	assert(world.get_entity(copy_id) != null)
	assert(redo_copy.get_meta("copy_origin") == "tree_001")
	assert(commands.undo())
	assert(world.get_entity("tree_001") != null)

	stage.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	print("LUNA 0.21: delete/undo/redo, references, copies and tombstone saves passed")
	quit(0)
