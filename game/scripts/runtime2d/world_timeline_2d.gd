extends RefCounted
## Bounded, data-only state history for safe recovery and future time mechanics.
## Never stores Nodes, script objects, images, or OS/desktop state.
## This is a technical service, not a complete Time Button artifact.

const SAMPLE_INTERVAL := 1.0
const MAX_SAMPLES := 64
const MAX_REWIND_SECONDS := 60.0
const SAFETY_COOLDOWN := 30.0 # Temporary engine safety tuning, not canonical.

var elapsed := 0.0
var cooldown_remaining := 0.0
var _since_sample := 0.0
var _samples: Array[Dictionary] = []


func tick(delta: float) -> bool:
	if not is_finite(delta) or delta <= 0.0:
		return false
	# Bound a single update so OS focus loss cannot jump the snapshot horizon.
	var advance: float = minf(delta, 0.25)
	elapsed += advance
	cooldown_remaining = maxf(cooldown_remaining - advance, 0.0)
	_since_sample += advance
	if _since_sample < SAMPLE_INTERVAL:
		return false
	_since_sample -= SAMPLE_INTERVAL
	return true


func reset(initial_world: Dictionary) -> void:
	# Reset on external disk load / manual safe rollback. Cooldown remains
	# separate so reloading a file cannot trivially reset a Time Button lock.
	elapsed = 0.0
	_since_sample = 0.0
	_samples.clear()
	record(initial_world)


func record(world: Dictionary) -> bool:
	if int(world.get("format", -1)) != 2 or _samples.size() > MAX_SAMPLES:
		return false
	var payload: Dictionary = world.duplicate(true)
	if not _samples.is_empty() and is_equal_approx(float(_samples.back()["time"]), elapsed):
		_samples[_samples.size() - 1] = {"time": elapsed, "world": payload}
	else:
		_samples.append({"time": elapsed, "world": payload})
	while _samples.size() > MAX_SAMPLES:
		_samples.pop_front()
	return true


func preview(seconds_back: float) -> Dictionary:
	if cooldown_remaining > 0.0 or not is_finite(seconds_back):
		return {}
	if seconds_back <= 0.0 or seconds_back > MAX_REWIND_SECONDS:
		return {}
	var target_time: float = elapsed - seconds_back
	for index in range(_samples.size() - 1, -1, -1):
		var entry: Dictionary = _samples[index]
		if float(entry["time"]) <= target_time + 0.0001:
			return {"time": float(entry["time"]),
				"world": (entry["world"] as Dictionary).duplicate(true)}
	return {}


func commit_rewind(target_time: float) -> void:
	# Called only after a full world apply_snapshot has succeeded.
	while not _samples.is_empty() and float(_samples.back()["time"]) > target_time + 0.0001:
		_samples.pop_back()
	elapsed = target_time
	_since_sample = 0.0
	cooldown_remaining = SAFETY_COOLDOWN


func available_samples() -> int:
	return _samples.size()
