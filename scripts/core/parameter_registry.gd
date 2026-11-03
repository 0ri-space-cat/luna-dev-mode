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
		"id": "alive", "label": "IS_ALIVE", "display_name": "Жизнь", "kind": "bool", "default": false,
		"hint": "Оживляет объект. Или делает неживым, тут как повезёт."
	})
	register_parameter({
		"id": "ai_enabled", "label": "AI_ENABLED", "display_name": "Самостоятельность", "kind": "bool", "default": true,
		"hint": "Пусть сам решает, куда ему идти."
	})
	register_parameter({
		"id": "behavior_mode", "label": "BEHAVIOR_MODE", "display_name": "Поведение", "kind": "enum", "default": "WANDER",
		"choices": [{"name":"WANDER","value":"WANDER"},{"name":"IDLE","value":"IDLE"},{"name":"FOLLOW","value":"FOLLOW"},{"name":"CHASE","value":"CHASE"},{"name":"FLEE","value":"FLEE"},{"name":"AUTO","value":"AUTO"}],
		"hint": "Гулять, догонять, убегать. Выбирай настроение."
	})
	register_parameter({
		"id": "target_group", "label": "TARGET_GROUP", "display_name": "Кого искать", "kind": "enum", "default": "LUNA",
		"choices": [{"name":"LUNA","value":"LUNA"},{"name":"ANY","value":"ANY"},{"name":"TREE","value":"TREE"},{"name":"FRIDGE","value":"FRIDGE"}],
		"hint": "За кем носиться? Или от кого."
	})
	register_parameter({
		"id": "luna_relation", "label": "LUNA_RELATION", "display_name": "Отношение к Луне", "kind": "enum", "default": "NEUTRAL",
		"choices": [{"name":"NEUTRAL","value":"NEUTRAL"},{"name":"FRIEND","value":"FRIEND"},{"name":"HOSTILE","value":"HOSTILE"},{"name":"AFRAID","value":"AFRAID"}],
		"hint": "Любит меня, боится или хочет прибить."
	})
	register_parameter({
		"id": "sense_range", "label": "SENSE_RANGE", "display_name": "Дальность зрения", "kind": "float", "min": 2.0, "max": 25.0, "step": 0.5, "default": 12.0,
		"hint": "Как далеко видит. Не проверяй на мне."
	})
	register_parameter({
		"id": "follow_distance", "label": "FOLLOW_DISTANCE", "display_name": "Личное пространство", "kind": "float", "min": 1.0, "max": 7.0, "step": 0.2, "default": 2.0,
		"hint": "Личное пространство. Уважаем."
	})
	register_parameter({
		"id": "health", "label": "HEALTH", "display_name": "Здоровье", "kind": "int",
		"min": 1.0, "max": 200.0, "step": 1.0, "default": 100,
		"hint": "Сколько ещё протянет."
	})
	register_parameter({
		"id": "speed", "label": "MOVE_SPEED", "display_name": "Скорость", "kind": "float",
		"min": 0.0, "max": 5.0, "step": 0.1, "default": 2.0,
		"hint": "Быстрее. Ещё быстрее. Ой."
	})
	register_parameter({
		"id": "size", "label": "SCALE", "display_name": "Размер", "kind": "float",
		"min": 0.5, "max": 2.0, "step": 0.1, "default": 1.0,
		"hint": "Большой, маленький. Вопрос вкуса."
	})
	register_parameter({
		"id": "color", "label": "BASE_COLOR", "display_name": "Цвет", "kind": "color",
		"default": Color("b790dd"), "choices": PALETTE,
		"hint": "Перекрасить? Запросто."
	})


func register_parameter(spec: Dictionary) -> bool:
	for required in ["id", "label", "kind", "default", "hint"]:
		if not spec.has(required):
			push_warning("Parameter definition is missing: %s" % required)
			return false
	var parameter_id: String = str(spec["id"])
	if parameter_id.is_empty() or _by_id.has(parameter_id):
		return false
	if not ["bool", "int", "float", "color", "enum"].has(str(spec["kind"])):
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
		"enum":
			if typeof(proposed) != TYPE_STRING:
				return {"ok": false, "error": "Expected enum string"}
			for option in spec.get("choices", []):
				if str(option.get("value", "")) == proposed:
					return {"ok": true, "value": proposed}
			return {"ok": false, "error": "Unknown enum option"}
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
