extends RefCounted
## W2 open laboratory and one continuous natural cave. No required quest gate.
const APPROACH := Rect2(2100, 505, 150, 45)
const TRAIL := Rect2(2100, 525, 80, 215)
const LAB := Rect2(2010, 710, 170, 145)
const STATION := Vector2(2090, 775)
const LOWER := Rect2(1920, 800, 190, 145)
const SHALLOW := Rect2(1860, 825, 60, 90)
const DEEP := Rect2(1780, 825, 80, 90)
const FAR_BANK := Rect2(1650, 800, 130, 145)
const DRY_SIDE := Rect2(2040, 825, 75, 120)
const EAST_STEP_1 := Rect2(2040, 925, 70, 70)
const EAST_STEP_2 := Rect2(2040, 980, 70, 70)
const WEST_STEP_1 := Rect2(1690, 925, 70, 70)
const WEST_STEP_2 := Rect2(1690, 980, 70, 70)
const UPPER := Rect2(1660, 1035, 450, 90)
const NICHE := Rect2(1650, 1090, 145, 110)
const UPPER_VIEW := Vector2(1875, 1080)
const LOWER_ENTRY := Vector2(1980, 865)
const DECKS := [APPROACH, TRAIL, LAB, LOWER, FAR_BANK, DRY_SIDE]
const ELEVATED := [
	{"bounds": EAST_STEP_1, "height": 6.0, "walk_up": true},
	{"bounds": EAST_STEP_2, "height": 12.0, "walk_up": true},
	{"bounds": WEST_STEP_1, "height": 6.0, "walk_up": true},
	{"bounds": WEST_STEP_2, "height": 12.0, "walk_up": true},
	{"bounds": UPPER, "height": 18.0, "walk_up": true},
	{"bounds": NICHE, "height": 18.0},
]
const WATER := [
	{"bounds": SHALLOW, "height": -4.0, "safe": false},
	{"bounds": DEEP, "height": -24.0, "safe": false},
]


static func contains(point: Vector2) -> bool:
	for deck in DECKS:
		if deck.has_point(point):
			return true
	for surface in ELEVATED + WATER:
		if surface["bounds"].has_point(point):
			return true
	return false


static func draw_on(canvas: Node2D) -> void:
	canvas.draw_rect(LAB, Color("8b8d79"))
	canvas.draw_rect(Rect2(2055, 735, 70, 25), Color("445b60"))
	for x in range(2063, 2120, 16):
		canvas.draw_circle(Vector2(x, 746), 5.0, Color("c4e8c6"))
	canvas.draw_string(ThemeDB.fallback_font, Vector2(2025, 817), "Лаборатория Мии")
	canvas.draw_rect(SHALLOW, Color("739c9b"))
	canvas.draw_rect(DEEP, Color("456d82"))
	for y in range(835, 910, 15):
		canvas.draw_line(Vector2(1788, y), Vector2(1912, y + 3), Color("8ab5b5"), 1.0)
	for surface in ELEVATED:
		canvas.draw_rect(surface["bounds"], Color("858e83"))
		canvas.draw_rect(surface["bounds"], Color("64746b"), false, 2.0)
	canvas.draw_rect(NICHE, Color("303a43"))
	for point in [Vector2(1690, 1140), Vector2(1740, 1160)]:
		canvas.draw_colored_polygon(PackedVector2Array([point + Vector2(-9, 5), point + Vector2(0, -18), point + Vector2(10, 5)]), Color("759aa6"))
	canvas.draw_string(ThemeDB.fallback_font, Vector2(1660, 875), "Пещера")
	canvas.draw_string(ThemeDB.fallback_font, Vector2(1840, 1070), "Верхний уступ")
