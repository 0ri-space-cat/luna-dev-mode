extends TileMapLayer
## Eternia meadow foundation. Twelve subtly distinct grass tiles with an identical
## edge color. Changes are interior-only; no per-cell borders or baked props.
const TILE := 64
const COLUMNS := 23
const ROWS := 16
const VARIANTS := 12
const ART_ROOT := "res://assets/2d/eternia/terrain/"
const BASE := Color("#83c258")

func _ready() -> void:
	var tiles := TileSet.new()
	tiles.tile_size = Vector2i(TILE, TILE)
	for n in range(VARIANTS):
		var texture: Texture2D
		var filename := ART_ROOT + "grass_%d.png" % (n + 1)
		if ResourceLoader.exists(filename):
			texture = load(filename)
		else:
			push_warning("Missing painted grass tile: " + filename)
			texture = _generate_tile(n)
		_add_source(tiles, texture, n)
	tile_set = tiles
	for y in range(ROWS):
		for x in range(COLUMNS):
			var variety := _variant_at(x, y)
			set_cell(Vector2i(x, y), variety, Vector2i.ZERO)

func _variant_at(x: int, y: int) -> int:
	# Clumped color variation, but repeatable independently of machine clock.
	var coarse := ((x / 4) * 3 + (y / 3) * 7 + (x * y / 13)) % VARIANTS
	var fine := ((x * 97 + y * 61 + x * y * 13) % VARIANTS)
	return (coarse + fine / 3) % VARIANTS

func _add_source(tiles: TileSet, texture: Texture2D, source_id: int) -> void:
	var atlas := TileSetAtlasSource.new()
	atlas.texture = texture
	atlas.texture_region_size = Vector2i(TILE, TILE)
	atlas.create_tile(Vector2i.ZERO)
	tiles.add_source(atlas, source_id)

func _generate_tile(index: int) -> Texture2D:
	var image := Image.create(TILE, TILE, false, Image.FORMAT_RGBA8)
	for y in range(TILE):
		for x in range(TILE):
			var u := float(x) / float(TILE - 1)
			var v := float(y) / float(TILE - 1)
			var edge_mask := sin(PI * u) * sin(PI * v)
			edge_mask *= edge_mask
			var slow := sin(u*8.0 + index*1.71)*cos(v*6.0 + index*0.76)
			var fine := sin(u*29.0 + index*4.01)*sin(v*21.0 + index*3.13)
			var shade := edge_mask * (slow * 0.070 + fine * 0.030)
			var red := clampf(BASE.r + shade * 0.58, 0.0, 1.0)
			var green := clampf(BASE.g + shade * 0.75, 0.0, 1.0)
			var blue := clampf(BASE.b + shade * 0.36, 0.0, 1.0)
			image.set_pixel(x, y, Color(red, green, blue, 1.0))
	var seed := (index + 1) * 21911
	for mark in range(34):
		var x := 8 + (seed * (mark + 3) * 17 + mark*49) % 48
		var y := 8 + (seed * (mark + 7) * 13 + mark*73) % 48
		var blade := Color("#73b443", 0.55) if mark % 2 == 0 else Color("#c9ea69", 0.75)
		_paint_grass(image, x, y, blade)
	return ImageTexture.create_from_image(image)

func _paint_grass(image: Image, x: int, y: int, blade: Color) -> void:
	for offset in [-2, 0, 2]:
		for rise in range(3):
			var xx: int = x + int(offset) + (int(offset / 2) if rise == 0 else 0)
			var yy: int = y - rise
			if xx > 2 and yy > 2 and xx < TILE - 3 and yy < TILE - 3:
				var base: Color = image.get_pixel(xx, yy)
				image.set_pixel(xx, yy, base.lerp(blade, 0.27))
