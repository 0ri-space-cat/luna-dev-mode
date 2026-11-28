extends "res://scripts/skeleton/elevation_fixture.gd"
## Developer map for ID-based creation, editing and saving of 2D+Z entities.

const ConsumableProfile = preload("res://scripts/runtime2d/consumable_profile_2d.gd")
const DebugEditor = preload("res://scripts/skeleton/entity_editor_debug.gd")
var _debug_editor: DebugEditor

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


func _location_id() -> String:
	return LOCATION_ID


func _entity_location(_point: Vector2) -> String:
	return _location_id()


func _starts_alive(category: String) -> bool:
	return category in ["player", "yeti"]


func _editor_parent() -> Node:
	return self


func _ready() -> void:
	_prepare_map()
	commands.configure_world(entities)
	actor = spawn_entity(PLAYER_DEFINITION, START, UPPER_HEIGHT)
	var target := spawn_entity(TARGET_DEFINITION, START + Vector2(48.0, 0.0), UPPER_HEIGHT)
	var yeti := spawn_entity({"id": YETI_ID, "category": "yeti", "label": "Йетти", "material": "FABRIC"}, START + Vector2(0, 52), UPPER_HEIGHT)
	if actor == null or target == null or yeti == null:
		set_physics_process(false)
		push_error("Could not place the P9-02 fixture actors on the starting platform")


func _entity_limit() -> int:
	return MAX_ENTITIES


func spawn_entity(definition: Dictionary, point: Vector2, height: float) -> EntityBody:
	if not point.is_finite() or not is_finite(height):
		return null
	if entities.count_live() >= _entity_limit():
		return null
	var identity: Variant = definition.get("id")
	if not identity is String or entities.get_entity(identity) != null:
		return null
	var candidate := _build_entity(definition)
	if candidate == null:
		return null
	if not _spawn_on_support(candidate, point, height) or _intersects_wall(point, height) \
			or _spawn_is_occupied(point, height):
		candidate.free()
		return null
	candidate.position = point
	candidate.location_id = _entity_location(point)
	entities.register_entity(identity, candidate, _target_group(candidate))
	add_child(candidate)
	return candidate


func _spawn_on_support(body: EntityBody, point: Vector2, height: float) -> bool:
	return body.motion.start_on_safe_support(point, height, body.surfaces) and body._is_dry(point, height)


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
	var body := _create_entity_body(identity, category)
	_configure_body(body, identity)
	body.record = EntityRecord.new(identity, category, label, parameters, {"material": material, "alive": _starts_alive(category), "asleep": category == "yeti", "ai_enabled": category != "player", "control_source": "PLAYER" if category == "player" else "NONE"})
	if category != "player":
		body.configure_seat(EntityBody.SEAT_HEIGHT, EntityBody.SEAT_CAPACITY, false)
	body.world_registry = entities
	return body


func _create_entity_body(_identity: String, _category: String) -> EntityBody:
	return EntityBody.new()


func request_wand_parameter_edit(target_id: String, parameter_id: String, value: Variant) -> bool:
	if not (actor as EntityBody).accepts_player_input():
		return false
	var target := _wand_target(target_id)
	var key := Parameters.storage_id(parameter_id)
	if not wand_policy.authorize(actor, target, _entity_location(actor.position), projection, access, parameters, key):
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
		data["location_id"] = _entity_location(body.position)
		data["life"] = body.life_snapshot()
		data["control"] = body.control_snapshot()
		data["movement"] = body.movement_snapshot()
		data["editor"] = body.editor_snapshot()
		data["gravity_scale"] = body.get_parameter("gravity_scale")
		data["attachment"] = body.attachment_snapshot()
		if body.consumable_flight_remaining > 0.0:
			data["consumable_flight"] = body.consumable_flight_remaining
		if body.consumable_glow_remaining > 0.0:
			data["consumable_glow"] = body.consumable_glow_remaining
		if body.life_suspended_remaining > 0.0:
			data["life_suspended"] = body.life_suspended_remaining
		if body.record.category in ["food", "drink"]:
			data["food"] = {"edible": body.get_parameter("edible"), "portions": body.get_parameter("portions")}
			if not body.food_effects.is_empty():
				data["food"]["effects"] = body.food_effects.duplicate(true)
		states.append(data)
	return {"format": SaveStore.FORMAT, "fixture": _location_id(), "entity_state_version": 6, "entities": states}


func apply_snapshot(data: Dictionary) -> bool:
	var states: Variant = data.get("entities")
	if data.get("format") != SaveStore.FORMAT or data.get("fixture") != _location_id():
		return false
	if not states is Array or states.is_empty() or states.size() > _entity_limit():
		return false
	var version: Variant = data.get("entity_state_version", 0)
	if typeof(version) not in [TYPE_INT, TYPE_FLOAT] or float(version) not in [0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0]:
		return false
	var candidates := {}
	for state in states:
		var candidate := _build_saved_entity(state, int(version))
		if candidate == null or candidates.has(candidate.entity_id):
			# A failed transaction must remain non-destructive, but name the rejected
			# stable record so the next migration can fix the actual invariant.
			push_warning("Snapshot rejected entity: " + str(state.get("id", "?") if state is Dictionary else "?"))
			if candidate != null:
				candidate.free()
			_free_candidates(candidates)
			return false
		candidates[candidate.entity_id] = candidate
	if not candidates.has(ENTITY_ID):
		_free_candidates(candidates)
		return false
	if version >= 6 and not _restore_attachments(states, candidates):
		push_warning("Snapshot rejected attachment graph")
		_free_candidates(candidates)
		return false
	if not _validate_saved_entities(candidates):
		push_warning("Snapshot rejected authored entity or finite module invariant")
		_free_candidates(candidates)
		return false

	if is_instance_valid(_debug_editor):
		_debug_editor.free()
		_debug_editor = null
	for identity in entities.list_ids():
		var previous := entities.get_entity(identity)
		entities.unregister_entity(identity)
		previous.free()
	actor = candidates[ENTITY_ID]
	for identity in candidates:
		var body: EntityBody = candidates[identity]
		entities.register_entity(identity, body, _target_group(body))
		add_child(body)
	commands.clear_history()
	return true


func _validate_saved_entities(_candidates: Dictionary) -> bool:
	return true


func _build_saved_entity(state: Variant, version: int) -> EntityBody:
	if not state is Dictionary or not state.has("dynamics"):
		return null
	if state.has("life") != (version >= 1) or state.has("control") != (version >= 2) or state.has("movement") != (version >= 3) or state.has("editor") != (version >= 4) or state.has("gravity_scale") != (version >= 5) or state.has("attachment") != (version >= 6):
		return null
	var body := _build_entity(state)
	if body != null and ((version >= 5 and not body.set_parameter("gravity_scale", state["gravity_scale"])) or (version >= 4 and not body.restore_editor(state["editor"])) or (version >= 3 and not body.restore_movement(state["movement"])) or not _restore_body_state(body, state) or (version >= 1 and not body.restore_life(state["life"])) or (version >= 2 and not body.restore_control(state["control"]))):
		body.free()
		return null
	if body != null and body.record.category in ["food", "drink"]:
		var food: Variant = state.get("food")
		if not food is Dictionary:
			body.free()
			return null
		var profile: Dictionary = food.duplicate(true)
		if not profile.has("effects"):
			profile["effects"] = []
		if not ConsumableProfile.valid_profile(profile, true):
			body.free()
			return null
		body.set_parameter("edible", profile["edible"])
		body.set_parameter("portions", profile["portions"])
		body.food_effects = profile["effects"]
	elif body != null and state.has("food"):
		body.free()
		return null
	if body != null:
		var flight: Variant = state.get("consumable_flight", 0.0)
		var glow: Variant = state.get("consumable_glow", 0.0)
		var dormant: Variant = state.get("life_suspended", 0.0)
		if not _valid_effect_duration(dormant, ConsumableProfile.DORMANT_LIMIT) \
				or (float(dormant) > 0.0 and (body.get_parameter("alive") or not body.supports_consumable_life())):
			body.free()
			return null
		if not _valid_effect_duration(flight, ConsumableProfile.FLIGHT_LIMIT) or not _valid_effect_duration(glow, ConsumableProfile.GLOW_LIMIT):
			body.free()
			return null
		body.consumable_flight_remaining = float(flight)
		body.consumable_glow_remaining = float(glow)
		body.life_suspended_remaining = float(dormant)
		body.location_id = _entity_location(body.position)
		if state.get("location_id") != body.location_id:
			body.free()
			return null
	return body


func _valid_effect_duration(value: Variant, maximum: float) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) \
		and float(value) >= 0.0 and float(value) <= maximum


func _restore_attachments(states: Array, candidates: Dictionary) -> bool:
	for state in states:
		var body: EntityBody = candidates[state["id"]]
		var attachment: Variant = state["attachment"]
		if not attachment is Dictionary or attachment.size() != 4:
			return false
		for field in Parameters.ATTACHMENT_FIELDS:
			var value: Variant = attachment.get(field)
			if not value is bool:
				return false
			if body.can_edit_parameter(field):
				if not body.set_parameter(field, value):
					return false
			elif value:
				return false
	for state in states:
		var attachment: Dictionary = state["attachment"]
		var carrier_id: Variant = attachment.get("carrier_id")
		var carried: Variant = attachment.get("carried")
		if not carrier_id is String or not carried is bool:
			return false
		if not carrier_id.is_empty():
			var carrier_body: EntityBody = candidates.get(carrier_id)
			if carrier_body == null or not carrier_body.restore_rider(candidates[state["id"]], carried):
				return false
		elif carried:
			return false
	return true


func _free_candidates(candidates: Dictionary) -> void:
	for body in candidates.values():
		body.free()


func _unhandled_key_input(event: InputEvent) -> void:
	if not keyboard or not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode == KEY_TAB:
		_toggle_debug_editor()
		get_viewport().set_input_as_handled()
		return
	if event.keycode == KEY_E and not is_instance_valid(_debug_editor):
		if interact_with_attachment():
			get_viewport().set_input_as_handled()
		return
	if event.keycode not in [KEY_BRACKETLEFT, KEY_BRACKETRIGHT]:
		return
	var target := entities.get_entity(TARGET_ID) as EntityBody
	if target == null:
		return
	var mass := 1.0 if event.keycode == KEY_BRACKETLEFT else 4.0
	if request_wand_parameter_edit(TARGET_ID, "MASS", mass):
		$Controls.text = "P9-02  |  E: board / pick up   TAB: edit   MASS %.1f" % target.get_parameter("mass")


func _apply_keyboard_input() -> void:
	if is_instance_valid(_debug_editor):
		apply_player_input(Vector2.ZERO)
		return
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


func interact_with_attachment(target_id: String = "") -> bool:
	var luna := actor as EntityBody
	if not luna.accepts_player_input():
		return false
	if luna.is_riding():
		return luna.try_dismount()
	if luna.has_passenger():
		return luna.try_drop()
	if not target_id.is_empty():
		var target := entities.get_entity(target_id) as EntityBody
		return target != null and (target.try_board(luna) or luna.try_pick_up(target))
	var closest_id := ""
	var closest_distance := INF
	for identity in entities.list_ids():
		var body := entities.get_entity(identity) as EntityBody
		if body == luna or not (body._allows_ride() or body._allows_pickup()):
			continue
		var distance: float = luna.position.distance_squared_to(body.position)
		if distance < closest_distance:
			closest_distance = distance
			closest_id = identity
	return not closest_id.is_empty() and interact_with_attachment(closest_id)


func _target_group(body: EntityBody) -> String:
	return "LUNA" if body.record.category == "player" else body.record.category.to_upper()


func get_wand_editor_tabs(target_id: String) -> Dictionary:
	if not (actor as EntityBody).accepts_player_input():
		return {}
	var target := _wand_target(target_id)
	if not wand_policy.authorize(actor, target, _entity_location(actor.position), projection, access, parameters, "mass"):
		return {}
	var offset := Vector3(actor.position.x - target.position.x, actor.position.y - target.position.y,
		actor.motion.elevation - target.motion.elevation)
	if offset.length_squared() > WandPolicy.REACH_PX * WandPolicy.REACH_PX:
		return {}
	var tabs := {}
	for tab in Parameters.EDITOR_TABS:
		var fields: Array[Dictionary] = []
		for key in Parameters.EDITOR_TABS[tab]:
			if not target.can_edit_parameter(key):
				continue
			var spec := parameters.get_spec(target.record.category, key)
			if spec.is_empty():
				continue
			spec["value"] = target.get_parameter(key)
			if key == "ai_enabled":
				spec["label"] = "AUTONOMY"
			fields.append(spec)
		tabs[tab] = fields
	return tabs


func _wand_target(target_id: String) -> EntityBody:
	return entities.get_entity(target_id) as EntityBody


func _wand_target_ids() -> Array[String]:
	return entities.list_ids()


func _toggle_debug_editor() -> void:
	if is_instance_valid(_debug_editor):
		_debug_editor.free()
		_debug_editor = null
		return
	var selected := ""
	var nearest := INF
	for identity in _wand_target_ids():
		var tabs := get_wand_editor_tabs(identity)
		if tabs.is_empty():
			continue
		var target := _wand_target(identity)
		var distance := actor.position.distance_squared_to(target.position)
		if distance < nearest:
			nearest = distance
			selected = identity
	_open_debug_editor(selected)


func _open_debug_editor(selected: String) -> void:
	if selected.is_empty() or is_instance_valid(_debug_editor):
		return
	var tabs := get_wand_editor_tabs(selected)
	if tabs.is_empty():
		return
	_debug_editor = DebugEditor.new()
	_debug_editor.position = Vector2(80, 90)
	_editor_parent().add_child(_debug_editor)
	_debug_editor.populate(tabs,
		func(key: String, value: Variant): return request_wand_parameter_edit(selected, key, value))
