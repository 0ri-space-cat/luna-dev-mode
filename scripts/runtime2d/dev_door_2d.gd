extends Area2D
## Debug address doorway. A full door later supplies its own art and collider.
var entity_id := ""


func _ready() -> void:
	var shape := CollisionShape2D.new()
	var disk := CircleShape2D.new()
	disk.radius = 28.0
	shape.shape = disk
	add_child(shape)
	queue_redraw()


func _draw() -> void:
	draw_arc(Vector2.ZERO, 24.0, 0.0, TAU, 32, Color("9c86d4"), 3.0)
	draw_circle(Vector2.ZERO, 3.0, Color("f1d8ff"))
