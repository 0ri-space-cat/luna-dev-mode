extends RefCounted
const Runes = preload("res://scripts/runtime2d/latin_runes_2d.gd")
const RuneRoom = preload("res://scripts/skeleton/rune_room_layout.gd")
## Chapter VII provisional geometry. Ground and height use the shared physics.
const MOUNTAIN := "ET_MOUNTAINS"
const UPDRAFT := "ET_UPDRAFT_VALLEY"
const SKY := "ET_SKY_ISLANDS"
const ORACLE := "ET_ORACLE_LOOKOUT"
const H0 := Rect2(1480, 1355, 195, 210)
const H1 := Rect2(1450, 1530, 225, 170)
const H2 := Rect2(1640, 1515, 290, 185)
const H5 := Rect2(1900, 1525, 275, 165)
const H6 := Rect2(1790, 1400, 180, 150)
const H3 := Rect2(1800, 1670, 190, 185)
const H4 := Rect2(1955, 1780, 200, 175)
const APPROACH := Rect2(1480, 660, 85, 755)
const GROUND := [APPROACH, H0, H1, H2, H5, H6, H3, H4]
const OLD_OFFSET := Vector2(0, 700)
const ADDRESSES := [MOUNTAIN, UPDRAFT, SKY, ORACLE]
const ENTRY := Vector2(1565, 1450)
const COMPASS := Vector2(1510, 1640)
const WIND := Rect2(1560, 1565, 95, 105)
const STAIRS := [
	{"bounds": Rect2(1690, 1555, 90, 95), "height": 6.0, "walk_up": true},
	{"bounds": Rect2(1740, 1555, 90, 95), "height": 12.0, "walk_up": true},
	{"bounds": Rect2(1790, 1555, 125, 95), "height": 18.0, "walk_up": true},
	{"bounds": Rect2(1860, 1545, 120, 105), "height": 18.0},
	{"bounds": Rect2(1935, 1550, 75, 95), "height": 18.0},
	{"bounds": Rect2(2090, 1550, 75, 95), "height": 18.0},
	{"bounds": Rect2(1830, 1465, 100, 100), "height": 12.0, "walk_up": true},
	{"bounds": Rect2(1830, 1415, 100, 100), "height": 6.0, "walk_up": true},
	{"bounds": Rect2(1990, 1800, 135, 110), "height": 48.0},
	{"bounds": Rect2(1950, 1825, 70, 85), "height": 18.0},
]
const CAMERA_BRIDGE := {"bounds": Rect2(1990, 1565, 120, 55), "height": 18.0, "safe": false, "feature_id": "BRIDGE_CAMERA_SKY_ISLAND"}
const ANCHOR := Vector3(2050, 1810, 48)
const ANCHOR_WALL := {"bounds": Rect2(2040, 1803, 20, 16), "height": 84.0, "layer": 2}
const ORACLE_ID := "H5_ORACLE"
const RAY_ID := "H3_FREE_RAY"
const FLY_INSTANCE := "FLY_H3_RAY"
const ORACLE_POINT := Vector2(1945, 1585)
const RAY_POINT := Vector2(1860, 1735)
const M07_SOURCE := Vector2(2070, 1880)
const H4_NOTE := Vector2(2115, 1880)
const H6_RUNE := Vector2(1885, 1445)
const TREE_POCKET := Rect2(1740, 244, 60, 61)
const CAMERA_POINT := Vector2(1770, 265)
const ROOT_WALLS := [
	{"bounds": Rect2(1725, 230, 90, 14), "height": 110.0, "layer": 2},
	{"bounds": Rect2(1725, 244, 15, 76), "height": 110.0, "layer": 2},
	{"bounds": Rect2(1800, 244, 15, 76), "height": 110.0, "layer": 2},
	{"bounds": Rect2(1740, 305, 21, 15), "height": 110.0, "layer": 2},
	{"bounds": Rect2(1779, 305, 21, 15), "height": 110.0, "layer": 2},
]
const STRENGTHS := [1.0, 0.5, 0.25, 1.5]


static func address(point: Vector2) -> String:
	if point.y < 700.0:
		return "" # M5 remains part of the meadows despite overlapping ground.
	if H5.has_point(point):
		return ORACLE
	if H4.has_point(point) or H3.has_point(point):
		return SKY
	if H1.has_point(point):
		return UPDRAFT
	if APPROACH.has_point(point) or H0.has_point(point) or H2.has_point(point) or H6.has_point(point):
		return MOUNTAIN
	return ""


static func wind_at(point: Vector2, height: float) -> Vector3:
	return Vector3(95.0, -18.0, 210.0) if WIND.has_point(point) and height < 110.0 else Vector3.ZERO


static func draw_on(canvas: Node2D, compass_owned: bool, camera_owned: bool, player_point: Vector2, prism: bool, echo: float) -> void:
	var font := ThemeDB.fallback_font
	for area in GROUND:
		canvas.draw_rect(area, Color("827e90"))
		canvas.draw_rect(area.grow(-3), Color("b4a9a4"), false, 1.5)
	for surface in STAIRS:
		var bounds: Rect2 = surface["bounds"]
		var height: float = surface["height"]
		var projected := Rect2(bounds.position - Vector2(0, height), bounds.size)
		canvas.draw_rect(Rect2(projected.position, projected.size + Vector2(0, 6)), Color("5e536b"))
		canvas.draw_rect(projected, Color("b3a9b2"))
		canvas.draw_rect(projected.grow(-3), Color("dfd1bc"), false, 1.0)
	for i in range(4):
		var p := WIND.position + Vector2(14 + i * 20, 70 - i * 12)
		canvas.draw_line(p, p + Vector2(17, -31), Color("d7e4ed"), 1.5)
	canvas.draw_string(font, ENTRY + Vector2(-50, -40), "Горная тропа")
	canvas.draw_string(font, Vector2(1465, 1555), "Восходящий ветер")
	if not compass_owned:
		canvas.draw_circle(COMPASS, 9.0, Color("e5c98c"))
		canvas.draw_line(COMPASS - Vector2(5, 0), COMPASS + Vector2(5, -6), Color("705272"), 2.0)
	var shrine := Rect2(1910, 1538, 77, 20)
	canvas.draw_rect(shrine, Color("795c60"))
	canvas.draw_polyline(PackedVector2Array([shrine.position + Vector2(-12, 0), shrine.position + Vector2(10, -16), shrine.position + Vector2(67, -16), shrine.end - Vector2(-12, 20)]), Color("b88783"), 4.0)
	canvas.draw_string(font, Vector2(1910, 1510), "Святилище")
	var anchor := Vector2(ANCHOR.x, ANCHOR.y - ANCHOR.z)
	canvas.draw_colored_polygon(PackedVector2Array([anchor + Vector2(-14, 8), anchor + Vector2(-8, -24), anchor + Vector2(5, -34), anchor + Vector2(16, -7), anchor + Vector2(10, 8)]), Color("91c7d2"))
	for i in range(3):
		canvas.draw_circle(Vector2(2005 + i * 40, 1860), 6.0, Color("edbf88"))
	Runes.draw_encoded(canvas, Runes.encode("ET_FORGOTTEN_EDGE"), H6_RUNE + Vector2(-70, -25), Color("e9d0a1") if prism else Color("b2a5a6"), 0.75)
	if prism:
		Runes.draw_encoded(canvas, Runes.encode(RuneRoom.TEMPLE_COMMAND), RuneRoom.TEMPLE_POINT + Vector2(-43, -28), Color("e9d0a1"), 0.8)
		canvas.draw_string(font, M07_SOURCE + Vector2(-32, -15), "↓ ↑ ← → ↓ ↑", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("83d8ee"))

	if echo > 0.0:
		canvas.draw_arc(M07_SOURCE, 16.0 + (3.0 - echo) * 9.0, 0, TAU, 24, Color(0.9, 0.8, 0.6, echo / 3.0), 2.0)
	if not camera_owned and TREE_POCKET.has_point(player_point):
		canvas.draw_rect(Rect2(CAMERA_POINT - Vector2(8, 8), Vector2(16, 11)), Color("a7c0cf"))
		canvas.draw_circle(CAMERA_POINT + Vector2(2, -3), 4.0, Color("47556d"))


static func old_mountain_point(point: Vector2) -> bool:
	if point.y < 700.0:
		return false
	for region in [H0, H1, H2, H5, H6, H3, H4]:
		var former := Rect2(region.position - OLD_OFFSET, region.size)
		if former.has_point(point):
			return true
	return false
