extends Node2D
## Transient in-world graybox staging. Never an Entity, inventory item,
## ability source, physical route or persisted character profile.
const PixelSteps = preload("res://scripts/skeleton/pixel_air_steps_2d.gd")
const INTRO_SECONDS := 2.4
const MERGE_SECONDS := 1.4
const FAREWELL_SECONDS := 1.6
const PIXEL_START := Vector2(455, 400)
const PIXEL_END := Vector2(520, 330)
const STEP_POINTS := [Vector2(455, 400), Vector2(479, 378), Vector2(500, 355), PIXEL_END]
const STEP_HEIGHTS := [0.0, 18.0, 36.0, 54.0]
var steps := PixelSteps.new()
var _pixel_marker: Node2D
var _step_index := 0
var _surfaces: Array[Dictionary] = []
var intro_remaining := 0.0
var merge_remaining := 0.0
var farewell_remaining := 0.0
var farewell_active := false
var center := Vector2.ZERO


func begin_intro(surfaces: Array[Dictionary]) -> void:
	clear()
	_surfaces = surfaces
	_pixel_marker = Node2D.new()
	add_child(_pixel_marker)
	_pixel_marker.position = STEP_POINTS[0]
	steps.bind(_pixel_marker)
	_step_index = 0
	intro_remaining = INTRO_SECONDS
	queue_redraw()


func begin_merge(point: Vector2) -> void:
	intro_remaining = 0.0
	center = point
	merge_remaining = MERGE_SECONDS
	queue_redraw()


func begin_farewell(point: Vector2) -> void:
	center = point
	farewell_active = true
	farewell_remaining = FAREWELL_SECONDS
	queue_redraw()


func clear() -> void:
	steps.clear(_surfaces)
	_surfaces = []
	if is_instance_valid(_pixel_marker):
		_pixel_marker.queue_free()
	_pixel_marker = null
	_step_index = 0
	intro_remaining = 0.0
	merge_remaining = 0.0
	farewell_remaining = 0.0
	farewell_active = false
	queue_redraw()


func advance(delta: float) -> bool:
	var had_steps := steps.active_count() > 0
	steps.advance(delta, _surfaces)
	if had_steps:
		queue_redraw()
	if intro_remaining > 0.0 or merge_remaining > 0.0 or farewell_active:
		var was_intro := intro_remaining > 0.0
		intro_remaining = maxf(0.0, intro_remaining - delta)
		if was_intro and is_instance_valid(_pixel_marker):
			var elapsed := INTRO_SECONDS - intro_remaining
			var next := mini(3, maxi(0, int(floor((elapsed - 0.55) / 0.45)) + 1))
			while _step_index < next:
				_step_index += 1
				_pixel_marker.position = STEP_POINTS[_step_index]
				steps.observe_step(_pixel_marker, STEP_HEIGHTS[_step_index], _surfaces)
		merge_remaining = maxf(0.0, merge_remaining - delta)
		farewell_remaining = maxf(0.0, farewell_remaining - delta)
		queue_redraw()
	return farewell_active and farewell_remaining <= 0.0


func _draw() -> void:
	for surface in steps.live_surfaces():
		var bounds: Rect2 = surface["bounds"]
		bounds.position.y -= float(surface["height"])
		draw_rect(bounds, Color(0.65, 0.86, 0.97, 0.35))
		draw_rect(bounds, Color(0.49, 0.72, 0.90, 0.85), false, 2.0)
	if intro_remaining > 0.0 and is_instance_valid(_pixel_marker):
		var p := _pixel_marker.position - Vector2(0.0, STEP_HEIGHTS[_step_index])
		var alpha := clampf(intro_remaining / 0.45, 0.0, 1.0)
		_draw_pixel(p, alpha, _step_index == 0)
	if merge_remaining > 0.0:
		var progress := 1.0 - merge_remaining / MERGE_SECONDS
		var alpha := sin(progress * PI)
		draw_circle(center - Vector2(0, 16), 24.0 + progress * 36.0, Color(0.98, 0.78, 0.30, alpha * 0.28))
		draw_arc(center - Vector2(0, 16), 20.0 + progress * 18.0, 0, TAU, 40, Color(0.90, 0.64, 0.22, alpha), 3.0, true)
	if farewell_active and farewell_remaining > 0.0:
		_draw_pixel(center + Vector2(38, -24), farewell_remaining / FAREWELL_SECONDS, false)


func _draw_pixel(p: Vector2, alpha: float, wink: bool) -> void:
	var ink := Color(0.66, 0.59, 0.78, alpha)
	var light := Color(0.99, 0.98, 1.0, alpha)
	draw_circle(p, 12.0, ink)
	draw_circle(p, 10.0, light)
	draw_colored_polygon(PackedVector2Array([p + Vector2(-9, -5), p + Vector2(-10, -17), p + Vector2(-1, -8)]), ink)
	draw_colored_polygon(PackedVector2Array([p + Vector2(9, -5), p + Vector2(10, -17), p + Vector2(1, -8)]), ink)
	draw_circle(p + Vector2(-4, 0), 1.6, ink)
	if wink:
		draw_line(p + Vector2(2, 0), p + Vector2(6, 0), ink, 1.5, true)
	else:
		draw_circle(p + Vector2(4, 0), 1.6, ink)
