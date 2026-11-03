extends RefCounted
## Cross-run profile. Records things Luna inspected, not entire world state.
## Persistent player knowledge never grants abilities by itself.

const JsonStore = preload("res://scripts/core/json_store.gd")
const FORMAT_VERSION := 1
const DEFAULT_PATH := "user://luna_profile_v1.json"
const MAX_CATEGORIES := 200
const MAX_PARAMETERS_PER_CATEGORY := 200

var path: String
var last_error := ""
var dirty := false
var _categories: Dictionary = {}
var _parameters: Dictionary = {}


func _init(profile_path: String = DEFAULT_PATH) -> void:
	path = profile_path


func has_profile() -> bool:
	return FileAccess.file_exists(path)


func discover_category(category: String) -> bool:
	if not _valid_key(category) or (_categories.size() >= MAX_CATEGORIES and not _categories.has(category)):
		return false
	if _categories.has(category):
		return false
	_categories[category] = true
	dirty = true
	return true


func discover_parameter(category: String, parameter_id: String) -> bool:
	if not _valid_key(category) or not _valid_key(parameter_id):
		return false
	discover_category(category)
	if not _categories.has(category):
		return false
	var found: Dictionary = _parameters.get(category, {})
	if found.has(parameter_id) or found.size() >= MAX_PARAMETERS_PER_CATEGORY:
		return false
	found[parameter_id] = true
	_parameters[category] = found
	dirty = true
	return true


func has_discovered_category(category: String) -> bool:
	return _categories.has(category)


func has_discovered_parameter(category: String, parameter_id: String) -> bool:
	var found: Dictionary = _parameters.get(category, {})
	return found.has(parameter_id)


func list_categories() -> Array[String]:
	var result: Array[String] = []
	for key in _categories.keys():
		result.append(str(key))
	result.sort()
	return result


func list_parameters(category: String) -> Array[String]:
	var result: Array[String] = []
	var found: Dictionary = _parameters.get(category, {})
	for key in found.keys():
		result.append(str(key))
	result.sort()
	return result


func export_data() -> Dictionary:
	var keys: Array[String] = list_categories()
	var discovered := {}
	for category in keys:
		discovered[category] = list_parameters(category)
	return {"version": FORMAT_VERSION, "categories": keys, "parameters": discovered}


func import_data(data: Dictionary) -> bool:
	last_error = ""
	if typeof(data.get("version")) != TYPE_INT and typeof(data.get("version")) != TYPE_FLOAT:
		return _fail("Profile has no version")
	if int(data["version"]) != FORMAT_VERSION:
		return _fail("Unsupported profile version")
	var categories: Variant = data.get("categories")
	var parameters: Variant = data.get("parameters")
	if typeof(categories) != TYPE_ARRAY or typeof(parameters) != TYPE_DICTIONARY or categories.size() > MAX_CATEGORIES:
		return _fail("Malformed discovery data")
	var new_categories := {}
	var new_parameters := {}
	for cat in categories:
		if typeof(cat) != TYPE_STRING or not _valid_key(cat) or new_categories.has(cat):
			return _fail("Invalid category in profile")
		new_categories[cat] = true
	for category in parameters.keys():
		if not new_categories.has(category):
			return _fail("Unlisted category in profile")
		var values: Variant = parameters[category]
		if typeof(values) != TYPE_ARRAY or values.size() > MAX_PARAMETERS_PER_CATEGORY:
			return _fail("Malformed discovered parameters")
		var unique := {}
		for key in values:
			if typeof(key) != TYPE_STRING or not _valid_key(key) or unique.has(key):
				return _fail("Invalid discovered parameter")
			unique[key] = true
		new_parameters[category] = unique
	_categories = new_categories
	_parameters = new_parameters
	dirty = false
	return true


func save_profile() -> bool:
	last_error = ""
	if not dirty and has_profile():
		return true
	var result: Dictionary = JsonStore.write_document(path, export_data())
	if not bool(result["ok"]):
		return _fail(str(result["error"]))
	dirty = false
	return true


func load_profile() -> bool:
	last_error = ""
	var result: Dictionary = JsonStore.read_document(path)
	if not bool(result["ok"]):
		return _fail(str(result["error"]))
	return import_data(result["data"])


func _valid_key(value: String) -> bool:
	return not value.is_empty() and value.length() <= 64 and value.is_valid_identifier()


func _fail(message: String) -> bool:
	last_error = message
	return false
