extends RefCounted
## Continuous P9-03 graybox. Flat dry paths run above the ravine and creek bed.

const LOCATION_ID := "ET_MEADOWS_MAIN"
const WEST_BOUNDARY := 1200.0
const M0 := Rect2(1140, 244, 264, 305)
const M1_BANK := Rect2(1330, 218, 200, 222)
const M2 := Rect2(1616, 206, 335, 277)
const SOUTH_TURN := Rect2(1232, 491, 212, 133)
const DRY_TRAIL := Rect2(1370, 565, 638, 134)
const M3 := Rect2(1840, 416, 168, 240)
# Provisional physical geography: two ordinary, dry meadow clearings.
# No new address, collectible, secret gate, puzzle or objective.
const QUIET_NORTH := Rect2(1210, 24, 185, 270)
const QUIET_SOUTH := Rect2(1600, 625, 365, 355)
const QUIET_DECKS := [QUIET_NORTH, QUIET_SOUTH]
const DECKS := [M0, M1_BANK, M2, SOUTH_TURN, DRY_TRAIL, M3] + QUIET_DECKS
const QUIET_FAUNA := {
	"M_QUIET_FOX_N": {"category": "fox", "label": "Лисичка", "point": Vector2(1290, 115), "size": 0.72, "speed": 0.85},
	"M_QUIET_TURTLE_N": {"category": "turtle", "label": "Черепашка", "point": Vector2(1330, 190), "size": 0.8, "speed": 0.35},
	"M_QUIET_FOX_S": {"category": "fox", "label": "Лисичка", "point": Vector2(1720, 825), "size": 0.95, "speed": 1.1},
	"M_QUIET_TURTLE_S": {"category": "turtle", "label": "Черепашка", "point": Vector2(1850, 865), "size": 1.05, "speed": 0.5},
}
const CREEK := Rect2(1530, 184, 86, 325)
const CREEK_BED := -112.0
const ICE_BOUNDS := Rect2(1517, 312, 112, 78)
const ICE_SURFACE := {"bounds": ICE_BOUNDS, "height": 0.0, "safe": false}
const ICE_SECONDS := 7.0
const FREEZE_REACH := 62.0
const FOX_ID := "MEADOWS_FOX"
const TROLLIK_ID := "MEADOWS_TROLLIK"
const PLANK_ID := "MEADOWS_PLANK"
const PLANK_START := Vector2(1435, 410)
const PLANK_SIZE := Vector2(124, 42)
const PLANK_BANK_OVERLAP := 8.0
const CAMP_SPOT := Vector2(1290, 495)


static func plank_support(point: Vector2, scale_factor: float) -> Dictionary:
	var size := PLANK_SIZE * scale_factor
	var bounds := Rect2(point - size / 2.0, size)
	if not CREEK.has_point(point):
		return {}
	var left := CREEK.position.x - PLANK_BANK_OVERLAP
	var right := CREEK.end.x + PLANK_BANK_OVERLAP
	if bounds.position.x > left or bounds.end.x < right:
		return {}
	if not M1_BANK.has_point(Vector2(left, bounds.position.y)) \
			or not M1_BANK.has_point(Vector2(left, bounds.end.y)) \
			or not M2.has_point(Vector2(right, bounds.position.y)) \
			or not M2.has_point(Vector2(right, bounds.end.y)):
		return {}
	return {"bounds": bounds, "height": 0.0, "safe": false}


static func draw_on(canvas: Node2D, frozen: bool) -> void:
	canvas.draw_rect(CREEK, Color("487d92"))
	for y in range(216, 500, 26):
		canvas.draw_line(Vector2(1542, y), Vector2(1604, y + 11), Color("639bae"), 1.5)
	if frozen:
		canvas.draw_rect(ICE_BOUNDS, Color("a9dbdf"))
		canvas.draw_rect(ICE_BOUNDS, Color("d2eff1"), false, 2.0)
	var font := ThemeDB.fallback_font
	canvas.draw_string(font, Vector2(1224, 329), "Перепутье")
	canvas.draw_string(font, Vector2(1420, 300), "Ручей")
	canvas.draw_string(font, Vector2(1694, 270), "Большая поляна")
	canvas.draw_string(font, Vector2(1870, 597), "Высокий край")
	canvas.draw_circle(Vector2(1770, 300), 33.0, Color("779080"))
	canvas.draw_rect(Rect2(1925, 543, 38, 17), Color("9a8a87"))
	canvas.draw_circle(CAMP_SPOT, 18.0, Color("6a574a"))
	canvas.draw_circle(CAMP_SPOT, 9.0, Color("f4ad62"))
	canvas.draw_circle(CAMP_SPOT + Vector2(0, -3), 4.0, Color("ffe2a0"))
	canvas.draw_rect(Rect2(CAMP_SPOT + Vector2(20, -9), Vector2(30, 18)), Color("d0afbc"))
