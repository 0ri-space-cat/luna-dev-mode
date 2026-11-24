class_name SkeletonElevationBody2D
extends CharacterBody2D
## Skeleton adapter. CharacterBody2D owns XY; the elevation model owns Z.
## The fixture uses a separate layer per height volume, with walkable tops.

const ElevationMotion = preload("res://scripts/skeleton/elevation_motion_2d.gd")
const WaterVolume = preload("res://scripts/skeleton/water_volume_2d.gd")
const GRAVITY := 620.0
const JUMP_SPEED := 295.0
const FLIGHT_ACCELERATION := 940.0
const WALK_SPEED := 175.0
const SWIM_SPEED := 120.0
const SWIM_ACCELERATION := 1000.0
const BODY_HEIGHT := 27.0
const MAX_WATER_LIFT := 12000.0
const FOOT_RADIUS := 11.0
const RECOVERY_HEIGHT := -96.0
const GROUND_DRAG := 3.0
const AIR_DRAG := 0.35
const MAX_IMPULSE_SPEED := 100000.0
const MAX_CONTACTS := 4
const BOARD_RADIUS := 30.0
const BOARD_HEIGHT := 26.0
const DISMOUNT_DISTANCE := 28.0
const MAX_SAFE_DROP := 30.0

var motion := ElevationMotion.new()
var surfaces: Array[Dictionary] = []
var walls: Array[Dictionary] = []
var water_volumes: Array[WaterVolume] = []
var direction := Vector2.ZERO
var gravity_scale := 1.0
var flight_enabled := false
var thrust_requested := false
var swim_intent := 0.0
var recoveries := 0
var entity_id := ""
var emergency_anchor := Vector3.ZERO
var _mass := 1.0
var _buoyancy := 0.0
var _swim_enabled := false
var _bounciness := 0.0
var _impulse_velocity := Vector2.ZERO
var _marker: Polygon2D
var _carrier: SkeletonElevationBody2D
var _rider: SkeletonElevationBody2D
var _seat_height := 0.0
var _seat_capacity := 0.0
var _protected_seat := false


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
		Vector2(-12, 0), Vector2(-9, -19), Vector2(0, -BODY_HEIGHT),
		Vector2(9, -19), Vector2(12, 0),
	])
	add_child(_marker)
	_sync_projection()


func jump() -> void:
	if motion.grounded and not is_riding():
		motion.add_impulse(JUMP_SPEED * _load_factor())


func configure_dynamics(mass: float, bounciness: float) -> bool:
	if not is_finite(mass) or mass <= 0.0 or not is_finite(bounciness):
		return false
	if bounciness < 0.0 or bounciness > 1.0:
		return false
	if is_riding() and mass > _carrier._seat_capacity:
		return false
	_mass = mass
	_bounciness = bounciness
	return true


func apply_impulse(planar: Vector2, vertical: float = 0.0) -> bool:
	if is_riding():
		return _carrier.apply_impulse(planar, vertical)
	var total_mass := _total_mass()
	var planar_delta := Vector2(planar.x / total_mass, planar.y / total_mass)
	var planar_speed := _impulse_velocity + planar_delta
	var speed_delta_z := vertical / total_mass
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


func configure_water(buoyancy: float, swim_enabled: bool) -> bool:
	if not is_finite(buoyancy) or buoyancy < 0.0:
		return false
	_buoyancy = buoyancy
	_swim_enabled = swim_enabled
	return true


func water_snapshot() -> Dictionary:
	return {"buoyancy": _buoyancy, "swim_enabled": _swim_enabled}


func load_water(data: Dictionary) -> bool:
	var buoyancy: Variant = data.get("buoyancy")
	var swim_enabled: Variant = data.get("swim_enabled")
	if typeof(buoyancy) not in [TYPE_INT, TYPE_FLOAT] or not swim_enabled is bool:
		return false
	return configure_water(float(buoyancy), swim_enabled)


func configure_seat(height: float, capacity: float, protected: bool) -> bool:
	if is_instance_valid(_rider) or not is_finite(height) or not is_finite(capacity):
		return false
	if height <= 0.0 or capacity <= 0.0:
		return false
	_seat_height = height
	_seat_capacity = capacity
	_protected_seat = protected
	return true


func seat_snapshot() -> Dictionary:
	return {"height": _seat_height, "capacity": _seat_capacity, "protected": _protected_seat}


func load_seat(data: Dictionary) -> bool:
	var height: Variant = data.get("height")
	var capacity: Variant = data.get("capacity")
	var protected: Variant = data.get("protected")
	if typeof(height) not in [TYPE_INT, TYPE_FLOAT] or typeof(capacity) not in [TYPE_INT, TYPE_FLOAT]:
		return false
	if not protected is bool:
		return false
	return configure_seat(float(height), float(capacity), protected)


func is_riding() -> bool:
	return is_instance_valid(_carrier)


func has_rider() -> bool:
	return is_instance_valid(_rider)


func try_board(rider: SkeletonElevationBody2D) -> bool:
	if not _can_attach(rider) or not is_inside_tree() or not rider.is_inside_tree():
		return false
	if get_parent() != rider.get_parent() or position.distance_to(rider.position) > BOARD_RADIUS:
		return false
	if absf(motion.elevation + _seat_height - rider.motion.elevation) > BOARD_HEIGHT:
		return false
	if not rider._clear_step(position, minf(rider.motion.elevation, motion.elevation + _seat_height)):
		return false
	_attach(rider)
	return true


func restore_rider(rider: SkeletonElevationBody2D) -> bool:
	if not _can_attach(rider) or not position.is_equal_approx(rider.position):
		return false
	if not is_equal_approx(rider.motion.elevation, motion.elevation + _seat_height):
		return false
	if rider.motion.grounded or not is_equal_approx(rider.motion.vertical_speed, motion.vertical_speed):
		return false
	_attach(rider)
	return true


func try_dismount() -> bool:
	if not is_riding():
		return false
	var feet := motion.elevation
	for direction_to_exit in [Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT, Vector2.UP]:
		var point: Vector2 = position + direction_to_exit * DISMOUNT_DISTANCE
		var floor := _dry_landing_height(point, feet)
		if not is_finite(floor) or not _clear_step(point, floor):
			continue
		_carrier._rider = null
		_carrier.direction = Vector2.ZERO
		_carrier.thrust_requested = false
		_carrier.swim_intent = 0.0
		_carrier = null
		_place_on_dismount(point, floor, feet)
		return true
	return false


func _place_on_dismount(point: Vector2, floor: float, feet: float) -> void:
	position = point
	motion.reset_on_surface(point, floor)
	if feet > floor + ElevationMotion.EPSILON:
		motion.elevation = feet
		motion.grounded = false
	if _marker != null:
		_sync_projection()


func _clear_step(target: Vector2, feet: float) -> bool:
	var original_mask := collision_mask
	_update_wall_mask(feet)
	var blocked := test_move(global_transform, target - position)
	collision_mask = original_mask
	return not blocked


func _dry_landing_height(point: Vector2, feet: float) -> float:
	var highest := -INF
	for surface in surfaces:
		var height: float = surface["height"]
		var bounds: Rect2 = surface["bounds"]
		if not surface.get("safe", true) or not bounds.grow(-FOOT_RADIUS).has_point(point):
			continue
		if height > feet + ElevationMotion.EPSILON or feet - height > MAX_SAFE_DROP:
			continue
		if _is_dry(point, height):
			highest = maxf(highest, height)
	return highest


func _is_dry(point: Vector2, feet: float) -> bool:
	for volume in water_volumes:
		if volume.submerged_fraction(point, feet, BODY_HEIGHT) > 0.0:
			return false
	return true


func _can_attach(rider: SkeletonElevationBody2D) -> bool:
	if not is_instance_valid(rider) or rider == self or has_rider() or is_riding():
		return false
	if rider.is_riding() or rider.has_rider() or rider._mass > _seat_capacity:
		return false
	return _seat_is_safe()


func _attach(rider: SkeletonElevationBody2D) -> void:
	_rider = rider
	rider._carrier = self
	rider.direction = Vector2.ZERO
	rider.thrust_requested = false
	rider.swim_intent = 0.0
	rider._impulse_velocity = Vector2.ZERO
	_update_rider_position()


func _seat_is_safe() -> bool:
	if _protected_seat:
		return true
	var head := motion.elevation + _seat_height + BODY_HEIGHT
	for volume in water_volumes:
		if volume.bounds.has_point(position) and head <= volume.surface:
			return false
	return true


func _update_rider_position() -> void:
	if not has_rider():
		return
	_rider.position = position
	_rider.motion.elevation = motion.elevation + _seat_height
	_rider.motion.vertical_speed = motion.vertical_speed
	_rider.motion.grounded = false
	if _rider._marker != null:
		_rider._sync_projection()


func _exit_tree() -> void:
	if has_rider():
		_rider._carrier = null
		_rider._recover_after_carrier_loss()
		_rider = null
	if is_riding():
		_carrier._rider = null
		_carrier = null


func _recover_after_carrier_loss() -> void:
	position = motion.recover()
	if not _is_dry(position, motion.elevation):
		position = Vector2(emergency_anchor.x, emergency_anchor.y)
		motion.reset_on_surface(position, emergency_anchor.z)
	_impulse_velocity = Vector2.ZERO
	velocity = Vector2.ZERO
	recoveries += 1
	if _marker != null:
		_sync_projection()


func _total_mass() -> float:
	return _mass + _rider._mass if has_rider() else _mass


func _load_factor() -> float:
	return _mass / _total_mass()


func _physics_process(delta: float) -> void:
	if is_riding():
		return
	var open_seat := has_rider() and not _protected_seat
	var position_before := position
	var motion_before := motion.snapshot() if open_seat else {}
	var total_mass := _total_mass()
	var load_factor := _load_factor()
	var drive_speed := WALK_SPEED
	var acceleration := -GRAVITY * gravity_scale
	var water := _current_water()
	if water == null and flight_enabled and thrust_requested:
		acceleration += FLIGHT_ACCELERATION * load_factor

	if water != null:
		var fraction := water.submerged_fraction(position, motion.elevation, BODY_HEIGHT)
		var drag_fraction := 1.0 - exp(-water.resistance * fraction * delta / total_mass)
		_impulse_velocity = _impulse_velocity.lerp(water.flow, drag_fraction)
		acceleration += minf(GRAVITY * (_buoyancy * fraction / total_mass), MAX_WATER_LIFT)
		acceleration -= motion.vertical_speed * drag_fraction / delta
		if _swim_enabled:
			drive_speed = lerpf(WALK_SPEED, SWIM_SPEED, fraction)
			acceleration += clampf(swim_intent, -1.0, 1.0) * SWIM_ACCELERATION * load_factor
		else:
			# Shallow feet can wade. A floating body has no swimming stroke.
			drive_speed = lerpf(WALK_SPEED, 0.0, minf(fraction / 0.35, 1.0))

	_move_with_contacts(direction.limit_length() * drive_speed * load_factor, delta, acceleration)
	if open_seat and not _seat_is_safe():
		position = position_before
		motion.load_snapshot(motion_before, position, surfaces, RECOVERY_HEIGHT)
		motion.vertical_speed = 0.0
		_impulse_velocity = Vector2.ZERO
		velocity = Vector2.ZERO
	if motion.elevation < RECOVERY_HEIGHT:
		position = motion.recover()
		_impulse_velocity = Vector2.ZERO
		velocity = Vector2.ZERO
		recoveries += 1
	elif water == null:
		var drag := GROUND_DRAG if motion.grounded else AIR_DRAG
		_impulse_velocity *= exp(-drag * delta)
	_update_rider_position()
	_sync_projection()


func _current_water() -> WaterVolume:
	var selected: WaterVolume
	var greatest_fraction := 0.0
	for volume in water_volumes:
		var fraction := volume.submerged_fraction(position, motion.elevation, BODY_HEIGHT)
		if fraction > greatest_fraction:
			selected = volume
			greatest_fraction = fraction
	return selected


func _move_with_contacts(drive: Vector2, delta: float, acceleration: float) -> void:
	var remaining := delta
	for contact in range(MAX_CONTACTS):
		velocity = drive + _impulse_velocity
		var displacement := velocity * remaining
		if displacement.length_squared() <= ElevationMotion.EPSILON * ElevationMotion.EPSILON:
			break
		_update_wall_mask(motion.elevation)
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


func _update_wall_mask(feet: float) -> void:
	collision_mask = 0
	for wall in walls:
		if feet < float(wall["height"]) - ElevationMotion.EPSILON:
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
