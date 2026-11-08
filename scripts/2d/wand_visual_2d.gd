extends Node2D
## Original artifact is a wand; not a UI icon baked into player textures.
var t := 0.0
func _process(delta: float) -> void:
	t += delta
	queue_redraw()
func _draw() -> void:
	draw_line(Vector2(0,17),Vector2(0,-28),Color("#4b2b73"),8,true)
	draw_line(Vector2(0,17),Vector2(0,-28),Color("#d9a1ef"),5,true)
	draw_circle(Vector2(0,-31),12,Color("#532c81"))
	draw_circle(Vector2(0,-31),9,Color("#c063ed"))
	var p := Vector2(0,-31)
	var star := PackedVector2Array([
		p+Vector2(0,-9),p+Vector2(3,-3),p+Vector2(9,0),
		p+Vector2(3,3),p+Vector2(0,9),p+Vector2(-3,3),
		p+Vector2(-9,0),p+Vector2(-3,-3)
	])
	draw_colored_polygon(star,Color("#fff0aa"))
	draw_arc(p, 14.0, 0, TAU, 24, Color("#69f8fb",0.6 + 0.2*sin(t*3.0)), 2)
	draw_circle(p+Vector2(-11,-14),2.5,Color("#f8c3ff"))
