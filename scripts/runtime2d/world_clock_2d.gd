extends RefCounted
## The author's SLOW / NORMAL / FAST world-time control, without freezing time.
## Only game-simulation adapters read this factor: UI and real OS time are never
## touched, and recovery cooldowns keep advancing in unscaled real time.
## The rates are engineering placeholders pending author balancing.

signal mode_changed(mode: String)

const SLOW := "SLOW"
const NORMAL := "NORMAL"
const FAST := "FAST"
const SCALES := {SLOW: 0.5, NORMAL: 1.0, FAST: 2.0}

var mode := NORMAL


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


func snapshot() -> Dictionary:
	return {"mode": mode}


func restore(data: Variant) -> bool:
	if not (data is Dictionary) or typeof(data.get("mode", null)) != TYPE_STRING:
		return false
	return set_mode(str(data["mode"]))
