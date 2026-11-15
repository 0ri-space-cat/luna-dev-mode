extends RefCounted
## Shared, scene-independent motion brain for approved editable behavior fields.
## No hand-authored NPC character, route, quest, or species is encoded here.
## WorldRegistry is the source of truth for nearby targets and active rooms.

const PIXELS_PER_UNIT := 80.0

var _wander_timer := 0.0
var _wander_direction := Vector2.RIGHT
var last_target_id := ""
var last_resolved_mode := "IDLE"


func direction_for(actor: CharacterBody2D, registry, delta: float) -> Vector2:
	last_target_id = ""
	last_resolved_mode = "IDLE"
	if registry == null or actor.record == null:
		return Vector2.ZERO
	var mode := str(actor.get_parameter("behavior_mode"))
	if mode == "AUTO":
		match str(actor.get_parameter("luna_relation")):
			"FRIEND": mode = "FOLLOW"
			"HOSTILE": mode = "CHASE"
			"AFRAID": mode = "FLEE"
			_: mode = "WANDER"
	last_resolved_mode = mode
	if mode == "IDLE":
		return Vector2.ZERO
	if mode == "WANDER":
		return _wander(delta)
	if mode not in ["FOLLOW", "CHASE", "FLEE"]:
		return Vector2.ZERO

	var distance_px: float = float(actor.get_parameter("sense_range")) * PIXELS_PER_UNIT
	var target_group := str(actor.get_parameter("target_group"))
	var options: Array[Dictionary] = registry.candidates_2d(
		str(actor.record.id), actor.global_position, target_group,
		distance_px, actor.location_id, 24)
	var winner := ""
	var nearest_sq := INF
	var target_position := Vector2.ZERO
	for entry in options:
		var d: float = actor.global_position.distance_squared_to(entry["position"])
		if d < nearest_sq:
			nearest_sq = d
			winner = str(entry["id"])
			target_position = entry["position"]
	if winner.is_empty():
		return Vector2.ZERO
	last_target_id = winner
	var difference: Vector2 = target_position - actor.global_position
	if difference.length_squared() < 0.01:
		return Vector2.ZERO
	var following_gap: float = float(actor.get_parameter("follow_distance")) * PIXELS_PER_UNIT
	if mode == "FOLLOW" and difference.length() <= following_gap:
		return Vector2.ZERO
	if mode == "FLEE" and difference.length() >= distance_px * 0.9:
		return Vector2.ZERO
	return -difference.normalized() if mode == "FLEE" else difference.normalized()


func avoid_obstacle() -> void:
	_wander_direction = _wander_direction.rotated(2.27)
	_wander_timer = 1.7


func _wander(delta: float) -> Vector2:
	_wander_timer -= delta
	if _wander_timer <= 0.0:
		_wander_timer = 1.7
		_wander_direction = _wander_direction.rotated(1.27)
	return _wander_direction
