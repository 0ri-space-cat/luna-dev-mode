extends Node2D
## Small optional riverbank on a dry offshoot of the forest walk.

const LOCATION_ID := "ET_FAIRY_FOREST"
const EDGE := Rect2(1848, 108, 106, 155)
const FOREST := Rect2(1823, -120, 385, 290)
const RIVER := Rect2(1990, -164, 218, 44)
const MEANDER := Rect2(1995, -144, 209, 126)
const DECKS := [EDGE, FOREST]
const FIGURE := Vector2(2113, -90)
const REST_SPOT := Rect2(FIGURE + Vector2(-33, -8), Vector2(75, 29))
const INTERACTION_POINT := FIGURE + Vector2(6, 8)
const INTERACTION_REACH := 39.0
const ANSWER_SECONDS := 0.68

var remaining := 0.0
var _answer: Label


func _ready() -> void:
	_answer = Label.new()
	_answer.text = "…"
	_answer.position = FIGURE + Vector2(-38, -47)
	_answer.hide()
	add_child(_answer)


func respond() -> void:
	remaining = ANSWER_SECONDS
	_answer.show()
	queue_redraw()


func can_interact(feet: Vector2, height: float) -> bool:
	return FOREST.has_point(feet) and MEANDER.has_point(feet) and Vector3(feet.x - INTERACTION_POINT.x,
		feet.y - INTERACTION_POINT.y, height).length_squared() <= INTERACTION_REACH * INTERACTION_REACH


func _process(delta: float) -> void:
	if remaining <= 0.0:
		return
	remaining = maxf(0.0, remaining - delta)
	if remaining == 0.0:
		_answer.hide()
	queue_redraw()


func _draw() -> void:
	draw_rect(RIVER, Color("48777d"))
	draw_line(RIVER.position + Vector2(10, 31), RIVER.end + Vector2(-10, -13), Color("609092"), 2.0)
	for root_tip in [Vector2(1882, -87), Vector2(1917, -74), Vector2(1970, -107), Vector2(1953, 99),
			Vector2(1990, 96), Vector2(2085, -8), Vector2(2168, 33)]:
		draw_circle(root_tip, 13.0, Color("496657"))
		draw_line(root_tip + Vector2(-10, 8), root_tip + Vector2(10, -7), Color("749486"), 2.0)
	var blanket := Rect2(FIGURE + Vector2(-18, -3), Vector2(56, 23))
	draw_rect(blanket.grow(5.0), Color("514e61"))
	draw_rect(blanket, Color("9690a2"))
	draw_line(blanket.position + Vector2(6, 5), blanket.end - Vector2(5, 8), Color("b8aaaf"), 2.0)
	var head := FIGURE + Vector2(-25, 0)
	if remaining > 0.0:
		head.y -= 7.0 * minf(remaining * 12.0, 1.0)
	draw_circle(head, 8.0, Color("bca3ac"))
