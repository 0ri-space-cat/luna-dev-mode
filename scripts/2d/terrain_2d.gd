extends TileMapLayer
## Seamless prototype ground. Tile boundaries are never outlined.
const TILE := 64
const COLUMNS := 23
const ROWS := 16

func _ready() -> void:
	var image := Image.create(TILE, TILE, false, Image.FORMAT_RGBA8)
	for y in range(TILE):
		for x in range(TILE):
			# Periodic color variation: opposite pixel edges match.
			var u := float(x) / float(TILE - 1)
			var v := float(y) / float(TILE - 1)
			var shade := 0.025 * sin(u * TAU) * sin(v * TAU) + 0.012 * cos(2.0 * u * TAU) * cos(2.0 * v * TAU)
			image.set_pixel(x, y, Color(0.57 + shade, 0.80 + shade, 0.27 + shade, 1.0))
	var atlas := TileSetAtlasSource.new()
	atlas.texture = ImageTexture.create_from_image(image)
	atlas.texture_region_size = Vector2i(TILE, TILE)
	atlas.create_tile(Vector2i.ZERO)
	var tiles := TileSet.new()
	tiles.tile_size = Vector2i(TILE, TILE)
	tiles.add_source(atlas, 0)
	tile_set = tiles
	for y in range(ROWS):
		for x in range(COLUMNS):
			set_cell(Vector2i(x, y), 0, Vector2i.ZERO)
