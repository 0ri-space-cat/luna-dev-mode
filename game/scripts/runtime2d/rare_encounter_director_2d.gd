extends RefCounted
## One global rare-event budget, owned by Adventure rather than local saves.
## Numerical balance is provisional; no event can grant progress or pressure.
const REFLECTION := "RE58"
const HAND := "RE66"
const IDS := [REFLECTION, HAND]
const WINDOW_SECONDS := 600.0
const COOLDOWN_SECONDS := 2700.0
const SCENE_SECONDS := 5.0
const AREA_BY_ID := {REFLECTION: "W1", HAND: "M2"}

var next_window := WINDOW_SECONDS
var cooldown_until := 0.0
var consumed: Array[String] = []
var last_area := ""
var active := ""
var active_until := 0.0


func window_due(now: float) -> bool:
	return is_finite(now) and now >= next_window


static func chance(confirmed: bool, pressure: float, identity: String) -> float:
	if not confirmed or identity not in IDS or not is_finite(pressure):
		return 0.0
	var normalized := clampf(pressure / 100.0, 0.0, 1.0)
	var result := 0.01 + 0.07 * normalized * normalized
	return result * 0.1 if identity == HAND else result


func consider(now: float, confirmed: bool, pressure: float, identity: String, roll: float) -> bool:
	if not window_due(now):
		return false
	# Never accumulate missed windows or retry on each screen/frame.
	next_window = now + WINDOW_SECONDS
	if not confirmed or not active.is_empty() or now < cooldown_until or identity not in IDS or identity in consumed:
		return false
	var area: String = AREA_BY_ID[identity]
	if last_area == area or not is_finite(roll) or roll < 0.0 or roll >= chance(confirmed, pressure, identity):
		return false
	consumed.append(identity)
	last_area = area
	cooldown_until = now + COOLDOWN_SECONDS
	active = identity
	active_until = now + SCENE_SECONDS
	return true


func clear_active() -> void:
	active = ""
	active_until = 0.0


func snapshot() -> Dictionary:
	return {"next_window": next_window, "cooldown_until": cooldown_until, "consumed": consumed.duplicate(), "last_area": last_area}


func restore(data: Variant, now: float, confirmed: bool) -> bool:
	if not is_finite(now) or now < 0.0 or not data is Dictionary:
		return false
	if data.is_empty():
		next_window = now + WINDOW_SECONDS
		cooldown_until = 0.0
		consumed.clear()
		last_area = ""
		clear_active()
		return true
	if data.size() != 4 or not _time(data.get("next_window"), now + WINDOW_SECONDS) or not _time(data.get("cooldown_until"), now + COOLDOWN_SECONDS) or not data.get("consumed") is Array:
		return false
	var ids: Array[String] = []
	for identity in data["consumed"]:
		if identity not in IDS or identity in ids:
			return false
		ids.append(identity)
	if (not ids.is_empty() and not confirmed) or (ids.is_empty() and (data.get("last_area") != "" or float(data["cooldown_until"]) != 0.0)):
		return false
	if not ids.is_empty() and data.get("last_area") != AREA_BY_ID[ids.back()]:
		return false
	next_window = float(data["next_window"])
	cooldown_until = float(data["cooldown_until"])
	consumed.assign(ids)
	last_area = data["last_area"]
	clear_active()
	return true


static func _time(value: Variant, maximum: float) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) and float(value) >= 0.0 and float(value) <= maximum
