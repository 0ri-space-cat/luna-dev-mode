extends RefCounted
## One original of each artifact, separate from the body's own parameters.
var compass_owned := false
var gravity_index := 0
var camera_owned := false
var camera_mode := "FOLLOW"
var camera_lock := Vector2.ZERO


func snapshot() -> Dictionary:
	return {"compass_owned": compass_owned, "gravity_index": gravity_index, "camera_owned": camera_owned, "camera_mode": camera_mode, "camera_lock": [camera_lock.x, camera_lock.y]}


func restore(data: Variant) -> bool:
	if not data is Dictionary or data.size() != 5:
		return false
	if not data.get("compass_owned") is bool or not data.get("camera_owned") is bool:
		return false
	var index: Variant = data.get("gravity_index")
	if typeof(index) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(index)) or float(index) != floorf(float(index)) or float(index) < 0.0 or float(index) > 3.0:
		return false
	if not data["compass_owned"] and int(index) != 0:
		return false
	if data.get("camera_mode") not in ["FOLLOW", "LOCKED"] or (not data["camera_owned"] and data["camera_mode"] != "FOLLOW"):
		return false
	var point: Variant = data.get("camera_lock")
	if not point is Array or point.size() != 2:
		return false
	for value in point:
		if typeof(value) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(value)) or absf(float(value)) > 20000.0:
			return false
	compass_owned = data["compass_owned"]
	gravity_index = int(index)
	camera_owned = data["camera_owned"]
	camera_mode = data["camera_mode"]
	camera_lock = Vector2(float(point[0]), float(point[1]))
	return true
