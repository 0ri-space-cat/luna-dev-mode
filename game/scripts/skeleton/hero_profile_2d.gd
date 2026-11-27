extends RefCounted
## First technical profile slice. Selection never creates or replaces an Entity,
## wand, ability instance or inventory. Other profiles require their own gates.
const LUNA := "LUNA"
const ONI := "ONI"
const NAMES := {LUNA: "Луна", ONI: "Они"}
var active := LUNA


func available(oni_deep_met: bool) -> Array[String]:
	var ids: Array[String] = [LUNA]
	if oni_deep_met:
		ids.append(ONI)
	return ids


func restore(value: Variant, oni_deep_met: bool) -> bool:
	if not value is String or value not in available(oni_deep_met):
		return false
	active = value
	return true


func choose(value: String, oni_deep_met: bool, authorized: bool) -> bool:
	return authorized and restore(value, oni_deep_met)


func sees_underside(eyes_open: bool) -> bool:
	return active == ONI and not eyes_open


static func within_projected_control(body: Node2D, camera: Camera2D, target: Control, reach: float) -> bool:
	if not is_instance_valid(body) or not is_instance_valid(camera) or not camera.is_current() or not is_instance_valid(target) or not target.is_visible_in_tree():
		return false
	camera.force_update_scroll()
	var screen: Rect2 = camera.get_viewport().get_visible_rect()
	var bounds: Rect2 = target.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, target.size)
	var point: Vector2 = camera.get_canvas_transform() * body.global_position
	return bounds.has_area() and screen.has_point(point) and bounds.grow(reach).has_point(point)
