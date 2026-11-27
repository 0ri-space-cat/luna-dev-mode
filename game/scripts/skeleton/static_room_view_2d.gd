extends Node2D
## Frames a single room from its authored bounds. Movement and masks of
## individual objects stay in the world; this layer has no input or physics.

const ART_OVERHANG := Vector2(26, 46)
const MATTE := Color("252136")

var bounds := Rect2()
var camera: Camera2D


func set_room(room: Rect2) -> void:
	if bounds == room:
		return
	bounds = room
	visible = bounds.has_area()
	queue_redraw()


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()


func screen_aperture() -> Rect2:
	if not bounds.has_area() or camera == null:
		return Rect2()
	var margin := Rect2(bounds.position - ART_OVERHANG, bounds.size + ART_OVERHANG * 2.0)
	var transform := camera.get_canvas_transform()
	return (transform * margin).intersection(get_viewport_rect())


func _draw() -> void:
	var viewport := get_viewport_rect()
	var aperture := screen_aperture()
	if not aperture.has_area():
		draw_rect(viewport, MATTE)
		return
	draw_rect(Rect2(viewport.position, Vector2(viewport.size.x, aperture.position.y)), MATTE)
	draw_rect(Rect2(0, aperture.end.y, viewport.size.x, viewport.end.y - aperture.end.y), MATTE)
	draw_rect(Rect2(0, aperture.position.y, aperture.position.x, aperture.size.y), MATTE)
	draw_rect(Rect2(aperture.end.x, aperture.position.y, viewport.end.x - aperture.end.x, aperture.size.y), MATTE)
