extends RefCounted
## A bounded list of data operations. The editor and the saved item use this schema.

const FLIGHT_LIMIT := 45
const GLOW_LIMIT := 35
const SWIM_LIMIT := 30
const FREEZE_LIMIT := 40
const MAX_EFFECTS := 6
const EFFECTS := {
	"HEAL": {"argument": "AMOUNT", "max": 100, "food": true},
	"FLY": {"argument": "SECONDS", "max": FLIGHT_LIMIT, "food": true},
	"GLOW": {"argument": "SECONDS", "max": GLOW_LIMIT, "food": true},
	"SWIM": {"argument": "SECONDS", "max": SWIM_LIMIT, "food": false},
	"FREEZE_WATER": {"argument": "SECONDS", "max": FREEZE_LIMIT, "food": false},
	"CLEAR": {"argument": "", "max": 0, "food": false},
	"NIGHT": {"argument": "", "max": 0, "food": false},
}
const RECIPES := {
	"ALC-R08": [{"id": "GLOW", "value": GLOW_LIMIT}],
	"ALC-R09": [{"id": "CLEAR"}],
	"ALC-R12": [{"id": "HEAL", "value": 25}],
	"ALC-R20": [{"id": "FREEZE_WATER", "value": FREEZE_LIMIT}],
	"ALC-R21": [{"id": "SWIM", "value": SWIM_LIMIT}],
	"ALC-R30": [{"id": "NIGHT"}],
}


static func valid_effects(effects: Variant, food: bool) -> bool:
	if not effects is Array or effects.size() > MAX_EFFECTS:
		return false
	var used := {}
	for effect in effects:
		if not effect is Dictionary:
			return false
		var id: Variant = effect.get("id")
		if not id is String or not EFFECTS.has(id) or used.has(id):
			return false
		var spec: Dictionary = EFFECTS[id]
		if food and not spec["food"]:
			return false
		if spec["max"] == 0:
			if effect.size() != 1:
				return false
		elif effect.size() != 2 or not whole_in_range(effect.get("value"), 1, spec["max"]):
			return false
		used[id] = true
	return true


static func valid_profile(profile: Dictionary, food: bool) -> bool:
	if not valid_effects(profile.get("effects"), food):
		return false
	if not food:
		return profile.size() == 1
	return profile.size() == 3 and profile.get("edible") is bool \
		and whole_in_range(profile.get("portions"), 0, 16)


static func whole_in_range(value: Variant, minimum: int, maximum: int) -> bool:
	if typeof(value) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(value)):
		return false
	return float(value) == floorf(float(value)) and float(value) >= minimum and float(value) <= maximum


static func parse(source: String, food: bool) -> Dictionary:
	if source.length() > 1200:
		return {"error": "Слишком длинная запись"}
	var profile := {"effects": []}
	var lines := source.split("\n")
	for index in lines.size():
		var line: String = lines[index].replace("\t", " ").strip_edges()
		if line.is_empty():
			continue
		var parts := line.split(" ", false)
		var key := parts[0].to_upper()
		if food and key == "EDIBLE" and parts.size() == 2 and not profile.has("edible"):
			if parts[1].to_lower() not in ["true", "false"]:
				return _line_error(index, "EDIBLE принимает true или false")
			profile["edible"] = parts[1].to_lower() == "true"
		elif food and key == "PORTIONS" and parts.size() == 2 and not profile.has("portions"):
			if not parts[1].is_valid_int() or not whole_in_range(int(parts[1]), 0, 16):
				return _line_error(index, "PORTIONS принимает целое от 0 до 16")
			profile["portions"] = int(parts[1])
		else:
			if not EFFECTS.has(key) or (food and not EFFECTS[key]["food"]):
				return _line_error(index, "Неизвестное или несовместимое поле «%s»" % key)
			var maximum: int = EFFECTS[key]["max"]
			var effect := {"id": key}
			if maximum > 0:
				if parts.size() != 2 or not parts[1].is_valid_int() or not whole_in_range(int(parts[1]), 1, maximum):
					return _line_error(index, "%s принимает целое от 1 до %d" % [key, maximum])
				effect["value"] = int(parts[1])
			elif parts.size() != 1:
				return _line_error(index, "%s не принимает аргумент" % key)
			profile["effects"].append(effect)
			if not valid_effects(profile["effects"], food):
				return _line_error(index, "Эффект повторяется или превышен предел действий")
	if not valid_profile(profile, food):
		return {"error": "Для еды нужны поля EDIBLE и PORTIONS"}
	return {"profile": profile}


static func format(profile: Dictionary) -> String:
	var lines := PackedStringArray()
	if profile.has("edible"):
		lines.append("EDIBLE %s" % str(profile["edible"]))
		lines.append("PORTIONS %d" % int(profile["portions"]))
	for effect: Dictionary in profile["effects"]:
		var id: String = effect["id"]
		lines.append("%s %d" % [id, int(effect["value"])] if effect.has("value") else id)
	return "\n".join(lines)


static func _line_error(index: int, message: String) -> Dictionary:
	return {"error": "Строка %d. %s" % [index + 1, message]}
