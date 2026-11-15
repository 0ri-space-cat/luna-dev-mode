extends RefCounted
## Separate V2 save namespace. Never deserialize a legacy 3D Vector3 save as 2D.
const FORMAT := 2
const PATH := "user://luna_runtime2d_v2.json"

var last_error := ""


func write_snapshot(data: Dictionary, path: String = PATH) -> bool:
	last_error = ""
	if int(data.get("format", -1)) != FORMAT:
		return _fail("Unsupported 2D save format")
	var temporary := path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return _fail("Cannot open temporary save")
	file.store_string(JSON.stringify(data))
	file.flush()
	file.close()
	var result: Error = DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), ProjectSettings.globalize_path(path))
	if result != OK:
		return _fail("Could not atomically replace save")
	return true


func read_snapshot(path: String = PATH) -> Dictionary:
	last_error = ""
	if not FileAccess.file_exists(path):
		last_error = "Save does not exist"
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		last_error = "Save cannot be read"
		return {}
	var value: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not (value is Dictionary) or int(value.get("format", -1)) != FORMAT:
		last_error = "Invalid or incompatible save format"
		return {}
	return value as Dictionary


func _fail(reason: String) -> bool:
	last_error = reason
	return false
