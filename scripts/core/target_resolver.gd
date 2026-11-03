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
