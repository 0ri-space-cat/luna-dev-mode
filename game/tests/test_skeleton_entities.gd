extends SceneTree
## Exercise creation and the public wand request against live 2D+Z bodies.

const Fixture = preload("res://scenes/skeleton/entity_fixture.tscn")
const SaveStore = preload("res://scripts/runtime2d/save_store_2d.gd")
const SAVE_PATH := "user://luna_test_p9_02_entities.json"
const TARGET_ID := "DEV_P9_02_FRIDGE"
const PROP_ID := "DEV_P9_02_PROP"
const PROP := {"id": PROP_ID, "category": "prop", "label": "Fixture prop", "material": "WOOD"}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene = Fixture.instantiate()
	scene.keyboard = false
	root.add_child(scene)
	await physics_frame
	var target = scene.entities.get_entity(TARGET_ID)
	assert(target != null and target.entity_id == target.record.id)
	assert(target.get_parameter("material") == "METAL")
	assert(scene.entities.count_live() == 3)

	# Safe creation claims its ID only after validating the physical placement.
	assert(scene.spawn_entity(PROP, target.position, 72.0) == null)
	assert(scene.spawn_entity(PROP, Vector2(478, 264), 0.0) == null)
	assert(scene.spawn_entity(PROP, Vector2(650, 264), 0.0) == null)
	assert(scene.spawn_entity(PROP, Vector2(129, 300), 72.0) == null)
	assert(scene.spawn_entity(PROP, Vector2(556, 264), NAN) == null)
	assert(scene.entities.get_entity(PROP_ID) == null)
	var prop = scene.spawn_entity(PROP, Vector2(556, 264), 0.0)
	assert(prop != null and prop.motion.grounded)
	assert(scene.spawn_entity(PROP, Vector2(556, 300), 0.0) == null)
	assert(scene.entities.get_entity(PROP_ID) == prop)

	# The registry resolves canonical IDs without exposing fields without adapters.
	var aliases := {
		"IS_ALIVE": "alive", "AUTONOMY": "ai_enabled", "MOVE_SPEED": "speed",
		"SCALE": "size", "BASE_COLOR": "color", "RESTITUTION": "bounciness",
		"FOLLOW_DISTANCE": "follow_distance", "PERSONAL_SPACE": "personal_space",
	}
	for canonical in aliases:
		assert(scene.Parameters.storage_id(canonical) == aliases[canonical])
	assert(scene.parameters.get_spec("fridge", "alive")["kind"] == "bool")
	assert(not scene.request_wand_parameter_edit(TARGET_ID, "BASE_COLOR", Color.RED))

	var fixture_location: String = target.location_id
	assert(scene.projection.drop_at(scene.actor.position, fixture_location))
	assert(not scene.request_wand_parameter_edit(TARGET_ID, "MASS", 4.0))
	assert(scene.projection.pick_up_from(scene.actor.position, 36.0, fixture_location))
	assert(not scene.request_wand_parameter_edit(PROP_ID, "MASS", 4.0))
	assert(not scene.request_wand_parameter_edit("MISSING_ENTITY", "MASS", 4.0))
	target.location_id = "OTHER_LOCATION"
	assert(not scene.request_wand_parameter_edit(TARGET_ID, "MASS", 4.0))
	target.location_id = fixture_location
	target.motion.elevation += 110.0
	assert(not scene.request_wand_parameter_edit(TARGET_ID, "MASS", 4.0))
	target.motion.elevation -= 110.0
	assert(scene.access.set_wand_mode("DEVELOPER"))
	assert(not scene.request_wand_parameter_edit(scene.actor.entity_id, "MASS", 4.0))
	assert(not scene.request_wand_parameter_edit(TARGET_ID, "MATERIAL", "WOOD"))
	assert(not scene.request_wand_parameter_edit(TARGET_ID, "ACCESS_LEVEL", 3))
	assert(scene.access.set_wand_mode("PLAYFUL"))
	for value in ["4", true, INF, NAN, 0.0, -3.0, 10000.0]:
		assert(not scene.request_wand_parameter_edit(TARGET_ID, "MASS", value))
	assert(not scene.request_wand_parameter_edit(TARGET_ID, "BOUNCINESS", 1.01))
	assert(scene.commands.get_audit_log().is_empty())
	assert(target.get_parameter("mass") == 1.0)
	assert(target.get_parameter("material") == "METAL")

	# The edit reaches the native body, and the audit uses the existing key.
	assert(target.apply_impulse(Vector2(160, 0)))
	assert(is_equal_approx(_impulse_x(target), 160.0))
	assert(target.apply_impulse(Vector2(-160, 0)))
	assert(scene.request_wand_parameter_edit(TARGET_ID, "MASS", 4.0))
	assert(scene.request_wand_parameter_edit(TARGET_ID, "mass", 4.0))
	assert(scene.request_wand_parameter_edit(TARGET_ID, "RESTITUTION", 0.65))
	var audit: Array = scene.commands.get_audit_log()
	assert(audit.size() == 2)
	assert(audit[0]["entity_id"] == TARGET_ID and audit[0]["parameter_id"] == "mass")
	assert(audit[0]["source_id"] == "wand:luna")
	assert(audit[1]["parameter_id"] == "bounciness")
	assert(target.apply_impulse(Vector2(160, 0), 800.0))
	assert(is_equal_approx(_impulse_x(target), 40.0))
	var start_x: float = target.position.x
	assert(await _until(func(): return target.motion.vertical_speed < -40.0))
	assert(target.position.x > start_x + 5.0)
	assert(await _until(func(): return target.motion.vertical_speed > 70.0))

	var state: Dictionary = _disk_or_json_round_trip(scene.make_snapshot())
	assert(not state.is_empty())
	var broken := state.duplicate(true)
	broken["entities"].push_back(broken["entities"].back().duplicate(true))
	assert(not scene.apply_snapshot(broken))
	broken = state.duplicate(true)
	_find_state(broken, TARGET_ID)["dynamics"]["mass"] = 0.0
	assert(not scene.apply_snapshot(broken))
	broken = state.duplicate(true)
	_find_state(broken, TARGET_ID)["location_id"] = "OTHER_LOCATION"
	assert(not scene.apply_snapshot(broken))
	assert(is_same(scene.entities.get_entity(TARGET_ID), target))
	assert(scene.commands.get_audit_log() == audit)
	assert(scene.request_wand_parameter_edit(TARGET_ID, "MASS", 2.0))
	assert(scene.apply_snapshot(state))
	target = scene.entities.get_entity(TARGET_ID)
	assert(target.entity_id == TARGET_ID and target.record.category == "fridge")
	assert(not target.motion.grounded and target.motion.vertical_speed > 70.0)
	assert(target.get_parameter("mass") == 4.0 and target.dynamics_snapshot()["mass"] == 4.0)
	assert(is_equal_approx(target.get_parameter("bounciness"), 0.65))
	assert(target.get_parameter("material") == "METAL")
	assert(scene.entities.get_entity(PROP_ID).get_parameter("material") == "WOOD")
	assert(scene.commands.get_audit_log().is_empty())
	assert(scene.request_wand_parameter_edit(TARGET_ID, "MASS", 3.0))
	assert(target.dynamics_snapshot()["mass"] == 3.0)
	assert(scene.commands.undo() and target.dynamics_snapshot()["mass"] == 4.0)
	assert(scene.commands.redo() and target.dynamics_snapshot()["mass"] == 3.0)

	print("P9-02: safe creation, stable IDs, wand permissions, real dynamics and atomic saves passed")
	scene.queue_free()
	await process_frame
	quit()


func _disk_or_json_round_trip(data: Dictionary) -> Dictionary:
	if OS.get_environment("LUNA_ELEVATION_JSON_ONLY") == "1":
		return JSON.parse_string(JSON.stringify(data))
	var store := SaveStore.new()
	if not store.write_snapshot(data, SAVE_PATH):
		return {}
	var read := store.read_snapshot(SAVE_PATH)
	for file_name in [SAVE_PATH, SAVE_PATH + ".bak"]:
		if FileAccess.file_exists(file_name):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(file_name))
	return read


func _find_state(snapshot: Dictionary, identity: String) -> Dictionary:
	for body in snapshot["entities"]:
		if body["id"] == identity:
			return body
	return {}


func _impulse_x(body) -> float:
	return float(body.dynamics_snapshot()["impulse_velocity"][0])


func _until(condition: Callable) -> bool:
	for tick in range(100):
		await physics_frame
		if condition.call():
			return true
	return false
