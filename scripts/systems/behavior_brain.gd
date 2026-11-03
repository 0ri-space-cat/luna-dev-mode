extends RefCounted
## Reusable steering for any AI-capable Entity. It doesn't know about trees,
## fridges, models, or Godot physics nodes. Physics is the caller's concern.
##
## Behaviour modes: IDLE, WANDER, FOLLOW, CHASE, FLEE, AUTO.
## AUTO translates the current attitude toward Luna into an action.

const WANDER_MIN := 0.45
const WANDER_MAX := 1.15
const TURN_RATE := 3.4
const EDGE_MARGIN := 7.8

var rng := RandomNumberGenerator.new()
var heading := Vector3.FORWARD
var _wanted := Vector3.FORWARD
var _turn_timer := 0.0
var _pause_timer := 0.0
var _last_mode := ""
var last_decision := "IDLE"
var last_target_id := ""


func _init(seed_value: int = 0) -> void:
	if seed_value == 0:
		rng.randomize()
	else:
		rng.seed = seed_value


func calculate(delta: float, position: Vector3, properties: Dictionary, targets: Array[Dictionary]) -> Vector3:
	if not bool(properties.get("alive", false)) or not bool(properties.get("ai_enabled", false)):
		last_decision = "IDLE"
		last_target_id = ""
		return Vector3.ZERO

	var mode: String = str(properties.get("behavior_mode", "WANDER"))
	if mode == "AUTO":
		match str(properties.get("luna_relation", "NEUTRAL")):
			"FRIEND":
				mode = "FOLLOW"
			"HOSTILE":
				mode = "CHASE"
			"AFRAID":
				mode = "FLEE"
			_:
				mode = "WANDER"
	if mode != _last_mode:
		_last_mode = mode
		_turn_timer = 0.0
		_pause_timer = 0.0
	if mode == "IDLE":
		last_decision = "IDLE"
		last_target_id = ""
		return Vector3.ZERO

	var wanted := Vector3.ZERO
	var effective_mode := mode
	var follow_distance := float(properties.get("follow_distance", 1.8))
	var nearest: Dictionary = _nearest(position, targets)
	last_target_id = str(nearest.get("id", ""))

	match mode:
		"FOLLOW", "CHASE", "FLEE":
			if nearest.is_empty():
				effective_mode = "WANDER"
			else:
				var offset: Vector3 = nearest["position"] - position
				offset.y = 0.0
				var distance := offset.length()
				if mode == "FLEE":
					if distance > follow_distance * 2.0:
						effective_mode = "IDLE"
					elif distance > 0.001:
						wanted = -offset.normalized()
				elif (mode == "FOLLOW" and distance > follow_distance) or (mode == "CHASE" and distance > 0.95):
					wanted = offset.normalized()
				else:
					effective_mode = "IDLE"

	if effective_mode == "WANDER":
		wanted = _wander(delta, position)
	if effective_mode == "IDLE":
		last_decision = "IDLE"
		return Vector3.ZERO

	wanted.y = 0.0
	if wanted.length_squared() < 0.001:
		last_decision = "IDLE"
		return Vector3.ZERO

	# Pushing inward is continuous. An entity won't move in axis-aligned
	# rectangles at the world edge as the old prototype did.
	var center_pull := Vector3.ZERO
	if absf(position.x) > EDGE_MARGIN:
		center_pull.x = -signf(position.x)
	if absf(position.z) > EDGE_MARGIN:
		center_pull.z = -signf(position.z)
	if center_pull.length_squared() > 0.01:
		wanted = (wanted + center_pull.normalized() * 2.0).normalized()
	heading = _smooth_turn(heading, wanted, minf(delta * TURN_RATE, 1.0))
	last_decision = effective_mode
	return heading * float(properties.get("speed", 2.0))


func turn_away_from_wall(normal: Vector3) -> void:
	# Turn along the surface instead of stopping when a fridge hits a tree.
	var horizontal := Vector3(normal.x, 0.0, normal.z)
	if horizontal.length_squared() > 0.01:
		heading = (heading + horizontal.normalized() * 1.1).normalized()
		_wanted = heading
		_turn_timer = rng.randf_range(0.2, 0.55)


func _wander(delta: float, position: Vector3) -> Vector3:
	if _pause_timer > 0.0:
		_pause_timer = maxf(0.0, _pause_timer - delta)
		return Vector3.ZERO
	_turn_timer -= delta
	if _turn_timer <= 0.0:
		_turn_timer = rng.randf_range(WANDER_MIN, WANDER_MAX)
		if rng.randf() < 0.10:
			_pause_timer = rng.randf_range(0.12, 0.38)
			return Vector3.ZERO
		var angle := rng.randf_range(-0.86, 0.86)
		_wanted = heading.rotated(Vector3.UP, angle).normalized()
		if position.length() > EDGE_MARGIN:
			_wanted = (_wanted + Vector3(-position.x, 0, -position.z).normalized() * 0.8).normalized()
	return _wanted


func _smooth_turn(current: Vector3, desired: Vector3, weight: float) -> Vector3:
	if current.length_squared() < 0.001:
		return desired.normalized()
	var turned := current.lerp(desired, weight)
	if turned.length_squared() < 0.001:
		return desired.normalized()
	return turned.normalized()


func _nearest(origin: Vector3, targets: Array[Dictionary]) -> Dictionary:
	var best: Dictionary = {}
	var best_distance := INF
	for item in targets:
		var candidate: Vector3 = item["position"]
		var sq := origin.distance_squared_to(candidate)
		if sq < best_distance:
			best_distance = sq
			best = item
	return best
