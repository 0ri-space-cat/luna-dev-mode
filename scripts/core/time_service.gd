extends RefCounted
## Engine-independent world clock and bounded state history.
## Snapshots are plain data supplied by the caller; this service never retains Nodes.

signal clock_changed(clock: Dictionary)
signal snapshot_recorded(index: int)
signal rewind_completed(index: int)
signal recovery_required(reason: String)

const MAX_SNAPSHOTS := 240
const MAX_SNAPSHOT_BYTES := 1_048_576
const MAX_HISTORY_BYTES := 8_388_608
const MAX_DATA_DEPTH := 32
const MAX_DELTA := 0.25
const MAX_WORLD_SCALE := 4.0

enum RuntimeState { READY, ERROR }

var snapshot_limit := 120
var world_time_scale := 1.0
var world_seconds := 0.0
var control_seconds := 0.0
var runtime_state := RuntimeState.READY
var last_error := ""
var _snapshots: Array[Dictionary] = []
var _capture: Callable
var _validate: Callable
var _restore: Callable
var _record_elapsed := 0.0
var _snapshot_interval := 0.5
var _history_bytes := 0


func configure(capture: Callable, validate: Callable, restore: Callable,
		interval_seconds: float = 0.5, history_limit: int = 120) -> bool:
	if not capture.is_valid() or not validate.is_valid() or not restore.is_valid():
		return false
	if not is_finite(interval_seconds) or interval_seconds < 0.05 or interval_seconds > 60.0:
		return false
	if history_limit < 2 or history_limit > MAX_SNAPSHOTS:
		return false
	_snapshots.clear()
	_history_bytes = 0
	_record_elapsed = 0.0
	world_seconds = 0.0
	control_seconds = 0.0
	runtime_state = RuntimeState.READY
	last_error = ""
	_capture = capture
	_validate = validate
	_restore = restore
	_snapshot_interval = interval_seconds
	snapshot_limit = history_limit
	return true


func set_world_time_scale(value: float) -> bool:
	if not is_finite(value) or value < 0.0 or value > MAX_WORLD_SCALE:
		return false
	world_time_scale = value
	clock_changed.emit(clock_state())
	return true


func advance(real_delta: float) -> Dictionary:
	if not is_finite(real_delta) or real_delta < 0.0:
		return {"ok": false, "error": "Invalid control delta"}
	var control_delta := minf(real_delta, MAX_DELTA)
	control_seconds += control_delta
	var world_delta := 0.0
	if runtime_state == RuntimeState.READY:
		world_delta = control_delta * world_time_scale
		world_seconds += world_delta
		_record_elapsed += world_delta
		if _record_elapsed >= _snapshot_interval and _capture.is_valid():
			_record_elapsed = fposmod(_record_elapsed, _snapshot_interval)
			capture_checkpoint()
	clock_changed.emit(clock_state())
	return {"ok": true, "control_delta": control_delta, "world_delta": world_delta,
		"world_seconds": world_seconds, "control_seconds": control_seconds}


func capture_checkpoint() -> bool:
	if not _capture.is_valid() or not _validate.is_valid():
		return _fail("Timeline is not configured")
	var captured: Variant = _capture.call()
	if typeof(captured) != TYPE_DICTIONARY or not _plain_data(captured, 0) or not bool(_validate.call(captured.duplicate(true))):
		return _fail("World snapshot failed validation")
	var data: Dictionary = captured.duplicate(true)
	var bytes := JSON.stringify(data).to_utf8_buffer().size()
	if bytes > MAX_SNAPSHOT_BYTES:
		return _fail("World snapshot exceeds memory limit")
	var entry := {"world_seconds": world_seconds, "state": data, "bytes": bytes}
	if not _snapshots.is_empty() and is_equal_approx(float(_snapshots.back()["world_seconds"]), world_seconds):
		_history_bytes -= int(_snapshots.back()["bytes"])
		_snapshots[_snapshots.size() - 1] = entry
	else:
		_snapshots.append(entry)
	_history_bytes += bytes
	while _snapshots.size() > snapshot_limit or _history_bytes > MAX_HISTORY_BYTES:
		_history_bytes -= int(_snapshots.pop_front()["bytes"])
	snapshot_recorded.emit(_snapshots.size() - 1)
	return true


func rewind_to_latest() -> bool:
	return rewind_to(_snapshots.size() - 1) if not _snapshots.is_empty() else false


func rewind_steps(steps: int = 1) -> bool:
	if steps < 1 or _snapshots.size() < 2 or steps >= _snapshots.size():
		return _fail("No earlier checkpoint is available")
	return rewind_to(_snapshots.size() - 1 - steps)


func rewind_to(index: int) -> bool:
	if index < 0 or index >= _snapshots.size() or not _restore.is_valid():
		return _fail("Checkpoint index is invalid")
	var target: Dictionary = _snapshots[index]
	var state: Dictionary = target["state"].duplicate(true)
	if not bool(_validate.call(state)):
		return _fail("Checkpoint failed validation")
	if not bool(_restore.call(state)):
		return _fail("Checkpoint restore failed; recovery is required")
	world_seconds = float(target["world_seconds"])
	while _snapshots.size() > index + 1:
		_history_bytes -= int(_snapshots.pop_back()["bytes"])
	_record_elapsed = 0.0
	runtime_state = RuntimeState.READY
	last_error = ""
	rewind_completed.emit(index)
	clock_changed.emit(clock_state())
	return true


func recover_to_latest_checkpoint() -> bool:
	if _snapshots.is_empty():
		return _fail("No recovery checkpoint is available")
	var latest: Dictionary = _snapshots.back()
	if not bool(_validate.call(latest["state"].duplicate(true))) or not bool(_restore.call(latest["state"].duplicate(true))):
		return _fail("Recovery checkpoint could not be restored")
	world_seconds = float(latest["world_seconds"])
	_record_elapsed = 0.0
	runtime_state = RuntimeState.READY
	last_error = ""
	clock_changed.emit(clock_state())
	return true


func clock_state() -> Dictionary:
	return {"world_seconds": world_seconds, "control_seconds": control_seconds,
		"world_time_scale": world_time_scale, "state": runtime_state}


func checkpoint_count() -> int:
	return _snapshots.size()


func _fail(reason: String) -> bool:
	last_error = reason
	runtime_state = RuntimeState.ERROR
	recovery_required.emit(reason)
	return false


func _plain_data(value: Variant, depth: int) -> bool:
	if depth > MAX_DATA_DEPTH:
		return false
	match typeof(value):
		TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_STRING:
			return true
		TYPE_FLOAT:
			return is_finite(value)
		TYPE_ARRAY:
			for item in value:
				if not _plain_data(item, depth + 1):
					return false
			return true
		TYPE_DICTIONARY:
			for key in value:
				if typeof(key) != TYPE_STRING or not _plain_data(value[key], depth + 1):
					return false
			return true
	return false
