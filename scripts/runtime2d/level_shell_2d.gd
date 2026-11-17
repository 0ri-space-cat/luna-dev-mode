extends Node2D
## Authored-level contract: art, collision, gameplay zones and entities remain
## separate. No arbitrary pixels are treated as hackable objects.

signal zone_entered(zone_id: String, entity_id: String)
signal zone_exited(zone_id: String, entity_id: String)

const PlatePair = preload("res://scripts/runtime2d/plate_pair_2d.gd")
const LevelGeometry = preload("res://scripts/runtime2d/level_geometry_2d.gd")

@export var level_size := Vector2(1536, 1024)
@export var ordinary_background: Texture2D
@export var underside_background: Texture2D
@export_file("*.json") var geometry_json_path := ""

var plate
var geometry
var collision_root: Node2D
var entity_mount: Node2D
var effects_mount: Node2D
var foreground_mount: Node2D
var last_error := ""


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	plate = PlatePair.new()
	plate.name = "RegisteredBackgroundPlates"
	plate.level_size = level_size
	plate.normal_plate = ordinary_background
	plate.underside_plate = underside_background
	add_child(plate)

	collision_root = Node2D.new()
	collision_root.name = "AuthoredCollision"
	add_child(collision_root)
	geometry = LevelGeometry.new()
	geometry.level_size = level_size
	geometry.name = "GameplayGeometry"
	collision_root.add_child(geometry)
	# Even a scene without a geometry JSON needs a valid, bounded navigation
	# grid. Author-made empty rooms must allow actors to move normally.
	if not geometry.build_from_description({"solids": [], "zones": []}):
		push_error("Invalid empty level geometry: " + geometry.last_error)
	geometry.zone_entered.connect(func(zone_id: String, entity_id: String):
		zone_entered.emit(zone_id, entity_id))
	geometry.zone_exited.connect(func(zone_id: String, entity_id: String):
		zone_exited.emit(zone_id, entity_id))

	entity_mount = Node2D.new()
	entity_mount.name = "LocationEntities"
	entity_mount.y_sort_enabled = true
	add_child(entity_mount)
	effects_mount = Node2D.new()
	effects_mount.name = "AmbientEffects"
	add_child(effects_mount)
	foreground_mount = Node2D.new()
	foreground_mount.name = "StaticForegroundOcclusion"
	add_child(foreground_mount)

	if not geometry_json_path.is_empty():
		if not load_geometry(geometry_json_path):
			push_error("Unable to load level geometry: " + last_error)


const MAX_GEOMETRY_JSON_BYTES := 1024 * 1024


## Called on an instanced, but not yet mounted, authored level. If a geometry
## manifest is malformed, no live scene, observer, entity or route is touched.
func preflight_geometry() -> bool:
	last_error = ""
	var validator = LevelGeometry.new()
	validator.level_size = level_size
	if not validator.navigation.configure(level_size, []):
		last_error = validator.navigation.last_error
		validator.free()
		return false
	if geometry_json_path.is_empty():
		validator.free()
		return true
	var payload: Variant = _read_geometry_json(geometry_json_path)
	if not (payload is Dictionary):
		validator.free()
		return false
	if not validator.validate_description(payload):
		last_error = validator.last_error
		validator.free()
		return false
	var usable: bool = validator.navigation.configure(level_size, payload.get("solids", []))
	if not usable:
		last_error = validator.navigation.last_error
	validator.free()
	return usable


func _read_geometry_json(path: String) -> Variant:
	if not path.begins_with("res://"):
		last_error = "Geometry must be a bundled authored resource"
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		last_error = "Geometry file is missing"
		return null
	if file.get_length() > MAX_GEOMETRY_JSON_BYTES:
		file.close()
		last_error = "Geometry manifest exceeds 1 MiB limit"
		return null
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not (parsed is Dictionary):
		last_error = "Invalid geometry JSON"
		return null
	return parsed


func load_geometry(path: String) -> bool:
	last_error = ""
	var parsed: Variant = _read_geometry_json(path)
	if not (parsed is Dictionary):
		return false
	if not geometry.build_from_description(parsed):
		last_error = geometry.last_error
		return false
	return true


func set_underside(active: bool) -> void:
	plate.set_underside(active)


func set_background_pair(ordinary: Texture2D, hidden: Texture2D) -> bool:
	return plate.set_plates(ordinary, hidden)
