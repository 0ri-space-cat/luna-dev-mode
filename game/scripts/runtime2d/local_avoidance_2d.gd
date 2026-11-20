extends RefCounted
## Bounded local steering for autonomous moving Entity bodies.
## The shared A* plans around static map geometry; this adapter reacts to
## physically present actors without changing collision layers or teleporting.
##
## Coarse separation is symmetrical for head-on movement: both agents steer
## to their local right so their world-space detours separate naturally.

const LOOKAHEAD_RADIUS := 56.0
const TARGET_STOP_DISTANCE := 25.0
const SIDE_HYSTERESIS := 0.36
const MAX_NEIGHBORS := 24

var last_obstacle_id := ""
var last_side := 1.0
var _side_timer := 0.0


func adjust(actor: Node2D, registry, desired: Vector2, target_id: String,
		delta: float) -> Vector2:
	if desired.length_squared() < 0.0001 or registry == null or actor == null:
		_reset_if_idle(delta)
		return Vector2.ZERO
	var heading: Vector2 = desired.normalized()
	var near: Array[Dictionary] = registry.candidates_2d(
		str(actor.record.id), actor.global_position, "ANY", LOOKAHEAD_RADIUS,
		str(actor.location_id), MAX_NEIGHBORS)
	var selected := ""
	var selected_offset := Vector2.ZERO
	var selected_distance_sq := LOOKAHEAD_RADIUS * LOOKAHEAD_RADIUS
	for item in near:
		var offset: Vector2 = item["position"] - actor.global_position
		var distance_sq: float = offset.length_squared()
		if str(item["id"]) == target_id:
			if distance_sq <= TARGET_STOP_DISTANCE * TARGET_STOP_DISTANCE:
				# Stop at contact instead of jittering through a chase target.
				return Vector2.ZERO
			continue
		if heading.dot(offset) <= 0.0 or distance_sq < 0.0001:
			continue
		if distance_sq < selected_distance_sq:
			selected = str(item["id"])
			selected_offset = offset
			selected_distance_sq = distance_sq
	_side_timer = maxf(0.0, _side_timer - maxf(delta, 0.0))
	if selected.is_empty():
		_reset_if_idle(delta)
		return heading
	if selected != last_obstacle_id or _side_timer <= 0.0:
		var cross: float = heading.cross(selected_offset.normalized())
		# Strongly off-axis agents pass on the unobstructed side; centered
		# encounters share a deterministic right-hand convention.
		if absf(cross) > 0.25:
			last_side = -signf(cross)
		else:
			last_side = 1.0
		last_obstacle_id = selected
		_side_timer = SIDE_HYSTERESIS
	var distance: float = sqrt(selected_distance_sq)
	var pressure: float = clampf(
		(LOOKAHEAD_RADIUS - distance) / LOOKAHEAD_RADIUS * 1.5, 0.15, 0.95)
	var tangent := Vector2(-heading.y, heading.x) * last_side
	return (heading * (1.0 - pressure * 0.4) + tangent * pressure * 1.75).normalized()


func reset() -> void:
	last_obstacle_id = ""
	last_side = 1.0
	_side_timer = 0.0


func _reset_if_idle(delta: float) -> void:
	_side_timer = maxf(0.0, _side_timer - maxf(delta, 0.0))
	if _side_timer <= 0.0:
		reset()
