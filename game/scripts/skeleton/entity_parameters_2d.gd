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


static func storage_id(parameter_id: String) -> String:
	var key := parameter_id.to_lower()
	return STORAGE_ALIASES.get(key, key)


func normalize(category: String, parameter_id: String, proposed: Variant) -> Dictionary:
	if parameter_id in PHYSICS_FIELDS:
		var spec := get_spec(category, parameter_id)
		if typeof(proposed) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(proposed)):
			return {"ok": false, "error": "Expected a finite number"}
		if float(proposed) < spec["min"] or float(proposed) > spec["max"]:
			return {"ok": false, "error": "Outside the supported physics range"}
	return super.normalize(category, parameter_id, proposed)
