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
const SHALLOW_SURFACE := {"bounds": Rect2(2490, 395, 45, 60), "height": -4.0, "safe": false}
# Keep the ordinary stone clear of the pre-existing ecology catalog.
const STONE_START := Vector2(2385, 455)
const BIRTH_POINTS := [Vector2(2410, 400), Vector2(2455, 400), Vector2(2410, 445),
	Vector2(2455, 450), Vector2(2380, 425), Vector2(2445, 485)]
const DECKS := [Rect2(1942, 561, 425, 83), Rect2(2280, 326, 210, 302),
	Rect2(2490, 505, 270, 93), Rect2(2490, 282, 270, 63), Rect2(2693, 330, 110, 188)]


static func draw_on(canvas: Node2D) -> void:
	canvas.draw_rect(POOL, Color("465884"))
	canvas.draw_rect(POOL.grow(-9), Color("737fb4"), false, 2.0)
	canvas.draw_string(ThemeDB.fallback_font, Vector2(2360, 314), "Озеро Дубликатов")


static func draw_shallow_on(canvas: Node2D) -> void:
	canvas.draw_rect(SHALLOW_SURFACE["bounds"], Color("8399b7"))
	canvas.draw_line(Vector2(2492, 405), Vector2(2528, 408), Color("aabccf"), 1.3)
