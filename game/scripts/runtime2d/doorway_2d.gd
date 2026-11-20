extends Area2D
## Drop this gameplay component into an authored level at its real map position.
## Destination is owned by the LocationRouter, never by the visual sprite.
## Art, animation and dialogue are supplied by separate child nodes.

@export var entity_id := ""
@export var destination_entry_id := "entry"
@export_range(12.0, 192.0, 1.0) var interaction_radius := 64.0


func _ready() -> void:
	add_to_group("runtime2d_address_doors")
	collision_layer = 0
	collision_mask = 2 # Active 2D actors only, no art-based collision.
	if get_node_or_null("DoorTrigger") == null:
		var trigger := CollisionShape2D.new()
		trigger.name = "DoorTrigger"
		var shape := CircleShape2D.new()
		shape.radius = 20.0
		trigger.shape = shape
		add_child(trigger)


func can_interact_from(point: Vector2) -> bool:
	return point.distance_squared_to(global_position) <= interaction_radius * interaction_radius
