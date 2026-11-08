extends Node2D
## Isolated 2D runtime experiment. Does not replace the main scene yet.
## No dependencies on Node3D or the legacy main.gd.

const WALK_SPEED := 210.0
@onready var player: CharacterBody2D = $Entities/Player

func _ready() -> void:
	queue_redraw()

func _physics_process(_delta: float) -> void:
	var axis := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	player.velocity = axis * WALK_SPEED
	player.move_and_slide()
	queue_redraw()

func _draw() -> void:
	# Temporary code-drawn ground: no generated art is needed to test coordinates.
	draw_rect(Rect2(Vector2.ZERO, Vector2(1280, 800)), Color("#8fcf53"))
	for x in range(0, 1280, 64):
		for y in range(0, 800, 64):
			if (x / 64 + y / 64) % 2 == 0:
				draw_rect(Rect2(x, y, 64, 64), Color(1, 1, 1, 0.018))
	# Marker for 2D player; replaced with an animated rig later.
	draw_circle(player.position, 14.0, Color("#8b49c7"))
	draw_arc(player.position, 14.0, 0.0, TAU, 24, Color("#3b205c"), 3.0)

# Entity adapter: res://scripts/2d/entity_actor_2d.gd
