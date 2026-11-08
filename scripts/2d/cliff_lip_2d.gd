extends TileMapLayer
## Artistic cliff-lip PILOT. Three 64px painterly SVG cells repeat along the
## existing lower terrace. The underlying old geometry is kept for rollback.
## Only this small terrain layer is new; no physics or save format changes.
const TILE_SIZE := 64
const ATLAS_COLUMNS := 3
const WORLD_COLUMNS := 23
const ATLAS_PATH := "res://assets/2d/eternia/terrain/cliff_lip_01.svg"

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var texture := load(ATLAS_PATH) as Texture2D
	if texture == null:
		push_error("Missing illustrated cliff lip atlas: " + ATLAS_PATH)
		return
	var tiles := TileSet.new()
	tiles.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	var atlas := TileSetAtlasSource.new()
	atlas.texture = texture
	atlas.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	for i in range(ATLAS_COLUMNS):
		atlas.create_tile(Vector2i(i, 0))
	tiles.add_source(atlas, 0)
	tile_set = tiles
	for x in range(WORLD_COLUMNS):
		set_cell(Vector2i(x, 0), 0, Vector2i(x % ATLAS_COLUMNS, 0))
