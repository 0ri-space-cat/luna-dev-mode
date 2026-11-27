extends Node2D
## Geometric placeholders keep the mouth and feet in the carrier's local space.

var actor
var mouth_radius := 16.0

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var ink := Color("383046")
	var body := Color("f6d9e8")
	var identity: String = actor.record.id
	var at := Vector2(0,-9)
	var radius := 12.0
	if identity == "giant": radius = 28
	mouth_radius = radius
	if actor.record.category == "object" or identity == "fridge":
		draw_rect(Rect2(-13,-30,26,30),body)
		draw_line(Vector2(-12,-20),Vector2(12,-20),ink,2)
	elif identity == "luna":
		draw_circle(at,12,body)
		draw_colored_polygon(PackedVector2Array([Vector2(-17,-18),Vector2(-3,-39),Vector2(14,-18)]),Color.PLUM)
	elif identity in ["fox","glitchfox","cat","watercat","echo_cat","rabbit","squirrel"]:
		for side in [-1,1]:
			draw_colored_polygon(PackedVector2Array([at+Vector2(side*12,0),at+Vector2(side*11,-18),at+Vector2(side*2,-7)]),body)
		draw_circle(at,radius,body)
	else: draw_circle(at,radius,body)
	for side in [-1,1]:
		draw_circle(at+Vector2(side*4,-2),1.8,ink)
		if actor.get_parameter("alive"):
			var step := sin(Time.get_ticks_msec()/85.0)*3 if actor.velocity.length() > 1 else 0.0
			draw_line(Vector2(side*6,-1),Vector2(side*(7+step),4),ink,3)
	if actor.has_ability("FLY"):
		for side in [-1,1]:
			draw_line(at+Vector2(side*7,0),at+Vector2(side*23,-9+sin(Time.get_ticks_msec()/150.0)*5),Color.SKY_BLUE,5)
	if actor.get_parameter("frozen"): draw_arc(at,radius+6,0,TAU,6,Color.CYAN,3)
