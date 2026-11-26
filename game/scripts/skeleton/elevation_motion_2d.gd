extends RefCounted
## Vertical motion for a body whose horizontal position belongs to physics.
## Supports are one-way top surfaces described in world coordinates.

const EPSILON := 0.00001
const REST_SPEED := 22.0
const MAX_STEP_RISE := 6.0

var elevation := 0.0
var vertical_speed := 0.0
var grounded := false
var safe_margin := 14.0
var _safe_position := Vector2.ZERO
var _safe_elevation := 0.0


func reset_on_surface(point: Vector2, height: float) -> void:
	elevation = height
	vertical_speed = 0.0
	grounded = true
	_safe_position = point
	_safe_elevation = height


func start_on_safe_support(point: Vector2, height: float, surfaces: Array[Dictionary]) -> bool:
	if not _has_support(point, height, surfaces, true):
		return false
	reset_on_surface(point, height)
	return true


func add_impulse(speed_delta: float) -> void:
	if grounded and speed_delta <= 0.0:
		return
	vertical_speed += speed_delta
	if vertical_speed > 0.0:
		grounded = false


func step(from: Vector2, to: Vector2, delta: float, acceleration: float,
		surfaces: Array[Dictionary], bounciness: float = 0.0) -> void:
	if delta <= EPSILON:
		return
	if acceleration > 0.0 and grounded:
		grounded = false
	var start := from
	var remaining := delta
	while remaining > EPSILON:
		if grounded:
			var next_tread := _entered_tread_height(start, to, surfaces)
			if next_tread > elevation:
				elevation = next_tread
				_update_anchor(to, surfaces)
				return
			var end_on_support := _support_exit(start, to, surfaces)
			if end_on_support >= 1.0:
				_update_anchor(to, surfaces)
				return
			start = start.lerp(to, end_on_support)
			remaining *= 1.0 - end_on_support
			grounded = false
		var landing_time := remaining + EPSILON
		var landing_height := elevation
		for surface in surfaces:
			var height: float = surface["height"]
			var impact := _descending_impact(height, acceleration)
			if impact < 0.0 or impact >= landing_time:
				continue
			var position_at_impact := start.lerp(to, clampf(impact / remaining, 0.0, 1.0))
			var bounds: Rect2 = surface["bounds"]
			if not bounds.has_point(position_at_impact):
				continue
			# Leaving a platform at time zero must not land on its departing edge.
			if impact <= EPSILON and not bounds.has_point(to):
				continue
			landing_time = impact
			landing_height = height
		if landing_time > remaining:
			elevation += vertical_speed * remaining + 0.5 * acceleration * remaining * remaining
			vertical_speed += acceleration * remaining
			return
		var impact_speed := -(vertical_speed + acceleration * landing_time)
		start = start.lerp(to, landing_time / remaining)
		remaining -= landing_time
		elevation = landing_height
		var rebound := impact_speed * bounciness
		if rebound >= REST_SPEED:
			vertical_speed = rebound
		else:
			vertical_speed = 0.0
			grounded = true
			_update_anchor(start, surfaces)


func recover() -> Vector2:
	reset_on_surface(_safe_position, _safe_elevation)
	return _safe_position


func snapshot() -> Dictionary:
	return {
		"elevation": elevation, "vertical_speed": vertical_speed, "grounded": grounded,
		"anchor": [_safe_position.x, _safe_position.y, _safe_elevation],
	}


func load_snapshot(data: Dictionary, position: Vector2, surfaces: Array[Dictionary],
		minimum_height: float) -> bool:
	var height: Variant = data.get("elevation")
	var speed: Variant = data.get("vertical_speed")
	var on_support: Variant = data.get("grounded")
	var anchor: Variant = data.get("anchor")
	if not _is_finite_number(height) or not _is_finite_number(speed) or not on_support is bool:
		return false
	if float(height) < minimum_height or absf(float(height)) > 100000.0 \
			or absf(float(speed)) > 100000.0 or not anchor is Array or anchor.size() != 3:
		return false
	for coordinate in anchor:
		if not _is_finite_number(coordinate):
			return false
	var safe_position := Vector2(float(anchor[0]), float(anchor[1]))
	var safe_elevation := float(anchor[2])
	if not _has_support(safe_position, safe_elevation, surfaces, true):
		return false
	if on_support and (not is_zero_approx(float(speed))
			or not _has_support(position, float(height), surfaces, false)):
		return false
	_safe_position = safe_position
	_safe_elevation = safe_elevation
	elevation = float(height)
	vertical_speed = float(speed)
	grounded = on_support
	return true


func _descending_impact(height: float, acceleration: float) -> float:
	if absf(acceleration) < EPSILON:
		return (height - elevation) / vertical_speed if vertical_speed < 0.0 else -1.0
	var discriminant := vertical_speed * vertical_speed + 2.0 * acceleration * (height - elevation)
	if discriminant < 0.0:
		return -1.0
	var descending_speed := sqrt(discriminant)
	if acceleration > 0.0 and descending_speed <= EPSILON:
		return -1.0
	return (-vertical_speed - descending_speed) / acceleration


func _entered_tread_height(from: Vector2, to: Vector2, surfaces: Array[Dictionary]) -> float:
	var result := elevation
	for surface in surfaces:
		if not surface.get("walk_up", false):
			continue
		var height: float = surface["height"]
		var bounds: Rect2 = surface["bounds"]
		if height > result and height <= elevation + MAX_STEP_RISE and bounds.has_point(to) \
				and not bounds.has_point(from):
			result = height
	return result


func _support_exit(from: Vector2, to: Vector2, surfaces: Array[Dictionary]) -> float:
	# Walk across a continuous union of same-height floors in either direction.
	if not _has_support(from, elevation, surfaces, false):
		return 0.0
	var delta := to - from
	var intervals: Array[Vector2] = []
	for surface in surfaces:
		if not is_equal_approx(float(surface["height"]), elevation):
			continue
		var bounds: Rect2 = surface["bounds"]
		var interval := _support_interval(from, delta, bounds)
		if interval.x <= interval.y:
			intervals.append(interval)
	intervals.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
	var covered := 0.0
	for interval in intervals:
		if interval.x > covered + EPSILON:
			break
		covered = maxf(covered, interval.y)
		if covered >= 1.0:
			return 1.0
	return covered


func _support_interval(from: Vector2, delta: Vector2, bounds: Rect2) -> Vector2:
	var entry := 0.0
	var exit := 1.0
	for axis in range(2):
		var origin: float = from[axis]
		var travel: float = delta[axis]
		var low: float = bounds.position[axis]
		var high: float = bounds.end[axis]
		if high <= low:
			return Vector2(1.0, 0.0)
		if absf(travel) <= EPSILON:
			if origin < low or origin >= high:
				return Vector2(1.0, 0.0)
			continue
		var first := (low - origin) / travel
		var last := (high - origin) / travel
		entry = maxf(entry, minf(first, last))
		exit = minf(exit, maxf(first, last))
		if entry > exit:
			return Vector2(1.0, 0.0)
	return Vector2(entry, exit)


func _update_anchor(point: Vector2, surfaces: Array[Dictionary]) -> void:
	if _has_support(point, elevation, surfaces, true):
		_safe_position = point
		_safe_elevation = elevation


func _has_support(point: Vector2, height: float, surfaces: Array[Dictionary],
		require_safe_anchor: bool) -> bool:
	for surface in surfaces:
		var bounds: Rect2 = surface["bounds"]
		if require_safe_anchor:
			if not surface.get("safe", true):
				continue
			# Narrow ledges remain walkable but cannot be a safe recovery anchor.
			if bounds.size.x <= safe_margin * 2.0 or bounds.size.y <= safe_margin * 2.0:
				continue
			bounds = bounds.grow(-safe_margin)
		if bounds.has_point(point) and is_equal_approx(float(surface["height"]), height):
			return true
	return false


func _is_finite_number(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value))
