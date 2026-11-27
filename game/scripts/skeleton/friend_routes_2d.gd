extends RefCounted
## Work-in-progress ordinary NPC schedules. Same Entity moves through existing
## public transport and door thresholds. Coordinates are graybox tuning only.
const TOFFI_MEADOW := Vector2(1820, 405)
const MEADOW_GATE := Vector2(1940, 620)
const CITY_GATE := Vector2(4560, 480)
const SHOP_GATE := Vector2(5135, 660)
const SHOP_INSIDE := Vector2(5965, 685)
const SHOP_TALK := Vector2(6010, 645)
const PLAZA_TURN := Vector2(5150, 480)
const MEADOW_PATH := [TOFFI_MEADOW, Vector2(1890, 430), Vector2(1910, 590), MEADOW_GATE]
const CITY_PATH := [CITY_GATE, Vector2(4745, 480), Vector2(5000, 480), PLAZA_TURN, Vector2(5135, 620), SHOP_GATE]
const SHOP_PATH := [SHOP_INSIDE, Vector2(5965, 645), SHOP_TALK]
const SECRET_PATH := [PLAZA_TURN, Vector2(5150, 320), Vector2(5150, 240), Vector2(5150, 145), Vector2(5095, 145)]
const LEIA_PATH := [Vector2(2058, -28), Vector2(2058, -65), Vector2(1900, -65), Vector2(1885, -145), Vector2(1885, -260)]


static func toffi_meadow_time(minute: int) -> bool:
	return minute < 12 * 60 or minute >= 18 * 60


## Recover route progress from the actual body position, including after save/load.
## Never snap a hacked or displaced body across the map to rejoin the schedule.
static func next_point(point: Vector2, path: Array, forward: bool) -> Vector2:
	var end: Vector2 = path[-1] if forward else path[0]
	if point.distance_to(end) < 6.0:
		return Vector2.INF
	var best_distance := INF
	var best_index := 0
	for index in range(path.size() - 1):
		var start: Vector2 = path[index]
		var finish: Vector2 = path[index + 1]
		var nearest := Geometry2D.get_closest_point_to_segment(point, start, finish)
		var distance := point.distance_squared_to(nearest)
		if distance < best_distance:
			best_distance = distance
			best_index = index
	if best_distance > 95.0 * 95.0:
		return Vector2.INF
	var target_index := best_index + 1 if forward else best_index
	var target: Vector2 = path[target_index]
	if point.distance_to(target) < 6.0:
		target_index += 1 if forward else -1
		if target_index < 0 or target_index >= path.size():
			return Vector2.INF
		target = path[target_index]
	return target
