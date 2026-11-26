extends RefCounted
## K1 high dry viewpoint and K5 optional personal-observation crossing.
const SHELF_STEPS := [
	{"bounds": Rect2(2415, 875, 65, 60), "height": 6.0, "walk_up": true},
	{"bounds": Rect2(2415, 825, 65, 65), "height": 12.0, "walk_up": true},
	{"bounds": Rect2(2350, 795, 130, 45), "height": 18.0, "walk_up": true},
]
const HIGH_VIEW := Vector2(2385, 818)
const BRIDGE_ID := "BRIDGE_II_COAST_GROTTO"
const BRIDGE := {"bounds": Rect2(3035, 865, 90, 55), "height": 0.0, "safe": false, "feature_id": BRIDGE_ID}
const LOWER := {"bounds": Rect2(3010, 850, 145, 85), "height": -18.0, "safe": false}
const LANDING := Rect2(3115, 845, 80, 95)
const VIEW := Vector2(3160, 895)


static func grotto_contains(point: Vector2) -> bool:
	return BRIDGE["bounds"].has_point(point) or LOWER["bounds"].has_point(point) or LANDING.has_point(point)


static func shelf_contains(point: Vector2) -> bool:
	for surface in SHELF_STEPS:
		if surface["bounds"].has_point(point):
			return true
	return false


static func draw_on(canvas: Node2D) -> void:
	for surface in SHELF_STEPS:
		canvas.draw_rect(surface["bounds"], Color("b1a491"))
		canvas.draw_rect(surface["bounds"], Color("827f78"), false, 1.5)
	canvas.draw_rect(LOWER["bounds"], Color("566c77"))
	canvas.draw_rect(LANDING, Color("91a3a2"))
	for point in [Vector2(3038, 867), Vector2(3038, 917), Vector2(3120, 867), Vector2(3120, 917)]:
		canvas.draw_circle(point, 3.0, Color("d6e6df"))
	canvas.draw_string(ThemeDB.fallback_font, HIGH_VIEW + Vector2(-22, 5), "Полка")
