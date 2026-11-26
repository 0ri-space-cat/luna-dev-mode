extends RefCounted
## Reversible continuous graybox F5 -> W0 -> W2 -> W4 -> W6.
## Existing lake shore and old regression route are preserved for this slice.
const LOCATION_ID := "ET_WATERFALL_VALLEY"
const FOREST_ID := "ET_FAIRY_FOREST"
const F5 := Rect2(2070, 140, 120, 145)
const W0 := Rect2(2070, 250, 200, 112)
const W2 := Rect2(2200, 330, 105, 145)
const W4 := Rect2(2250, 385, 100, 90)
const DECKS := [F5, W0, W2, W4]
const LAKE_SHORE_X := 2280.0

static func location_at(point: Vector2) -> String:
	if F5.has_point(point) and point.y < 250.0:
		return FOREST_ID
	if point.x < LAKE_SHORE_X and (W0.has_point(point) or W2.has_point(point) or W4.has_point(point)):
		return LOCATION_ID
	return ""
