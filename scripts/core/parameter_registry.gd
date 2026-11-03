extends RefCounted
## Single source of truth for editable parameters: types, limits, UI metadata.
## To add a field, register a definition. The inspector reads this registry.

const PALETTE = [
	{"name": "LAVENDER", "value": Color("b790dd")},
	{"name": "MINT", "value": Color("8ed7bd")},
	{"name": "PINK", "value": Color("f49fc9")},
	{"name": "BLUE", "value": Color("87bfe8")},
	{"name": "PEACH", "value": Color("efb68e")},
	{"name": "VIOLET", "value": Color("684a96")}
]

var _ordered_specs: Array[Dictionary] = []
var _by_id: Dictionary = {}


func _init() -> void:
	register_parameter({
		"id": "alive", "label": "IS_ALIVE", "kind": "bool", "default": false,
		"hint": "Объект живой. При включённом AI_ENABLED действует самостоятельно."
	})
	register_parameter({
		"id": "ai_enabled", "label": "AI_ENABLED", "kind": "bool", "default": true,
		"hint": "Разрешает самостоятельное поведение живого объекта."
	})
	register_parameter({
		"id": "health", "label": "HEALTH", "kind": "int",
		"min": 1.0, "max": 200.0, "step": 1.0, "default": 100,
		"hint": "Запас здоровья объекта."
	})
	register_parameter({
		"id": "speed", "label": "MOVE_SPEED", "kind": "float",
		"min": 0.0, "max": 5.0, "step": 0.1, "default": 2.0,
		"hint": "Скорость самостоятельного передвижения."
	})
	register_parameter({
		"id": "size", "label": "SCALE", "kind": "float",
		"min": 0.5, "max": 2.0, "step": 0.1, "default": 1.0,
		"hint": "Размер объекта относительно исходного."
	})
	register_parameter({
		"id": "color", "label": "BASE_COLOR", "kind": "color",
		"default": Color("b790dd"), "choices": PALETTE,
		"hint": "Основной цвет объекта."
	})


func register_parameter(spec: Dictionary) -> bool:
	for required in ["id", "label", "kind", "default", "hint"]:
		if not spec.has(required):
			push_warning("Parameter definition is missing: %s" % required)
			return false
	var parameter_id: String = str(spec["id"])
	if parameter_id.is_empty() or _by_id.has(parameter_id):
		return false
	if not ["bool", "int", "float", "color"].has(str(spec["kind"])):
		return false
	var checked := _normalize_using_spec(spec, spec["default"])
	if not checked["ok"]:
		push_warning("Invalid default for parameter %s" % parameter_id)
		return false
	var stored := spec.duplicate(true)
	stored["default"] = checked["value"]
	_by_id[parameter_id] = stored
	_ordered_specs.append(stored)
	return true


func get_specs_for(category: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for spec in _ordered_specs:
		if _applies_to(spec, category):
			result.append(spec.duplicate(true))
	return result


func get_spec(category: String, parameter_id: String) -> Dictionary:
	var spec: Dictionary = _by_id.get(parameter_id, {})
	if spec.is_empty() or not _applies_to(spec, category):
		return {}
	return spec.duplicate(true)


func make_defaults(category: String, overrides: Dictionary = {}) -> Dictionary:
	var result := {}
	for spec in get_specs_for(category):
		var parameter_id: String = str(spec["id"])
		result[parameter_id] = spec["default"]
		if overrides.has(parameter_id):
			var checked := normalize(category, parameter_id, overrides[parameter_id])
			if checked["ok"]:
				result[parameter_id] = checked["value"]
	return result


func normalize(category: String, parameter_id: String, proposed: Variant) -> Dictionary:
	var spec: Dictionary = _by_id.get(parameter_id, {})
	if spec.is_empty() or not _applies_to(spec, category):
		return {"ok": false, "error": "Unknown or inapplicable parameter: %s" % parameter_id}
	return _normalize_using_spec(spec, proposed)


func _applies_to(spec: Dictionary, category: String) -> bool:
	var categories: Array = spec.get("categories", [])
	return categories.is_empty() or categories.has(category)


func _normalize_using_spec(spec: Dictionary, proposed: Variant) -> Dictionary:
	var kind: String = str(spec["kind"])
	match kind:
		"bool":
			if typeof(proposed) != TYPE_BOOL:
				return {"ok": false, "error": "Expected boolean"}
			return {"ok": true, "value": proposed}
		"int":
			if typeof(proposed) != TYPE_INT and typeof(proposed) != TYPE_FLOAT:
				return {"ok": false, "error": "Expected number"}
			var result: int = clampi(int(roundf(float(proposed))), int(spec["min"]), int(spec["max"]))
			return {"ok": true, "value": result}
		"float":
			if typeof(proposed) != TYPE_INT and typeof(proposed) != TYPE_FLOAT:
				return {"ok": false, "error": "Expected number"}
			var step: float = float(spec["step"])
			var result: float = clampf(float(proposed), float(spec["min"]), float(spec["max"]))
			if step > 0.0:
				result = clampf(snappedf(result, step), float(spec["min"]), float(spec["max"]))
			return {"ok": true, "value": result}
		"color":
			if typeof(proposed) != TYPE_COLOR:
				return {"ok": false, "error": "Expected Color"}
			return {"ok": true, "value": proposed}
	return {"ok": false, "error": "Unsupported type"}
