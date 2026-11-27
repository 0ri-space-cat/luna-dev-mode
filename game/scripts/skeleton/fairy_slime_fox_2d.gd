extends "res://scripts/skeleton/entity_body_2d.gd"
## A local body with one identity on both sides of the temporal passage.

var _spots: Polygon2D

func can_edit_parameter(key: String) -> bool:
	return key == "alive" or (key not in Parameters.ATTACHMENT_FIELDS and super.can_edit_parameter(key))


func set_parameter(key: String, value: Variant) -> bool:
	if key != "alive":
		return super.set_parameter(key, value)
	if not value is bool:
		return false
	record.parameters["alive"] = value
	if not value:
		_stop_active_motion()
	return true


func restore_life(data: Variant) -> bool:
	if not data is Dictionary or data.size() != 2 or data.get("asleep") != false:
		return false
	return set_parameter("alive", data.get("alive"))


func refresh_form_marker() -> void:
	if not is_instance_valid(_marker):
		return
	_marker.polygon = PackedVector2Array([Vector2(-15, 0), Vector2(-22, -12), Vector2(-16, -25),
		Vector2(-7, -19), Vector2(4, -21), Vector2(14, -30), Vector2(20, -13), Vector2(21, 0)])
	if not is_instance_valid(_spots):
		_spots = Polygon2D.new()
		_spots.color = Color("efe7b5")
		_spots.polygon = PackedVector2Array([Vector2(-10, -8), Vector2(-6, -14), Vector2(-1, -8),
			Vector2(-6, -4)])
		_marker.add_child(_spots)
