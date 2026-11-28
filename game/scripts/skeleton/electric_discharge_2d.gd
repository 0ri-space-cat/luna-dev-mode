extends Node2D
## One bounded pulse over bodies already present in the local 2D+Z world.

const MaterialProfile = preload("res://scripts/core/material_profile.gd")
const Body = preload("res://scripts/skeleton/entity_body_2d.gd")
const Fauna = preload("res://scripts/skeleton/fauna_body_2d.gd")
const Water = preload("res://scripts/skeleton/water_volume_2d.gd")
const Profile = preload("res://scripts/runtime2d/consumable_profile_2d.gd")
const DRY_SECONDS := 7.0
const WET_SECONDS := 10.0
const MAX_ENTRY_DAMAGE := Profile.ELECTRO_LIMIT * 3
const MAX_TARGETS := 4
const MAX_SPLASHES := 12
const DRY_REACH := 74.0
const WET_REACH := 128.0
const FLASH_SECONDS := 0.34

var home: Node
var _segments: Array[PackedVector2Array] = []
var _splashes: Array[Vector2] = []
var _flash := 0.0


static func is_conductor(body: Body) -> bool:
	return body != null and body.visible and not body.is_queued_for_deletion() \
		and body.record.category in ["prop", "fridge"] and MaterialProfile.is_conductive(body.get_parameter("material"))


func can_start(receiver: Body, water: Water) -> bool:
	return water != null or _compatible(receiver)


func _compatible(body: Body) -> bool:
	return is_conductor(body) or (body != null and body.visible and body.get_parameter("alive") \
		and not body.is_queued_for_deletion() and (body == home.actor or body is Fauna))


func pulse(receiver: Body, point: Vector2, water: Water, power: int) -> void:
	_segments.clear()
	_splashes.clear()
	var address: String = home._entity_location(receiver.position if receiver != null else point)
	var source := _probe(receiver) if receiver != null else Vector3(point.x, point.y, water.surface)
	var first := receiver
	if first == null:
		_add_splash(point - Vector2(0.0, water.surface))
		first = _nearest(source, address, water, {}, true)
	var visited := {}
	for hop in MAX_TARGETS:
		if first == null:
			break
		var destination := _probe(first)
		visited[first.entity_id] = true
		if hop > 0 or receiver == null:
			_add_arc(source, destination)
		else:
			_add_splash(_project(destination))
		var bath := first._current_water()
		_affect(first, bath != null, maxi(1, power - hop * 2))
		source = destination
		first = _nearest(source, address, bath, visited, false)
	_flash = FLASH_SECONDS
	queue_redraw()


func _nearest(source: Vector3, address: String, water: Water, visited: Dictionary, only_in_water: bool) -> Body:
	var best: Body
	var best_distance := INF
	for identity in home.entities.list_ids():
		if visited.has(identity):
			continue
		var body := home.entities.get_entity(identity) as Body
		if not _compatible(body) or home._entity_location(body.position) != address:
			continue
		var shared_water := water != null and body._current_water() == water
		if only_in_water and not shared_water:
			continue
		var point := _probe(body)
		var distance := source.distance_squared_to(point)
		var reach := WET_REACH if shared_water else DRY_REACH
		if distance > reach * reach or distance > best_distance:
			continue
		if best != null and is_equal_approx(distance, best_distance) and identity > best.entity_id:
			continue
		if not _clear_path(source, point):
			continue
		best = body
		best_distance = distance
	return best


func _clear_path(source: Vector3, target: Vector3) -> bool:
	var from := Vector2(source.x, source.y)
	var to := Vector2(target.x, target.y)
	var low := minf(source.z, target.z)
	for wall: Dictionary in home._walls:
		if float(wall["height"]) <= low:
			continue
		var bounds: Rect2 = wall["bounds"]
		if (bounds.has_point(from) and source.z < wall["height"]) or (bounds.has_point(to) and target.z < wall["height"]):
			return false
		var corners := [bounds.position, Vector2(bounds.end.x, bounds.position.y),
			bounds.end, Vector2(bounds.position.x, bounds.end.y)]
		for index in 4:
			var hit: Variant = Geometry2D.segment_intersects_segment(from, to, corners[index], corners[(index + 1) % 4])
			if hit != null:
				var fraction := from.distance_to(hit) / maxf(from.distance_to(to), 0.001)
				if lerpf(source.z, target.z, fraction) < float(wall["height"]):
					return false
	return true


func _affect(body: Body, wet: bool, power: int) -> void:
	if is_conductor(body):
		if body.record.category == "fridge" and not body.get_parameter("alive") \
				and body.life_suspended_remaining <= 0.0:
			home.commands.execute_set(body, "alive", true, home.ENTITY_ID, "alchemy:electro")
		return
	_damage(body, power * (2 if wet else 1))
	var charge := body.electric_charge
	body.electric_charge = {
		"remaining": maxf(float(charge.get("remaining", 0.0)), WET_SECONDS if wet else DRY_SECONDS),
		"entry_damage": maxi(int(charge.get("entry_damage", 0)), power * 3),
		"armed": not wet,
	}


func tick_body(body: Body, delta: float) -> void:
	if delta <= 0.0 or body.electric_charge.is_empty():
		return
	var charge := body.electric_charge
	charge["remaining"] = maxf(0.0, float(charge["remaining"]) - delta)
	if charge["remaining"] <= 0.0 or not body.get_parameter("alive"):
		body.electric_charge = {}
		return
	if charge["entry_damage"] == 0:
		return
	if body._current_water() == null:
		charge["armed"] = true
	elif charge["armed"]:
		_damage(body, charge["entry_damage"])
		charge["entry_damage"] = 0
		charge["armed"] = false
		_add_splash(_project(_probe(body)))
		_flash = FLASH_SECONDS
		queue_redraw()


static func _damage(body: Body, amount: int) -> void:
	var minimum: int = int(body.record.registry.get_spec(body.record.category, "health")["min"])
	body.record.set_parameter("health", maxi(minimum, int(body.get_parameter("health")) - amount))


static func valid_charge(state: Variant) -> bool:
	if not state is Dictionary:
		return false
	if state.is_empty():
		return true
	var time: Variant = state.get("remaining")
	var damage: Variant = state.get("entry_damage")
	var armed: Variant = state.get("armed")
	if state.size() != 3 or typeof(time) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(time)) \
			or float(time) <= 0.0 or float(time) > WET_SECONDS or not armed is bool:
		return false
	if typeof(damage) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(damage)) \
			or float(damage) != floorf(float(damage)) or float(damage) < 0.0 or float(damage) > MAX_ENTRY_DAMAGE:
		return false
	return damage > 0 or not armed


func tick(delta: float) -> void:
	if _flash <= 0.0:
		return
	_flash = maxf(0.0, _flash - delta)
	if _flash == 0.0:
		clear_flash()
	else:
		queue_redraw()


func clear_flash() -> void:
	_flash = 0.0
	_segments.clear()
	_splashes.clear()
	queue_redraw()


func _add_splash(point: Vector2) -> void:
	if _splashes.size() >= MAX_SPLASHES:
		_splashes.pop_front()
	_splashes.append(point)


func _add_arc(from: Vector3, to: Vector3) -> void:
	var start := _project(from)
	var finish := _project(to)
	var edge := (finish - start).normalized().orthogonal()
	_segments.append(PackedVector2Array([start, start.lerp(finish, 0.30) + edge * 5.0,
		start.lerp(finish, 0.57) - edge * 5.0, finish]))


static func _probe(body: Body) -> Vector3:
	return Vector3(body.position.x, body.position.y, body.motion.elevation + body.body_height() * 0.44)


static func _project(point: Vector3) -> Vector2:
	return Vector2(point.x, point.y - point.z)


func _draw() -> void:
	var tint := Color(0.96, 0.89, 0.46, _flash / FLASH_SECONDS)
	for points in _segments:
		draw_polyline(points, tint, 2.0, true)
	for point in _splashes:
		draw_arc(point, 7.0 + (1.0 - tint.a) * 14.0, 0.0, TAU, 24, tint, 2.0, true)
