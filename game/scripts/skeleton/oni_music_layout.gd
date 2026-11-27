extends RefCounted
## Physical ordinary route. One Oni body, never a duplicate at two endpoints.
const ONI_ID := "W1_K6_ONI"
const Refuge = preload("res://scripts/skeleton/underside_refuge_layout.gd")
const ROUTE := [Vector2(2138, 490), Vector2(2194, 490), Vector2(2240, 490),
	Vector2(2240, 600), Vector2(2240, 755), Vector2(2340, 790),
	Vector2(2440, 805), Vector2(2620, 870), Vector2(2750, 940),
	Vector2(2770, 1040), Vector2(2855, 1085),
	Vector2(2940, 1085), Vector2(3245, 1085), Vector2(3300, 1100), Vector2(3365, 1145), Vector2(3480, 1150),
	# Append only: all existing saved route indices retain their meanings.
	Vector2(2440, 580), Vector2(2440, 550), Vector2(2740, 550), Vector2(2740, 415),
	Vector2(3085, 415), Refuge.NEAR, Refuge.FAR, Vector2(4120, 655), Vector2(4140, 610)]
const CAPE_INDEX := 10
const BRIDGE_WEST_INDEX := 11
const BRIDGE_EAST_INDEX := 12
const EDGE_INDEX := 15
const W8_JUNCTION := 3
const W8_FIRST_INDEX := 16
const W8_NEAR_INDEX := 21
const W8_FAR_INDEX := 22
const W8_ROOM_ENTRY_INDEX := 23
const W8_STUDY_INDEX := 24


static func private_refuge_period(minute: int) -> bool:
	# DEV schedule; not a published meeting time or a quest prerequisite.
	return minute >= 2 * 60 and minute < 5 * 60
const EDGE_SPOT := Vector2(3480, 1150)


static func destination_index(minute: int, daytime: bool) -> int:
	# DEV repeated private study period; ordinary W1/K6 hours remain otherwise intact.
	if minute >= 23 * 60 or minute < 2 * 60:
		return EDGE_INDEX
	return CAPE_INDEX if daytime else 0
const FLUTE := Vector2(1880, -275)
const CAPE := Vector2(2855, 1085)
const LAKE := Vector2(2138, 490)
const SHELL_NOTE := Vector2(2740, 740)
const M02_RECORD := Vector2(1895, 112)
const PRISM_BLUE := Color("8adfff")
const PRISM_GREEN := Color("8de7a8")


static func draw_on(canvas: Node2D, _flute_owned: bool, prism: bool) -> void:
	var font := ThemeDB.fallback_font
	canvas.draw_string(font, M02_RECORD + Vector2(-32, -12), "♪ ↑ → ↑ ← ↓ →", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, PRISM_BLUE if prism else Color("e3d4b4"))
	canvas.draw_arc(SHELL_NOTE, 10.0, PI, TAU, 16, Color("d2b9a6"), 2.0, true)
	if prism:
		canvas.draw_string(font, SHELL_NOTE + Vector2(-37, -15), "♪ → ↓ → ↑ ←", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, PRISM_BLUE)
		canvas.draw_string(font, Vector2(3520, 343), "♪ ↑ ↑ ↓ ↓ ← → ← →", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, PRISM_BLUE)
		canvas.draw_string(font, Vector2(3510, 169), "Палочка рядом / далеко", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, PRISM_GREEN)
