extends RefCounted
const Cipher = preload("res://scripts/runtime2d/latin_runes_2d.gd")
const KEY_ROOM := Rect2(2050, -425, 240, 150)
const KEY_PATH := Rect2(1940, -330, 125, 48)
const KEY_ENTRY := Vector2(1955, -306)
const KEY_VIEW := Vector2(2170, -352)
const KEY_WALL := Rect2(2050, -425, 240, 14)
const WALLS := [
	{"bounds": KEY_WALL, "height": 85.0, "layer": 2},
	{"bounds": Rect2(2276, -411, 14, 136), "height": 85.0, "layer": 2},
	{"bounds": Rect2(2050, -289, 226, 14), "height": 85.0, "layer": 2},
	{"bounds": Rect2(2050, -411, 14, 81), "height": 85.0, "layer": 2},
]
const TEMPLE_COMMAND := "SPAWN CAT"
const TEMPLE_POINT := Vector2(1948, 1536)


static func contains(point: Vector2) -> bool:
	return KEY_ROOM.has_point(point) or KEY_PATH.has_point(point)


static func draw_on(canvas: Node2D) -> void:
	canvas.draw_rect(KEY_ROOM, Color("565268"))
	canvas.draw_rect(KEY_PATH, Color("526859"))
	canvas.draw_rect(Rect2(KEY_WALL.position - Vector2(0, 62), Vector2(240, 76)), Color("827989"))
	var color := Color("e3d7b6")
	for index in Cipher.ALPHABET.length():
		var point := KEY_WALL.position + Vector2(8 + (index % 13) * 17, -54 + floori(float(index) / 13.0) * 30)
		canvas.draw_string(ThemeDB.fallback_font, point + Vector2(1, 8), Cipher.ALPHABET[index], HORIZONTAL_ALIGNMENT_LEFT, -1, 9, color)
		Cipher.glyph(canvas, index, point + Vector2(1, 11), color, 0.85)
