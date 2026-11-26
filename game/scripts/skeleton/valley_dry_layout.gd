extends RefCounted
## Reversible continuous graybox F5 -> W0 -> W2 -> W4 -> W6.
## W1 adds the ordinary lake and a dry loop between W0 and W2.
## Existing duplicate lake and legacy route remain unchanged.
const LOCATION_ID := "ET_WATERFALL_VALLEY"
const FOREST_ID := "ET_FAIRY_FOREST"
const F5 := Rect2(2070, 140, 120, 145)
const W0 := Rect2(2070, 250, 200, 112)
const W2 := Rect2(2200, 330, 105, 145)
const W4 := Rect2(2250, 385, 100, 90)
const ORDINARY_POOL := Rect2(2080, 375, 90, 90)
const ORDINARY_BED := -32.0
const W1_NORTH := Rect2(2035, 340, 190, 35)
const W1_WEST := Rect2(2035, 365, 45, 110)
const W1_SOUTH := Rect2(2035, 465, 190, 45)
const W1_EAST := Rect2(2170, 365, 55, 110)
const W1_DECKS := [W1_NORTH, W1_WEST, W1_SOUTH, W1_EAST]
const DECKS := [F5, W0, W2, W4, W1_NORTH, W1_WEST, W1_SOUTH, W1_EAST]
const LAKE_SHORE_X := 2280.0

static func location_at(point: Vector2) -> String:
	for bank in W1_DECKS:
		if bank.has_point(point):
			return LOCATION_ID
	if ORDINARY_POOL.has_point(point):
		return LOCATION_ID
	return location_at_v1(point)


static func location_at_v1(point: Vector2) -> String:
	if F5.has_point(point) and point.y < 250.0:
		return FOREST_ID
	if point.x < LAKE_SHORE_X and (W0.has_point(point) or W2.has_point(point) or W4.has_point(point)):
		return LOCATION_ID
	return ""


static func draw_on(canvas: Node2D) -> void:
	canvas.draw_rect(ORDINARY_POOL, Color("527f86"))
	canvas.draw_rect(ORDINARY_POOL.grow(-5), Color("7baba9"), false, 2.0)
	for y in range(385, 460, 18):
		canvas.draw_line(Vector2(2090, y), Vector2(2157, y + 4), Color("79a5a7"), 1.0)
	var font := ThemeDB.fallback_font
	canvas.draw_string(font, Vector2(2085, 280), "Каскады")
	canvas.draw_string(font, Vector2(2038, 500), "Тихое озеро")
	canvas.draw_string(font, Vector2(2205, 370), "Речная тропа")
