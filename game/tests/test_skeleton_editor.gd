extends SceneTree

const Fixture = preload("res://scenes/skeleton/entity_fixture.tscn")
const TARGET := "DEV_P9_02_FRIDGE"
const YETI := "DEV_P9_02_YETI"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene = Fixture.instantiate()
	scene.keyboard = false
	root.add_child(scene)
	await physics_frame
	var target = scene.entities.get_entity(TARGET)
	var tabs: Dictionary = scene.get_wand_editor_tabs(TARGET)
	assert(tabs.size() == 6)
	assert(tabs["Облик"].size() == 2 and tabs["Отношения"].size() == 1)
	assert(tabs["Общее"].size() == 1 and tabs["Общее"][0]["id"] == "alive")
	assert(scene.get_wand_editor_tabs(YETI)["Общее"][0]["id"] == "asleep")
	assert(scene.get_wand_editor_tabs(scene.actor.entity_id).is_empty())
	scene._toggle_debug_editor()
	assert(is_instance_valid(scene._debug_editor))
	scene._toggle_debug_editor()
	assert(scene.request_wand_parameter_edit(TARGET, "BASE_COLOR", Color("8ed7bd")))
	assert(target._marker.color == Color("8ed7bd"))
	assert(not scene.request_wand_parameter_edit(TARGET, "BASE_COLOR", Color.RED))
	assert(scene.request_wand_parameter_edit(TARGET, "IS_ALIVE", true))
	assert(scene.request_wand_parameter_edit(TARGET, "BEHAVIOR_MODE", "IDLE"))
	var start: Vector2 = target.position
	await _ticks(10)
	assert(target.position.is_equal_approx(start))
	assert(scene.request_wand_parameter_edit(TARGET, "BEHAVIOR_MODE", "CHASE"))
	await _ticks(10)
	assert(target.position.distance_to(scene.actor.position) < start.distance_to(scene.actor.position) - 8.0)
	assert(target.brain.last_target_id == scene.actor.entity_id)
	assert(scene.request_wand_parameter_edit(TARGET, "BEHAVIOR_MODE", "AUTO"))
	assert(scene.request_wand_parameter_edit(TARGET, "LUNA_RELATION", "AFRAID"))
	await _ticks(3)
	assert(target.brain.last_resolved_mode == "FLEE")
	assert(scene.request_wand_parameter_edit(TARGET, "BEHAVIOR_MODE", "IDLE"))
	var saved: Dictionary = JSON.parse_string(JSON.stringify(scene.make_snapshot()))
	var invalid := saved.duplicate(true)
	for entry in invalid["entities"]:
		if entry["id"] == TARGET:
			entry["editor"]["color"] = "invalid"
	assert(not scene.apply_snapshot(invalid))
	assert(scene.apply_snapshot(saved))
	target = scene.entities.get_entity(TARGET)
	assert(target.get_parameter("behavior_mode") == "IDLE")
	assert(target.get_parameter("luna_relation") == "AFRAID")
	assert(target._marker.color == Color("8ed7bd"))
	assert(scene.projection.drop_at(scene.actor.position, target.location_id))
	assert(scene.get_wand_editor_tabs(TARGET).is_empty())
	print("P9-02: six editor tabs, palette, behavior, relations and snapshots passed")
	scene.queue_free()
	await process_frame
	quit()

func _ticks(count: int) -> void:
	for tick in range(count):
		await physics_frame
