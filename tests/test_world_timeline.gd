extends SceneTree

const SaveService = preload("res://scripts/core/save_service.gd")
const ProfileService = preload("res://scripts/core/profile_service.gd")

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var stage = load("res://scenes/main.tscn").instantiate()
	stage.save_service = SaveService.new("user://world_timeline_test/save.json")
	stage.profile_service = ProfileService.new("user://world_timeline_test/profile.json")
	stage.spell_library_path = "user://world_timeline_test/spells.json"
	root.add_child(stage)
	var world = stage.world_registry
	var fridge: Node3D = world.get_entity("fridge_001")
	var tree: Node3D = world.get_entity("tree_001")
	assert(fridge != null and tree != null)
	assert(stage.timeline.checkpoint_count() == 1, stage.timeline.last_error)
	var original_position: Vector3 = stage.luna.position
	var original_health: int = fridge.get_parameter("health")
	assert(stage.elemental_status_service.apply_element("fridge_001", "FROST"))
	var effects: Dictionary = stage.elemental_status_service.export_data()
	assert(not effects.is_empty())
	var first_copy: Node3D = stage._duplicate_entity(fridge)
	assert(first_copy != null)
	var first_id: String = first_copy.record.id
	stage.luna.velocity = Vector3(2, -1, 3)
	stage.timeline.advance(0.1)
	assert(stage.timeline.capture_checkpoint(), stage.timeline.last_error)

	assert(stage.command_processor.execute_entity_delete(stage.entity_lifecycle, first_id))
	assert(stage.command_processor.execute_entity_delete(stage.entity_lifecycle, "tree_001"))
	var later_copy: Node3D = stage._duplicate_entity(fridge)
	assert(later_copy != null)
	var later_id: String = later_copy.record.id
	assert(fridge.set_parameter("health", 1))
	stage.luna.position += Vector3(4, 0, 0)
	stage.luna.velocity = Vector3.ZERO
	assert(stage.rewind_world_checkpoint(), stage.timeline.last_error)
	assert(stage.luna.position == original_position)
	assert(stage.luna.velocity == Vector3(2, -1, 3))
	assert(fridge.get_parameter("health") == original_health)
	assert(world.get_entity(first_id) != null)
	assert(world.get_entity("tree_001") != null)
	assert(world.get_entity(later_id) == null)
	assert(stage.elemental_status_service.export_data() == effects)
	assert(stage.rewind_world_checkpoint(true))
	assert(world.get_entity(first_id) == null)

	assert(stage.set_camera_mode("FOLLOW"))
	var pose: Transform3D = stage.camera.global_transform
	assert(stage.set_camera_mode("LOCKED"))
	assert(not stage.set_camera_mode("INVALID"))
	stage.luna.position += Vector3(2, 0, 1)
	stage._process(0.0)
	assert(stage.camera.global_transform == pose)
	assert(stage.set_camera_mode("FOLLOW"))
	assert(stage.camera.global_transform != pose)
	stage.save_service = null
	stage.free()
	print("World timeline restores state, effects and actor identities; camera modes passed")
	quit(0)
