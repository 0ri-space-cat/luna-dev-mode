extends "res://scripts/skeleton/address_room.gd"
## In-world support, explored bounds and one physical route trigger.

@export var travel_bounds: Rect2
@export var action_bounds: Rect2
@export var other_floors: Array[Rect2] = []


func support_surfaces() -> Array[Dictionary]:
	var supports := super.support_surfaces()
	for bounds in other_floors:
		supports.append({"bounds": bounds, "height": floor_height})
	return supports
