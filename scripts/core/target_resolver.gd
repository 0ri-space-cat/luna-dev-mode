extends RefCounted
## Shared spatial selection: spells, explosions, auras and future AI rules.
## The world registry remains authoritative. Only editable entities are affected.

const MAX_TARGETS := 8
const MAX_RADIUS := 6.0


static func around(world, primary_id: String, radius: float) -> Array[String]:
	var selected: Array[String] = []
	var primary: Node = world.get_entity(primary_id)
	if not (primary is Node3D) or not primary.has_method("get_parameter"):
		return selected
	if is_nan(radius) or is_inf(radius) or radius < 0.0 or radius > MAX_RADIUS:
		return selected
	selected.append(primary_id)
	if radius <= 0.0:
		return selected
	var center: Vector3 = (primary as Node3D).global_position
	var possibilities: Array[Dictionary] = world.candidates(
		primary_id, center, "ANY", radius
	)
	possibilities.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var distance_a: float = center.distance_squared_to(a["position"])
		var distance_b: float = center.distance_squared_to(b["position"])
		if is_equal_approx(distance_a, distance_b):
			return str(a["id"]) < str(b["id"])
		return distance_a < distance_b
	)
	for candidate in possibilities:
		var entity_id: String = str(candidate["id"])
		var entity: Node = world.get_entity(entity_id)
		if entity == null or not entity.has_method("get_parameter"):
			continue
		if selected.has(entity_id):
			continue
		selected.append(entity_id)
		if selected.size() >= MAX_TARGETS:
			break
	return selected



static func chain(world, primary_id: String, radius: float, max_jumps: int) -> Array[String]:
	## Each hop seeks the nearest not-yet-hit living entity from its OWN origin.
	## The primary target can be inert; subsequent links require IS_ALIVE.
	var result: Array[String] = []
	var origin: Node = world.get_entity(primary_id)
	if not (origin is Node3D) or not origin.has_method("get_parameter"):
		return result
	if is_nan(radius) or is_inf(radius) or radius <= 0.0 or radius > MAX_RADIUS:
		return result
	if max_jumps < 0 or max_jumps > 4:
		return result
	result.append(primary_id)
	var visited := {primary_id: true}
	var current_id := primary_id
	for _step in range(max_jumps):
		var current: Node = world.get_entity(current_id)
		if not (current is Node3D):
			break
		var where: Vector3 = (current as Node3D).global_position
		var candidates: Array[Dictionary] = world.candidates(current_id, where, "ANY", radius)
		var closest_id := ""
		var closest_distance := INF
		for option in candidates:
			var target_id: String = str(option["id"])
			if visited.has(target_id):
				continue
			var target: Node = world.get_entity(target_id)
			if target == null or not target.has_method("get_parameter"):
				continue
			if target.call("get_parameter", "alive") != true:
				continue
			var distance: float = where.distance_squared_to(option["position"])
			if distance < closest_distance - 0.00001 or (is_equal_approx(distance, closest_distance) and (closest_id.is_empty() or target_id < closest_id)):
				closest_id = target_id
				closest_distance = distance
		if closest_id.is_empty():
			break
		result.append(closest_id)
		visited[closest_id] = true
		current_id = closest_id
	return result
