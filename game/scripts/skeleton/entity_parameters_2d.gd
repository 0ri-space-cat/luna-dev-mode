extends "res://scripts/core/parameter_registry.gd"
## Canonical editor identifiers resolve to the existing serialized keys.
## Each slice exposes only the fields with a live adapter in this runtime.

const STORAGE_ALIASES := {
	"is_alive": "alive",
	"autonomy": "ai_enabled",
	"move_speed": "speed",
	"scale": "size",
	"base_color": "color",
	"restitution": "bounciness",
}
const PHYSICS_FIELDS := ["mass", "bounciness"]
const BEHAVIOR_FIELDS := ["behavior_mode", "target_group", "sense_range", "follow_distance", "luna_relation"]
const EDITOR_TABS := {
	"Общее": ["alive", "asleep"],
	"Облик": ["size", "color"],
	"Физика": ["mass", "bounciness", "gravity_scale"],
	"Разум": ["ai_enabled", "control_source", "sense_range"],
	"Поведение": ["speed", "behavior_mode", "target_group", "follow_distance"],
	"Отношения": ["luna_relation"],
}


func _init() -> void:
	super()
	register_parameter({
		"id": "mass", "label": "MASS", "display_name": "Вес", "kind": "float",
		"tab": "PHYSICS", "min": 0.05, "max": 1000.0, "step": 0.0, "default": 1.0,
		"hint": "Меняет отклик на внешний импульс.",
	})
	register_parameter({
		"id": "bounciness", "label": "BOUNCINESS", "display_name": "Прыгучесть", "kind": "float",
		"tab": "PHYSICS", "min": 0.0, "max": 1.0, "step": 0.0, "default": 0.0,
		"hint": "Меняет отскок от опор и стен.",
	})
	register_parameter({"id": "gravity_scale", "label": "GRAVITY_SCALE", "kind": "float", "min": 0.0, "max": 3.0, "step": 0.1, "default": 1.0, "hint": "Сила гравитации"})
	register_parameter({"id": "asleep", "label": "ASLEEP", "kind": "bool", "default": false, "hint": "Сон"})
	register_parameter({"id": "control_source", "label": "CONTROL_SOURCE", "kind": "enum", "default": "NONE", "choices": [{"name": "NONE", "value": "NONE"}, {"name": "PLAYER", "value": "PLAYER"}], "hint": "Источник управления"})


static func storage_id(parameter_id: String) -> String:
	var key := parameter_id.to_lower()
	return STORAGE_ALIASES.get(key, key)


func normalize(category: String, parameter_id: String, proposed: Variant) -> Dictionary:
	if parameter_id in PHYSICS_FIELDS or parameter_id in ["size", "speed", "sense_range", "follow_distance", "gravity_scale"]:
		var spec := get_spec(category, parameter_id)
		if typeof(proposed) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(proposed)):
			return {"ok": false, "error": "Expected a finite number"}
		if float(proposed) < spec["min"] or float(proposed) > spec["max"]:
			return {"ok": false, "error": "Outside the supported physics range"}
	if parameter_id == "color":
		for choice in PALETTE:
			if proposed is Color and proposed == choice["value"]:
				return {"ok": true, "value": proposed}
		return {"ok": false, "error": "Unknown palette color"}
	return super.normalize(category, parameter_id, proposed)
