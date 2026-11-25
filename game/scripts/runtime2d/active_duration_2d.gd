extends RefCounted
## Countdown in active gameplay seconds. Clock jumps and pauses do not tick it.

signal active_changed(active: bool)

var _limit: float
var _remaining := 0.0

var remaining: float:
	get:
		return _remaining


func _init(limit: float) -> void:
	_limit = limit


func start() -> void:
	restore(_limit)


func tick(active_delta: float) -> void:
	if _remaining > 0.0 and is_finite(active_delta) and active_delta > 0.0:
		restore(maxf(0.0, _remaining - active_delta))


func restore(seconds: Variant) -> bool:
	if typeof(seconds) not in [TYPE_INT, TYPE_FLOAT]:
		return false
	var next := float(seconds)
	if not is_finite(next) or next < 0.0 or next > _limit:
		return false
	var was_active := _remaining > 0.0
	_remaining = next
	if was_active != (_remaining > 0.0):
		active_changed.emit(_remaining > 0.0)
	return true
