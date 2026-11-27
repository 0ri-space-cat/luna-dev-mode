extends "res://scripts/skeleton/entity_body_2d.gd"

const Map = preload("res://scripts/skeleton/fairy_realm_layout.gd")
var eyes_closed := false
var _eye: Line2D


func _ready() -> void:
	super._ready()
	_eye = Line2D.new()
	_eye.points = PackedVector2Array([Vector2(-6, -17), Vector2(5, -17)])
	_eye.default_color = Color("f4d3bd")
	_eye.width = 1.8
	_eye.visible = false
	_marker.add_child(_eye)


func close_eyes(value: bool) -> void:
	eyes_closed = value
	_eye.visible = value


func _update_wall_mask(feet: float) -> void:
	super._update_wall_mask(feet)
	if eyes_closed:
		collision_mask &= ~int(Map.CANOPY_DOOR["layer"])
