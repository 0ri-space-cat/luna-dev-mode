extends Node2D
## Authored collision geometry only. Rendering plates never define passability.
## Input rectangles are [left, top, width, height] in canonical 2D world units.
## Solid walls remain solid during flight; low obstacles may be bypassed by FLY.

signal zone_entered(zone_id: String, entity_id: String)
signal zone_exited(zone_id: String, entity_id: String)

const GridNavigation = preload("res://scripts/runtime2d/grid_navigation_2d.gd")

const WALL_LAYER := 1
const ACTOR_LAYER := 2
const GROUND_ONLY_LAYER := 4
const MAX_SOLIDS := 256
const MAX_ZONES := 96

var last_error := ""
var level_size := Vector2(1536, 1024)
var navigation = GridNavigation.new()
var _solids: Array[StaticBody2D] = []
var _zones: Array[Area2D] = []


func build_from_description(description: Dictionary) -> bool:
	last_error = ""
	if not validate_description(description):
		return false
	if not navigation.configure(level_size, description.get("solids", [])):
		return _fail(navigation.last_error)
	clear_geometry()
	for entry in description.get("solids", []):
		var data: Dictionary = entry
		var rect := _parse_rect(data["rect"])
		_add_solid(rect, str(data["kind"]) == "GROUND_ONLY", str(data.get("id", "")))
	for entry in description.get("zones", []):
		var data: Dictionary = entry
		_add_zone(_parse_rect(data["rect"]), str(data["id"]))
	return true


func validate_description(description: Dictionary) -> bool:
	if not (description.get("solids", []) is Array) or not (description.get("zones", []) is Array):
		return _fail("Geometry arrays required")
	var solids: Array = description.get("solids", [])
	var zones: Array = description.get("zones", [])
	if solids.size() > MAX_SOLIDS or zones.size() > MAX_ZONES:
		return _fail("Too many colliders or zones")
	var ids := {}
	for entry in solids:
		if not (entry is Dictionary) or not _valid_rect(entry.get("rect", null)):
			return _fail("Invalid solid rectangle")
		if str(entry.get("kind", "")) not in ["WALL", "GROUND_ONLY"]:
			return _fail("Unknown collision kind")
		var solid_id := str(entry.get("id", ""))
		if not solid_id.is_empty():
			if not _valid_id(solid_id) or ids.has(solid_id):
				return _fail("Repeated or invalid collision ID")
			ids[solid_id] = true
	for entry in zones:
		if not (entry is Dictionary) or not _valid_rect(entry.get("rect", null)):
			return _fail("Invalid zone rectangle")
		var zone_id := str(entry.get("id", ""))
		if not _valid_id(zone_id) or ids.has(zone_id):
			return _fail("Repeated or invalid zone ID")
		ids[zone_id] = true
	return true


func clear_geometry() -> void:
	for child in _solids:
		remove_child(child)
		child.queue_free()
	for child in _zones:
		remove_child(child)
		child.queue_free()
	_solids.clear()
	_zones.clear()


func solid_count() -> int:
	return _solids.size()


func zone_count() -> int:
	return _zones.size()


func _add_solid(rect: Rect2, ground_only: bool, id: String) -> void:
	var wall := StaticBody2D.new()
	wall.name = id if not id.is_empty() else "AuthoredSolid"
	wall.position = rect.position + rect.size * 0.5
	wall.collision_layer = GROUND_ONLY_LAYER if ground_only else WALL_LAYER
	wall.collision_mask = 0
	var hitbox := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	hitbox.shape = shape
	wall.add_child(hitbox)
	add_child(wall)
	_solids.append(wall)


func _add_zone(rect: Rect2, zone_id: String) -> void:
	var area := Area2D.new()
	area.name = zone_id
	area.position = rect.position + rect.size * 0.5
	area.collision_layer = 0
	area.collision_mask = ACTOR_LAYER
	area.monitoring = true
	area.monitorable = false
	var hitbox := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	hitbox.shape = shape
	area.add_child(hitbox)
	add_child(area)
	area.body_entered.connect(_on_zone_body_entered.bind(zone_id))
	area.body_exited.connect(_on_zone_body_exited.bind(zone_id))
	_zones.append(area)


func _on_zone_body_entered(body: Node2D, zone_id: String) -> void:
	var record: Variant = body.get("record")
	if record != null:
		zone_entered.emit(zone_id, str(record.id))


func _on_zone_body_exited(body: Node2D, zone_id: String) -> void:
	var record: Variant = body.get("record")
	if record != null:
		zone_exited.emit(zone_id, str(record.id))


func _parse_rect(values: Array) -> Rect2:
	return Rect2(Vector2(float(values[0]), float(values[1])), Vector2(float(values[2]), float(values[3])))


func _valid_rect(data: Variant) -> bool:
	if not (data is Array) or data.size() != 4:
		return false
	for value in data:
		if typeof(value) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(value)):
			return false
		if absf(float(value)) > 100000.0:
			return false
	return float(data[2]) >= 1.0 and float(data[3]) >= 1.0 and float(data[2]) <= 20000.0 and float(data[3]) <= 20000.0


func _valid_id(value: String) -> bool:
	return not value.is_empty() and value.length() <= 96 and value.is_valid_identifier()


func _fail(reason: String) -> bool:
	last_error = reason
	return false
