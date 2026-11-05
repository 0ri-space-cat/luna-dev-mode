extends RefCounted
## Central catalog for replaceable art/audio. Missing assets resolve to null so
## callers can keep their explicit graybox fallbacks.
const CATALOG_PATH := "res://assets/asset_catalog.json"
var entries: Dictionary = {}
var last_error := ""

func load_catalog(path: String = CATALOG_PATH) -> bool:
	last_error = ""
	if not FileAccess.file_exists(path):
		last_error = "Catalog not found: %s" % path
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (parsed is Dictionary) or not (parsed.get("assets", {}) is Dictionary):
		last_error = "Catalog must contain an assets object"
		return false
	entries = parsed["assets"]
	return true

func get_path(asset_id: String) -> String:
	var entry: Variant = entries.get(asset_id, {})
	return str(entry.get("path", "")) if entry is Dictionary else ""

func load_asset(asset_id: String) -> Resource:
	var path := get_path(asset_id)
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path)

func list_ids() -> Array[String]:
	var result: Array[String] = []
	for key in entries:
		result.append(str(key))
	result.sort()
	return result
