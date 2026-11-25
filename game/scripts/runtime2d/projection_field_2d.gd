extends RefCounted
## The wand projects the ordinary world even when another tool is active.
## The underside begins only outside the dropped wand's projection field.

var carried := true
var ground_position := Vector2.ZERO
var ground_location_id := ""
var radius := 320.0 # Prototype tuning value; not a canonical distance.


func drop_at(world_position: Vector2, location_id: String = "") -> bool:
	if not carried:
		return false
	carried = false
	ground_position = world_position
	ground_location_id = location_id
	return true


func pick_up_from(player_position: Vector2, reach: float = 36.0, location_id: String = "") -> bool:
	if not ground_location_id.is_empty() and ground_location_id != location_id:
		return false
	if carried or player_position.distance_to(ground_position) > reach:
		return false
	carried = true
	return true


func is_underside_at(player_position: Vector2, location_id: String = "") -> bool:
	if carried:
		return false
	if not ground_location_id.is_empty() and ground_location_id != location_id:
		return true
	return player_position.distance_to(ground_position) > radius


static func is_outside_all(fields: Array, point: Vector2, location_id: String) -> bool:
	for field in fields:
		if not field.is_underside_at(point, location_id):
			return false
	return true


func snapshot() -> Dictionary:
	return {"carried": carried, "position": [ground_position.x, ground_position.y],
		"location_id": ground_location_id, "radius": radius}


func restore(data: Dictionary) -> bool:
	var point: Variant = data.get("position", [])
	var raw_radius: Variant = data.get("radius")
	var raw_location: Variant = data.get("location_id", "")
	var raw_carried: Variant = data.get("carried", true)
	if typeof(raw_radius) not in [TYPE_INT, TYPE_FLOAT] or not raw_location is String or not raw_carried is bool:
		return false
	var next_radius := float(raw_radius)
	if not (point is Array) or point.size() != 2 or next_radius <= 0.0 or next_radius > 4096.0 or not is_finite(next_radius):
		return false
	for value in point:
		if typeof(value) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(value)):
			return false
	if absf(float(point[0])) > 100000.0 or absf(float(point[1])) > 100000.0:
		return false
	var restored_location: String = raw_location
	if not restored_location.is_empty() and (not restored_location.is_valid_identifier() or restored_location.length() > 96):
		return false
	carried = raw_carried
	ground_location_id = restored_location
	ground_position = Vector2(float(point[0]), float(point[1]))
	radius = next_radius
	return true
