extends "res://scripts/skeleton/elevation_fixture.gd"
## Developer map for ID-based creation, editing and saving of 2D+Z entities.

const EntityBody = preload("res://scripts/skeleton/entity_body_2d.gd")
const EntityRecord = preload("res://scripts/core/entity_record.gd")
const WorldRegistry = preload("res://scripts/core/world_registry.gd")
const CommandProcessor = preload("res://scripts/core/command_processor.gd")
const WandPolicy = preload("res://scripts/runtime2d/wand_edit_policy_2d.gd")
const AccessState = preload("res://scripts/runtime2d/access_state_2d.gd")
const WandProjection = preload("res://scripts/runtime2d/projection_field_2d.gd")
const Parameters = preload("res://scripts/skeleton/entity_parameters_2d.gd")
const LOCATION_ID := "DEV_P9_02"
const TARGET_ID := "DEV_P9_02_FRIDGE"
const MAX_ENTITIES := 24
const YETI_ID := "DEV_P9_02_YETI"
const PLAYER_DEFINITION := {
	"id": ENTITY_ID, "category": "player", "label": "Луна", "material": "FABRIC",
}
const TARGET_DEFINITION := {
	"id": TARGET_ID, "category": "fridge", "label": "Холодильник", "material": "METAL",
}

var entities := WorldRegistry.new()
var parameters := Parameters.new()
var commands := CommandProcessor.new()
var wand_policy := WandPolicy.new()
var access := AccessState.new()
var projection := WandProjection.new()


func _ready() -> void:
	_prepare_map()
	commands.configure_world(entities)
	actor = spawn_entity(PLAYER_DEFINITION, START, UPPER_HEIGHT)
	var target := spawn_entity(TARGET_DEFINITION, START + Vector2(48.0, 0.0), UPPER_HEIGHT)
	var yeti := spawn_entity({"id": YETI_ID, "category": "yeti", "label": "Йетти", "material": "FABRIC"}, START + Vector2(0, 52), UPPER_HEIGHT)
	if actor == null or target == null or yeti == null:
		set_physics_process(false)
		push_error("Could not place the P9-02 fixture actors on the starting platform")


func spawn_entity(definition: Dictionary, point: Vector2, height: float) -> EntityBody:
	if not point.is_finite() or not is_finite(height):
		return null
	if entities.count_live() >= MAX_ENTITIES:
		return null
	var identity: Variant = definition.get("id")
	if not identity is String or entities.get_entity(identity) != null:
		return null
	var candidate := _build_entity(definition)
	if candidate == null:
		return null
	if not candidate.motion.start_on_safe_support(point, height, _surfaces) \
			or _intersects_wall(point, height) or not candidate._is_dry(point, height) \
			or _spawn_is_occupied(point, height):
		candidate.free()
		return null
	candidate.position = point
	entities.register_entity(identity, candidate, candidate.record.category)
	add_child(candidate)
	return candidate


func _spawn_is_occupied(point: Vector2, height: float) -> bool:
	for identity in entities.list_ids():
		var body := entities.get_entity(identity) as EntityBody
		if height >= body.motion.elevation + body.body_height() or body.motion.elevation >= height + ElevationBody.BODY_HEIGHT:
			continue
		if body.position.distance_to(point) < ElevationBody.FOOT_RADIUS + body.foot_radius():
			return true
	return false


func _build_entity(definition: Dictionary) -> EntityBody:
	var identity: Variant = definition.get("id")
	var category: Variant = definition.get("category")
	var label: Variant = definition.get("label")
	var material: Variant = definition.get("material")
	if not identity is String or identity.length() > 96 or not identity.is_valid_identifier():
		return null
	if not category is String or category.length() > 32 or not category.is_valid_identifier():
		return null
	if (identity == ENTITY_ID) != (category == "player") or identity == CARRIER_ID:
		return null
	if not label is String or label.strip_edges().is_empty() or label.length() > 96:
		return null
	if not parameters.normalize(category, "material", material)["ok"]:
		return null
	var body := EntityBody.new()
	_configure_body(body, identity)
	body.record = EntityRecord.new(identity, category, label, parameters, {"material": material, "alive": category in ["player", "yeti"], "asleep": category == "yeti", "ai_enabled": category != "player", "control_source": "PLAYER" if category == "player" else "NONE"})
	body.world_registry = entities
	body.location_id = LOCATION_ID
	return body


func request_wand_parameter_edit(target_id: String, parameter_id: String, value: Variant) -> bool:
	if not (actor as EntityBody).accepts_player_input():
		return false
	var target := entities.get_entity(target_id) as EntityBody
	var key := Parameters.storage_id(parameter_id)
	if not wand_policy.authorize(actor, target, LOCATION_ID, projection, access, parameters, key):
		return false
	var offset: Vector2 = actor.global_position - target.global_position
	var height_gap: float = actor.motion.elevation - target.motion.elevation
	if Vector3(offset.x, offset.y, height_gap).length_squared() > WandPolicy.REACH_PX * WandPolicy.REACH_PX:
		return false
	return commands.execute_set(target, key, value, actor.entity_id, "wand:luna")


func make_snapshot() -> Dictionary:
	var states: Array[Dictionary] = []
	for identity in entities.list_ids():
		var body := entities.get_entity(identity) as EntityBody
		var data := _body_snapshot(body)
		data["category"] = body.record.category
		data["label"] = body.record.display_name
		data["material"] = body.get_parameter("material")
		data["location_id"] = body.location_id
		data["life"] = body.life_snapshot()
		data["control"] = body.control_snapshot()
		data["movement"] = body.movement_snapshot()
		states.append(data)
	return {"format": SaveStore.FORMAT, "fixture": LOCATION_ID, "entity_state_version": 3, "entities": states}


func apply_snapshot(data: Dictionary) -> bool:
	var states: Variant = data.get("entities")
	if data.get("format") != SaveStore.FORMAT or data.get("fixture") != LOCATION_ID:
		return false
	if not states is Array or states.is_empty() or states.size() > MAX_ENTITIES:
		return false
	var version: Variant = data.get("entity_state_version", 0)
	if typeof(version) not in [TYPE_INT, TYPE_FLOAT] or float(version) not in [0.0, 1.0, 2.0, 3.0]:
		return false
	var candidates := {}
	for state in states:
		var candidate := _build_saved_entity(state, int(version))
		if candidate == null or candidates.has(candidate.entity_id):
			if candidate != null:
				candidate.free()
			_free_candidates(candidates)
			return false
		candidates[candidate.entity_id] = candidate
	if not candidates.has(ENTITY_ID):
		_free_candidates(candidates)
		return false

	for identity in entities.list_ids():
		var previous := entities.get_entity(identity)
		entities.unregister_entity(identity)
		previous.free()
	actor = candidates[ENTITY_ID]
	for identity in candidates:
		var body: EntityBody = candidates[identity]
		entities.register_entity(identity, body, body.record.category)
		add_child(body)
	commands.clear_history()
	return true


func _build_saved_entity(state: Variant, version: int) -> EntityBody:
	if not state is Dictionary or state.get("location_id") != LOCATION_ID or not state.has("dynamics"):
		return null
	if state.has("life") != (version >= 1) or state.has("control") != (version >= 2) or state.has("movement") != (version >= 3):
		return null
	var body := _build_entity(state)
	if body != null and ((version >= 3 and not body.restore_movement(state["movement"])) or not _restore_body_state(body, state) or (version >= 1 and not body.restore_life(state["life"])) or (version >= 2 and not body.restore_control(state["control"]))):
		body.free()
		return null
	return body


func _free_candidates(candidates: Dictionary) -> void:
	for body in candidates.values():
		body.free()


func _unhandled_key_input(event: InputEvent) -> void:
	if not keyboard or not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode not in [KEY_BRACKETLEFT, KEY_BRACKETRIGHT]:
		return
	var target := entities.get_entity(TARGET_ID) as EntityBody
	if target == null:
		return
	var mass := 1.0 if event.keycode == KEY_BRACKETLEFT else 4.0
	if request_wand_parameter_edit(TARGET_ID, "MASS", mass):
		$Controls.text = "P9-02  |  [ / ]: test MASS   Current MASS %.1f" % target.get_parameter("mass")


func _apply_keyboard_input() -> void:
	var movement := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	movement.x += float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A))
	movement.y += float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))
	var jump_down := Input.is_physical_key_pressed(KEY_SPACE)
	apply_player_input(movement, jump_down and not _jump_down)
	_jump_down = jump_down
	if Input.is_physical_key_pressed(KEY_HOME):
		return_to_luna()


func apply_player_input(movement: Vector2, jump_requested: bool = false) -> void:
	if not movement.is_finite():
		return
	for identity in entities.list_ids():
		var body := entities.get_entity(identity) as EntityBody
		if body.accepts_player_input():
			body.direction = movement.limit_length()
			if jump_requested:
				body.jump()


func return_to_luna() -> bool:
	# Recovery control is independent of the wand and never teleports a body.
	var luna := actor as EntityBody
	return luna.set_parameter("control_source", "PLAYER") and luna.set_parameter("ai_enabled", false)
