extends "res://scripts/skeleton/entity_fixture.gd"
## The first playable P9-03 graybox. S0–S3 share one simulation and camera.

const ISLAND_ID := "ET_START_ISLAND"
const FRIDGE_ID := "START_FRIDGE"
const BRIDGE_YETI_ID := "START_YETI"
const SPAWN := Vector2(320, 374)
const FRIDGE_SPOT := Vector2(320, 222)
const RIFT_SPOT := Vector2(320, 524)
const BRIDGE_SPOT := Vector2(740, 374)
const YETI_RETREAT := [Vector2(975, 374), Vector2(975, 482)]
const INTERACT_REACH := 64.0
const DONUT_REFILL_SECONDS := 8.0
const SAVE_PATH := "user://luna_start_island.json"
const ISLAND_DECKS: Array[Dictionary] = [
	{"bounds": Rect2(95, 142, 565, 456), "height": 0.0},
	{"bounds": Rect2(623, 344, 261, 60), "height": 0.0},
	{"bounds": Rect2(850, 244, 350, 306), "height": 0.0},
]
const BRIDGE_RAILS: Array[Dictionary] = [
	{"bounds": Rect2(656, 326, 199, 18), "height": 92.0, "layer": 1},
	{"bounds": Rect2(656, 404, 199, 18), "height": 92.0, "layer": 1},
]

var has_donut := false
var donut_refill := 0.0
var retreat_step := -1
var _store := SaveStore.new()

@onready var _camera: Camera2D = $Camera
@onready var _status: Label = $Interface/Status
@onready var _prompt: Label = $Interface/Prompt


func _location_id() -> String:
	return ISLAND_ID


func _editor_parent() -> Node:
	return $Interface


func _ready() -> void:
	_decks.assign(ISLAND_DECKS)
	_surfaces.assign(_decks)
	_walls.assign(BRIDGE_RAILS)
	for wall in _walls:
		_build_wall(wall)
	commands.configure_world(entities)
	access.set_wand_mode(AccessState.ORDINARY)
	actor = spawn_entity(PLAYER_DEFINITION, SPAWN, 0.0)
	var fridge := spawn_entity({
		"id": FRIDGE_ID, "category": "fridge", "label": "Холодильник", "material": "METAL",
	}, FRIDGE_SPOT, 0.0)
	var yeti := spawn_entity({
		"id": BRIDGE_YETI_ID, "category": "yeti", "label": "Йетти", "material": "FABRIC",
	}, BRIDGE_SPOT, 0.0)
	if actor == null or fridge == null or yeti == null:
		set_physics_process(false)
		push_error("Could not place the start island entities")
		return
	yeti.set_parameter("size", 2.0)
	yeti.set_parameter("behavior_mode", "IDLE")
	_connect_bridge_body()
	_camera.position = actor.position


func _configure_body(body: ElevationBody, entity_id: String) -> void:
	super._configure_body(body, entity_id)
	body.emergency_anchor = Vector3(SPAWN.x, SPAWN.y, 0.0)


func _connect_bridge_body() -> void:
	var yeti := entities.get_entity(BRIDGE_YETI_ID) as EntityBody
	yeti.collision_layer = EntityBody.BODY_OBSTACLE_LAYER
	(actor as EntityBody).step_obstacle = yeti


func _physics_process(delta: float) -> void:
	if keyboard:
		_apply_keyboard_input()
	if not is_instance_valid(_debug_editor):
		donut_refill = maxf(0.0, donut_refill - delta)
		_update_yeti_route()
	_camera.position = actor.position
	var area := "Стартовый остров" if actor.position.x < 925.0 else "Край Больших лугов"
	var wand := "Обычная палочка" if access.wand_mode == AccessState.ORDINARY else access.wand_mode
	_status.text = "%s  ·  %s" % [area, wand]
	if has_donut:
		_status.text += "  ·  Пончик"
	var action := _nearby_action()
	_prompt.text = "" if action.is_empty() or is_instance_valid(_debug_editor) else "E  " + action


func _update_yeti_route() -> void:
	var yeti := entities.get_entity(BRIDGE_YETI_ID) as EntityBody
	yeti.autonomous_destination = Vector2.INF
	if retreat_step < 0 or retreat_step >= YETI_RETREAT.size() or yeti.get_parameter("behavior_mode") != "IDLE":
		return
	var goal: Vector2 = YETI_RETREAT[retreat_step]
	if yeti.position.distance_squared_to(goal) <= 4.0:
		retreat_step += 1
		if retreat_step == YETI_RETREAT.size():
			return
		goal = YETI_RETREAT[retreat_step]
	yeti.autonomous_destination = goal


func _within_reach(point: Vector2, height: float = 0.0) -> bool:
	var offset := point - actor.position
	return Vector3(offset.x, offset.y, height - actor.motion.elevation).length_squared() <= INTERACT_REACH * INTERACT_REACH


func _nearby_action() -> String:
	if access.wand_mode == AccessState.ORDINARY and projection.carried and _within_reach(RIFT_SPOT):
		return "Поднести палочку"
	var fridge := entities.get_entity(FRIDGE_ID) as EntityBody
	if not has_donut and donut_refill <= 0.0 and _within_reach(fridge.position, fridge.motion.elevation):
		return "Взять пончик"
	var yeti := entities.get_entity(BRIDGE_YETI_ID) as EntityBody
	if has_donut and not yeti.get_parameter("asleep") and _within_reach(yeti.position, yeti.motion.elevation):
		return "Предложить пончик"
	return ""


func interact() -> bool:
	if not (actor as EntityBody).accepts_player_input() or is_instance_valid(_debug_editor):
		return false
	match _nearby_action():
		"Поднести палочку":
			return access.set_wand_mode(AccessState.PLAYFUL)
		"Взять пончик":
			has_donut = true
			donut_refill = DONUT_REFILL_SECONDS
			return true
		"Предложить пончик":
			has_donut = false
			if retreat_step < 0:
				retreat_step = 0
			return true
	return interact_with_attachment()


func _unhandled_key_input(event: InputEvent) -> void:
	if not keyboard or not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_E:
			if interact():
				get_viewport().set_input_as_handled()
		KEY_TAB:
			_toggle_debug_editor()
			get_viewport().set_input_as_handled()
		KEY_ESCAPE:
			if is_instance_valid(_debug_editor):
				_toggle_debug_editor()
				get_viewport().set_input_as_handled()
		KEY_F5:
			if _store.write_snapshot(make_snapshot(), SAVE_PATH):
				$Interface/SaveNotice.text = "Сохранено"
		KEY_F9:
			var saved := _store.read_snapshot(SAVE_PATH)
			$Interface/SaveNotice.text = "Загружено" if apply_snapshot(saved) else "Нет подходящего сохранения"


func _toggle_debug_editor() -> void:
	super._toggle_debug_editor()
	var active := not is_instance_valid(_debug_editor)
	for identity in entities.list_ids():
		var body := entities.get_entity(identity) as EntityBody
		body.set_physics_process(active)


func make_snapshot() -> Dictionary:
	var data := super.make_snapshot()
	data["island"] = {
		"access": access.snapshot(), "projection": projection.snapshot(), "has_donut": has_donut,
		"donut_refill": donut_refill, "retreat_step": retreat_step,
	}
	return data


func apply_snapshot(data: Dictionary) -> bool:
	var island: Variant = data.get("island")
	var states: Variant = data.get("entities")
	if not island is Dictionary or not states is Array:
		return false
	var next_access := AccessState.new()
	var next_projection := WandProjection.new()
	var access_data: Variant = island.get("access")
	var projection_data: Variant = island.get("projection")
	var food: Variant = island.get("has_donut")
	var refill: Variant = island.get("donut_refill")
	var step: Variant = island.get("retreat_step")
	if not access_data is Dictionary or not next_access.restore(access_data) \
			or not projection_data is Dictionary or not next_projection.restore(projection_data) \
			or not food is bool:
		return false
	if typeof(refill) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(refill)) \
			or float(refill) < 0.0 or float(refill) > DONUT_REFILL_SECONDS:
		return false
	if typeof(step) not in [TYPE_INT, TYPE_FLOAT] or float(step) not in [-1.0, 0.0, 1.0, 2.0]:
		return false
	var fridge_found := false
	var yeti_found := false
	for state in states:
		if state is Dictionary:
			fridge_found = fridge_found or (state.get("id") == FRIDGE_ID and state.get("category") == "fridge")
			yeti_found = yeti_found or (state.get("id") == BRIDGE_YETI_ID and state.get("category") == "yeti")
	if not fridge_found or not yeti_found or not super.apply_snapshot(data):
		return false
	access = next_access
	projection = next_projection
	has_donut = food
	donut_refill = float(refill)
	retreat_step = int(step)
	_connect_bridge_body()
	_camera.position = actor.position
	return true


func _draw() -> void:
	for index in _decks.size():
		var deck: Rect2 = _decks[index]["bounds"]
		var color := Color("7c6a72") if index == 1 else Color("4b655c")
		draw_rect(deck.grow(5.0), Color("2b393d"))
		draw_rect(deck, color)
	for wall in _walls:
		draw_rect(wall["bounds"], Color("b5a0b0"))
	draw_rect(Rect2(FRIDGE_SPOT - Vector2(55, 35), Vector2(110, 70)), Color("657572"))
	draw_circle(RIFT_SPOT, 22.0, Color("3c3354"))
	draw_arc(RIFT_SPOT, 22.0, -0.8, 4.8, 28, Color("bca3e4"), 3.0, true)
	draw_polyline(PackedVector2Array([RIFT_SPOT + Vector2(4, -20), RIFT_SPOT + Vector2(-5, -4),
		RIFT_SPOT + Vector2(7, 3), RIFT_SPOT + Vector2(-3, 22)]), Color("eee0fa"), 2.0, true)
	var font := ThemeDB.fallback_font
	draw_string(font, FRIDGE_SPOT + Vector2(-48, -47), "Холодильник")
	draw_string(font, RIFT_SPOT + Vector2(-28, 48), "Разлом")
	draw_string(font, Vector2(1005, 339), "Большие луга")
