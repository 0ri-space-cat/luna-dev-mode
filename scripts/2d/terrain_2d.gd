extends TileMapLayer
## Seamless terrain: production PNG tiles if installed, periodic fallback otherwise.
const TILE := 64
const COLUMNS := 23
const ROWS := 16
const ART_ROOT := "res://assets/2d/eternia/terrain/"

func _ready() -> void:
	var tiles := TileSet.new()
	tiles.tile_size = Vector2i(TILE, TILE)
	var installed := true
	for n in range(1,4):
		if not ResourceLoader.exists(ART_ROOT + "grass_%d.png" % n):
			installed = false
	if installed:
		for n in range(1,4):
			var texture: Texture2D = load(ART_ROOT + "grass_%d.png" % n) as Texture2D
			_add_source(tiles, texture, n - 1)
	else:
		_add_source(tiles, _make_periodic_texture(), 0)
	tile_set = tiles
	for y in range(ROWS):
		for x in range(COLUMNS):
			var source_id := ((x * 11 + y * 17 + x * y * 3) % 3) if installed else 0
			set_cell(Vector2i(x, y), source_id, Vector2i.ZERO)

func _add_source(tiles: TileSet, texture: Texture2D, source_id: int) -> void:
	var atlas := TileSetAtlasSource.new()
	atlas.texture = texture
	atlas.texture_region_size = Vector2i(TILE, TILE)
	atlas.create_tile(Vector2i.ZERO)
	tiles.add_source(atlas, source_id)

func _make_periodic_texture() -> Texture2D:
	var image := Image.create(TILE, TILE, false, Image.FORMAT_RGBA8)
	for y in range(TILE):
		for x in range(TILE):
			var u := float(x) / float(TILE - 1)
			var v := float(y) / float(TILE - 1)
			var shade := 0.025 * sin(u * TAU) * sin(v * TAU) + 0.012 * cos(2.0 * u * TAU) * cos(2.0 * v * TAU)
			image.set_pixel(x, y, Color(0.57 + shade, 0.80 + shade, 0.27 + shade, 1.0))
	return ImageTexture.create_from_image(image)
