extends Camera2D
## The camera never suspends world simulation. No third camera mode is defined.

signal mode_changed(new_mode: String)

const FOLLOW := "FOLLOW"
const LOCKED := "LOCKED"

var mode := FOLLOW
var target: Node2D


func _process(_delta: float) -> void:
	update_follow()


func update_follow() -> void:
	if mode == FOLLOW and is_instance_valid(target):
		global_position = target.global_position


func set_mode(value: String) -> bool:
	if value != FOLLOW and value != LOCKED:
		return false
	if value == mode:
		return true
	mode = value
	mode_changed.emit(mode)
	return true


func toggle_mode() -> void:
	set_mode(LOCKED if mode == FOLLOW else FOLLOW)


func contains_world_point(point: Vector2) -> bool:
	# Screen-rectangle observation only. Eye contact and line-of-sight remain
	# separate physical/perception rules, not inferred from a sprite's visibility.
	return world_view_rect().has_point(point)


func world_view_rect() -> Rect2:
	var extent: Vector2 = get_viewport_rect().size / zoom
	return Rect2(get_screen_center_position() - extent * 0.5, extent)
