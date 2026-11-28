extends "res://scripts/skeleton/fauna_body_2d.gd"
## The waterfall guardian is an ordinary living Entity with a saved body.

const CATEGORY := "giant_axolotl"


func can_edit_parameter(key: String) -> bool:
	return key == "health" or (key not in Parameters.ATTACHMENT_FIELDS and super.can_edit_parameter(key))


func set_parameter(key: String, value: Variant) -> bool:
	if key == "health":
		return record.set_parameter(key, value)
	return super.set_parameter(key, value)


func refresh_form_marker() -> void:
	_marker.polygon = PackedVector2Array([Vector2(-20, -2), Vector2(-25, -9), Vector2(-22, -21),
		Vector2(-14, -27), Vector2(10, -26), Vector2(24, -18), Vector2(22, -6), Vector2(13, 0)])
	var gills := Line2D.new()
	gills.points = PackedVector2Array([Vector2(-22, -16), Vector2(-34, -21), Vector2(-21, -19),
		Vector2(-28, -31), Vector2(-15, -23)])
	gills.width = 4.0
	gills.default_color = Color("cc609e")
	_marker.add_child(gills)
