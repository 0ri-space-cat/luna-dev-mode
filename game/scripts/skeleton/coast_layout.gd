extends RefCounted
## K0/K1 continuous ordinary coast blockout; neither tides nor secrets gate travel.
const LOCATION_ID := "ET_COAST"
const ESTUARY := Rect2(2185, 710, 275, 145)
const BEACH := Rect2(2420, 785, 355, 175)
const SEA := Rect2(2420, 960, 355, 95)
const SEA_BED := -32.0
const DECKS := [ESTUARY, BEACH]
const ENTRY := Vector2(2340, 790)
const BEACH_ENTRY := Vector2(2620, 870)


static func contains(point: Vector2) -> bool:
	return ESTUARY.has_point(point) or BEACH.has_point(point) or SEA.has_point(point)


static func draw_on(canvas: Node2D) -> void:
	# Temporary blockout color: permanent sand above a real water volume.
	canvas.draw_rect(ESTUARY, Color("8c8875"))
	canvas.draw_rect(BEACH, Color("b7a587"))
	canvas.draw_rect(SEA, Color("487d92"))
	for y in range(971, 1047, 18):
		canvas.draw_line(Vector2(2430, y), Vector2(2764, y + 3), Color("75a9b1"), 1.5)
	canvas.draw_string(ThemeDB.fallback_font, Vector2(2215, 760), "Устье")
	canvas.draw_string(ThemeDB.fallback_font, Vector2(2520, 830), "Побережье")
