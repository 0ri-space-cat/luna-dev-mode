extends Node2D
## Temporary modular cartoon avatar; replace with rigged sprites without touching physics.
var elapsed := 0.0
func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()
func _draw() -> void:
	var parent: CharacterBody2D = get_parent() as CharacterBody2D
	if parent == null:
		return
	var motion := clampf(parent.velocity.length() / 220.0, 0.0, 1.0)
	var swing := sin(elapsed * 11.0) * 9.0 * motion
	var bob := sin(elapsed * 3.0) * 1.5 + absf(sin(elapsed * 11.0)) * 2.0 * motion
	draw_circle(Vector2(0, 16), 20.0, Color(0.12, 0.07, 0.23, 0.25))
	draw_line(Vector2(-10, -1), Vector2(-12 + swing, 17), Color("#f5a8d5"), 10)
	draw_line(Vector2(10, -1), Vector2(12 - swing, 17), Color("#f5a8d5"), 10)
	draw_circle(Vector2(-12 + swing, 17), 7, Color("#7b3fa7"))
	draw_circle(Vector2(12 - swing, 17), 7, Color("#7b3fa7"))
	draw_rect(Rect2(-19, -35 - bob, 38, 38), Color("#a464da"))
	draw_circle(Vector2(0, -47 - bob), 21, Color("#f5bbdc"))
	draw_circle(Vector2(-9, -48 - bob), 5, Color.WHITE)
	draw_circle(Vector2(9, -48 - bob), 5, Color.WHITE)
	draw_circle(Vector2(-8, -47 - bob), 2, Color("#38304f"))
	draw_circle(Vector2(9, -47 - bob), 2, Color("#38304f"))
	draw_arc(Vector2(1,-36-bob),7,0.1,PI-0.1,12,Color("#643677"),2)
	draw_colored_polygon(PackedVector2Array([Vector2(-33, -61-bob),Vector2(0,-103-bob),Vector2(30,-61-bob)]),Color("#7847b6"))
	draw_line(Vector2(-30,-62-bob),Vector2(30,-62-bob),Color("#d17ef2"),7)
	draw_line(Vector2(17,-27-bob),Vector2(30,-42-bob),Color("#f8c6e4"),8)
	draw_line(Vector2(30,-42-bob),Vector2(42,-70-bob),Color("#ae69e3"),4)
	draw_circle(Vector2(42,-70-bob),9,Color("#f4a4f3"))
	draw_circle(Vector2(42,-70-bob),4,Color("#68f0f5"))
