extends Node2D
## Fictional desktop overlay, entirely inside the game's canvas.
const INSET := Vector2(0.16, 0.18)
var active := false
var solid := true
var physics_tick: Callable


func _ready() -> void:
	# Actors move at default priority; constrain the finished step, not the previous one.
	process_physics_priority = 100
	set_physics_process(physics_tick.is_valid())


func _physics_process(_delta: float) -> void:
	if physics_tick.is_valid():
		physics_tick.call()


static func logical_size(size: Vector2) -> Vector2:
	return size if size.x >= 100.0 and size.y >= 100.0 else Vector2(1280, 800)


func _draw() -> void:
	if not active:
		return
	var size := logical_size(get_viewport().get_visible_rect().size)
	var frame := Rect2(size * INSET, size * (Vector2.ONE - INSET * 2.0))
	var ink := Color("343348")
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, frame.position.y)), ink)
	draw_rect(Rect2(Vector2(0, frame.end.y), Vector2(size.x, size.y - frame.end.y)), ink)
	draw_rect(Rect2(Vector2(0, frame.position.y), Vector2(frame.position.x, frame.size.y)), ink)
	draw_rect(Rect2(Vector2(frame.end.x, frame.position.y), Vector2(size.x - frame.end.x, frame.size.y)), ink)
	draw_rect(frame.grow(2.0), Color("b8a8d1") if solid else Color("e5d4fa"), false, 3.0)
	draw_rect(Rect2(frame.position - Vector2(0, 22), Vector2(frame.size.x, 22)), Color("695b86"))
	draw_string(ThemeDB.fallback_font, frame.position + Vector2(9, -6), "LUNA: Dev Mode", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("f1e9fa"))
