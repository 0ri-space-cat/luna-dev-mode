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
const DECKS := [M0, M1_BANK, M2, SOUTH_TURN, DRY_TRAIL, M3]
const CREEK := Rect2(1530, 184, 86, 325)
const CREEK_BED := -112.0
const ICE_BOUNDS := Rect2(1517, 312, 112, 78)
const ICE_SURFACE := {"bounds": ICE_BOUNDS, "height": 0.0, "safe": false}
const ICE_SECONDS := 7.0
const FREEZE_REACH := 62.0
const FOX_ID := "MEADOWS_FOX"
const TROLLIK_ID := "MEADOWS_TROLLIK"


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
