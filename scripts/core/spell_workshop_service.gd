extends RefCounted
## Recipes are portable typed data. ParameterRegistry is the only source of
## available fields and valid values; no scripts or free-form code are stored.

const JsonStore = preload("res://scripts/core/json_store.gd")
const FORMAT_VERSION := 1
const DEFAULT_PATH := "user://luna_spells_v1.json"
const MAX_RECIPES := 48
const MAX_EFFECTS := 12

var registry
var spells
var path: String
var last_error := ""
var _recipes: Array[Dictionary] = []


func _init(parameter_registry, spell_service, library_path: String = DEFAULT_PATH) -> void:
	registry = parameter_registry
	spells = spell_service
	path = library_path


func has_library() -> bool:
	return FileAccess.file_exists(path)


func available_fields() -> Array[Dictionary]:
	## For the current prototype all published fields apply to fridge and tree.
	var result: Array[Dictionary] = registry.get_specs_for("fridge")
	for spec in registry.get_specs_for("tree"):
		var exists := false
		for other in result:
			if other["id"] == spec["id"]:
				exists = true
				break
		if not exists:
			result.append(spec)
	return result


func create_recipe(label: String, cast_range: float, actions: Array[Dictionary]) -> String:
	last_error = ""
	if _recipes.size() >= MAX_RECIPES:
		last_error = "Палочка уже забита заклинаниями."
		return ""
	var name := label.strip_edges()
	var id := _next_id()
	var spec := {
		"id": id,
		"label": name,
		"cast_range": cast_range,
		"symbol_id": "CUSTOM",
		"stone_color": Color("b790dd"),
		"effects": actions.duplicate(true)
	}
	if not _valid_recipe(spec):
		last_error = "Проверь название, дальность и блоки."
		return ""
	if not spells.register_spell(spec):
		last_error = "Не удалось создать заклинание."
		return ""
	_recipes.append(spec)
	if not save_library():
		_recipes.pop_back()
		spells.unregister_custom_spell(id)
		return ""
	return id


func list_user_spells() -> Array[Dictionary]:
	return _recipes.duplicate(true)


func save_library() -> bool:
	last_error = ""
	var records := []
	for spec in _recipes:
		records.append(_serialize_recipe(spec))
	var result: Dictionary = JsonStore.write_document(path, {
		"version": FORMAT_VERSION, "recipes": records
	})
	if not bool(result["ok"]):
		last_error = str(result["error"])
		return false
	return true


func load_library() -> bool:
	last_error = ""
	var response: Dictionary = JsonStore.read_document(path)
	if not bool(response["ok"]):
		last_error = str(response["error"])
		return false
	var data: Dictionary = response["data"]
	if typeof(data.get("version")) not in [TYPE_INT, TYPE_FLOAT] or int(data["version"]) != FORMAT_VERSION:
		last_error = "Несовместимая версия библиотеки."
		return false
	var stored: Variant = data.get("recipes")
	if typeof(stored) != TYPE_ARRAY or stored.size() > MAX_RECIPES:
		last_error = "Повреждён список заклинаний."
		return false
	var prospective: Array[Dictionary] = []
	var seen := {}
	for raw in stored:
		if typeof(raw) != TYPE_DICTIONARY:
			last_error = "Повреждён рецепт."
			return false
		var decoded: Dictionary = _parse_recipe(raw)
		if decoded.is_empty() or not _valid_recipe(decoded):
			last_error = "Неизвестный блок или параметр в рецепте."
			return false
		var spell_id: String = decoded["id"]
		if seen.has(spell_id) or spells.contains_spell(spell_id):
			last_error = "Повторяется ID заклинания."
			return false
		seen[spell_id] = true
		prospective.append(decoded)
	var registered: Array[String] = []
	for spec in prospective:
		if not spells.register_spell(spec):
			for spell_id in registered:
				spells.unregister_custom_spell(spell_id)
			last_error = "Не удалось восстановить библиотеку."
			return false
		registered.append(spec["id"])
	_recipes = prospective
	return true


func _valid_recipe(spec: Dictionary) -> bool:
	for required in ["id", "label", "cast_range", "effects"]:
		if not spec.has(required):
			return false
	var spell_id: String = str(spec["id"])
	if not spell_id.begins_with("CUSTOM_") or not spell_id.is_valid_identifier() or spell_id.length() > 32:
		return false
	if typeof(spec["label"]) != TYPE_STRING:
		return false
	var label: String = spec["label"]
	if label.strip_edges().is_empty() or label.length() > 40:
		return false
	if typeof(spec["cast_range"]) not in [TYPE_INT, TYPE_FLOAT]:
		return false
	var range_value := float(spec["cast_range"])
	if is_nan(range_value) or is_inf(range_value) or range_value < 0.5 or range_value > 50.0:
		return false
	if typeof(spec["effects"]) != TYPE_ARRAY:
		return false
	var actions: Array = spec["effects"]
	if actions.is_empty() or actions.size() > MAX_EFFECTS:
		return false
	for effect in actions:
		if typeof(effect) != TYPE_DICTIONARY or not _valid_effect(effect):
			return false
	return true


func _valid_effect(action: Dictionary) -> bool:
	if not action.has("operation") or not action.has("parameter_id"):
		return false
	var op: String = str(action["operation"])
	var field: String = str(action["parameter_id"])
	if not ["SET", "ADD", "MULTIPLY", "TOGGLE"].has(op):
		return false
	var spec: Dictionary = _field_spec(field)
	if spec.is_empty():
		return false
	var kind: String = str(spec["kind"])
	if op == "TOGGLE":
		return kind == "bool"
	if not action.has("value"):
		return false
	var value: Variant = action["value"]
	if op == "SET":
		var valid_category := "fridge" if not registry.get_spec("fridge", field).is_empty() else "tree"
		return bool(registry.normalize(valid_category, field, value)["ok"])
	if kind not in ["int", "float"] or typeof(value) not in [TYPE_INT, TYPE_FLOAT]:
		return false
	var number := float(value)
	return not is_nan(number) and not is_inf(number) and absf(number) <= 1000.0


func _field_spec(field: String) -> Dictionary:
	for spec in available_fields():
		if spec["id"] == field:
			return spec
	return {}


func _next_id() -> String:
	var index := 1
	while spells.contains_spell("CUSTOM_%03d" % index):
		index += 1
	return "CUSTOM_%03d" % index


func _serialize_recipe(spec: Dictionary) -> Dictionary:
	var actions := []
	for action in spec["effects"]:
		var packed: Dictionary = action.duplicate(true)
		if packed.has("value") and typeof(packed["value"]) == TYPE_COLOR:
			packed["value"] = {"color_hex": (packed["value"] as Color).to_html(true)}
		actions.append(packed)
	return {
		"id": spec["id"],
		"label": spec["label"],
		"cast_range": spec["cast_range"],
		"effects": actions
	}


func _parse_recipe(raw: Dictionary) -> Dictionary:
	for required in ["id", "label", "cast_range", "effects"]:
		if not raw.has(required):
			return {}
	if typeof(raw["effects"]) != TYPE_ARRAY:
		return {}
	var decoded := []
	for source in raw["effects"]:
		if typeof(source) != TYPE_DICTIONARY:
			return {}
		var action: Dictionary = source.duplicate(true)
		if typeof(action.get("value")) == TYPE_DICTIONARY:
			var value: Dictionary = action["value"]
			if value.size() != 1 or typeof(value.get("color_hex")) != TYPE_STRING:
				return {}
			if not Color.html_is_valid(value["color_hex"]):
				return {}
			action["value"] = Color.html(value["color_hex"])
		decoded.append(action)
	return {
		"id": raw["id"],
		"label": raw["label"],
		"cast_range": raw["cast_range"],
		"symbol_id": "CUSTOM",
		"stone_color": Color("b790dd"),
		"effects": decoded
	}
