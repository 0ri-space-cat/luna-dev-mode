extends RefCounted
## Graybox for independent L0 finds. Actual 2D+Z stairs, no required artifact.
const GRAVITY_POINT := Vector2(5450, 465)
const GRAVITY_HEIGHT := 24.0
const GRAVITY_ENTRY := Vector2(5270, 465)
const GRAVITY_STEPS := [
	{"bounds": Rect2(5300, 435, 65, 65), "height": 6.0, "walk_up": true},
	{"bounds": Rect2(5340, 435, 65, 65), "height": 12.0, "walk_up": true},
	{"bounds": Rect2(5380, 435, 65, 65), "height": 18.0, "walk_up": true},
	{"bounds": Rect2(5420, 425, 85, 85), "height": 24.0, "walk_up": true},
]
const FLUTE_POINT := Vector2(1880, -275)
const FLUTE_HEIGHT := 18.0
const FLUTE_ENTRY := Vector2(1880, -105)
const FLUTE_STEPS := [
	{"bounds": Rect2(1850, -190, 65, 65), "height": 6.0, "walk_up": true},
	{"bounds": Rect2(1850, -230, 65, 65), "height": 12.0, "walk_up": true},
	{"bounds": Rect2(1835, -315, 95, 105), "height": 18.0, "walk_up": true},
]


static func can_reach(point: Vector2, height: float, target: Vector2, target_height: float) -> bool:
	return absf(height - target_height) < 0.1 and point.distance_to(target) <= 22.0


static func draw_on(canvas: Node2D, feet: Vector2, height: float, gun_owned: bool, flute_owned: bool) -> void:
	for surface in GRAVITY_STEPS + FLUTE_STEPS:
		var bounds: Rect2 = surface["bounds"]
		var projected := Rect2(bounds.position - Vector2(0, surface["height"]), bounds.size)
		canvas.draw_rect(projected, Color("637c70"))
		canvas.draw_rect(projected, Color("a0b1a0"), false, 1.0)
	if not gun_owned and height >= GRAVITY_HEIGHT and feet.distance_to(GRAVITY_POINT) < 75.0:
		canvas.draw_rect(Rect2(GRAVITY_POINT - Vector2(12, GRAVITY_HEIGHT + 9), Vector2(24, 13)), Color("f4d6a4"))
	if not flute_owned and height >= FLUTE_HEIGHT and feet.distance_to(FLUTE_POINT) < 75.0:
		canvas.draw_line(FLUTE_POINT - Vector2(12, FLUTE_HEIGHT), FLUTE_POINT + Vector2(12, -FLUTE_HEIGHT - 8), Color("d9b889"), 5.0)
	var bird := Vector2(1895, 112)
	canvas.draw_circle(bird - Vector2(0, 20), 5.0, Color("edd7ad"))
	canvas.draw_string(ThemeDB.fallback_font, bird + Vector2(-18, 18), "↑ → ↓ ←", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("e3d4b4"))
