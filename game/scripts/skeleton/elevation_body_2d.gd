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
const GROUND_DRAG := 3.0
const AIR_DRAG := 0.35
const MAX_IMPULSE_SPEED := 100000.0
const MAX_CONTACTS := 4

var motion := ElevationMotion.new()
var surfaces: Array[Dictionary] = []
var walls: Array[Dictionary] = []
var direction := Vector2.ZERO
var gravity_scale := 1.0
var flight_enabled := false
var thrust_requested := false
var recoveries := 0
var entity_id := ""
var _mass := 1.0
var _bounciness := 0.0
var _impulse_velocity := Vector2.ZERO
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


func configure_dynamics(mass: float, bounciness: float) -> bool:
	if not is_finite(mass) or mass <= 0.0 or not is_finite(bounciness):
		return false
	if bounciness < 0.0 or bounciness > 1.0:
		return false
	_mass = mass
	_bounciness = bounciness
	return true


func apply_impulse(planar: Vector2, vertical: float = 0.0) -> bool:
	var planar_delta := Vector2(planar.x / _mass, planar.y / _mass)
	var planar_speed := _impulse_velocity + planar_delta
	var speed_delta_z := vertical / _mass
	if not _valid_impulse_velocity(planar_speed) or not is_finite(speed_delta_z):
		return false
	if absf(motion.vertical_speed + speed_delta_z) > MAX_IMPULSE_SPEED:
		return false
	_impulse_velocity = planar_speed
	motion.add_impulse(speed_delta_z)
	return true


func dynamics_snapshot() -> Dictionary:
	return {
		"mass": _mass, "bounciness": _bounciness,
		"impulse_velocity": [_impulse_velocity.x, _impulse_velocity.y],
	}


func load_dynamics(data: Dictionary) -> bool:
	var mass: Variant = data.get("mass")
	var bounciness: Variant = data.get("bounciness")
	var planar: Variant = data.get("impulse_velocity")
	if not planar is Array or planar.size() != 2:
		return false
	for number in [mass, bounciness, planar[0], planar[1]]:
		if typeof(number) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(number)):
			return false
	var impulse_velocity := Vector2(float(planar[0]), float(planar[1]))
	if not _valid_impulse_velocity(impulse_velocity):
		return false
	if not configure_dynamics(float(mass), float(bounciness)):
		return false
	_impulse_velocity = impulse_velocity
	return true


func _valid_impulse_velocity(candidate: Vector2) -> bool:
	return candidate.is_finite() and candidate.length_squared() <= MAX_IMPULSE_SPEED * MAX_IMPULSE_SPEED


func _physics_process(delta: float) -> void:
	var drive := direction.limit_length() * WALK_SPEED
	var acceleration := -GRAVITY * gravity_scale
	if flight_enabled and thrust_requested:
		acceleration += FLIGHT_ACCELERATION
	_move_with_contacts(drive, delta, acceleration)
	if motion.elevation < RECOVERY_HEIGHT:
		position = motion.recover()
		_impulse_velocity = Vector2.ZERO
		velocity = Vector2.ZERO
		recoveries += 1
	else:
		var drag := GROUND_DRAG if motion.grounded else AIR_DRAG
		_impulse_velocity *= exp(-drag * delta)
	_sync_projection()


func _move_with_contacts(drive: Vector2, delta: float, acceleration: float) -> void:
	var remaining := delta
	for contact in range(MAX_CONTACTS):
		velocity = drive + _impulse_velocity
		var displacement := velocity * remaining
		if displacement.length_squared() <= ElevationMotion.EPSILON * ElevationMotion.EPSILON:
			break
		_update_wall_mask()
		var previous := position
		var hit := move_and_collide(displacement)
		if hit == null:
			motion.step(previous, position, remaining, acceleration, surfaces, _bounciness)
			return
		var fraction_left := clampf(hit.get_remainder().length() / displacement.length(), 0.0, 1.0)
		var after_impact := remaining * fraction_left
		motion.step(previous, position, remaining - after_impact, acceleration, surfaces, _bounciness)
		remaining = after_impact

		var normal := hit.get_normal()
		var incoming := -velocity.dot(normal)
		if incoming <= ElevationMotion.EPSILON:
			break
		var rebound := incoming * _bounciness
		if rebound < ElevationMotion.REST_SPEED:
			rebound = 0.0
		drive = drive.slide(normal)
		_impulse_velocity = (_impulse_velocity.slide(normal) + normal * rebound).limit_length(MAX_IMPULSE_SPEED)
	motion.step(position, position, remaining, acceleration, surfaces, _bounciness)


func _update_wall_mask() -> void:
	collision_mask = 0
	for wall in walls:
		if motion.elevation < float(wall["height"]) - ElevationMotion.EPSILON:
			collision_mask |= int(wall["layer"])


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
