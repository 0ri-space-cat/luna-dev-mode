extends RefCounted
## W7 optional physical observation branch; no W8 or H1 shortcut.
const BRIDGE_ID := "BRIDGE_II_CRYSTAL"
const DOOR_ID := "DOOR_EYES_CLOSED_CRYSTAL"
const BRIDGE := {"bounds": Rect2(3105, 385, 110, 60), "height": 0.0, "safe": false, "feature_id": BRIDGE_ID}
const LOWER := {"bounds": Rect2(3060, 350, 180, 125), "height": -24.0, "safe": false}
const FAR := Rect2(3205, 365, 125, 95)
const CORRIDOR := Rect2(3315, 385, 110, 55)
const ROOM := Rect2(3410, 350, 75, 120)
const DECKS := [FAR, CORRIDOR, ROOM]
const DOOR := {"bounds": Rect2(3350, 381, 14, 63), "height": 96.0, "layer": 8, "feature_id": DOOR_ID}
const NEAR_POINT := Vector2(3080, 415)
const FAR_POINT := Vector2(3250, 415)
const ROOM_POINT := Vector2(3445, 415)


static func contains(point: Vector2) -> bool:
	if BRIDGE["bounds"].has_point(point) or LOWER["bounds"].has_point(point):
		return true
	for deck in DECKS:
		if deck.has_point(point):
			return true
	return false


static func draw_on(canvas: Node2D, door_solid: bool) -> void:
	canvas.draw_rect(LOWER["bounds"], Color("424959"))
	canvas.draw_rect(FAR, Color("6b777f"))
	canvas.draw_rect(CORRIDOR, Color("6b777f"))
	canvas.draw_rect(ROOM, Color("7a838b"))
	for point in [Vector2(3105, 387), Vector2(3105, 443), Vector2(3215, 387), Vector2(3215, 443)]:
		canvas.draw_circle(point, 3.5, Color("b3cad2"))
	var bounds: Rect2 = DOOR["bounds"]
	if door_solid:
		canvas.draw_rect(bounds, Color("aaa2cc"))
		canvas.draw_line(bounds.position, bounds.end, Color("d3c3ed"), 1.5)
	for point in [Vector2(3430, 373), Vector2(3460, 448)]:
		canvas.draw_colored_polygon(PackedVector2Array([point + Vector2(-9, 5), point + Vector2(0, -18), point + Vector2(9, 5)]), Color("98c3d5"))
