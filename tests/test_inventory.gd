extends SceneTree
## 0.26: world items remain hackable entities while carried.
const SaveService = preload("res://scripts/core/save_service.gd")
const PATH := "user://luna_inventory_026.json"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	var stage = load("res://scenes/main.tscn").instantiate()
	root.add_child(stage)
	stage.save_service = SaveService.new(PATH)
	var items = stage.inventory_service
	var world = stage.world_registry
	var commands = stage.command_processor
	var abilities = stage.ability_service
	var fridge: Node3D = world.get_entity("fridge_001")
	var tree: Node3D = world.get_entity("tree_001")
	var luna: Node3D = stage.luna
	assert(fridge != null and tree != null and items != null)
	assert(items.make_pickup("fridge_001", 4.0))
	assert(items.list_items("luna").is_empty())
	assert(not items.pickup("luna", "fridge_001")) # Out of reach
	luna.position = fridge.position + Vector3(0, 0, 1)
	assert(items.pickup("luna", "fridge_001"))
	assert(items.list_items("luna") == ["fridge_001"])
	assert(fridge.record.category == "fridge")
	assert(not fridge.visible)
	assert(fridge.collision_layer == 0)

	# The carried fridge can cast an independently granted ability from
	# Luna's current position. Provenance identifies both carrier and item.
	assert(abilities.register_ability({
		"id": "HEAL_ITEM", "range": 8.0,
		"effects": [{"operation": "ADD", "parameter_id": "health", "value": 4}]
	}))
	assert(abilities.grant("fridge_001", "HEAL_ITEM"))
	var old_hp: int = int(tree.get_parameter("health"))
	assert(items.use("luna", "fridge_001", "HEAL_ITEM", "tree_001"))
	assert(tree.get_parameter("health") == old_hp + 4)
	assert(commands.get_recent_audit(1)[0]["initiator_id"] == "luna")
	assert(commands.get_recent_audit(1)[0]["source_id"] == "ability:HEAL_ITEM@fridge_001")

	# Copying a carried entity must not auto-insert an extra copy into the bag.
	var duplicate: Node3D = stage._duplicate_entity(fridge)
	assert(duplicate != null and duplicate.visible)
	assert(items.list_items("luna") == ["fridge_001"])
	assert(duplicate.record.has_component("PICKUP"))
	assert(duplicate.record.get_component("PICKUP")["holder_id"] == "")

	# Inventories on other beings use exactly the same item IDs as Luna.
	tree.position = luna.position + Vector3(1, 0, 0)
	assert(items.add_inventory("tree_001", 1, 5.0))
	assert(items.transfer("luna", "tree_001", "fridge_001"))
	assert(items.list_items("tree_001") == ["fridge_001"])
	assert(items.list_items("luna").is_empty())
	assert(not commands.execute_entity_delete(stage.entity_lifecycle, "tree_001"))
	assert(world.get_entity("tree_001") != null)
	assert(items.make_pickup("tree_001", 2.0))
	assert(items.add_inventory("fridge_001", 1, 5.0))
	assert(not items.pickup("fridge_001", "tree_001")) # Ownership cycle
	assert(items.transfer("tree_001", "luna", "fridge_001"))
	# Return the fridge to the tree for a valid checkpoint.
	assert(items.transfer("luna", "tree_001", "fridge_001"))

	var drop_pos: Vector3 = tree.position + Vector3(0, 0, 1)
	assert(items.drop("tree_001", "fridge_001", drop_pos))
	assert(fridge.visible)
	assert(fridge.collision_layer != 0)
	assert(fridge.position == drop_pos)
	assert(commands.undo())
	assert(not fridge.visible)
	assert(items.list_items("tree_001") == ["fridge_001"])
	assert(commands.redo())
	assert(fridge.visible)
	assert(items.pickup("luna", "fridge_001"))
	assert(items.list_items("luna") == ["fridge_001"])
	stage._save_checkpoint(false)
	assert(stage.save_service.has_save())

	# A loaded game restores the same item ownership and physical presence.
	assert(items.drop("luna", "fridge_001", luna.position + Vector3(1, 0, 0)))
	assert(fridge.visible)
	stage._load_checkpoint(false)
	assert(items.list_items("luna") == ["fridge_001"])
	assert(not world.get_entity("fridge_001").visible)
	assert(world.get_entity("fridge_001").collision_layer == 0)

	var bad: Dictionary = stage.save_service.snapshot(world, luna,
		stage.relationship_service, stage.elemental_status_service,
		stage.surface_field_service, stage.social_awareness, stage.rule_engine)
	bad["entities"]["fridge_001"]["components"]["PICKUP"]["holder_id"] = "missing_actor"
	var before_position: Vector3 = luna.position
	assert(not stage.save_service.apply_snapshot(bad, world, luna,
		stage.relationship_service, Callable(stage, "_restore_arcane_actor"),
		stage.parameter_registry, stage.elemental_status_service,
		stage.surface_field_service, stage.social_awareness,
		Callable(stage, "_restore_saved_duplicate"), stage.rule_engine,
		Callable(stage, "_remove_saved_entity"), Callable(stage, "_restore_base_actor")))
	assert(luna.position == before_position)
	assert(items.list_items("luna") == ["fridge_001"])

	stage.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	print("LUNA 0.26: entity inventory, transfer, copy, drop, use and save passed")
	quit(0)
