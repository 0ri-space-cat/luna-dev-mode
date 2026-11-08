extends SceneTree
const Pixel = preload("res://scripts/2d/pixel_art_pipeline_2d.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	assert(Pixel.SOURCE_TILE == 32 and Pixel.WORLD_TILE == 64 and Pixel.PIXEL_SCALE == 2)
	# Use synthesized test textures: the pipeline does not depend on paid generators.
	var grass := Image.create(128, 96, false, Image.FORMAT_RGBA8)
	grass.fill(Color("#86be69"))
	var atlas := ImageTexture.create_from_image(grass)
	assert(Pixel.build_tile_set(atlas, 32, 4, 2) == null)
	var layer := TileMapLayer.new()
	root.add_child(layer)
	assert(Pixel.configure_tile_layer(layer, atlas, 32, 4, 3))
	assert(layer.tile_set.tile_size == Vector2i(32, 32))
	assert(layer.scale == Vector2(2, 2))
	assert(layer.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST)
	var source := layer.tile_set.get_source(0) as TileSetAtlasSource
	assert(source != null and source.get_tiles_count() == 12)
	layer.set_cell(Vector2i(0, 0), 0, Vector2i(0, 0))
	layer.set_cell(Vector2i(1, 0), 0, Vector2i(1, 0))
	assert(layer.get_cell_atlas_coords(Vector2i(1, 0)) == Vector2i(1, 0))
	# A 32-pixel atlas cell is 64 world units after the layer's uniform scale.
	assert(layer.map_to_local(Vector2i(1, 0)) * layer.scale == Vector2(96, 32))
	assert(not Pixel.configure_tile_layer(layer, atlas, 32, 5, 3))
	assert(layer.get_cell_source_id(Vector2i(0, 0)) == 0)
	layer.queue_free()

	var strip := Image.create(48 * 4, 64 * 4, false, Image.FORMAT_RGBA8)
	strip.fill(Color("#ddb2f4"))
	var sheet := ImageTexture.create_from_image(strip)
	var layout := {
		"walk_down": {"row": 0, "frames": 4},
		"walk_left": {"row": 1, "frames": 4},
		"walk_right": {"row": 2, "frames": 4},
		"walk_up": {"row": 3, "frames": 4}
	}
	var animations := Pixel.build_sprite_frames(sheet, Vector2i(48, 64), layout, 7.0)
	assert(animations != null)
	assert(animations.get_frame_count("walk_down") == 4)
	assert(animations.get_animation_speed("walk_down") == 7.0)
	assert(animations.get_frame_count("walk_up") == 4)
	var final_frame := animations.get_frame_texture("walk_up", 3) as AtlasTexture
	assert(final_frame != null)
	assert(final_frame.region == Rect2(144, 192, 48, 64))
	assert(final_frame.filter_clip)
	assert(Pixel.build_sprite_frames(sheet, Vector2i(48, 64), {"bad": {"row": 4, "frames": 4}}) == null)
	var sprite := AnimatedSprite2D.new()
	root.add_child(sprite)
	assert(Pixel.configure_animated_sprite(sprite, animations))
	assert(sprite.scale == Vector2(2, 2))
	assert(sprite.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST)
	assert(sprite.sprite_frames.has_animation("walk_right"))
	sprite.queue_free()
	print("Pixel art tile/spritesheet pipeline: PASS")
	quit()
