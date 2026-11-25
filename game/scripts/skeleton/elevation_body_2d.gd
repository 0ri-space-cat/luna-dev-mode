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
const CARRY_MASS_LIMIT := 3.0
const PLACE_REACH := 64.0
const MAX_RIDER_FOOTPRINT_RATIO := 1.5

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
var _footprint: CircleShape2D
var body_size := 1.0
var drive_multiplier := 1.0
var _carrier: SkeletonElevationBody2D
var _rider: SkeletonElevationBody2D
var _carried := false
var _seat_height := 0.0
var _seat_capacity := 0.0
var _protected_seat := false


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = 0
	var footprint := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = foot_radius()
	_footprint = circle
	footprint.shape = circle
	add_child(footprint)
	_marker = Polygon2D.new()
	_marker.color = Color("eed7f8")
	_marker.polygon = PackedVector2Array([
		Vector2(-12, 0), Vector2(-9, -19), Vector2(0, -BODY_HEIGHT),
		Vector2(9, -19), Vector2(12, 0),
	])
	add_child(_marker)
	_marker.scale = Vector2.ONE * body_size
	_sync_projection()


func jump() -> void:
	if motion.grounded and not is_attached():
		motion.add_impulse(JUMP_SPEED * _load_factor())


func configure_dynamics(mass: float, bounciness: float) -> bool:
	if not is_finite(mass) or mass <= 0.0 or not is_finite(bounciness):
		return false
	if bounciness < 0.0 or bounciness > 1.0:
		return false
	if is_attached() and mass > (CARRY_MASS_LIMIT if _carried else _carrier._seat_capacity):
		return false
	_mass = mass
	_bounciness = bounciness
	return true


func apply_impulse(planar: Vector2, vertical: float = 0.0) -> bool:
	if is_attached():
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
	if has_passenger() or not is_finite(height) or not is_finite(capacity):
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
	return is_attached() and not _carried


func is_carried() -> bool:
	return is_attached() and _carried


func is_attached() -> bool:
	return is_instance_valid(_carrier)


func has_rider() -> bool:
	return has_passenger() and not _rider._carried


func has_passenger() -> bool:
	return is_instance_valid(_rider)


func try_board(rider: SkeletonElevationBody2D) -> bool:
	return _try_attach(rider, false)


func try_pick_up(item: SkeletonElevationBody2D) -> bool:
	return _try_attach(item, true)


func _try_attach(rider: SkeletonElevationBody2D, carried: bool) -> bool:
	if not _can_attach(rider, carried) or not is_inside_tree() or not rider.is_inside_tree():
		return false
	if get_parent() != rider.get_parent() or position.distance_to(rider.position) > BOARD_RADIUS:
		return false
	var elevation := motion.elevation + _attachment_height(carried)
	var reach_height := motion.elevation if carried else elevation
	if absf(reach_height - rider.motion.elevation) > BOARD_HEIGHT:
		return false
	if not rider._clear_step(position, minf(rider.motion.elevation, elevation), self):
		return false
	_attach(rider, carried)
	return true


func restore_rider(rider: SkeletonElevationBody2D, carried: bool = false) -> bool:
	if not _can_attach(rider, carried) or not position.is_equal_approx(rider.position):
		return false
	if not is_equal_approx(rider.motion.elevation, motion.elevation + _attachment_height(carried)):
		return false
	if rider.motion.grounded or not is_equal_approx(rider.motion.vertical_speed, motion.vertical_speed):
		return false
	_attach(rider, carried)
	return true


func try_dismount() -> bool:
	return is_riding() and _try_release()


func try_drop() -> bool:
	return has_passenger() and _rider.is_carried() and _rider._try_release()


## The caller supplies a surface already supported by the surrounding geometry.
func try_place_carried(point: Vector2, floor: float) -> bool:
	if not has_passenger() or not _rider.is_carried() or not motion.grounded:
		return false
	if not point.is_finite() or not is_finite(floor) or point.distance_to(position) > PLACE_REACH \
			or absf(motion.elevation - floor) > MAX_SAFE_DROP:
		return false
	var item := _rider
	if not item._clear_step(point, floor) or not item._release_is_clear(point, floor, item.motion.elevation):
		return false
	item._detach_from_carrier()
	item.position = point
	item.motion.elevation = floor
	item.motion.grounded = true
	item.motion.vertical_speed = 0.0
	item._sync_projection()
	return true


func _try_release() -> bool:
	var feet := motion.elevation
	var release_height := _carrier.motion.elevation if _carried else feet
	var distance := maxf(DISMOUNT_DISTANCE, foot_radius() + _carrier.foot_radius() + 2.0)
	for direction_to_exit in [Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT, Vector2.UP]:
		var point: Vector2 = position + direction_to_exit * distance
		var floor := _dry_landing_height(point, release_height)
		if not is_finite(floor) or not _clear_step(point, floor) or not _release_is_clear(point, floor, feet):
			continue
		_detach_from_carrier()
		_place_on_dismount(point, floor, feet)
		return true
	return false


func _detach_from_carrier() -> void:
	_carrier._rider = null
	if not _carried:
		_carrier.direction = Vector2.ZERO
		_carrier.thrust_requested = false
		_carrier.swim_intent = 0.0
	_carrier = null
	_carried = false


func _release_is_clear(_point: Vector2, _floor: float, _feet: float) -> bool:
	return true


func _place_on_dismount(point: Vector2, floor: float, feet: float) -> void:
	position = point
	motion.reset_on_surface(point, floor)
	if feet > floor + ElevationMotion.EPSILON:
		motion.elevation = feet
		motion.grounded = false
	if _marker != null:
		_sync_projection()


func _clear_step(target: Vector2, feet: float, destination_body: SkeletonElevationBody2D = null) -> bool:
	var original_mask := collision_mask
	_update_wall_mask(feet)
	var exclude_destination := destination_body != null and destination_body not in get_collision_exceptions()
	if exclude_destination:
		add_collision_exception_with(destination_body)
	var blocked := test_move(global_transform, target - position)
	if exclude_destination:
		remove_collision_exception_with(destination_body)
	collision_mask = original_mask
	return not blocked


func _dry_landing_height(point: Vector2, feet: float) -> float:
	var highest := -INF
	for surface in surfaces:
		var height: float = surface["height"]
		var bounds: Rect2 = surface["bounds"]
		if not surface.get("safe", true) or not bounds.grow(-motion.safe_margin).has_point(point):
			continue
		if height > feet + ElevationMotion.EPSILON or feet - height > MAX_SAFE_DROP:
			continue
		if _is_dry(point, height):
			highest = maxf(highest, height)
	return highest


func _is_dry(point: Vector2, feet: float) -> bool:
	for volume in water_volumes:
		if volume.submerged_fraction(point, feet, body_height()) > 0.0:
			return false
	return true


func _allows_ride() -> bool:
	return _seat_capacity > 0.0


func _allows_pickup() -> bool:
	return false


func _attachment_height(carried: bool) -> float:
	return body_height() if carried else _seat_height * body_size


func _can_attach(rider: SkeletonElevationBody2D, carried: bool) -> bool:
	if not is_instance_valid(rider) or rider == self or has_passenger() or is_attached():
		return false
	if rider.is_attached() or rider.has_passenger():
		return false
	if carried:
		if not rider._allows_pickup() or rider._mass > CARRY_MASS_LIMIT or rider.foot_radius() > foot_radius():
			return false
	elif not _allows_ride() or rider._mass > _seat_capacity \
			or rider.foot_radius() > foot_radius() * MAX_RIDER_FOOTPRINT_RATIO:
		return false
	return _attachment_space_is_safe(rider, carried)


func _attach(rider: SkeletonElevationBody2D, carried: bool) -> void:
	_rider = rider
	rider._carrier = self
	rider._carried = carried
	rider.direction = Vector2.ZERO
	rider.thrust_requested = false
	rider.swim_intent = 0.0
	rider._impulse_velocity = Vector2.ZERO
	_update_rider_position()


func _attachment_space_is_safe(rider: SkeletonElevationBody2D, carried: bool) -> bool:
	var feet := motion.elevation + _attachment_height(carried)
	if not rider.fits_walls_at(position, feet, rider.foot_radius()):
		return false
	if carried or _protected_seat:
		return true
	var head := feet + rider.body_height()
	for volume in water_volumes:
		if volume.bounds.has_point(position) and head <= volume.surface:
			return false
	return true


func _update_rider_position() -> void:
	if not has_passenger():
		return
	_rider.position = position
	_rider.motion.elevation = motion.elevation + _attachment_height(_rider._carried)
	_rider.motion.vertical_speed = motion.vertical_speed
	_rider.motion.grounded = false
	if _rider._marker != null:
		_rider._sync_projection()


func _exit_tree() -> void:
	if has_passenger():
		_rider._carrier = null
		_rider._carried = false
		_rider._recover_after_carrier_loss()
		_rider = null
	if is_attached():
		_carrier._rider = null
		_carrier = null
		_carried = false


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
	return _mass + _rider._mass if has_passenger() else _mass


func _load_factor() -> float:
	return _mass / _total_mass()


func _physics_process(delta: float) -> void:
	if is_attached():
		return
	var position_before := position
	var motion_before := motion.snapshot() if has_passenger() else {}
	var total_mass := _total_mass()
	var load_factor := _load_factor()
	var drive_speed := WALK_SPEED
	var acceleration := -GRAVITY * gravity_scale
	var water := _current_water()
	if water == null and flight_enabled and thrust_requested:
		acceleration += FLIGHT_ACCELERATION * load_factor

	if water != null:
		var fraction := water.submerged_fraction(position, motion.elevation, body_height())
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

	_move_with_contacts(direction.limit_length() * drive_speed * load_factor * drive_multiplier, delta, acceleration)
	if has_passenger() and (not _rider._clear_step(position, _rider.motion.elevation) \
			or not _attachment_space_is_safe(_rider, _rider._carried)):
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
		var fraction := volume.submerged_fraction(position, motion.elevation, body_height())
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
	draw_circle(Vector2.ZERO, foot_radius(), Color(0.05, 0.04, 0.1, 0.65))


func foot_radius() -> float:
	return FOOT_RADIUS * body_size


func body_height() -> float:
	return BODY_HEIGHT * body_size


func fits_walls_at(point: Vector2, elevation: float, radius: float) -> bool:
	for wall in walls:
		if elevation >= float(wall["height"]):
			continue
		var bounds: Rect2 = wall["bounds"]
		var closest := point.clamp(bounds.position, bounds.end)
		if point.distance_to(closest) < radius - 0.01:
			return false
	return true


func _apply_body_size(value: float) -> void:
	body_size = value
	motion.safe_margin = 14.0 * value
	if _footprint != null:
		_footprint.radius = foot_radius()
	if _marker != null:
		_marker.scale = Vector2.ONE * value
		queue_redraw()
