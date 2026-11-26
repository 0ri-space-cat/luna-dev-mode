extends RefCounted
## Dry approach from the high edge to a small test section of W6.

const LOCATION_ID := "ET_DUPLICATE_LAKE_CAVERN"
const LEGACY_LOCATION_ID := "ET_WATERFALL_DUPLICATE_LAKE"
const FEATURE_ID := "ET_DUPLICATE_LAKE"
const BOUNDARY := 2260.0
const SHORE := Vector2(2445, 426)
const CONTACT := Vector2(2490, 426)
const BED_HEIGHT := -32.0
const POOL := Rect2(2490, 345, 203, 160)
const DECKS := [Rect2(1942, 561, 425, 83), Rect2(2280, 326, 210, 302),
	Rect2(2490, 505, 270, 93), Rect2(2490, 282, 270, 63), Rect2(2693, 330, 110, 188)]


static func draw_on(canvas: Node2D) -> void:
	canvas.draw_rect(POOL, Color("465884"))
	canvas.draw_rect(POOL.grow(-9), Color("737fb4"), false, 2.0)
	canvas.draw_string(ThemeDB.fallback_font, Vector2(2360, 314), "Озеро Дубликатов")
