extends RefCounted
## State shared by the temporary doorway and bounded optional encounters.

const MIN_WAIT := 5.0
const MAX_WAIT := 9.0
const MIN_OPENINGS := 3
const MAX_OPENINGS := 6

var return_wait := 0.0
var return_delay := MIN_WAIT
var station_ghost := ""
var house_source: Variant = null
var door_open := false
var door_openings := 0
var glow_after := MIN_OPENINGS
var buffer_from_house := false
var _random := RandomNumberGenerator.new()


func _init() -> void:
	_random.randomize()


func begin_void_visit() -> void:
	return_wait = 0.0
	return_delay = _random.randf_range(MIN_WAIT, MAX_WAIT)


func advance_void(delta: float) -> void:
	return_wait = minf(return_wait + delta, return_delay)


func ghost_waiting() -> bool:
	return return_wait >= return_delay


func begin_natural_door() -> void:
	door_open = false
	door_openings = 0
	glow_after = _random.randi_range(MIN_OPENINGS, MAX_OPENINGS)


func door_glowing() -> bool:
	return door_open and door_openings == glow_after


func toggle_natural_door() -> void:
	if door_glowing():
		begin_natural_door()
	elif door_open:
		door_open = false
	else:
		door_open = true
		door_openings += 1


func snapshot() -> Dictionary:
	var origin := []
	if house_source is Vector2:
		origin = [house_source.x, house_source.y]
	return {
		"return_wait": return_wait, "return_delay": return_delay,
		"station_ghost": station_ghost, "house_source": origin,
		"door_open": door_open, "door_openings": door_openings, "glow_after": glow_after,
		"buffer_from_house": buffer_from_house,
	}


func restore(data: Variant) -> bool:
	if not data is Dictionary \
			or not _number_in_range(data.get("return_delay"), MIN_WAIT, MAX_WAIT) \
			or not _number_in_range(data.get("return_wait"), 0.0, data["return_delay"]) \
			or not _whole_in_range(data.get("glow_after"), MIN_OPENINGS, MAX_OPENINGS) \
			or not _whole_in_range(data.get("door_openings"), 0, int(data["glow_after"])) \
			or not data.get("house_source") is Array or not data.get("station_ghost") is String \
			or not data.get("door_open") is bool or not data.get("buffer_from_house") is bool:
		return false
	var origin: Array = data["house_source"]
	var opened := int(data["door_openings"])
	var threshold := int(data["glow_after"])
	if not origin.is_empty() and (origin.size() != 2 \
			or not _number_in_range(origin[0], 0.0, 1280.0) \
			or not _number_in_range(origin[1], 0.0, 800.0)):
		return false
	if (data["door_open"] and opened == 0) or (not data["door_open"] and opened == threshold) \
			or (not origin.is_empty() and opened > 0):
		return false
	return_wait = data["return_wait"]
	return_delay = data["return_delay"]
	station_ghost = data["station_ghost"]
	house_source = null if origin.is_empty() else Vector2(origin[0], origin[1])
	door_open = data["door_open"]
	door_openings = opened
	glow_after = threshold
	buffer_from_house = data["buffer_from_house"]
	return true


func _whole_in_range(value: Variant, minimum: int, maximum: int) -> bool:
	return _number_in_range(value, minimum, maximum) and float(value) == floorf(float(value))


func _number_in_range(value: Variant, minimum: float, maximum: float) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) \
		and float(value) >= minimum and float(value) <= maximum
