extends RefCounted
## W5: real submerged corridor with two dry air shelves and one shared W6.
const LOCATION_ID := "ET_WATERFALL_UNDERWATER"
const WEST := Rect2(3820, 370, 95, 110)
const EAST := Rect2(4340, 370, 95, 110)
const WEST_EXIT := Vector2(3860, 425)
const EAST_EXIT := Vector2(4390, 425)
const W1_MOUTH := Vector2(2125, 420)
const W1_RETURN := Vector2(2125, 357)
const W6_MOUTH := Vector2(2520, 425)
const WATER := Rect2(3915, 385, 425, 80)
const BED := -32.0
const DECKS := [WEST, EAST]
const WATER_SURFACES := [
	{"bounds": WATER, "height": BED, "safe": false},
	{"bounds": Rect2(3915, 385, 40, 80), "height": -4.0, "safe": false, "walk_up": true},
	{"bounds": Rect2(3950, 385, 40, 80), "height": -10.0, "safe": false, "walk_up": true},
	{"bounds": Rect2(3985, 385, 40, 80), "height": -16.0, "safe": false, "walk_up": true},
	{"bounds": Rect2(4020, 385, 40, 80), "height": -22.0, "safe": false, "walk_up": true},
	{"bounds": Rect2(4055, 385, 40, 80), "height": -28.0, "safe": false, "walk_up": true},
	{"bounds": Rect2(4165, 385, 40, 80), "height": -28.0, "safe": false, "walk_up": true},
	{"bounds": Rect2(4200, 385, 40, 80), "height": -22.0, "safe": false, "walk_up": true},
	{"bounds": Rect2(4235, 385, 40, 80), "height": -16.0, "safe": false, "walk_up": true},
	{"bounds": Rect2(4270, 385, 40, 80), "height": -10.0, "safe": false, "walk_up": true},
	{"bounds": Rect2(4305, 385, 35, 80), "height": -4.0, "safe": false, "walk_up": true},
	{"bounds": WEST, "height": 0.0, "walk_up": true},
	{"bounds": EAST, "height": 0.0, "walk_up": true},
]


static func contains(point: Vector2) -> bool:
	return WEST.has_point(point) or EAST.has_point(point) or WATER.has_point(point)


static func draw_on(canvas: Node2D) -> void:
	canvas.draw_rect(WATER, Color("324e69"))
	for surface in WATER_SURFACES:
		if float(surface["height"]) < 0.0:
			canvas.draw_rect(surface["bounds"], Color("587b83"), false, 1.0)
	for x in range(3928, 4330, 29):
		canvas.draw_line(Vector2(x, 455), Vector2(x + 4, 440), Color("749b89"), 2.0)
	for point in [WEST_EXIT, EAST_EXIT]:
		canvas.draw_circle(point, 15.0, Color("b0c6c0"), false, 2.0)
		canvas.draw_circle(point, 4.0, Color("e3dfac"))
	canvas.draw_string(ThemeDB.fallback_font, Vector2(3825, 398), "Воздух")
	canvas.draw_string(ThemeDB.fallback_font, Vector2(4350, 398), "Воздух")
	canvas.draw_string(ThemeDB.fallback_font, Vector2(4040, 380), "Подводный ход")
	canvas.draw_arc(W1_MOUTH, 15.0, 0.0, TAU, 20, Color("a2c5c1"), 2.0)
	canvas.draw_arc(W6_MOUTH, 15.0, 0.0, TAU, 20, Color("9dafe5"), 2.0)
