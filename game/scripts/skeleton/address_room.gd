extends Node2D
## Authored 2D+Z room geometry and the position of its natural door.

const Doorway = preload("res://scripts/runtime2d/doorway_2d.gd")

@export var floor_bounds: Rect2
@export var floor_height := 0.0
@export var column_bounds: Rect2
@export var column_top := 0.0
@export var requires_door := true

@onready var door := get_node_or_null("Door") as Doorway


func floor_surface() -> Dictionary:
	return {"bounds": floor_bounds, "height": floor_height}


func support_surfaces() -> Array[Dictionary]:
	return [floor_surface()]


func walls() -> Array[Dictionary]:
	if column_bounds.has_area():
		return [{"bounds": column_bounds, "height": column_top, "layer": 1}]
	return []


func _draw() -> void:
	if door == null:
		return
	var opening := Rect2(door.position - Vector2(17, 46 + floor_height), Vector2(34, 46))
	draw_rect(opening, Color("473750"))
	draw_rect(opening, Color("c8a9cf"), false, 3.0)
	draw_circle(opening.position + Vector2(26, 26), 2.5, Color("f4d6a0"))
