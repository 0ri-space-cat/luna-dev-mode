extends RefCounted
## The wand projects the ordinary world even when another tool is active.
## The underside begins only outside the dropped wand's projection field.

var carried := true
var ground_position := Vector2.ZERO
var radius := 320.0 # Prototype tuning value; not a canonical distance.


func drop_at(world_position: Vector2) -> bool:
	if not carried:
		return false
	carried = false
	ground_position = world_position
	return true


func pick_up_from(player_position: Vector2, reach: float = 36.0) -> bool:
	if carried or player_position.distance_to(ground_position) > reach:
		return false
	carried = true
	return true


func is_underside_at(player_position: Vector2) -> bool:
	return not carried and player_position.distance_to(ground_position) > radius


func snapshot() -> Dictionary:
	return {"carried": carried, "position": [ground_position.x, ground_position.y], "radius": radius}


func restore(data: Dictionary) -> bool:
	var point: Variant = data.get("position", [])
	var next_radius: float = float(data.get("radius", -1.0))
	if not (point is Array) or point.size() != 2 or next_radius <= 0.0 or next_radius > 4096.0:
		return false
	if absf(float(point[0])) > 100000.0 or absf(float(point[1])) > 100000.0:
		return false
	carried = bool(data.get("carried", true))
	ground_position = Vector2(float(point[0]), float(point[1]))
	radius = next_radius
	return true
