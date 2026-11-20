extends RefCounted
## Separate V2 save namespace. Never deserialize a legacy 3D Vector3 save.
## A bounded temp-file replacement retains the previous valid save in .bak.
const FORMAT := 2
const PATH := "user://luna_runtime2d_v2.json"
const MAX_SAVE_BYTES := 4 * 1024 * 1024

var last_error := ""


func write_snapshot(data: Dictionary, path: String = PATH) -> bool:
	last_error = ""
	if not _supported_format(data):
		return _fail("Unsupported 2D save format")
	if not path.begins_with("user://") or not path.ends_with(".json"):
		return _fail("Saves must use a user:// JSON file")
	var encoded: String = JSON.stringify(data)
	if encoded.to_utf8_buffer().size() > MAX_SAVE_BYTES:
		return _fail("Save exceeds the 4 MiB safety limit")
	# Reject any dictionary that cannot be serialized back as a JSON object.
	# The game controller separately validates all game-specific fields before
	# applying a save; this layer is intentionally independent of scene data.
	var checked_parser := JSON.new()
	if checked_parser.parse(encoded) != OK:
		return _fail("Save could not be decoded")
	var parsed: Variant = checked_parser.data
	if not (parsed is Dictionary) or not _supported_format(parsed):
		return _fail("Save is not serializable as valid V2 JSON")
	var temporary := path + ".tmp"
	var global_temp: String = ProjectSettings.globalize_path(temporary)
	var global_path: String = ProjectSettings.globalize_path(path)
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return _fail("Cannot open temporary save")
	file.store_string(encoded)
	file.flush()
	var write_ok: bool = file.get_error() == OK
	file.close()
	if not write_ok:
		DirAccess.remove_absolute(global_temp)
		return _fail("Could not completely write temporary save")
	# Validate our completed write before changing either primary or backup.
	var checked: Dictionary = _read_file(temporary)
	if checked.is_empty():
		DirAccess.remove_absolute(global_temp)
		return _fail("Temporary save failed verification")
	if FileAccess.file_exists(path):
		# Never replace the last known-good backup with corrupt source data.
		var previous: Dictionary = _read_file(path)
		if not previous.is_empty():
			var copied: Error = DirAccess.copy_absolute(
				global_path, ProjectSettings.globalize_path(path + ".bak"))
			if copied != OK:
				DirAccess.remove_absolute(global_temp)
				return _fail("Cannot preserve previous save backup")
	var result: Error = DirAccess.rename_absolute(global_temp, global_path)
	if result != OK:
		DirAccess.remove_absolute(global_temp)
		return _fail("Could not atomically replace save")
	last_error = ""
	return true


func read_snapshot(path: String = PATH) -> Dictionary:
	last_error = ""
	var current: Dictionary = _read_file(path)
	if not current.is_empty():
		return current
	var backup: Dictionary = _read_file(path + ".bak")
	if not backup.is_empty():
		last_error = "Recovered last valid V2 save backup"
		return backup
	last_error = "Save and backup are missing, too large, corrupt or incompatible"
	return {}


func _read_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	if file.get_length() <= 0 or file.get_length() > MAX_SAVE_BYTES:
		file.close()
		return {}
	var content: String = file.get_as_text()
	file.close()
	var decoder := JSON.new()
	if decoder.parse(content) != OK:
		return {}
	var value: Variant = decoder.data
	if not (value is Dictionary) or not _supported_format(value):
		return {}
	return value as Dictionary


func _supported_format(data: Dictionary) -> bool:
	var format_value: Variant = data.get("format", null)
	return typeof(format_value) in [TYPE_INT, TYPE_FLOAT] and float(format_value) == float(FORMAT)


func _fail(reason: String) -> bool:
	last_error = reason
	return false
