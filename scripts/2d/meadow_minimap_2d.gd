extends Control
## Runtime projection. World geography, never a baked screenshot.
var player: Node2D
var markers: Array = []
func set_targets(actor: Node2D, things: Array) -> void:
	player = actor
	markers = things
func _process(_delta: float) -> void:
	queue_redraw()
func _draw() -> void:
	var center := Vector2(64, 64)
	draw_circle(center, 62, Color("#28204c"))
	draw_circle(center, 57, Color("#a5d65c"))
	draw_arc(center, 59, 0, TAU, 64, Color("#e7a4fb"), 5)
	for item in markers:
		if is_instance_valid(item):
			var point := center + (item.global_position - Vector2(640, 400)) / 12.0
			if point.distance_to(center) < 54:
				draw_circle(point, 4.5, Color("#8130b0"))
	if is_instance_valid(player):
		var pos := center + (player.global_position - Vector2(640, 400)) / 12.0
		if pos.distance_to(center) < 54:
			draw_circle(pos, 5, Color("#fff4ff"))
			draw_circle(pos, 2, Color("#7541e6"))
