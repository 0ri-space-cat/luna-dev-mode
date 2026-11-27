extends RefCounted
## Fixed Latin alphabet. Private-use tokens are rendered as authored strokes.
const FIRST := 0xE000
const ALPHABET := "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
const MASKS := [19, 5, 26, 12, 7, 23, 10, 30, 3, 16, 25, 9, 21, 14, 1, 28, 11, 18, 6, 24, 13, 29, 2, 20, 15, 27]
const STROKES := [
	[Vector2(5, 2), Vector2(0, 0)],
	[Vector2(5, 2), Vector2(10, 0)],
	[Vector2(5, 7), Vector2(0, 10)],
	[Vector2(5, 7), Vector2(10, 10)],
	[Vector2(0, 14), Vector2(10, 14)],
]


static func encode(source: String) -> String:
	var result := ""
	for character in source:
		var index := ALPHABET.find(character)
		if index >= 0:
			result += String.chr(FIRST + index)
		elif character in " _0123456789":
			result += character
		else:
			return ""
	return result


static func glyph(canvas: Node2D, index: int, point: Vector2, color: Color, scale_factor: float = 1.0) -> void:
	if index < 0 or index >= MASKS.size():
		return
	canvas.draw_line(point + Vector2(5, 0) * scale_factor, point + Vector2(5, 14) * scale_factor, color, 1.4 * scale_factor, true)
	var mask: int = MASKS[index]
	for bit in STROKES.size():
		if (mask & (1 << bit)) != 0:
			canvas.draw_line(point + STROKES[bit][0] * scale_factor, point + STROKES[bit][1] * scale_factor, color, 1.4 * scale_factor, true)


static func draw_encoded(canvas: Node2D, encoded: String, origin: Vector2, color: Color, scale_factor: float = 1.0) -> void:
	var point := origin
	for character in encoded:
		var index := character.unicode_at(0) - FIRST
		if index >= 0 and index < MASKS.size():
			glyph(canvas, index, point, color, scale_factor)
		elif character != " ":
			canvas.draw_string(ThemeDB.fallback_font, point + Vector2(0, 13) * scale_factor, character, HORIZONTAL_ALIGNMENT_LEFT, -1, roundi(12.0 * scale_factor), color)
		point.x += 14.0 * scale_factor
