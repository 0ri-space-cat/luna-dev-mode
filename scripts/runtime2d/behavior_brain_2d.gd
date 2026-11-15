extends RefCounted
## Bounded, data-driven 2D motion brain. Authored static collision is planned
## by GridNavigation2D; actual actor collisions stay in CharacterBody2D.
## No species, geography, scripted NPC routes or secret placements live here.

const PIXELS_PER_UNIT := 80.0
const REPLAN_INTERVAL := 0.35
const GOAL_REPLAN_DISTANCE := 24.0
const WAYPOINT_REACHED := 10.0
const FLEE_DISTANCE := 160.0

var _wander_timer := 0.0
var _wander_direction := Vector2.RIGHT
var _route := PackedVector2Array()
var _route_cursor := 0
var _route_timer := 0.0
var _route_target := Vector2.ZERO
var _route_mode := ""
var _route_revision := -1
var _route_flying := false
var _route_swimming := false
var _route_navigation

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
	if mode == "FLEE":
		if difference.length() >= distance_px * 0.9:
			return Vector2.ZERO
		# A fleeing actor must NOT run 10 A* searches every physics frame.
		# Keep the chosen escape destination until it is reached or a replanning
		# interval, navigation revision or movement ability requires an update.
		var nav: Variant = actor.get("navigation")
		var destination: Vector2 = _route_target
		var recalculate: bool = _route_timer <= 0.0 			or _route_mode != "FLEE" or nav != _route_navigation 			or (nav != null and nav.revision != _route_revision) 			or destination.distance_squared_to(actor.global_position) < 20.0 * 20.0
		if recalculate:
			destination = _flee_goal(actor, -difference.normalized())
		return _navigated_direction(actor, destination, mode, delta)
	return _navigated_direction(actor, target_position, mode, delta)


func avoid_obstacle() -> void:
	# Collision with actors may require a new plan even when the target did not
	# move. Static barriers are handled by the grid on the next recalculation.
	_route_timer = 0.0
	_wander_direction = _wander_direction.rotated(2.27)
	_wander_timer = 1.7


func _navigated_direction(actor: CharacterBody2D, goal: Vector2, mode: String,
		delta: float) -> Vector2:
	var navigation: Variant = actor.get("navigation")
	if navigation == null:
		_route = PackedVector2Array()
		return (goal - actor.global_position).normalized()

	var can_fly: bool = actor.has_ability("FLY")
	var can_swim: bool = actor.has_ability("SWIM")
	_route_timer -= maxf(delta, 0.0)
	var should_replan: bool = (
		_route_timer <= 0.0
		or navigation != _route_navigation
		or navigation.revision != _route_revision
		or mode != _route_mode
		or can_fly != _route_flying
		or can_swim != _route_swimming
		or goal.distance_squared_to(_route_target) > GOAL_REPLAN_DISTANCE * GOAL_REPLAN_DISTANCE
	)
	if should_replan:
		_route = navigation.get_path(actor.global_position, goal, can_fly, can_swim)
		_route_cursor = 0
		_route_timer = REPLAN_INTERVAL
		_route_target = goal
		_route_mode = mode
		_route_navigation = navigation
		_route_revision = navigation.revision
		_route_flying = can_fly
		_route_swimming = can_swim
	if _route.is_empty():
		# Never try walking straight through an authored solid if no path exists.
		return Vector2.ZERO
	while _route_cursor < _route.size() and actor.global_position.distance_to(
			_route[_route_cursor]) <= WAYPOINT_REACHED:
		_route_cursor += 1
	if _route_cursor >= _route.size():
		return Vector2.ZERO
	return (_route[_route_cursor] - actor.global_position).normalized()


func _flee_goal(actor: CharacterBody2D, away: Vector2) -> Vector2:
	var navigation: Variant = actor.get("navigation")
	if navigation == null:
		return actor.global_position + away * FLEE_DISTANCE
	# Search a handful of alternative headings around blocking geometry.
	# Queries are bounded and only use the actor's real FLY/ground mobility.
	for angle in [0.0, PI / 4.0, -PI / 4.0, PI / 2.0, -PI / 2.0]:
		for travel in [FLEE_DISTANCE, FLEE_DISTANCE * 0.5]:
			var destination: Vector2 = actor.global_position + away.rotated(angle) * travel
			if navigation.is_walkable(destination, actor.has_ability("FLY"), actor.has_ability("SWIM")):
				if not navigation.get_path(actor.global_position, destination,
						actor.has_ability("FLY"), actor.has_ability("SWIM")).is_empty():
					return destination
	return actor.global_position


func _wander(delta: float) -> Vector2:
	_wander_timer -= delta
	if _wander_timer <= 0.0:
		_wander_timer = 1.7
		_wander_direction = _wander_direction.rotated(1.27)
	return _wander_direction
