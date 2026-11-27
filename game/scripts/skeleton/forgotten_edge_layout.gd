extends RefCounted
## Chapter VIII. Separate L4 geography; no overlap with L0.
const ID := "ET_FORGOTTEN_EDGE"
const SERVICE := "ET_FORGOTTEN_SERVICE"
const BANK := "ET_WATERFALL_HIDDEN_BANK"
const REFUGE := "ET_PROTO_LUNA_REFUGE"
const D0 := Rect2(3200, 1015, 180, 175)
const D1 := Rect2(3430, 940, 190, 160)
const D2 := Rect2(3340, 1055, 265, 205)
const D3 := Rect2(3570, 1060, 250, 210)
const D4 := Rect2(3620, 1230, 185, 100)
const D4_DESK := Rect2(3620, 1390, 185, 100)
const D8 := Rect2(3315, 1230, 285, 250)
const D5_TRAIL := Rect2(3780, 1080, 225, 120)
const D5 := Rect2(3970, 1045, 140, 155)
# Q22 now lies north of the existing crystal cavern, in the waterfall region.
# Keep the old D5 as an ordinary dead end and preserve the old address IDs.
const REFUGE_OFFSET := Vector2(-1110, -1115)
const LEGACY_D6 := Rect2(4330, 1045, 165, 155)
const LEGACY_D7 := Rect2(4430, 1170, 160, 155)
const REFUGE_APPROACH := Rect2(2860, -70, 140, 155)
const REFUGE_PATH := Rect2(2875, 65, 110, 260)
const D6 := Rect2(3220, -70, 165, 155)
const D7 := Rect2(3320, 55, 160, 155)
const LEGACY_GROUND := [D0, D1, D2, D3, D4, D4_DESK, D8, D5_TRAIL, D5, LEGACY_D6, LEGACY_D7]
const GROUND := [D0, D1, D2, D3, D4, D4_DESK, D8, D5_TRAIL, D5, REFUGE_PATH, REFUGE_APPROACH, D6, D7]
const R07 := {"bounds": Rect2(2970, 1060, 250, 55), "height": 0.0, "safe": false, "feature_id": "BRIDGE_CAMERA_COAST_EDGE"}
const LEGACY_BRIDGE := Rect2(4090, 1080, 260, 65)
const BRIDGE := {"bounds": Rect2(2980, -35, 260, 65), "height": 0.0, "safe": false, "feature_id": "BRIDGE_III_FORGOTTEN"}
const CYCLE_SPAN := {"bounds": Rect2(3670, 1310, 85, 100), "height": 0.0, "safe": false}
const LEGACY_LOWER := Rect2(4075, 1130, 260, 100)
const LEGACY_WATER := Rect2(4100, 1045, 230, 85)
const LOWER := {"bounds": Rect2(2965, 15, 260, 100), "height": -48.0}
const WATER := Rect2(2990, -70, 230, 85)
const LEGACY_LOWER_STEPS := [
	{"bounds": Rect2(3970, 1145, 75, 90), "height": -6.0, "walk_up": true},
	{"bounds": Rect2(3990, 1160, 75, 90), "height": -12.0, "walk_up": true},
	{"bounds": Rect2(4010, 1180, 75, 70), "height": -18.0, "walk_up": true},
	{"bounds": Rect2(4030, 1190, 75, 70), "height": -24.0, "walk_up": true},
	{"bounds": Rect2(4050, 1200, 75, 70), "height": -30.0, "walk_up": true},
	{"bounds": Rect2(4070, 1200, 75, 70), "height": -36.0, "walk_up": true},
	{"bounds": Rect2(4090, 1180, 75, 70), "height": -42.0, "walk_up": true},
]
const LOWER_STEPS := [
	{"bounds": Rect2(2860, 30, 75, 90), "height": -6.0, "walk_up": true},
	{"bounds": Rect2(2880, 45, 75, 90), "height": -12.0, "walk_up": true},
	{"bounds": Rect2(2900, 65, 75, 70), "height": -18.0, "walk_up": true},
	{"bounds": Rect2(2920, 75, 75, 70), "height": -24.0, "walk_up": true},
	{"bounds": Rect2(2940, 85, 75, 70), "height": -30.0, "walk_up": true},
	{"bounds": Rect2(2960, 85, 75, 70), "height": -36.0, "walk_up": true},
	{"bounds": Rect2(2980, 65, 75, 70), "height": -42.0, "walk_up": true},
]
const ENTRY := Vector2(3480, 995)
const FALL_ENTRY := Vector2(3400, 1140)
const RETURN := Vector2(3235, 1145)
const COAST_RETURN := Vector2(2900, 1085)
const DESK := Vector2(3710, 1440)
const LEGACY_NOTE := Vector2(4520, 1260)
const NOTE := Vector2(3410, 145)
const PORTAL_A := Vector2(3360, 1310)
const PORTAL_B := Vector2(3545, 1410)
const PORTAL_A_EXIT := Vector2(3395, 1310)
const PORTAL_B_EXIT := Vector2(3510, 1410)
const CYCLE_SECONDS := 72.0
const INTACT_SECONDS := 60.0


static func legacy_refuge_point(point: Vector2) -> bool:
	if D5.has_point(point) or LEGACY_D6.has_point(point) or LEGACY_D7.has_point(point) or LEGACY_BRIDGE.has_point(point) or LEGACY_LOWER.has_point(point) or LEGACY_WATER.has_point(point):
		return true
	for surface in LEGACY_LOWER_STEPS:
		if surface["bounds"].has_point(point):
			return true
	return false


static func address(point: Vector2) -> String:
	if D7.has_point(point):
		return REFUGE
	if D6.has_point(point):
		return BANK
	if REFUGE_PATH.has_point(point) or REFUGE_APPROACH.has_point(point) or BRIDGE["bounds"].has_point(point) or LOWER["bounds"].has_point(point) or WATER.has_point(point):
		return "ET_WATERFALL_VALLEY"
	for surface in LOWER_STEPS:
		if surface["bounds"].has_point(point):
			return "ET_WATERFALL_VALLEY"
	if D4.has_point(point) or D4_DESK.has_point(point) or CYCLE_SPAN["bounds"].has_point(point):
		return SERVICE
	for region in [D0, D1, D2, D3, D4, D4_DESK, D8, D5_TRAIL, D5]:
		if region.has_point(point):
			return ID
	if R07["bounds"].has_point(point) and point.x >= 2990.0:
		return ID
	return ""


static func address_v18(point: Vector2) -> String:
	if LEGACY_D7.has_point(point):
		return REFUGE
	if LEGACY_D6.has_point(point):
		return BANK
	if D4.has_point(point) or D4_DESK.has_point(point) or CYCLE_SPAN["bounds"].has_point(point):
		return SERVICE
	for region in LEGACY_GROUND:
		if region.has_point(point):
			return ID
	if LEGACY_BRIDGE.has_point(point) or LEGACY_LOWER.has_point(point) or LEGACY_WATER.has_point(point):
		return ID
	for surface in LEGACY_LOWER_STEPS:
		if surface["bounds"].has_point(point):
			return ID
	if R07["bounds"].has_point(point) and point.x >= 2990.0:
		return ID
	return ""


static func draw_on(canvas: Node2D, elapsed: float, time_owned: bool, portal_owned: bool) -> void:
	var font := ThemeDB.fallback_font
	for region in GROUND:
		canvas.draw_rect(region, Color("827b9c"))
		canvas.draw_rect(region.grow(-4), Color("b4a9c9"), false, 1.5)
	for p in [Vector2(3370, 1080), Vector2(3520, 960), Vector2(3620, 1100), Vector2(3740, 1180)]:
		canvas.draw_rect(Rect2(p, Vector2(45, 30)), Color("625d7d"))
		canvas.draw_rect(Rect2(p + Vector2(15, 9), Vector2(13, 12)), Color("e6c89b"))
	canvas.draw_string(font, Vector2(3220, 1040), "Скальные сады")
	canvas.draw_string(font, Vector2(3400, 1110), "Уцелевший двор")
	canvas.draw_string(font, Vector2(3600, 1085), "Покинутые улицы")
	canvas.draw_string(font, Vector2(3640, 1260), "Служебный карман")
	canvas.draw_string(font, Vector2(3990, 1070), "Тихая улица")
	canvas.draw_string(font, REFUGE_APPROACH.position + Vector2(20, 25), "Край водопадов")
	canvas.draw_string(font, D6.position + Vector2(20, 25), "Тихий берег")
	canvas.draw_string(font, D7.position + Vector2(20, 40), "Убежище")
	canvas.draw_rect(WATER, Color("597d9f"))
	for x in range(int(WATER.position.x) + 10, int(WATER.end.x) - 10, 18):
		canvas.draw_line(Vector2(x, WATER.position.y + 7), Vector2(x + 4, WATER.end.y - 7), Color("a4c9e0"), 2.0)
	if elapsed < INTACT_SECONDS:
		canvas.draw_rect(CYCLE_SPAN["bounds"], Color("8f7e89"))
	else:
		for p in [Vector2(3690, 1340), Vector2(3730, 1370)]:
			canvas.draw_rect(Rect2(p, Vector2(25, 17)), Color("5d526d"))
	canvas.draw_rect(Rect2(DESK - Vector2(22, 12), Vector2(44, 24)), Color("8e736d"))
	if not time_owned:
		canvas.draw_circle(DESK, 8.0, Color("dfc58d"))
	for point in [PORTAL_A, PORTAL_B]:
		canvas.draw_arc(point - Vector2(0, 18), 19.0, 0.0, TAU, 32, Color("b7d9ee"), 4.0)
	if not portal_owned:
		canvas.draw_rect(Rect2(Vector2(3450, 1440), Vector2(20, 9)), Color("d9b5e6"))
	canvas.draw_rect(Rect2(NOTE - Vector2(25, 12), Vector2(50, 24)), Color("8e736d"))
	canvas.draw_rect(Rect2(NOTE - Vector2(9, 7), Vector2(18, 14)), Color("e3d6c6"))
