extends "res://scripts/skeleton/elevation_fixture.gd"
## Three invisible 2D+Z crossings with identical entrances and a common lower path.

const FollowCamera = preload("res://scripts/runtime2d/camera_follow_lock_2d.gd")
const Observer = preload("res://scripts/runtime2d/observer_query_2d.gd")
const Solidity = preload("res://scripts/runtime2d/observation_body_2d.gd")

const BRIDGE_Z := 48.0
const SPAWN := Vector2(330, 275)
const WEST_LOCK := Vector2(160, 385)
const GROUNDS: Array[Dictionary] = [
	{"bounds": Rect2(85, 100, 880, 455), "height": 0.0},
	{"bounds": Rect2(115, 120, 310, 330), "height": BRIDGE_Z},
	{"bounds": Rect2(705, 120, 240, 330), "height": BRIDGE_Z},
]
const ALWAYS_BRIDGE := {"bounds": Rect2(410, 145, 310, 40), "height": BRIDGE_Z, "safe": false}
const GAZE_BRIDGE := {"bounds": Rect2(410, 255, 310, 40), "height": BRIDGE_Z, "safe": false}
const CAMERA_BRIDGE := {"bounds": Rect2(410, 365, 310, 40), "height": BRIDGE_Z, "safe": false}

var observer := Observer.new()

@onready var camera: FollowCamera = $Camera
@onready var _camera_target: Marker2D = $CameraTarget
@onready var _status: Label = $Interface/Status


func _fixture_key() -> String:
	return "p9_05_observation"


func _ready() -> void:
	_decks.assign(GROUNDS)
	_surfaces.assign(_decks)
	_surfaces.append(ALWAYS_BRIDGE)
	actor = _new_body(ENTITY_ID)
	actor.position = SPAWN
	actor.emergency_anchor = Vector3(SPAWN.x, SPAWN.y, BRIDGE_Z)
	actor.motion.reset_on_surface(SPAWN, BRIDGE_Z)
	add_child(actor)
	camera.target = _camera_target
	camera.make_current()
	_sync_observation()


func _physics_process(_delta: float) -> void:
	if keyboard:
		_apply_keyboard_input()
	if not actor.direction.is_zero_approx():
		observer.facing = actor.direction.normalized()
	_sync_observation()
	_status.text = "%s  ·  %s" % [
		"Камера следует" if camera.mode == FollowCamera.FOLLOW else "Камера закреплена",
		"Глаза открыты" if observer.luna_eyes_open else "Глаза закрыты",
	]


func _apply_keyboard_input() -> void:
	var movement := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	movement.x += float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A))
	movement.y += float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))
	actor.direction = movement.limit_length()
	var jump_down := Input.is_physical_key_pressed(KEY_SPACE)
	if jump_down and not _jump_down:
		actor.jump()
	_jump_down = jump_down


func _unhandled_key_input(event: InputEvent) -> void:
	if not keyboard or not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_E:
			_sync_observation()
			camera.toggle_mode()
			_sync_observation()
			get_viewport().set_input_as_handled()
		KEY_F2:
			observer.luna_eyes_open = not observer.luna_eyes_open
			_sync_observation()
			get_viewport().set_input_as_handled()


func _sync_observation() -> void:
	_camera_target.position = actor.position - Vector2(0, actor.motion.elevation)
	camera.update_follow()
	camera.force_update_scroll()
	var gaze_bounds: Rect2 = GAZE_BRIDGE["bounds"]
	var gaze_state := observer.evaluate(actor, null, gaze_bounds.get_center())
	_set_support(GAZE_BRIDGE, Solidity.solid_for(Solidity.WHEN_UNOBSERVED, Solidity.LUNA, gaze_state))
	var camera_bounds: Rect2 = CAMERA_BRIDGE["bounds"]
	camera_bounds.position.y -= BRIDGE_Z
	var camera_state := {"player_camera": camera.world_view_rect().intersects(camera_bounds)}
	_set_support(CAMERA_BRIDGE, Solidity.solid_for(Solidity.WHEN_UNOBSERVED, Solidity.CAMERA, camera_state))


func _set_support(surface: Dictionary, solid: bool) -> void:
	if solid and not _surfaces.has(surface):
		_surfaces.append(surface)
	elif not solid:
		_surfaces.erase(surface)


func _draw() -> void:
	super._draw()
	for bridge in [ALWAYS_BRIDGE, GAZE_BRIDGE, CAMERA_BRIDGE]:
		var bounds: Rect2 = bridge["bounds"]
		var screen_y := bounds.get_center().y - BRIDGE_Z
		draw_circle(Vector2(405, screen_y), 4.0, Color("cdb8cf"))
		draw_circle(Vector2(723, screen_y), 4.0, Color("cdb8cf"))


func make_snapshot() -> Dictionary:
	var data := super.make_snapshot()
	data["observation"] = {
		"mode": camera.mode, "camera_point": [camera.position.x, camera.position.y],
		"eyes_open": observer.luna_eyes_open, "facing": [observer.facing.x, observer.facing.y],
	}
	return data


func apply_snapshot(data: Dictionary) -> bool:
	var state: Variant = data.get("observation")
	if not state is Dictionary or state.get("mode") not in [FollowCamera.FOLLOW, FollowCamera.LOCKED] \
			or not state.get("eyes_open") is bool:
		return false
	var camera_point := _read_vector(state.get("camera_point"))
	var facing := _read_vector(state.get("facing"))
	if not camera_point.is_finite() or not facing.is_finite() or not is_equal_approx(facing.length(), 1.0):
		return false
	var candidate := _snapshot_with_rechecked_support(data)
	if not super.apply_snapshot(candidate):
		return false
	actor.emergency_anchor = Vector3(SPAWN.x, SPAWN.y, BRIDGE_Z)
	camera.set_mode(state["mode"])
	camera.position = camera_point
	observer.luna_eyes_open = state["eyes_open"]
	observer.facing = facing
	_sync_observation()
	return true


func _snapshot_with_rechecked_support(data: Dictionary) -> Dictionary:
	var saved_body: Variant = data.get("actor")
	if not saved_body is Dictionary or not saved_body.get("motion") is Dictionary:
		return data
	var motion_state: Dictionary = saved_body["motion"]
	if motion_state.get("grounded") != true or motion_state.get("elevation") != BRIDGE_Z \
			or motion_state.get("vertical_speed") != 0:
		return data
	var point := _read_vector(saved_body.get("position"))
	if not point.is_finite():
		return data
	for deck in GROUNDS:
		if deck["height"] == BRIDGE_Z and deck["bounds"].has_point(point):
			return data
	for bridge in [GAZE_BRIDGE, CAMERA_BRIDGE]:
		if bridge["bounds"].has_point(point):
			# Recheck a conditional contact with the restored observers on the next physics tick.
			var candidate := data.duplicate(true)
			candidate["actor"]["motion"]["grounded"] = false
			return candidate
	return data


func _read_vector(value: Variant) -> Vector2:
	if not value is Array or value.size() != 2:
		return Vector2.INF
	for coordinate in value:
		if typeof(coordinate) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(coordinate)) \
				or absf(float(coordinate)) > 100000.0:
			return Vector2.INF
	return Vector2(float(value[0]), float(value[1]))
