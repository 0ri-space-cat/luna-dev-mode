extends RefCounted
## Shared spatial selection: spells, explosions, auras and future AI rules.
## The world registry remains authoritative. Only editable entities are affected.

const MaterialProfile = preload("res://scripts/core/material_profile.gd")

const MAX_TARGETS := 8
const MAX_RADIUS := 6.0
const MAX_SELECTOR_RADIUS := 12.0
const VALID_ATTITUDES := ["FRIEND", "HOSTILE", "AFRAID", "NEUTRAL"]
const SELECTOR_FIELDS := [
	"radius", "max_targets", "category", "role", "tag", "alive",
	"attitude", "relation_direction", "include_origin"
]


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
		var hop_radius: float = radius
		if current.has_method("get_parameter") and MaterialProfile.is_conductive(str(current.call("get_parameter", "material"))):
			hop_radius = minf(radius + 1.0, MAX_RADIUS)
		var candidates: Array[Dictionary] = world.candidates(current_id, where, "ANY", hop_radius)
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


## All selector queries use stable entity IDs. Returned IDs are sorted by
## distance, then lexically by ID, not by insertion/scene traversal order.
## This selector is intentionally JSON-friendly for saved rules and spells.
static func validate_selector(raw: Variant) -> bool:
	if typeof(raw) != TYPE_DICTIONARY:
		return false
	var selector: Dictionary = raw
	if selector.is_empty():
		return false
	for key in selector.keys():
		if str(key) not in SELECTOR_FIELDS:
			return false
	var distance: Variant = selector.get("radius")
	if typeof(distance) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(distance)):
		return false
	if float(distance) < 0.5 or float(distance) > MAX_SELECTOR_RADIUS:
		return false
	var limit: Variant = selector.get("max_targets", 4)
	if typeof(limit) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(limit)):
		return false
	if float(limit) != float(int(limit)) or int(limit) < 1 or int(limit) > MAX_TARGETS:
		return false
	for key in ["category", "role", "tag"]:
		if selector.has(key):
			if typeof(selector[key]) != TYPE_STRING or not str(selector[key]).is_valid_identifier() or str(selector[key]).length() > 40:
				return false
			if key != "category" and str(selector[key]) != str(selector[key]).to_upper():
				return false
	for key in ["alive", "include_origin"]:
		if selector.has(key) and typeof(selector[key]) != TYPE_BOOL:
			return false
	if selector.has("attitude") and (typeof(selector["attitude"]) != TYPE_STRING or str(selector["attitude"]) not in VALID_ATTITUDES):
		return false
	if selector.has("relation_direction"):
		if not selector.has("attitude") or str(selector["relation_direction"]) not in ["FROM_ORIGIN", "TO_ORIGIN"]:
			return false
	return true


static func select_by_properties(world, origin_id: String, selector: Dictionary,
		relationships = null) -> Array[String]:
	var selected: Array[String] = []
	if not validate_selector(selector):
		return selected
	var origin: Node = world.get_entity(origin_id)
	if not (origin is Node3D):
		return selected
	if selector.has("attitude") and relationships == null:
		return selected
	var location: Vector3 = (origin as Node3D).global_position
	var max_dist: float = float(selector["radius"]) * float(selector["radius"])
	var matches: Array[Dictionary] = []
	for entity_id in world.list_ids():
		if entity_id == origin_id and not bool(selector.get("include_origin", false)):
			continue
		var target: Node = world.get_entity(entity_id)
		if not (target is Node3D) or not target.has_method("get_parameter"):
			continue
		var record: Variant = target.get("record")
		if record == null:
			continue
		if record.has_component("PICKUP") and not str(record.get_component("PICKUP").get("holder_id", "")).is_empty():
			continue # Hidden carried objects are absent from spatial targeting.
		if selector.has("category") and str(record.category) != str(selector["category"]):
			continue
		if selector.has("role") and not record.has_role(str(selector["role"])):
			continue
		if selector.has("tag") and not record.has_tag(str(selector["tag"])):
			continue
		if selector.has("alive") and bool(target.call("get_parameter", "alive")) != bool(selector["alive"]):
			continue
		if selector.has("attitude"):
			if entity_id == origin_id:
				continue # Self-relations are not meaningful.
			var from_id: String = origin_id
			var to_id: String = entity_id
			if str(selector.get("relation_direction", "FROM_ORIGIN")) == "TO_ORIGIN":
				from_id = entity_id
				to_id = origin_id
			if relationships.get_attitude(from_id, to_id) != str(selector["attitude"]):
				continue
		var squared: float = location.distance_squared_to((target as Node3D).global_position)
		if squared > max_dist:
			continue
		matches.append({"id": entity_id, "distance": squared})
	matches.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var d_a: float = float(a["distance"])
		var d_b: float = float(b["distance"])
		if is_equal_approx(d_a, d_b):
			return str(a["id"]) < str(b["id"])
		return d_a < d_b
	)
	for entry in matches:
		selected.append(str(entry["id"]))
		if selected.size() >= int(selector.get("max_targets", 4)):
			break
	return selected
