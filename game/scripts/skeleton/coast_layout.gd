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
# K1 optional invisible foam bridge, K3 tidal mouth, K5 dry grotto and
# K6 ordinary headland. The upper escape is made of actual elevation treads.
const GROTTO_ID := "ET_COAST_SEA_GROTTO"
const FOAM_BRIDGE_ID := "BRIDGE_I_COAST"
const FOAM_BRIDGE := Rect2(2490, 945, 65, 65)
const FOAM_LANDING := Rect2(2475, 995, 100, 65)
const FOAM_VIEW := Vector2(2520, 1030)
const GROTTO_EXTERIOR := Rect2(2700, 680, 100, 165)
const TIDAL_MOUTH := Rect2(2755, 850, 135, 60)
const GROTTO_ROOM := Rect2(2870, 825, 175, 130)
const GROTTO_ENTRY := Vector2(2950, 880)
const ESCAPE_STEP_1 := Rect2(2950, 790, 70, 70)
const ESCAPE_STEP_2 := Rect2(2950, 735, 70, 70)
const ESCAPE_STEP_3 := Rect2(2950, 680, 70, 70)
const ESCAPE_TOP := Rect2(2785, 680, 235, 70)
const ESCAPE_DECKS := [
	{"bounds": ESCAPE_STEP_1, "height": 6.0, "walk_up": true},
	{"bounds": ESCAPE_STEP_2, "height": 12.0, "walk_up": true},
	{"bounds": ESCAPE_STEP_3, "height": 18.0, "walk_up": true},
	{"bounds": ESCAPE_TOP, "height": 18.0},
]
const CAPE_PATH := Rect2(2740, 925, 70, 145)
const CAPE := Rect2(2780, 1030, 210, 110)
const CAPE_VIEW := Vector2(2900, 1085)
const DECKS := [ESTUARY, BEACH, HOUSE_VERANDA, HOUSE_ROOM, FOAM_LANDING,
	GROTTO_EXTERIOR, GROTTO_ROOM, CAPE_PATH, CAPE]
const ENTRY := Vector2(2340, 790)
const BEACH_ENTRY := Vector2(2620, 870)
const PHASE_COLORS := [Color("e8dcef"), Color("e9e8d3"), Color("ecac84"), Color("65749e")]


static func contains_v4(point: Vector2) -> bool:
	return ESTUARY.has_point(point) or BEACH.has_point(point) or SEA.has_point(point)


static func contains_v5(point: Vector2) -> bool:
	return contains_v4(point) or HOUSE_VERANDA.has_point(point)


static func grotto_contains(point: Vector2) -> bool:
	return GROTTO_ROOM.has_point(point) or ESCAPE_STEP_1.has_point(point) \
		or ESCAPE_STEP_2.has_point(point) or ESCAPE_STEP_3.has_point(point) \
		or (ESCAPE_TOP.has_point(point) and point.x >= GROTTO_EXTERIOR.end.x)


static func contains(point: Vector2) -> bool:
	return contains_v5(point) or FOAM_BRIDGE.has_point(point) or FOAM_LANDING.has_point(point) \
		or GROTTO_EXTERIOR.has_point(point) or TIDAL_MOUTH.has_point(point) \
		or CAPE_PATH.has_point(point) or CAPE.has_point(point)


# A shared physical water level, independent of camera, local house and UI.
# Working balance: dry morning, thirty game minutes of ebb/rise.
static func tide_height(minute: int) -> float:
	if minute >= 360 and minute < 540:
		return 0.0
	if minute >= 330 and minute < 360:
		return 30.0 * float(360 - minute) / 30.0
	if minute >= 540 and minute < 570:
		return 30.0 * float(minute - 540) / 30.0
	return 30.0


static func draw_on(canvas: Node2D, local_phase: int, outside_phase: int, tide: float) -> void:
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
	canvas.draw_rect(FOAM_LANDING, Color("a6a397"))
	# Foam reveals the otherwise unrendered solid bridge.
	for y in range(955, 1000, 9):
		canvas.draw_line(Vector2(2501, y), Vector2(2544, y + 2), Color("b9d9d7"), 1.3)
	canvas.draw_rect(GROTTO_EXTERIOR, Color("a6a397"))
	canvas.draw_rect(TIDAL_MOUTH, Color("827b72").lerp(Color("527f94"), tide / 30.0))
	canvas.draw_rect(GROTTO_ROOM, Color("7b8584"))
	canvas.draw_rect(ESCAPE_TOP, Color("9b9892"))
	for tread in [ESCAPE_STEP_1, ESCAPE_STEP_2, ESCAPE_STEP_3]:
		canvas.draw_rect(tread, Color("96938c"), false, 2.0)
	canvas.draw_rect(CAPE_PATH, Color("a9a18e"))
	canvas.draw_rect(CAPE, Color("899b8c"))
	canvas.draw_string(ThemeDB.fallback_font, Vector2(2875, 855), "Морской грот")
	canvas.draw_string(ThemeDB.fallback_font, Vector2(2830, 1065), "Мыс")
	canvas.draw_string(ThemeDB.fallback_font, Vector2(2215, 760), "Устье")
	canvas.draw_string(ThemeDB.fallback_font, Vector2(2520, 830), "Побережье")
	canvas.draw_string(ThemeDB.fallback_font, Vector2(2475, 715), "Дом вечерних окон")
	canvas.draw_string(ThemeDB.fallback_font, Vector2(3260, 918), "Дом вечерних окон")
