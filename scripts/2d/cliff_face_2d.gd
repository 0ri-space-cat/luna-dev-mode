extends TileMapLayer
## Lower-cliff face made from repeatable art tiles. It lives behind the lip
## and can be replaced independently when the final painted atlas arrives.
const TILE_SIZE := 64
const ATLAS_COLUMNS := 3
const WORLD_COLUMNS := 23
const FACE_ROWS := 4
const ATLAS_PATH := "res://assets/2d/eternia/terrain/cliff_face_01.svg"

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var texture := load(ATLAS_PATH) as Texture2D
	if texture == null:
		push_error("Missing illustrated cliff face atlas: " + ATLAS_PATH)
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
	for y in range(FACE_ROWS):
		for x in range(WORLD_COLUMNS):
			set_cell(Vector2i(x, y), 0, Vector2i((x + y) % ATLAS_COLUMNS, 0))
