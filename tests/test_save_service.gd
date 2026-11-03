extends SceneTree
## Standalone headless save tests. Never touches the actual player save.

const ParameterRegistry = preload("res://scripts/core/parameter_registry.gd")
const WorldRegistry = preload("res://scripts/core/world_registry.gd")
const SaveService = preload("res://scripts/core/save_service.gd")
const Hackable = preload("res://scripts/hackable_entity.gd")

const TEMP_SAVE := "user://luna_world_test_v1.json"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if FileAccess.file_exists(TEMP_SAVE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEMP_SAVE))
	var parameter_registry = ParameterRegistry.new()
	var world = WorldRegistry.new()
	var player := Node3D.new()
	player.position = Vector3(3, 0.1, 4)
	root.add_child(player)
	var fridge = Hackable.new()
	var tree = Hackable.new()
	root.add_child(fridge)
	root.add_child(tree)
	fridge.configure("fridge_test", "fridge", Vector3(2, 0.1, -1), parameter_registry, world)
	tree.configure("tree_test", "tree", Vector3(-3, 0.1, -2), parameter_registry, world)
	assert(world.register_entity("luna", player, "LUNA"))
	assert(world.register_entity("fridge_test", fridge, "FRIDGE"))
	assert(world.register_entity("tree_test", tree, "TREE"))
	assert(world.list_ids().size() == 3)

	var save = SaveService.new(TEMP_SAVE)
	assert(not save.has_save())
	assert(fridge.set_parameter("alive", true))
	assert(fridge.set_parameter("ai_enabled", false))
	assert(fridge.set_parameter("behavior_mode", "FOLLOW"))
	assert(fridge.set_parameter("color", Color("f49fc9")))
	assert(fridge.set_parameter("speed", 4.2))
	assert(fridge.set_parameter("health", 42))
	assert(tree.set_parameter("size", 1.6))
	assert(save.save_world(world, player))
	assert(save.has_save())
	assert(save.save_world(world, player)) # Replace an existing save safely.
	var packed: Dictionary = save.snapshot(world, player)
	assert(packed["version"] == SaveService.FORMAT_VERSION)
	assert(packed["entities"].size() == 2)
	assert(packed["entities"]["fridge_test"]["parameters"]["color"]["type"] == "color")

	fridge.position = Vector3(-5, 0.1, -5)
	player.position = Vector3(-8, 0.1, 2)
	fridge.set_parameter("alive", false)
	fridge.set_parameter("color", Color("87bfe8"))
	fridge.set_parameter("health", 100)
	tree.set_parameter("size", 0.5)
	assert(save.load_world(world, player))
	assert(fridge.position.distance_to(Vector3(2, 0.1, -1)) < 0.001)
	assert(player.position.distance_to(Vector3(3, 0.1, 4)) < 0.001)
	assert(fridge.get_parameter("alive") == true)
	assert(fridge.get_parameter("ai_enabled") == false)
	assert(fridge.get_parameter("behavior_mode") == "FOLLOW")
	assert(fridge.get_parameter("color") == Color("f49fc9"))
	assert(fridge.get_parameter("health") == 42)
	assert(is_equal_approx(float(fridge.get_parameter("speed")), 4.2))
	assert(is_equal_approx(float(tree.get_parameter("size")), 1.6))
	assert(fridge.record.category == "fridge")

	# Invalid data must be rejected without partial mutation.
	var corrupt: Dictionary = save.snapshot(world, player)
	corrupt["entities"]["tree_test"]["parameters"]["health"] = "oops"
	fridge.set_parameter("health", 29)
	assert(not save.apply_snapshot(corrupt, world, player))
	assert(fridge.get_parameter("health") == 29)
	var mismatch: Dictionary = save.snapshot(world, player)
	mismatch["version"] = 99
	assert(not save.apply_snapshot(mismatch, world, player))
	assert(fridge.get_parameter("health") == 29)

	# Truncated / unreadable JSON is rejected, not silently used.
	var damaged := FileAccess.open(TEMP_SAVE, FileAccess.WRITE)
	assert(damaged != null)
	damaged.store_string("{broken JSON!")
	damaged.close()
	assert(not save.load_world(world, player))
	assert(fridge.get_parameter("health") == 29)

	# A clean re-save can recover from a corrupted file.
	assert(save.save_world(world, player))
	assert(save.load_world(world, player))
	assert(fridge.get_parameter("health") == 29)

	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEMP_SAVE))
	fridge.free()
	tree.free()
	player.free()
	print("LUNA 0.5: versioned save, restore and corruption tests passed")
	quit(0)
