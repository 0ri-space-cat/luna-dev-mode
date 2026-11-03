extends RefCounted
## Temporary terrain effects, shared by Luna, NPCs and future spells.
## ICE is intentionally a movement/traction field, not a new level mesh.

signal fields_changed(fields: Array)

const FORMAT_VERSION := 1
const MAX_FIELDS := 16
const ICE_DURATION := 6.0
const ICE_RADIUS := 2.1
const ICE_TRACTION := 0.2

var _fields: Array[Dictionary] = []


func add_ice_at(center: Vector3) -> bool:
	if not center.is_finite() or center.length() > 100000.0:
		return false
	var ground := Vector3(center.x, 0.0, center.z)
	for field in _fields:
		if field["center"].distance_squared_to(ground) <= 0.75 * 0.75:
			field["remaining"] = ICE_DURATION
			fields_changed.emit(get_fields())
			return true
	if _fields.size() >= MAX_FIELDS:
		return false
	_fields.append({
		"kind": "ICE", "center": ground,
		"radius": ICE_RADIUS, "remaining": ICE_DURATION
	})
	fields_changed.emit(get_fields())
	return true


func traction(position: Vector3) -> float:
	for field in _fields:
		var center: Vector3 = field["center"]
		if absf(position.y - center.y) > 2.5:
			continue
		var dx: float = position.x - center.x
		var dz: float = position.z - center.z
		if dx * dx + dz * dz <= pow(float(field["radius"]), 2.0):
			return ICE_TRACTION
	return 1.0


func advance(delta: float) -> void:
	if is_nan(delta) or is_inf(delta) or delta <= 0.0:
		return
	var changed := false
	for index in range(_fields.size() - 1, -1, -1):
		_fields[index]["remaining"] = maxf(
			0.0, float(_fields[index]["remaining"]) - minf(delta, 1.0)
		)
		if float(_fields[index]["remaining"]) <= 0.0:
			_fields.remove_at(index)
			changed = true
	if changed:
		fields_changed.emit(get_fields())


func get_fields() -> Array[Dictionary]:
	return _fields.duplicate(true)


func export_data() -> Dictionary:
	var rows := []
	for field in _fields:
		var p: Vector3 = field["center"]
		rows.append({
			"kind": "ICE", "position": [p.x, p.y, p.z],
			"radius": field["radius"], "remaining": field["remaining"]
		})
	return {"version": FORMAT_VERSION, "fields": rows}


func validate_data(data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false
	if data.is_empty():
		return true # A world created before the first ice field.
	if data.size() != 2 or typeof(data.get("version")) not in [TYPE_FLOAT, TYPE_INT]:
		return false
	if int(data["version"]) != FORMAT_VERSION or typeof(data.get("fields")) != TYPE_ARRAY:
		return false
	if data["fields"].size() > MAX_FIELDS:
		return false
	for row in data["fields"]:
		if typeof(row) != TYPE_DICTIONARY or row.size() != 4:
			return false
		if row.get("kind") != "ICE" or typeof(row.get("position")) != TYPE_ARRAY or row["position"].size() != 3:
			return false
		for n in row["position"]:
			if typeof(n) not in [TYPE_FLOAT, TYPE_INT] or is_nan(float(n)) or is_inf(float(n)) or absf(float(n)) > 100000.0:
				return false
		for key in ["radius", "remaining"]:
			var val: Variant = row.get(key)
			if typeof(val) not in [TYPE_FLOAT, TYPE_INT] or is_nan(float(val)) or is_inf(float(val)):
				return false
		if float(row["radius"]) <= 0.0 or float(row["radius"]) > ICE_RADIUS:
			return false
		if float(row["remaining"]) <= 0.0 or float(row["remaining"]) > ICE_DURATION:
			return false
	return true


func import_data(data: Dictionary) -> bool:
	if not validate_data(data):
		return false
	var restored: Array[Dictionary] = []
	if not data.is_empty():
		for row in data["fields"]:
			var pos: Array = row["position"]
			restored.append({
				"kind": "ICE",
				"center": Vector3(float(pos[0]), float(pos[1]), float(pos[2])),
				"radius": float(row["radius"]), "remaining": float(row["remaining"])
			})
	_fields = restored
	fields_changed.emit(get_fields())
	return true
