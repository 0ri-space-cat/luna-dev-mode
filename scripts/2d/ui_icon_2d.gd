extends TextureRect
## Consistent illustrated game icons, not system-font emoji.
const DIR := "res://assets/2d/ui/icons/"
func _init(icon_id: String = "wand") -> void:
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var uri := DIR + icon_id + ".svg"
	if ResourceLoader.exists(uri):
		texture = load(uri)
