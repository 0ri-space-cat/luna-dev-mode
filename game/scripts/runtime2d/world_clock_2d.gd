extends RefCounted
## Shared time of day and SLOW / NORMAL / FAST simulation speed.
## Only game-simulation adapters read this factor: UI and real OS time are never
## touched, and recovery cooldowns keep advancing in unscaled real time.
## The rates are engineering placeholders pending author balancing.

signal mode_changed(mode: String)
signal minute_changed(minute: int)

const SLOW := "SLOW"
const NORMAL := "NORMAL"
const FAST := "FAST"
const SCALES := {SLOW: 0.5, NORMAL: 1.0, FAST: 2.0}
const MINUTES_PER_DAY := 24 * 60
const MORNING_MINUTE := 6 * 60
const START_MINUTE := 9 * 60
const EVENING_MINUTE := 18 * 60
const NIGHT_MINUTE := 22 * 60
const MINUTES_PER_SIM_SECOND := 1.0

enum Phase { MORNING, DAY, EVENING, NIGHT }

var mode := NORMAL
var _day_minute: float = float(START_MINUTE)


func set_mode(requested: String) -> bool:
	if not SCALES.has(requested):
		return false
	if mode == requested:
		return true
	mode = requested
	mode_changed.emit(mode)
	return true


func scale() -> float:
	return float(SCALES.get(mode, 1.0))


func sim_delta(unscaled_delta: float) -> float:
	if not is_finite(unscaled_delta) or unscaled_delta < 0.0:
		return 0.0
	return unscaled_delta * scale()


func advance(unscaled_delta: float) -> void:
	var elapsed_minutes := sim_delta(unscaled_delta) * MINUTES_PER_SIM_SECOND
	if is_finite(elapsed_minutes) and elapsed_minutes > 0.0:
		set_time_of_day(fposmod(_day_minute + elapsed_minutes, float(MINUTES_PER_DAY)))


func minute_of_day() -> int:
	return int(_day_minute)


func phase() -> Phase:
	var minute := minute_of_day()
	if minute < MORNING_MINUTE or minute >= NIGHT_MINUTE:
		return Phase.NIGHT
	if minute < START_MINUTE:
		return Phase.MORNING
	if minute < EVENING_MINUTE:
		return Phase.DAY
	return Phase.EVENING


func set_time_of_day(minute: float) -> bool:
	if not is_finite(minute) or minute < 0.0 or minute >= MINUTES_PER_DAY:
		return false
	var previous := minute_of_day()
	_day_minute = minute
	if minute_of_day() != previous:
		minute_changed.emit(minute_of_day())
	return true


static func is_valid_window(start: Variant, end: Variant) -> bool:
	return _is_whole_minute(start) and _is_whole_minute(end) and int(start) != int(end)


static func _is_whole_minute(value: Variant) -> bool:
	if typeof(value) not in [TYPE_INT, TYPE_FLOAT]:
		return false
	var number := float(value)
	return is_finite(number) and number >= 0.0 and number < MINUTES_PER_DAY and floorf(number) == number


## The start is inclusive, the end exclusive. A descending interval crosses midnight.
func is_in_window(start: int, end: int) -> bool:
	if not is_valid_window(start, end):
		return false
	var now := minute_of_day()
	if start < end:
		return now >= start and now < end
	return now >= start or now < end


func snapshot() -> Dictionary:
	return {"mode": mode, "day_minute": _day_minute}


func restore(data: Variant) -> bool:
	if not (data is Dictionary):
		return false
	var requested_mode: Variant = data.get("mode", null)
	if typeof(requested_mode) != TYPE_STRING or not SCALES.has(requested_mode):
		return false
	var saved_minute: Variant = data.get("day_minute", START_MINUTE)
	if typeof(saved_minute) not in [TYPE_INT, TYPE_FLOAT]:
		return false
	var requested_minute := float(saved_minute)
	if not is_finite(requested_minute) or requested_minute < 0.0 or requested_minute >= MINUTES_PER_DAY:
		return false
	var previous_mode := mode
	var previous_minute := minute_of_day()
	mode = str(requested_mode)
	_day_minute = requested_minute
	if mode != previous_mode:
		mode_changed.emit(mode)
	if minute_of_day() != previous_minute:
		minute_changed.emit(minute_of_day())
	return true
