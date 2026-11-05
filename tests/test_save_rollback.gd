extends SceneTree
## 0.26: failure injection tests for snapshot apply and inventory references.
const ParameterRegistry = preload("res://scripts/core/parameter_registry.gd")
const WorldRegistry = preload("res://scripts/core/world_registry.gd")
const SaveService = preload("res://scripts/core/save_service.gd")
const Hackable = preload("res://scripts/hackable_entity.gd")
const FailingEntity = preload("res://tests/helpers/failing_entity.gd")
const PATH := "user://luna_save_rollback_026.json"
var scene


func _initialize() -> void:
	call_deferred("_run")


func _remove_first_then_fail(entity_id: String) -> bool:
	if entity_id == "tree_001":
		return scene._remove_saved_entity(entity_id)
	return false


func _run() -> void:
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	var registry = ParameterRegistry.new()
	var world = WorldRegistry.new()
	var player := Node3D.new()
	root.add_child(player)
	assert(world.register_entity("luna", player, "LUNA"))
	var first = Hackable.new()
	var last = FailingEntity.new()
	root.add_child(first)
	root.add_child(last)
	first.configure("a_tree", "tree", Vector3(-3, 0.1, 0), registry, world)
	last.configure("z_fridge", "fridge", Vector3(3, 0.1, 0), registry, world)
	assert(world.register_entity("a_tree", first, "TREE"))
	assert(world.register_entity("z_fridge", last, "FRIDGE"))
	var save = SaveService.new(PATH)
	assert(first.set_parameter("health", 51))
	assert(last.set_parameter("health", 42))
	var desired: Dictionary = save.snapshot(world, player)
	assert(first.set_parameter("health", 11))
	assert(last.set_parameter("health", 9))
	player.position = Vector3(4, 0, 2)
	first.position = Vector3(5, 0, 5)
	last.rejected_health = 42
	assert(not save.apply_snapshot(desired, world, player))
	assert("Failed to restore health" in save.last_error)
	assert(first.get_parameter("health") == 11)
	assert(last.get_parameter("health") == 9)
	assert(first.position == Vector3(5, 0, 5))
	assert(player.position == Vector3(4, 0, 2))
	assert(world.list_ids().size() == 3)
	last.free()
	first.free()
	player.free()

	# A callback that fails after deleting the first of two actors must
	# restore the first actor, its ID, and unrelated state.
	scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	scene.save_service = SaveService.new(PATH)
	var live_world = scene.world_registry
	var tree: Node3D = live_world.get_entity("tree_001")
	var fridge: Node3D = live_world.get_entity("fridge_001")
	var before_hp: int = int(fridge.get_parameter("health"))
	var bad: Dictionary = scene.save_service.snapshot(live_world, scene.luna,
		scene.relationship_service, scene.elemental_status_service,
		scene.surface_field_service, scene.social_awareness, scene.rule_engine)
	bad["entities"].erase("tree_001")
	bad["entities"].erase("tree_002")
	bad["deleted_entities"] = ["tree_001", "tree_002"]
	bad["entities"]["fridge_001"]["parameters"]["health"] = 20
	assert(not scene.save_service.apply_snapshot(bad, live_world, scene.luna,
		scene.relationship_service, Callable(scene, "_restore_arcane_actor"),
		scene.parameter_registry, scene.elemental_status_service,
		scene.surface_field_service, scene.social_awareness,
		Callable(scene, "_restore_saved_duplicate"), scene.rule_engine,
		Callable(self, "_remove_first_then_fail"), Callable(scene, "_restore_base_actor")))
	assert(live_world.get_entity("tree_001") != null)
	assert(live_world.get_entity("tree_002") != null)
	assert(not live_world.was_deleted("tree_001"))
	assert(fridge.get_parameter("health") == before_hp)
	assert(scene.save_service.last_error.contains("Unable to apply deletion"))
	scene.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	print("LUNA 0.26: snapshot rollback after actor setter and deletion callback failure passed")
	quit(0)
