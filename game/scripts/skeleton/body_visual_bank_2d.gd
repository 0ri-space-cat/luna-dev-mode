extends RefCounted
## DEV views imported byte-for-byte from the production register and approved Chibi bank.
## No authority over simulation; all scale/pivot estimates remain P0 candidates.
const ROOT := "res://assets/body_preview/"
const VIEWS := ["front", "front_right", "side_right", "back_right", "back"]
const FRIENDS := ["oni", "mia", "leia", "ori", "toffi", "yuki"]
const FRIEND_CANVAS := Vector2(128, 192)
const FRIEND_PIVOT := Vector2(64, 184)
const FRIEND_SCALE := 0.375
const CHIBI_HEIGHT := 58.0
const CHIBI_FRAMES := ["unarmed_idle_00", "unarmed_walk_00", "unarmed_idle_00", "unarmed_walk_01", "unarmed_idle_00"]

static var _textures: Dictionary = {}
static var _pivots: Dictionary = {}
static var _chibi_scale := 0.0


static func _texture(path: String) -> Texture2D:
	if not _textures.has(path):
		_textures[path] = load(path) as Texture2D
	return _textures[path]


static func _chibi_idle(view: String) -> Texture2D:
	return _texture(ROOT + "chibi_luna/" + view + "/unarmed_idle_00.png")


static func _chibi_pivot(view: String) -> Vector2:
	if not _pivots.has(view):
		var bounds := _chibi_idle(view).get_image().get_used_rect()
		_pivots[view] = Vector2(bounds.position.x + bounds.size.x * 0.5, bounds.end.y)
	return _pivots[view]


static func frame_for(category: String, row: int, frame: int) -> Dictionary:
	var view: String = VIEWS[clampi(row, 0, 4)]
	if category in FRIENDS:
		var texture := _texture(ROOT + category + "/" + view + ".png")
		if texture == null or texture.get_size() != FRIEND_CANVAS:
			return {}
		return {"texture": texture, "pivot": FRIEND_PIVOT, "scale": FRIEND_SCALE}
	if category == "chibi_luna":
		var texture := _texture(ROOT + category + "/" + view + "/" + CHIBI_FRAMES[clampi(frame, 0, 4)] + ".png")
		var idle := _chibi_idle(view)
		# Same per-view estimate for every contact, not a moving foot bbox.
		if texture == null or idle == null or texture.get_size() != idle.get_size():
			return {}
		if _chibi_scale <= 0.0:
			var bounds := _chibi_idle("front").get_image().get_used_rect()
			if bounds.size.y <= 0:
				return {}
			_chibi_scale = CHIBI_HEIGHT / float(bounds.size.y)
		return {"texture": texture, "pivot": _chibi_pivot(view), "scale": _chibi_scale}
	return {}


static func original_color(category: String) -> Color:
	# Existing graybox identity colors are not edits to the approved artwork.
	match category:
		"oni":
			return Color("efb68e")
		"mia":
			return Color("8ed7bd")
		_:
			return Color("b790dd")
