extends RefCounted
## F2: physical height plus body scale. One original canonical room address.
const ID := "ET_FAIRY_ROOT_HOUSE_01"
const RESIDENT := "F2_FAIRY_RESIDENT"
const ENTRY := Vector2(2168, 120)
const DOOR := Vector2(2168, -40)
const HEIGHT := 24.0
const MAX_SIZE := 0.5
const STEPS := [
	{"bounds": Rect2(2138, 48, 60, 60), "height": 6.0, "walk_up": true},
	{"bounds": Rect2(2138, 13, 60, 60), "height": 12.0, "walk_up": true},
	{"bounds": Rect2(2138, -22, 60, 60), "height": 18.0, "walk_up": true},
	{"bounds": Rect2(2138, -62, 60, 65), "height": HEIGHT, "walk_up": true},
]
const ROOM := Rect2(6300, 220, 145, 115)
const INSIDE := Vector2(6330, 305)
const RESIDENT_POINT := Vector2(6410, 256)


static func can_enter(point: Vector2, height: float, size: float) -> bool:
	return point.distance_to(DOOR) <= 16.0 and is_equal_approx(height, HEIGHT) and size <= MAX_SIZE


static func draw_on(canvas: Node2D) -> void:
	for step in STEPS:
		var bounds: Rect2 = step["bounds"]
		var projected := Rect2(bounds.position - Vector2(0, step["height"]), bounds.size)
		canvas.draw_rect(projected, Color("776859"))
		canvas.draw_rect(projected, Color("a59679"), false, 1.0)
	var base := DOOR - Vector2(0, HEIGHT)
	canvas.draw_rect(Rect2(base + Vector2(-18, -28), Vector2(36, 28)), Color("b99379"))
	canvas.draw_colored_polygon(PackedVector2Array([base + Vector2(-23, -28), base + Vector2(0, -46), base + Vector2(23, -28)]), Color("846e98"))
	canvas.draw_rect(Rect2(base + Vector2(-5, -14), Vector2(10, 14)), Color("66536a"))
	canvas.draw_rect(Rect2(base + Vector2(8, -24), Vector2(8, 8)), Color("f4d8a0"))
	canvas.draw_rect(ROOM, Color("938179"))
	canvas.draw_rect(ROOM.grow(-5), Color("bcaa9a"), false, 2.0)
	canvas.draw_rect(Rect2(6400, 223, 28, 14), Color("f4d8a0"))
	canvas.draw_rect(Rect2(INSIDE + Vector2(-8, -14), Vector2(16, 14)), Color("66536a"))
