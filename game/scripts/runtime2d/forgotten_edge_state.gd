extends RefCounted
## Local cycle and portable artifact ownership; no rewind of global progress.
var elapsed := 0.0
var time_owned := false
var portal_owned := false
var portal_a: Array = []
var portal_b: Array = []


func snapshot() -> Dictionary:
	return {"elapsed": elapsed, "time_owned": time_owned, "portal_owned": portal_owned, "portal_a": portal_a.duplicate(), "portal_b": portal_b.duplicate()}


func restore(data: Variant) -> bool:
	if not data is Dictionary or data.size() != 5 or not data.get("time_owned") is bool or not data.get("portal_owned") is bool:
		return false
	var phase: Variant = data.get("elapsed")
	if typeof(phase) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(phase)) or float(phase) < 0.0 or float(phase) >= 72.0:
		return false
	if not _valid_anchor(data.get("portal_a")) or not _valid_anchor(data.get("portal_b")):
		return false
	if not data["portal_owned"] and (not data["portal_a"].is_empty() or not data["portal_b"].is_empty()):
		return false
	if data["portal_a"].size() == 2 and data["portal_b"].size() == 2:
		var a := Vector2(data["portal_a"][0], data["portal_a"][1])
		var b := Vector2(data["portal_b"][0], data["portal_b"][1])
		if a.distance_to(b) < 64.0:
			return false
	portal_a = data["portal_a"].duplicate()
	portal_b = data["portal_b"].duplicate()
	elapsed = float(phase)
	time_owned = data["time_owned"]
	portal_owned = data["portal_owned"]
	return true


static func _valid_anchor(value: Variant) -> bool:
	if not value is Array or value.size() not in [0, 2]:
		return false
	for coordinate in value:
		if typeof(coordinate) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(coordinate)) or absf(float(coordinate)) > 10000.0:
			return false
	return true
