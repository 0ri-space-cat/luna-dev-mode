extends RefCounted
## Physical ordinary route. One Oni body, never a duplicate at two endpoints.
const ONI_ID := "W1_K6_ONI"
const ROUTE := [Vector2(2138, 490), Vector2(2194, 490), Vector2(2240, 490),
	Vector2(2240, 600), Vector2(2240, 755), Vector2(2340, 790),
	Vector2(2440, 805), Vector2(2620, 870), Vector2(2750, 940),
	Vector2(2770, 1040), Vector2(2855, 1085)]
const FLUTE := Vector2(1895, 125)
const CAPE := Vector2(2855, 1085)
const LAKE := Vector2(2138, 490)
const SHELL_NOTE := Vector2(2740, 740)
const M02_RECORD := Vector2(1895, 112)
const PRISM_BLUE := Color("8adfff")
const PRISM_GREEN := Color("8de7a8")


static func draw_on(canvas: Node2D, flute_owned: bool, prism: bool) -> void:
	var font := ThemeDB.fallback_font
	if not flute_owned:
		canvas.draw_line(FLUTE + Vector2(-13, -3), FLUTE + Vector2(13, -10), Color("d9b889"), 5.0)
		for x in [-8, 0, 8]:
			canvas.draw_circle(FLUTE + Vector2(x, -6), 1.5, Color("514c53"))
	canvas.draw_string(font, M02_RECORD + Vector2(-32, -12), "♪ ↑ → ↑ ← ↓ →", PRISM_BLUE if prism else Color("e3d4b4"))
	canvas.draw_arc(SHELL_NOTE, 10.0, PI, TAU, 16, Color("d2b9a6"), 2.0, true)
	if prism:
		canvas.draw_string(font, SHELL_NOTE + Vector2(-37, -15), "♪ → ↓ → ↑ ←", PRISM_BLUE)
		canvas.draw_string(font, Vector2(3520, 343), "♪ ↑ ↑ ↓ ↓ ← → ← →", PRISM_BLUE)
		canvas.draw_string(font, Vector2(3510, 169), "Палочка рядом / далеко", PRISM_GREEN)
