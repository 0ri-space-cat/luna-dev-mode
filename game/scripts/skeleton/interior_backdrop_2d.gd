extends RefCounted
## Internal backdrop route. Inactive until an explicitly authored room binds
## its real doorway, static camera and actual HUD control. No address catalog.
const Access = preload("res://scripts/runtime2d/access_state_2d.gd")
const Door = preload("res://scripts/runtime2d/doorway_2d.gd")
const MIN_OUTSIDE_DISTANCE := 68.0
const MAX_STEP := 32.0
const HUD_REACH_PIXELS := 24.0

var source_address := ""
var source_point := Vector2.INF
var _door: Door
var _camera: Camera2D
var _hud: Control
var _room := Rect2()
var _outward := Vector2.ZERO
var _camera_center := Vector2.ZERO
var _camera_zoom := Vector2.ONE
var _actor: Node2D
var _last := Vector2.INF
var _left_room := false
var _crossed_screen := false
var _distance := 0.0
var _used := false


func configure(address: String, door: Door, camera: Camera2D, hud: Control, room: Rect2, outward: Vector2) -> bool:
	if address.is_empty() or not is_instance_valid(door) or door.entity_id.is_empty() or not is_instance_valid(camera) or not is_instance_valid(hud) or not room.has_area() or not outward.is_finite() or outward.length_squared() < 0.5:
		return false
	if not room.grow(door.interaction_radius).has_point(door.global_position):
		return false
	_invalidate()
	source_address = address
	_door = door
	_camera = camera
	_hud = hud
	_room = room
	_outward = outward.normalized()
	return true


func _invalidate() -> void:
	_actor = null
	_last = Vector2.INF
	_left_room = false
	_crossed_screen = false
	_distance = 0.0
	_used = false
	source_point = Vector2.INF


func _can_move(body) -> bool:
	return is_instance_valid(body) and body.motion.grounded and is_zero_approx(float(body.motion.elevation)) and not body.is_attached() and not body.has_passenger() and body.accepts_player_input()


func begin(body, clock) -> bool:
	if source_address.is_empty() or not is_instance_valid(_door) or not is_instance_valid(_camera) or not _camera.is_current() or not _can_move(body) or not _door.is_open_at(clock) or body.get_world_location_id() != source_address:
		return false
	if not is_zero_approx(float(body.motion.elevation)) or not _room.has_point(body.global_position) or not _door.can_interact_from(body.global_position):
		return false
	# Start only at the interior side of the real threshold.
	if (body.global_position - _door.global_position).dot(_outward) > 0.0:
		return false
	_camera.force_update_scroll()
	_camera_center = _camera.get_screen_center_position()
	_camera_zoom = _camera.zoom
	source_point = body.position
	_actor = body
	_last = body.global_position
	_left_room = false
	_crossed_screen = false
	_distance = 0.0
	_used = false
	return true


func _static_camera() -> bool:
	return is_instance_valid(_camera) and _camera.is_current() and _camera.get_screen_center_position().distance_to(_camera_center) < 1.0 and _camera.zoom.is_equal_approx(_camera_zoom)


func _screen_point(body) -> Vector2:
	return _camera.get_canvas_transform() * (body.global_position - Vector2(0, body.motion.elevation))


func on_backdrop() -> bool:
	return _left_room and not _used and is_instance_valid(_actor) and _static_camera() and _can_move(_actor) and _actor.global_position.distance_to(_last) < 1.0


func can_edit_hud(body, access: Access, target: Control) -> bool:
	if not on_backdrop() or body != _actor or not _static_camera() or not _can_move(body) or access.wand_mode != Access.DEVELOPER:
		return false
	if target != _hud or not is_instance_valid(target) or not target.is_visible_in_tree():
		return false
	var bounds: Rect2 = target.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, target.size)
	var screen: Rect2 = _camera.get_viewport().get_visible_rect()
	return bounds.has_area() and screen.has_point(_screen_point(body)) and bounds.grow(HUD_REACH_PIXELS).has_point(_screen_point(body))


func observe(body) -> bool:
	if _used or not is_instance_valid(_actor) or body != _actor:
		return false
	if not _can_move(body) or not _static_camera():
		_invalidate()
		return false
	var current: Vector2 = body.global_position
	var step := current - _last
	var previous := _last
	_last = current
	if not step.is_finite() or step.length() > MAX_STEP:
		_invalidate()
		return false
	if _room.has_point(current):
		_left_room = false
		_crossed_screen = false
		_distance = 0.0
		return false
	if not _left_room:
		if not _room.has_point(previous) or step.dot(_outward) <= 0.0 or not is_instance_valid(_door) or not _door.can_interact_from(previous):
			_invalidate()
			return false
		_left_room = true
	var transform := _camera.get_canvas_transform()
	var screen: Rect2 = _camera.get_viewport().get_visible_rect()
	var elevation := Vector2(0, body.motion.elevation)
	var before := transform * (previous - elevation)
	var after := transform * (current - elevation)
	if screen.has_point(after):
		_crossed_screen = false
		_distance = 0.0
	elif screen.has_point(before):
		_crossed_screen = true
		_distance = 0.0
	elif _crossed_screen:
		# Distance away from the real viewport, not time spent standing still.
		var nearest := after.clamp(screen.position, screen.end)
		_distance = (after - nearest).length() / maxf(_camera_zoom.x, _camera_zoom.y)
	return ready_for_void(body)


func ready_for_void(body) -> bool:
	return on_backdrop() and body == _actor and _can_move(body) and _static_camera() and _crossed_screen and _distance >= MIN_OUTSIDE_DISTANCE and body.global_position.distance_to(_last) < 1.0


func consume(body) -> bool:
	if not ready_for_void(body):
		return false
	_used = true
	return true


func can_use_reverse_door(body, destination: Callable) -> bool:
	# The reverse destination is intentionally not assigned by this adapter.
	return on_backdrop() and body == _actor and _static_camera() and _can_move(body) and destination.is_valid() and is_instance_valid(_door) and _door.can_interact_from(body.global_position) and (body.global_position - _door.global_position).dot(_outward) > 0.0
