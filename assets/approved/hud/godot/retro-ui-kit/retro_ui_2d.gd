extends RefCounted
## Textures are shared between the inspector and HUD; game state lives in their callers.
const ROOT := "res://assets/ui/pixel-v1/"
const FONT = preload("res://assets/ui/pixel-v1/font/PressStart2P-Regular.ttf")
const IDS := ["luna", "yuki", "ori", "leya", "toffi", "miya", "oni"]
const INK := {
	"luna": "#fff3ff", "yuki": "#380e36", "ori": "#041150",
	"leya": "#d9fae8", "toffi": "#541d0b", "miya": "#e5f5fc", "oni": "#fafcfc"
}
const DARK_INK := {
	"luna": "#260d42", "yuki": "#541442", "ori": "#17447f",
	"leya": "#184f30", "toffi": "#71391b", "miya": "#102c59", "oni": "#11234b"
}

static func id_for(value: String) -> String:
	return "miya" if value == "mia" else (value if value in IDS else "luna")

static func texture(part: String) -> Texture2D:
	return load(ROOT + part + ".png") as Texture2D

static func style(part: String, slice: int, padding: float = 4) -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	box.texture = texture(part)
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		box.set_texture_margin(side, slice)
		box.set_content_margin(side, padding)
	return box

static func part(id: String, key: String) -> String:
	return "themes/" + id_for(id) + "/" + key

static func label(value: String, color: Color, font_size: int = 12) -> Label:
	var result := Label.new()
	result.text = value
	result.add_theme_font_override("font", FONT)
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", color)
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return result

static func button(id: String, value: String, selected: bool = false) -> Button:
	var result := Button.new()
	result.text = value
	result.add_theme_font_override("font", FONT)
	result.add_theme_font_size_override("font_size", 12)
	result.add_theme_stylebox_override("normal", style(part(id, "tab_selected" if selected else "tab_normal"), 6, 6))
	result.add_theme_stylebox_override("hover", style(part(id, "tab_hover"), 6, 6))
	result.add_theme_stylebox_override("pressed", style(part(id, "tab_selected"), 6, 6))
	var ink := Color(DARK_INK[id_for(id)])
	result.add_theme_color_override("font_color", ink)
	result.add_theme_color_override("font_hover_color", ink)
	result.add_theme_color_override("font_pressed_color", ink)
	return result

static func image(source: Texture2D, extent: Vector2) -> TextureRect:
	var result := TextureRect.new()
	result.texture = source
	result.custom_minimum_size = extent
	result.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	result.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return result
