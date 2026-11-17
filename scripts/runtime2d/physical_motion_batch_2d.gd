extends RefCounted
## Single-snapshot physics checks for simultaneous movement of a bounded set
## of actors. All members exclude one another during sweep, while *real*
## walls, observation solids and nonmembers remain physical obstacles.
##
## Godot's physics server does not synchronously propagate a Node2D position
## update to subsequent move_and_collide calls in the same physics tick.
## Querying a group from its ORIGINAL transforms before moving any members
## avoids false self-collisions and permits exact atomic Undo/Redo.
const MAX_MEMBERS := 4
const MAX_DISTANCE := 64.0


static func safe_common_motion(bodies: Array[CharacterBody2D], motion: Vector2) -> Vector2:
	if bodies.is_empty() or bodies.size() > MAX_MEMBERS or not _finite_motion(motion) \
			or motion.length_squared() < 0.25 or motion.length() > MAX_DISTANCE:
		return Vector2.ZERO
	var fraction := 1.0
	for body in bodies:
		if not is_instance_valid(body) or body.collision_layer & 2 == 0:
			return Vector2.ZERO
		var params: PhysicsTestMotionParameters2D = _query_for(body, bodies, motion)
		var result := PhysicsTestMotionResult2D.new()
		if PhysicsServer2D.body_test_motion(body.get_rid(), params, result):
			fraction = minf(fraction, clampf(result.get_collision_safe_fraction(), 0.0, 1.0))
		if fraction <= 0.001:
			return Vector2.ZERO
	# Stay just shy of the impact margin so exact later replay is stable.
	var safe_distance: float = motion.length() * fraction
	if fraction < 1.0:
		safe_distance = maxf(0.0, safe_distance - 0.08)
	if safe_distance < 0.5:
		return Vector2.ZERO
	return motion.normalized() * safe_distance


static func paths_are_clear(bodies: Array[CharacterBody2D],
		destinations: Array[Vector2]) -> bool:
	if bodies.is_empty() or bodies.size() > MAX_MEMBERS \
			or destinations.size() != bodies.size():
		return false
	for i in range(bodies.size()):
		var body: CharacterBody2D = bodies[i]
		var goal: Vector2 = destinations[i]
		if not is_instance_valid(body) or body.collision_layer & 2 == 0 \
				or not _valid_point(goal):
			return false
		var motion: Vector2 = goal - body.global_position
		if not _finite_motion(motion) or motion.length() > MAX_DISTANCE + 0.5:
			return false
		if motion.length_squared() < 0.001:
			continue
		var params: PhysicsTestMotionParameters2D = _query_for(body, bodies, motion)
		var result := PhysicsTestMotionResult2D.new()
		if PhysicsServer2D.body_test_motion(body.get_rid(), params, result):
			if result.get_collision_safe_fraction() * motion.length() < motion.length() - 0.2:
				return false
	return true


static func _query_for(body: CharacterBody2D, bodies: Array[CharacterBody2D],
		motion: Vector2) -> PhysicsTestMotionParameters2D:
	var params := PhysicsTestMotionParameters2D.new()
	params.from = body.global_transform
	params.motion = motion
	var excluded: Array[RID] = []
	for peer in bodies:
		if peer != body:
			excluded.append(peer.get_rid())
	params.exclude_bodies = excluded
	return params


static func _finite_motion(motion: Vector2) -> bool:
	return is_finite(motion.x) and is_finite(motion.y)


static func _valid_point(point: Vector2) -> bool:
	return _finite_motion(point) and absf(point.x) <= 100000.0 \
		and absf(point.y) <= 100000.0
