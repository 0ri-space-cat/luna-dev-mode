extends Node2D

var tint := Color.GRAY
var paths := {}

func _draw() -> void:
	draw_rect(Rect2(-600,-350,1200,700),tint.darkened(0.45))
	for title in paths:
		var at: Vector2 = paths[title]
		draw_line(Vector2.ZERO,at,Color(tint,0.5),22)
		draw_arc(at,17,0,TAU,8,tint.lightened(0.3),2)
		draw_string(ThemeDB.fallback_font,at+Vector2(-100,36),title,HORIZONTAL_ALIGNMENT_CENTER,200,16)
