extends RefCounted
## Reusable pixel-art import contract; nothing here affects simulation or saves.
## 32 source pixels become a 64-unit world tile via TileMapLayer.scale = (2, 2).
const SOURCE_TILE := 32
const WORLD_TILE := 64
const PIXEL_SCALE := 2

static func build_tile_set(atlas_texture: Texture2D, tile_pixels: int, columns: int, rows: int) -> TileSet:
	if atlas_texture == null or tile_pixels <= 0 or columns <= 0 or rows <= 0:
		return null
	if atlas_texture.get_width() != columns * tile_pixels or atlas_texture.get_height() != rows * tile_pixels:
		return null
	var tiles := TileSet.new()
	tiles.tile_size = Vector2i(tile_pixels, tile_pixels)
	var source := TileSetAtlasSource.new()
	source.texture = atlas_texture
	source.texture_region_size = Vector2i(tile_pixels, tile_pixels)
	for y in range(rows):
		for x in range(columns):
			source.create_tile(Vector2i(x, y))
	tiles.add_source(source, 0)
	return tiles

static func configure_tile_layer(layer: TileMapLayer, atlas_texture: Texture2D, tile_pixels: int, columns: int, rows: int, world_pixels: int = WORLD_TILE) -> bool:
	if layer == null or world_pixels <= 0 or tile_pixels <= 0 or world_pixels % tile_pixels != 0:
		return false
	var tiles := build_tile_set(atlas_texture, tile_pixels, columns, rows)
	if tiles == null:
		return false
	layer.tile_set = tiles
	layer.scale = Vector2.ONE * float(world_pixels / tile_pixels)
	layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return true

static func build_sprite_frames(sheet: Texture2D, frame_size: Vector2i, sequences: Dictionary, fps: float = 8.0) -> SpriteFrames:
	# Example: {"idle_down": {"row": 0, "frames": 2}, "walk_down": {"row": 4, "frames": 4}}
	if sheet == null or frame_size.x <= 0 or frame_size.y <= 0 or fps <= 0.0 or sequences.is_empty():
		return null
	if sheet.get_width() % frame_size.x != 0 or sheet.get_height() % frame_size.y != 0:
		return null
	var columns: int = int(sheet.get_width() / frame_size.x)
	var rows: int = int(sheet.get_height() / frame_size.y)
	for name in sequences:
		var spec: Variant = sequences[name]
		if typeof(spec) != TYPE_DICTIONARY or str(name).is_empty():
			return null
		var row: int = int(spec.get("row", -1))
		var count: int = int(spec.get("frames", 0))
		if row < 0 or row >= rows or count < 1 or count > columns:
			return null
	var result := SpriteFrames.new()
	for name in sequences:
		var animation := str(name)
		var spec: Dictionary = sequences[name]
		if not result.has_animation(animation):
			result.add_animation(animation)
		result.set_animation_speed(animation, fps)
		result.set_animation_loop(animation, bool(spec.get("loop", true)))
		var row: int = int(spec["row"])
		for column in range(int(spec["frames"])):
			var frame := AtlasTexture.new()
			frame.atlas = sheet
			frame.region = Rect2(Vector2(column * frame_size.x, row * frame_size.y), Vector2(frame_size))
			frame.filter_clip = true
			result.add_frame(animation, frame)
	return result

static func configure_animated_sprite(sprite: AnimatedSprite2D, frames: SpriteFrames, pixel_scale: int = PIXEL_SCALE) -> bool:
	if sprite == null or frames == null or pixel_scale < 1:
		return false
	sprite.sprite_frames = frames
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2.ONE * float(pixel_scale)
	return true
