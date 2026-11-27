extends Node2D
## Transient in-world graybox staging. Never an Entity, inventory item,
## ability source, physical route or persisted character profile.
const INTRO_SECONDS := 2.4
const MERGE_SECONDS := 1.4
const FAREWELL_SECONDS := 1.6
const PIXEL_START := Vector2(455, 400)
const PIXEL_END := Vector2(520, 330)
var intro_remaining := 0.0
var merge_remaining := 0.0
var farewell_remaining := 0.0
var farewell_active := false
var center := Vector2.ZERO


func begin_intro() -> void:
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
	intro_remaining = 0.0
	merge_remaining = 0.0
	farewell_remaining = 0.0
	farewell_active = false
	queue_redraw()


func advance(delta: float) -> bool:
	if intro_remaining > 0.0 or merge_remaining > 0.0 or farewell_active:
		intro_remaining = maxf(0.0, intro_remaining - delta)
		merge_remaining = maxf(0.0, merge_remaining - delta)
		farewell_remaining = maxf(0.0, farewell_remaining - delta)
		queue_redraw()
	return farewell_active and farewell_remaining <= 0.0


func _draw() -> void:
	if intro_remaining > 0.0:
		var progress := 1.0 - intro_remaining / INTRO_SECONDS
		var p := PIXEL_START.lerp(PIXEL_END, clampf((progress - 0.25) / 0.75, 0.0, 1.0))
		var alpha := clampf(intro_remaining / 0.45, 0.0, 1.0)
		# Temporary presentation only; AIR_STEP collision and final animation
		# are not implemented by these markers.
		_draw_pixel(p, alpha, progress < 0.25)
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
