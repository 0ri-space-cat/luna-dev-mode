extends "res://scripts/runtime2d/doorway_2d.gd"
## Development-only doorway marker. Authored levels use Doorway2D and their own art.


func _ready() -> void:
	super._ready()
	queue_redraw()


func _draw() -> void:
	draw_arc(Vector2.ZERO, 24.0, 0.0, TAU, 32, Color("9c86d4"), 3.0)
	draw_circle(Vector2.ZERO, 3.0, Color("f1d8ff"))
