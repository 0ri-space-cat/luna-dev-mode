extends SceneTree
## 0.20 entity classification: immutable origin, composable roles and safe saves.
const SaveService = preload("res://scripts/core/save_service.gd")
const TEMP_PATH := "user://luna_traits_test.json"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if FileAccess.file_exists(TEMP_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEMP_PATH))
	var stage = load("res://scenes/main.tscn").instantiate()
	root.add_child(stage)
	stage.save_service = SaveService.new(TEMP_PATH)
	var tree: Node3D = stage.world_registry.get_entity("tree_001") as Node3D
	var fridge: Node3D = stage.world_registry.get_entity("fridge_001") as Node3D
	assert(tree != null and fridge != null)
	assert(tree.record.category == "tree")
	assert(tree.record.get_stored_roles() == ["PLANT"])
	assert(tree.record.get_roles() == ["PLANT"])
	assert(tree.record.get_tags() == ["NATURE"])
	assert(fridge.record.get_stored_roles() == ["MACHINE", "OBJECT"])
	assert(not stage.world_registry.query_ids({"role": "CREATURE"}).has("tree_001"))
	assert(tree.set_parameter("alive", true))
	assert(tree.record.has_role("CREATURE"))
	assert(tree.record.category == "tree")
	assert(tree.record.get_stored_roles() == ["PLANT"]) # Life is a derived role.
	assert(tree.set_parameter("alive", false))
	assert(not tree.record.has_role("CREATURE"))
	assert(tree.record.has_role("PLANT"))

	assert(tree.record.add_role("TRADER"))
	assert(tree.record.add_tag("FRUIT_BEARING"))
	assert(not tree.record.add_tag("FRUIT_BEARING"))
	assert(not tree.record.add_tag("invalid"))
	assert(not tree.record.set_traits(["TRADER", "TRADER"], ["NATURE"]))
	assert(tree.record.has_role("TRADER"))
	assert(tree.record.has_tag("FRUIT_BEARING"))
	assert(stage.world_registry.query_ids({"category": "tree", "role": "TRADER",
		"tag": "FRUIT_BEARING"}) == ["tree_001"])
	assert(stage.world_registry.query_ids({"tag": "FRUIT_BEARING", "alive": false}) == ["tree_001"])
	assert(stage.world_registry.query_ids({"unknown": "whatever"}).is_empty())

	# COPY has an independent identity, while classifications and parameters
	# are copied as values rather than sharing the original record.
	var copy: Node3D = stage._duplicate_entity(tree)
	assert(copy != null)
	var copy_id: String = str(copy.record.id)
	assert(copy.record.category == "tree")
	assert(copy.record.has_role("TRADER"))
	assert(copy.record.has_tag("FRUIT_BEARING"))
	assert(copy.record.remove_tag("FRUIT_BEARING"))
	assert(tree.record.has_tag("FRUIT_BEARING"))
	assert(stage.world_registry.query_ids({"role": "TRADER"}).has(copy_id))
	assert(stage.world_registry.query_ids({"role": "CREATURE"}).is_empty())

	assert(stage.save_service.save_world(stage.world_registry, stage.luna,
		stage.relationship_service, stage.elemental_status_service,
		stage.surface_field_service, stage.social_awareness, stage.rule_engine))
	var snapshot: Dictionary = stage.save_service.snapshot(stage.world_registry, stage.luna,
		stage.relationship_service, stage.elemental_status_service,
		stage.surface_field_service, stage.social_awareness, stage.rule_engine)
	assert(snapshot["entities"]["tree_001"]["roles"].has("TRADER"))
	assert(snapshot["entities"][copy_id]["tags"] == ["NATURE"])

	tree.record.remove_role("TRADER")
	tree.record.remove_tag("FRUIT_BEARING")
	assert(stage.save_service.load_world(stage.world_registry, stage.luna,
		stage.relationship_service, Callable(stage, "_restore_arcane_actor"),
		stage.parameter_registry, stage.elemental_status_service,
		stage.surface_field_service, stage.social_awareness,
		Callable(stage, "_restore_saved_duplicate"), stage.rule_engine))
	assert(tree.record.has_role("TRADER"))
	assert(tree.record.has_tag("FRUIT_BEARING"))
	assert(not copy.record.has_tag("FRUIT_BEARING"))

	# Reject invalid traits before moving or modifying any entity.
	var invalid: Dictionary = snapshot.duplicate(true)
	invalid["entities"]["tree_001"]["tags"] = ["VALID", "bad lowercase"]
	tree.position = Vector3(7, 0, 7)
	assert(not stage.save_service.apply_snapshot(invalid, stage.world_registry, stage.luna,
		stage.relationship_service, Callable(stage, "_restore_arcane_actor"),
		stage.parameter_registry, stage.elemental_status_service,
		stage.surface_field_service, stage.social_awareness,
		Callable(stage, "_restore_saved_duplicate"), stage.rule_engine))
	assert(tree.position == Vector3(7, 0, 7))
	assert(tree.record.has_tag("FRUIT_BEARING"))

	# Earlier saves without classifications load with category-based defaults.
	var legacy: Dictionary = snapshot.duplicate(true)
	legacy["entities"]["tree_001"].erase("roles")
	legacy["entities"]["tree_001"].erase("tags")
	assert(stage.save_service.apply_snapshot(legacy, stage.world_registry, stage.luna,
		stage.relationship_service, Callable(stage, "_restore_arcane_actor"),
		stage.parameter_registry, stage.elemental_status_service,
		stage.surface_field_service, stage.social_awareness,
		Callable(stage, "_restore_saved_duplicate"), stage.rule_engine))
	assert(tree.record.category == "tree")
	assert(tree.record.get_stored_roles() == ["PLANT"])
	assert(tree.record.get_tags() == ["NATURE"])

	stage.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEMP_PATH))
	print("LUNA 0.20: immutable origin, independent traits, selectors and saves passed")
	quit(0)
