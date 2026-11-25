extends "res://scripts/skeleton/address_room.gd"
## Geometry authored for the projection sample only.

const ElevationMotion = preload("res://scripts/skeleton/elevation_motion_2d.gd")
const TREAD_RISE := ElevationMotion.MAX_STEP_RISE

@export var isometric := false
@export var stairs: Array[Rect2] = []
@export var raised_deck: Rect2
@export var oni_position := Vector2.ZERO
@export var obstacles: Array[Dictionary] = []


func support_surfaces() -> Array[Dictionary]:
	var supports := super.support_surfaces()
	for index in stairs.size():
		supports.append({
			"bounds": stairs[index], "height": float(index + 1) * TREAD_RISE,
			"walk_up": true, "safe": false,
		})
	if raised_deck.has_area():
		supports.append({"bounds": raised_deck, "height": float(stairs.size()) * TREAD_RISE})
	return supports


func walls() -> Array[Dictionary]:
	var solids := obstacles.duplicate()
	# Open along the run, solid along the two sides of the staircase.
	for index in stairs.size():
		var tread := stairs[index]
		var height := float(index + 1) * TREAD_RISE
		var layer := 1 << (index + 3)
		for side in [tread.position.y - 2.0, tread.end.y]:
			solids.append({
				"bounds": Rect2(tread.position.x, side, tread.size.x, 2.0),
				"height": height, "layer": layer,
			})
	return solids


func _draw() -> void:
	pass
