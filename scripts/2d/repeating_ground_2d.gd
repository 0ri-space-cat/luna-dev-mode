extends Sprite2D
## One quiet authored ground image repeated over the continuous starter world.
## This layer is visual only: gameplay geometry and saves remain in world units.
const PRIMARY := "res://assets/2d/eternia/pixel/ground_base.png"
const FALLBACK := "res://assets/2d/eternia/terrain/grass_1.png"
const WORLD_SIZE := Vector2(1472, 1024)
var source_path := ""

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	centered = false
	region_enabled = true
	z_index = -20
	if ResourceLoader.exists(PRIMARY):
		var candidate := load(PRIMARY) as Texture2D
		if candidate != null and candidate.get_width() > 0 and candidate.get_height() > 0:
			texture = candidate
			source_path = PRIMARY
	if texture == null and ResourceLoader.exists(FALLBACK):
		texture = load(FALLBACK) as Texture2D
		source_path = FALLBACK
	if texture == null:
		push_error("No authored ground texture: " + PRIMARY + " / " + FALLBACK)
		return
	# Exact native 32px ImageGen tile is enlarged 2x, preserving the 64-unit grid.
	var pixel_scale := 2.0 if source_path == PRIMARY and texture.get_width() == 32 and texture.get_height() == 32 else 1.0
	scale = Vector2.ONE * pixel_scale
	region_rect = Rect2(Vector2.ZERO, WORLD_SIZE / pixel_scale)
	var old_ground := get_parent().get_node_or_null("Terrain") as CanvasItem
	if old_ground != null:
		old_ground.visible = false
