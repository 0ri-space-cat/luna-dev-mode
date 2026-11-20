extends RefCounted
## Data-only component definitions; no executable scripts in saved data.
const DEFINITIONS := {
	"INTERACTION": {
		"enabled": {"type": "bool", "default": true},
		"verb": {"type": "enum", "default": "USE", "choices": ["USE", "TALK", "OPEN", "INSPECT"]},
		"reach": {"type": "float", "default": 2.5, "min": 0.5, "max": 8.0}
	},
	"INVENTORY": {
		"max_slots": {"type": "int", "default": 8, "min": 1, "max": 24},
		"max_weight": {"type": "float", "default": 30.0, "min": 0.5, "max": 200.0}
	},
	"PICKUP": {
		"enabled": {"type": "bool", "default": true},
		"holder_id": {"type": "entity_id", "default": ""},
		"weight": {"type": "float", "default": 1.0, "min": 0.1, "max": 100.0},
		"world_position": {"type": "position", "default": [0.0, 0.0, 0.0]}
	},
	"ABILITY_SET": {
		"ids": {"type": "identifiers", "default": []}
	},
	"TRIGGER_ZONE": {
		"enabled": {"type": "bool", "default": true},
		"radius": {"type": "float", "default": 2.5, "min": 0.5, "max": 12.0},
		"watch_group": {"type": "enum", "default": "LUNA", "choices": ["LUNA", "ANY", "TREE", "FRIDGE", "CREATURE"]}
	},
	"DOOR_LINK": {
		"enabled": {"type": "bool", "default": true},
		"destination": {"type": "location_id", "default": ""}
	},
	"CONSUMABLE": {
		"delivery": {"type": "enum", "default": "CONSUMER", "choices": ["CONSUMER", "TARGET", "SPLASH"]},
		"radius": {"type": "float", "default": 2.5, "min": 0.5, "max": 6.0},
		"max_targets": {"type": "int", "default": 3, "min": 1, "max": 4},
		"effects": {"type": "effect_recipe", "default": []}
	},
	"ABILITY_BANK": {
		"stock": {"type": "ability_stock", "default": {}}
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
			"location_id":
				if typeof(value) != TYPE_STRING or str(value).length() > 96:
					return {"ok": false}
				if not str(value).is_empty() and not str(value).is_valid_identifier():
					return {"ok": false}
			"effect_recipe":
				if typeof(value) != TYPE_ARRAY or value.size() > 3:
					return {"ok": false}
				var checked_recipe: Array = []
				for action in value:
					if typeof(action) != TYPE_DICTIONARY:
						return {"ok": false}
					var op: String = str(action.get("operation", ""))
					var parameter: String = str(action.get("parameter_id", ""))
					if op not in ["SET", "ADD", "MULTIPLY", "TOGGLE"] or parameter.is_empty() or not parameter.is_valid_identifier():
						return {"ok": false}
					# Resource authority and servings are not an edible effect.
					if parameter in ["access_level", "portions"] or parameter.length() > 64:
						return {"ok": false}
					if action.size() != (2 if op == "TOGGLE" else 3):
						return {"ok": false}
					if op != "TOGGLE":
						var amount: Variant = action.get("value")
						if typeof(amount) not in [TYPE_INT, TYPE_FLOAT, TYPE_STRING, TYPE_BOOL]:
							return {"ok": false}
						if typeof(amount) in [TYPE_INT, TYPE_FLOAT] and (not is_finite(float(amount)) or absf(float(amount)) > 10000.0):
							return {"ok": false}
						if typeof(amount) == TYPE_STRING and str(amount).length() > 64:
							return {"ok": false}
						if op in ["ADD", "MULTIPLY"] and typeof(amount) not in [TYPE_INT, TYPE_FLOAT]:
							return {"ok": false}
					checked_recipe.append(action.duplicate(true))
				value = checked_recipe
			"ability_stock":
				if typeof(value) != TYPE_DICTIONARY or value.size() > 16:
					return {"ok": false}
				var checked_stock: Dictionary = {}
				for ability_id in value.keys():
					if typeof(ability_id) != TYPE_STRING or not str(ability_id).is_valid_identifier() or str(ability_id).length() > 64:
						return {"ok": false}
					if typeof(value[ability_id]) != TYPE_INT or int(value[ability_id]) < 1 or int(value[ability_id]) > 8:
						return {"ok": false}
					checked_stock[str(ability_id)] = int(value[ability_id])
				value = checked_stock
			"identifiers":
				if typeof(value) != TYPE_ARRAY or value.size() > 16:
					return {"ok": false}
				var seen := {}
				for ability_id in value:
					if typeof(ability_id) != TYPE_STRING or not str(ability_id).is_valid_identifier() or str(ability_id).length() > 64 or seen.has(ability_id):
						return {"ok": false}
					seen[ability_id] = true
				value = value.duplicate(true)
			"entity_id":
				if typeof(value) != TYPE_STRING or str(value).length() > 96:
					return {"ok": false}
				if not str(value).is_empty() and not str(value).is_valid_identifier():
					return {"ok": false}
			"position":
				if typeof(value) != TYPE_ARRAY or value.size() != 3:
					return {"ok": false}
				var coords: Array = []
				for coord in value:
					if typeof(coord) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(coord)) or absf(float(coord)) > 100000.0:
						return {"ok": false}
					coords.append(float(coord))
				value = coords
			"int":
				if typeof(value) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(value)) or float(value) != float(int(value)):
					return {"ok": false}
				if int(value) < int(spec["min"]) or int(value) > int(spec["max"]):
					return {"ok": false}
				value = int(value)
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
