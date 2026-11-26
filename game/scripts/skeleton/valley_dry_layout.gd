extends RefCounted
## Reversible continuous graybox F5 -> W0 -> W2 -> W4 -> W6.
## W1 adds the ordinary lake and a dry loop between W0 and W2.
## M3.82: W3 dry tower site, W0 invisible support, and W2 route to K0.
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
const CRYSTAL_ID := "ET_CRYSTAL_CAVES"
const W7_APPROACH := Rect2(2770, 375, 150, 88)
const W7_NICHE := Rect2(2870, 300, 245, 200)
const W7_ENTRY := Vector2(2945, 415)
const W7_DECKS := [W7_APPROACH, W7_NICHE]
# Ordinary road remains independent of these optional branches.
const W3_SITE := Rect2(1970, 330, 83, 79)
const W3_VIEW := Vector2(2005, 370)
const RAIN_BRIDGE_ID := "BRIDGE_I_RAINFALL"
const RAIN_BRIDGE := Rect2(2250, 265, 95, 45)
const RAIN_LANDING := Rect2(2330, 245, 95, 75)
const RIVER_LINK := Rect2(2210, 445, 65, 300)
const DECKS := [F5, W0, W2, W4, W1_NORTH, W1_WEST, W1_SOUTH, W1_EAST,
	W7_APPROACH, W7_NICHE, W3_SITE, RAIN_LANDING, RIVER_LINK]
const LAKE_SHORE_X := 2280.0

static func location_at(point: Vector2) -> String:
	if W3_SITE.has_point(point) or RAIN_BRIDGE.has_point(point) \
			or RAIN_LANDING.has_point(point) or RIVER_LINK.has_point(point):
		return LOCATION_ID
	return location_at_v3(point)


static func location_at_v3(point: Vector2) -> String:
	if point.x >= 2803.0:
		for deck in W7_DECKS:
			if deck.has_point(point):
				return CRYSTAL_ID
	return location_at_v2(point)


static func location_at_v2(point: Vector2) -> String:
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
	# A dry site for the phase-dependent tower, not the tower interior yet.
	canvas.draw_string(font, Vector2(1974, 351), "Уступ")
	# Water spray reveals an otherwise unrendered support. Its collider is
	# independent of this presentation and never changes with observation.
	for x in range(2274, 2330, 8):
		canvas.draw_line(Vector2(x, 252), Vector2(x + 4, 278), Color("8bbac2"), 1.3)
		canvas.draw_circle(Vector2(x + 4, 280), 2.0, Color("c4e1df"))
	canvas.draw_string(font, Vector2(2217, 690), "К морю ↓")
	# Temporary silhouettes only: production crystal artwork will replace these.
	for point in [Vector2(2910, 335), Vector2(3035, 342), Vector2(3065, 470)]:
		canvas.draw_colored_polygon(PackedVector2Array([point + Vector2(-12, 7), point + Vector2(-8, -20), point + Vector2(3, -30), point + Vector2(14, -10), point + Vector2(12, 7)]), Color("7886aa"))
		canvas.draw_line(point + Vector2(3, -30), point + Vector2(3, 7), Color("bac6df"), 2.0)
	canvas.draw_string(font, Vector2(2895, 386), "Кристальные пещеры")
