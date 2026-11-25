extends "res://scripts/skeleton/elevation_fixture.gd"
## A projected span uses the same 2D+Z supports as the two permanent banks.

const WandField = preload("res://scripts/runtime2d/projection_field_2d.gd")
const FollowCamera = preload("res://scripts/runtime2d/camera_follow_lock_2d.gd")

const LOCATION_ID := "DEV_UNDERSIDE"
const FIRST_WAND := "DEV_WAND_A"
const SECOND_WAND := "DEV_WAND_B"
const RADIUS := 155.0
const PICKUP_REACH := 36.0
const LEDGE_Z := 48.0
const START_POINT := Vector2(185, 220)
const SECOND_POINT := Vector2(370, 335)
const GROUNDS: Array[Dictionary] = [
	{"bounds": Rect2(70, 130, 980, 410), "height": 0.0},
	{"bounds": Rect2(95, 170, 345, 90), "height": LEDGE_Z},
	{"bounds": Rect2(685, 170, 340, 90), "height": LEDGE_Z},
]
const BRIDGE := {"bounds": Rect2(420, 193, 284, 54), "height": LEDGE_Z, "safe": false}

var fields := {}
var wand_heights := {}
var underside := false
var eyes_open := true

@onready var camera: FollowCamera = $Camera
@onready var _camera_target: Marker2D = $CameraTarget
@onready var _light: CanvasModulate = $WorldLight
@onready var _status: Label = $Interface/Status


func _fixture_key() -> String:
	return "p9_05_underside"


func _ready() -> void:
	_decks.assign(GROUNDS)
	_surfaces.assign(_decks)
	actor = _new_body(ENTITY_ID)
	actor.position = START_POINT
	actor.motion.reset_on_surface(START_POINT, LEDGE_Z)
	actor.emergency_anchor = Vector3(START_POINT.x, START_POINT.y, LEDGE_Z)
	add_child(actor)
	for identity in [FIRST_WAND, SECOND_WAND]:
		var field := WandField.new()
		field.radius = RADIUS
		fields[identity] = field
	wand_heights = {FIRST_WAND: LEDGE_Z, SECOND_WAND: 0.0}
	fields[SECOND_WAND].drop_at(SECOND_POINT, LOCATION_ID)
	camera.target = _camera_target
	camera.make_current()
	_sync_view()


func held_wand() -> String:
	for identity in fields:
		if fields[identity].carried:
			return identity
	return ""


func interact_with_wand() -> bool:
	if not actor.motion.grounded:
		return false
	var point := actor.position
	var height := actor.motion.elevation
	var held := held_wand()
	if not held.is_empty():
		if not _permanent_support_at(point, height):
			return false
		fields[held].drop_at(point, LOCATION_ID)
		wand_heights[held] = height
	else:
		var best := ""
		var nearest := PICKUP_REACH * PICKUP_REACH
		for identity in fields:
			var distance: float = point.distance_squared_to(fields[identity].ground_position)
			if is_equal_approx(height, wand_heights[identity]) and distance <= nearest:
				best = identity
				nearest = distance
		if best.is_empty() or not fields[best].pick_up_from(point, PICKUP_REACH, LOCATION_ID):
			return false
	_sync_view()
	queue_redraw()
	return true


func _permanent_support_at(point: Vector2, height: float) -> bool:
	for deck in GROUNDS:
		var bounds: Rect2 = deck["bounds"]
		if is_equal_approx(height, deck["height"]) and bounds.grow(-actor.motion.safe_margin).has_point(point):
			return true
	return false


func _set_underside(active: bool) -> void:
	if active == underside:
		return
	underside = active
	if active:
		_surfaces.append(BRIDGE)
	else:
		_surfaces.erase(BRIDGE)
	_light.color = Color("a3cce9") if active else Color.WHITE
	queue_redraw()


func _sync_view() -> void:
	_camera_target.position = actor.position - Vector2(0, actor.motion.elevation)
	camera.update_follow()
	camera.force_update_scroll()
	_set_underside(WandField.is_outside_all(fields.values(), actor.position, LOCATION_ID))


func _physics_process(_delta: float) -> void:
	if keyboard:
		_apply_keyboard_input()
	_sync_view()
	_status.text = "%s  ·  %s  ·  %s" % [
		"Изнанка" if underside else "Обычная проекция",
		"Камера следует" if camera.mode == FollowCamera.FOLLOW else "Камера закреплена",
		"Глаза открыты" if eyes_open else "Глаза закрыты",
	]


func _apply_keyboard_input() -> void:
	actor.direction = _keyboard_movement().limit_length()
	var jump_down := Input.is_physical_key_pressed(KEY_SPACE)
	if jump_down and not _jump_down:
		actor.jump()
	_jump_down = jump_down


func _unhandled_key_input(event: InputEvent) -> void:
	if not keyboard or not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_F4:
			interact_with_wand()
		KEY_E:
			camera.toggle_mode()
			_sync_view()
		KEY_F2:
			eyes_open = not eyes_open
		_:
			return
	get_viewport().set_input_as_handled()


func make_snapshot() -> Dictionary:
	var data := super.make_snapshot()
	var wands := {}
	for identity in fields:
		wands[identity] = fields[identity].snapshot()
		wands[identity]["height"] = wand_heights[identity]
	data["wands"] = wands
	data["view"] = {
		"mode": camera.mode, "point": [camera.position.x, camera.position.y],
		"eyes_open": eyes_open,
	}
	return data


func apply_snapshot(data: Dictionary) -> bool:
	var snapshot_wands: Variant = data.get("wands")
	var view: Variant = data.get("view")
	if not snapshot_wands is Dictionary or snapshot_wands.size() != fields.size() \
			or not view is Dictionary or view.get("mode") not in [FollowCamera.FOLLOW, FollowCamera.LOCKED] \
			or not view.get("eyes_open") is bool:
		return false
	var next_camera := _read_vector(view.get("point"))
	var body: Variant = data.get("actor")
	if not next_camera.is_finite() or not body is Dictionary:
		return false
	var next_position := _read_vector(body.get("position"))
	if not next_position.is_finite():
		return false
	var next_fields := {}
	var next_heights := {}
	var held_count := 0
	for identity in fields:
		var entry: Variant = snapshot_wands.get(identity)
		var field := WandField.new()
		if not entry is Dictionary or not field.restore(entry):
			return false
		var height: Variant = entry.get("height")
		if typeof(height) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(height)):
			return false
		if field.carried:
			held_count += 1
		elif field.ground_location_id != LOCATION_ID or not _permanent_support_at(field.ground_position, float(height)):
			return false
		next_fields[identity] = field
		next_heights[identity] = float(height)
	if held_count > 1:
		return false
	var before := underside
	_set_underside(WandField.is_outside_all(next_fields.values(), next_position, LOCATION_ID))
	if not super.apply_snapshot(data):
		_set_underside(before)
		return false
	fields = next_fields
	wand_heights = next_heights
	actor.emergency_anchor = Vector3(START_POINT.x, START_POINT.y, LEDGE_Z)
	eyes_open = view["eyes_open"]
	camera.set_mode(view["mode"])
	camera.position = next_camera
	_sync_view()
	queue_redraw()
	return true


func _read_vector(value: Variant) -> Vector2:
	if not value is Array or value.size() != 2:
		return Vector2.INF
	for coordinate in value:
		if typeof(coordinate) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(coordinate)) \
				or absf(float(coordinate)) > 100000.0:
			return Vector2.INF
	return Vector2(float(value[0]), float(value[1]))


func _draw() -> void:
	super._draw()
	if underside:
		_draw_platform(BRIDGE["bounds"], LEDGE_Z, Color("537d9f"))
	for identity in fields:
		var field: WandField = fields[identity]
		if field.carried:
			continue
		var point := field.ground_position - Vector2(0, wand_heights[identity])
		draw_line(point + Vector2(-8, 5), point + Vector2(8, -5), Color("e7c3ee"), 3.0)
		draw_circle(point + Vector2(8, -5), 3.0, Color("f8e7be"))
