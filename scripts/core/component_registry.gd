extends RefCounted
## Data-only component definitions; no executable scripts in saved data.
const DEFINITIONS := {
	"INTERACTION": {
		"enabled": {"type": "bool", "default": true},
		"verb": {"type": "enum", "default": "USE", "choices": ["USE", "TALK", "OPEN", "INSPECT"]},
		"reach": {"type": "float", "default": 2.5, "min": 0.5, "max": 8.0}
	},
	"ABILITY_SET": {
		"ids": {"type": "identifiers", "default": []}
	},
	"TRIGGER_ZONE": {
		"enabled": {"type": "bool", "default": true},
		"radius": {"type": "float", "default": 2.5, "min": 0.5, "max": 12.0},
		"watch_group": {"type": "enum", "default": "LUNA", "choices": ["LUNA", "ANY", "TREE", "FRIDGE", "CREATURE"]}
	}
}

static func defaults(id: String) -> Dictionary:
	var result := {}
	for field in DEFINITIONS.get(id, {}).keys():
		result[field] = DEFINITIONS[id][field]["default"]
	return result

static func validate(id: String, data: Variant) -> Dictionary:
	if typeof(data) != TYPE_DICTIONARY or not DEFINITIONS.has(id):
		return {"ok": false}
	var result: Dictionary = defaults(id)
	for key in data.keys():
		if typeof(key) != TYPE_STRING or not DEFINITIONS[id].has(key):
			return {"ok": false}
		var spec: Dictionary = DEFINITIONS[id][key]
		var value: Variant = data[key]
		match str(spec["type"]):
			"bool":
				if typeof(value) != TYPE_BOOL:
					return {"ok": false}
			"enum":
				if typeof(value) != TYPE_STRING or not spec["choices"].has(value):
					return {"ok": false}
			"identifiers":
				if typeof(value) != TYPE_ARRAY or value.size() > 16:
					return {"ok": false}
				var seen := {}
				for ability_id in value:
					if typeof(ability_id) != TYPE_STRING or not str(ability_id).is_valid_identifier() or str(ability_id).length() > 64 or seen.has(ability_id):
						return {"ok": false}
					seen[ability_id] = true
				value = value.duplicate(true)
			"float":
				if typeof(value) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(value)):
					return {"ok": false}
				if float(value) < float(spec["min"]) or float(value) > float(spec["max"]):
					return {"ok": false}
				value = float(value)
		result[key] = value
	return {"ok": true, "value": result}

static func validate_collection(data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY or data.size() > 12:
		return false
	for id in data.keys():
		if typeof(id) != TYPE_STRING or not validate(str(id), data[id])["ok"]:
			return false
	return true
