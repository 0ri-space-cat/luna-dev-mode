extends RefCounted
## K0/K1/K2 continuous ordinary coast and one phase-linked house.
const LOCATION_ID := "ET_COAST"
const HOUSE_ID := "ET_COAST_TIDE_HOUSE"
const ESTUARY := Rect2(2185, 710, 275, 145)
const BEACH := Rect2(2420, 785, 355, 175)
const SEA := Rect2(2420, 960, 355, 95)
const SEA_BED := -32.0
const HOUSE_VERANDA := Rect2(2350, 650, 300, 160)
const HOUSE_SHELL := Rect2(2485, 660, 125, 48)
const HOUSE_ROOM := Rect2(3200, 750, 240, 185)
const HOUSE_OUTSIDE := Vector2(2550, 740)
const HOUSE_INSIDE := Vector2(3250, 850)
const DIAL_OUTSIDE := Vector2(2400, 735)
const DIAL_INSIDE := Vector2(3375, 790)
const DECKS := [ESTUARY, BEACH, HOUSE_VERANDA, HOUSE_ROOM]
const ENTRY := Vector2(2340, 790)
const BEACH_ENTRY := Vector2(2620, 870)
const PHASE_COLORS := [Color("e8dcef"), Color("e9e8d3"), Color("ecac84"), Color("65749e")]


static func contains_v4(point: Vector2) -> bool:
	return ESTUARY.has_point(point) or BEACH.has_point(point) or SEA.has_point(point)


static func contains(point: Vector2) -> bool:
	return contains_v4(point) or HOUSE_VERANDA.has_point(point)


static func draw_on(canvas: Node2D, local_phase: int, outside_phase: int) -> void:
	# Temporary blockout color: permanent sand above a real water volume.
	canvas.draw_rect(ESTUARY, Color("8c8875"))
	canvas.draw_rect(BEACH, Color("b7a587"))
	canvas.draw_rect(SEA, Color("487d92"))
	for y in range(971, 1047, 18):
		canvas.draw_line(Vector2(2430, y), Vector2(2764, y + 3), Color("75a9b1"), 1.5)
	canvas.draw_rect(HOUSE_VERANDA, Color("b0a08a"))
	canvas.draw_rect(HOUSE_SHELL, Color("76686c"))
	canvas.draw_rect(Rect2(2500, 671, 35, 24), PHASE_COLORS[local_phase])
	canvas.draw_rect(Rect2(2565, 671, 30, 24), PHASE_COLORS[outside_phase])
	canvas.draw_rect(Rect2(2540, 691, 20, 17), Color("d4b77c") if local_phase == outside_phase else Color("544a58"))
	canvas.draw_rect(HOUSE_ROOM, Color("998579"))
	canvas.draw_rect(Rect2(3220, 765, 75, 24), PHASE_COLORS[local_phase])
	canvas.draw_rect(Rect2(3325, 765, 75, 24), PHASE_COLORS[outside_phase])
	canvas.draw_rect(Rect2(3275, 802, 55, 25), Color("6d5555"))
	canvas.draw_rect(Rect2(3235, 875, 30, 12), Color("d4b77c"))
	# Two views of the same dial state, not two independent clocks.
	for point in [DIAL_OUTSIDE, DIAL_INSIDE]:
		canvas.draw_circle(point, 11.0, Color("514a55"))
		canvas.draw_circle(point, 8.0, PHASE_COLORS[local_phase])
		var angle := float(local_phase) * PI / 2.0 - PI / 2.0
		canvas.draw_line(point, point + Vector2.from_angle(angle) * 7.0, Color("3f3845"), 2.0)
	canvas.draw_string(ThemeDB.fallback_font, Vector2(2215, 760), "Устье")
	canvas.draw_string(ThemeDB.fallback_font, Vector2(2520, 830), "Побережье")
	canvas.draw_string(ThemeDB.fallback_font, Vector2(2475, 715), "Дом вечерних окон")
	canvas.draw_string(ThemeDB.fallback_font, Vector2(3260, 918), "Дом вечерних окон")
