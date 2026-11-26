extends RefCounted
## K1 shore ecology and W2/K2 one-of-a-kind artifact placements.
const HOURGLASS_ID := "HOURGLASS"
const HOURGLASS_POINT := Vector2(3250, 881)
const FLASK_ID := "MIA_FLASK"
const MIA_ID := "W2_MIA"
const MIA_START := Vector2(2050, 780)
const MIA_ROUTE := [Vector2(2075, 875), Vector2(2075, 950), Vector2(2075, 1010), Vector2(2075, 1080), Vector2(1875, 1080)]
const POOL := Rect2(2650, 790, 94, 45)
const SHELL_ID := "K1_LIGHT_SHELL"
const STONE_ID := "K1_HEAVY_STONE"
const CRAB_ID := "K1_CRAB"
const TURTLE_ID := "K1_TURTLE"
const FAUNA := {CRAB_ID: Vector2(2475, 885), TURTLE_ID: Vector2(2690, 925)}
const FAUNA_CATEGORY := {CRAB_ID: "crab", TURTLE_ID: "turtle"}
const SHELL_START := Vector2(2665, 808)
const STONE_START := Vector2(2715, 818)
const ICE := [
	{"bounds": Rect2(1775, 825, 150, 90), "height": 0.0, "safe": false, "feature_id": "MIA_ICE"},
]


static func draw_on(canvas: Node2D, tide: float, hourglass_taken: bool, flask_state: int, ice: bool) -> void:
	canvas.draw_rect(POOL, Color("a39b86").lerp(Color("6d9cae"), tide / 8.0))
	canvas.draw_rect(POOL, Color("788d8b"), false, 1.5)
	if not hourglass_taken:
		var p := HOURGLASS_POINT
		# Two valid triangles instead of a self-intersecting bow tie.
		canvas.draw_colored_polygon(PackedVector2Array([p + Vector2(-7, -14), p + Vector2(7, -14), p + Vector2(0, -7)]), Color("efc583"))
		canvas.draw_colored_polygon(PackedVector2Array([p + Vector2(0, -7), p + Vector2(7, 0), p + Vector2(-7, 0)]), Color("efc583"))
		canvas.draw_line(p + Vector2(-9, -15), p + Vector2(9, -15), Color("795f66"), 3.0)
		canvas.draw_line(p + Vector2(-9, 1), p + Vector2(9, 1), Color("795f66"), 3.0)
	if flask_state == 0:
		canvas.draw_circle(MIA_START + Vector2(16, -15), 6.0, Color("88d3c6"))
	if ice:
		for surface in ICE:
			canvas.draw_rect(surface["bounds"], Color("b1dfe8"))
			canvas.draw_rect(surface["bounds"], Color("e0f7fb"), false, 2.0)
