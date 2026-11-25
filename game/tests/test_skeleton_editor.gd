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
	assert(tabs["Общее"].map(func(field): return field["id"]) == ["alive", "rideable", "pickable"])
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
	await _check_attachments()
	quit()

func _check_attachments() -> void:
	var scene = Fixture.instantiate()
	scene.keyboard = false
	root.add_child(scene)
	await physics_frame
	var luna = scene.actor
	var fridge = scene.entities.get_entity(TARGET)
	var yeti = scene.entities.get_entity(YETI)
	assert(not luna.set_parameter("pickable", true))
	assert(not luna.set_parameter("rideable", true))
	assert(scene.request_wand_parameter_edit(YETI, "PICKABLE", true))
	assert(not scene.interact_with_attachment(YETI)) # Too far away.
	fridge.position = luna.position + Vector2(26.0, 0.0)
	fridge.motion.reset_on_surface(fridge.position, luna.motion.elevation)
	assert(not scene.interact_with_attachment(TARGET))
	assert(not scene.request_wand_parameter_edit(TARGET, "RIDEABLE", "true"))
	assert(scene.request_wand_parameter_edit(TARGET, "RIDEABLE", true))
	assert(scene.request_wand_parameter_edit(TARGET, "SCALE", 0.6))
	assert(not scene.interact_with_attachment(TARGET))
	assert(scene.request_wand_parameter_edit(TARGET, "SCALE", 1.0))
	assert(scene.request_wand_parameter_edit(TARGET, "MASS", 2.5))
	assert(scene.interact_with_attachment(TARGET))
	assert(luna.is_riding() and fridge.has_rider())
	assert(not scene.request_wand_parameter_edit(TARGET, "RIDEABLE", false))
	assert(not luna.set_parameter("mass", 3.0))
	assert(not fridge.flight_enabled and not fridge.water_snapshot()["swim_enabled"])
	assert(not fridge.try_pick_up(yeti))
	assert(scene.request_wand_parameter_edit(TARGET, "IS_ALIVE", true))
	assert(scene.request_wand_parameter_edit(TARGET, "AUTONOMY", false))
	assert(scene.request_wand_parameter_edit(TARGET, "CONTROL_SOURCE", "PLAYER"))
	var ride_start: Vector2 = fridge.position
	scene.apply_player_input(Vector2.RIGHT)
	await _ticks(8)
	scene.apply_player_input(Vector2.ZERO)
	assert(fridge.position.x > ride_start.x + 8.0 and luna.position.is_equal_approx(fridge.position))
	var mounted: Dictionary = JSON.parse_string(JSON.stringify(scene.make_snapshot()))
	assert(scene.apply_snapshot(mounted))
	luna = scene.actor
	fridge = scene.entities.get_entity(TARGET)
	assert(luna.is_riding() and fridge.has_rider())
	assert(scene.interact_with_attachment())
	assert(not luna.is_riding())
	await _ticks(20)
	assert(luna.motion.grounded)
	assert(scene.request_wand_parameter_edit(TARGET, "RIDEABLE", false))
	assert(scene.commands.undo())
	assert(fridge.get_parameter("rideable"))
	assert(scene.commands.redo())
	assert(not fridge.get_parameter("rideable"))

	assert(scene.request_wand_parameter_edit(TARGET, "PICKABLE", true))
	assert(scene.request_wand_parameter_edit(TARGET, "MASS", 4.0))
	assert(not scene.interact_with_attachment(TARGET))
	assert(scene.request_wand_parameter_edit(TARGET, "MASS", 1.0))
	assert(scene.request_wand_parameter_edit(TARGET, "SCALE", 1.1))
	assert(not scene.interact_with_attachment(TARGET))
	assert(scene.request_wand_parameter_edit(TARGET, "SCALE", 0.8))
	assert(scene.interact_with_attachment(TARGET))
	assert(fridge.is_carried() and not fridge.is_riding())
	assert(not scene.request_wand_parameter_edit(TARGET, "PICKABLE", false))
	assert(not scene.request_wand_parameter_edit(TARGET, "MASS", 4.0))
	assert(not scene.request_wand_parameter_edit(TARGET, "SCALE", 0.9))
	scene.apply_player_input(Vector2.RIGHT, true)
	assert(luna.apply_impulse(Vector2.ZERO, 360.0))
	await _ticks(8)
	scene.apply_player_input(Vector2.ZERO)
	assert(fridge.position.is_equal_approx(luna.position))
	assert(is_equal_approx(fridge.motion.elevation, luna.motion.elevation + luna.body_height()))
	assert(not scene.interact_with_attachment()) # No safe floor within drop range.
	var carrying: Dictionary = JSON.parse_string(JSON.stringify(scene.make_snapshot()))
	var corrupt := carrying.duplicate(true)
	for entry in corrupt["entities"]:
		if entry["id"] == TARGET:
			entry["attachment"]["carrier_id"] = "MISSING"
	assert(not scene.apply_snapshot(corrupt))
	assert(scene.actor == luna and fridge.is_carried())
	assert(scene.apply_snapshot(carrying))
	luna = scene.actor
	fridge = scene.entities.get_entity(TARGET)
	assert(fridge.is_carried() and luna.has_passenger())
	await _ticks(65)
	assert(scene.interact_with_attachment())
	assert(not fridge.is_carried() and not luna.has_passenger())
	await _ticks(25)
	assert(fridge.motion.grounded and fridge.position.distance_to(luna.position) > 20.0)
	var legacy: Dictionary = scene.make_snapshot()
	legacy["entity_state_version"] = 5
	for entry in legacy["entities"]:
		entry.erase("attachment")
	assert(scene.apply_snapshot(legacy))
	assert(not scene.entities.get_entity(TARGET).get_parameter("pickable"))
	print("P9-02: editable riding and carry, weight and size limits, safe release and saved links passed")
	scene.queue_free()
	await process_frame

func _ticks(count: int) -> void:
	for tick in range(count):
		await physics_frame
