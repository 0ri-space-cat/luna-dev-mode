extends CharacterBody2D
## Skeleton adapter. CharacterBody2D owns XY; the elevation model owns Z.
## The fixture uses a separate layer per height volume, with walkable tops.

const ElevationMotion = preload("res://scripts/skeleton/elevation_motion_2d.gd")
const GRAVITY := 620.0
const JUMP_SPEED := 295.0
const FLIGHT_ACCELERATION := 940.0
const WALK_SPEED := 175.0
const FOOT_RADIUS := 11.0
const RECOVERY_HEIGHT := -96.0

var motion := ElevationMotion.new()
var surfaces: Array[Dictionary] = []
var walls: Array[Dictionary] = []
var direction := Vector2.ZERO
var gravity_scale := 1.0
var flight_enabled := false
var thrust_requested := false
var recoveries := 0
var entity_id := ""
var _marker: Polygon2D


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = 0
	var footprint := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = FOOT_RADIUS
	footprint.shape = circle
	add_child(footprint)
	_marker = Polygon2D.new()
	_marker.color = Color("eed7f8")
	_marker.polygon = PackedVector2Array([
		Vector2(-12, 0), Vector2(-9, -19), Vector2(0, -27),
		Vector2(9, -19), Vector2(12, 0),
	])
	add_child(_marker)
	_sync_projection()


func jump() -> void:
	if motion.grounded:
		motion.add_impulse(JUMP_SPEED)


func _physics_process(delta: float) -> void:
	collision_mask = 0
	for wall in walls:
		if motion.elevation < float(wall["height"]) - ElevationMotion.EPSILON:
			collision_mask |= int(wall["layer"])
	velocity = direction.limit_length() * WALK_SPEED
	var previous := position
	move_and_slide()
	var acceleration := -GRAVITY * gravity_scale
	if flight_enabled and thrust_requested:
		acceleration += FLIGHT_ACCELERATION
	motion.step(previous, position, delta, acceleration, surfaces)
	if motion.elevation < RECOVERY_HEIGHT:
		position = motion.recover()
		velocity = Vector2.ZERO
		recoveries += 1
	_sync_projection()


func _sync_projection() -> void:
	_marker.position.y = -motion.elevation
	queue_redraw()


func _draw() -> void:
	var shadow_height := -INF
	for surface in surfaces:
		var bounds: Rect2 = surface["bounds"]
		var height: float = surface["height"]
		if bounds.has_point(position) and height <= motion.elevation + ElevationMotion.EPSILON:
			shadow_height = maxf(shadow_height, height)
	if not is_finite(shadow_height):
		return
	draw_set_transform(Vector2(0.0, -shadow_height), 0.0, Vector2(1.0, 0.42))
	draw_circle(Vector2.ZERO, FOOT_RADIUS, Color(0.05, 0.04, 0.1, 0.65))
