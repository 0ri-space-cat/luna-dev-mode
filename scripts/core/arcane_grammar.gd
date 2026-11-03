extends RefCounted
## Small, typed vocabulary for visible magic. The player sees readable cards;
## these values are a shared recipe, not scripts per spell.

const FORMS = [
	{"id": "ORB", "name": "Шар"},
	{"id": "SHARD", "name": "Осколок"},
	{"id": "BOLT", "name": "Разряд"}
]
const ESSENCES = [
	{"id": "FIRE", "name": "Огонь", "tint": Color("ff884a")},
	{"id": "FROST", "name": "Лёд", "tint": Color("9edffa")},
	{"id": "STORM", "name": "Молния", "tint": Color("e6d77a")}
]
const DELIVERIES = [{"id": "PROJECTILE", "name": "Снаряд"}]

const DEFAULT_SPEED := 14.0
const DEFAULT_SIZE := 0.42


static func valid(recipe: Dictionary) -> bool:
	if recipe.is_empty():
		return true # Legacy instant parameter spells still work.
	if recipe.size() != 5:
		return false
	for key in ["form", "essence", "delivery", "speed", "size"]:
		if not recipe.has(key):
			return false
	if not _has_id(FORMS, recipe["form"]):
		return false
	if not _has_id(ESSENCES, recipe["essence"]):
		return false
	if not _has_id(DELIVERIES, recipe["delivery"]):
		return false
	for key in ["speed", "size"]:
		if typeof(recipe[key]) not in [TYPE_FLOAT, TYPE_INT]:
			return false
		var amount: float = float(recipe[key])
		if is_nan(amount) or is_inf(amount):
			return false
	return float(recipe["speed"]) >= 3.0 and float(recipe["speed"]) <= 30.0 and float(recipe["size"]) >= 0.15 and float(recipe["size"]) <= 0.9


static func make(form: String, essence: String, speed: float = DEFAULT_SPEED, size: float = DEFAULT_SIZE) -> Dictionary:
	return {"form": form, "essence": essence, "delivery": "PROJECTILE", "speed": speed, "size": size}


static func readable(recipe: Dictionary) -> String:
	if recipe.is_empty():
		return "Прямое воздействие"
	return "%s · %s · %s" % [
		_name(FORMS, str(recipe.get("form", ""))),
		_name(ESSENCES, str(recipe.get("essence", ""))),
		_name(DELIVERIES, str(recipe.get("delivery", "")))
	]


static func tint(essence: String) -> Color:
	for item in ESSENCES:
		if item["id"] == essence:
			return item["tint"]
	return Color("d8b8f8")


static func _has_id(options: Array, value: Variant) -> bool:
	if typeof(value) != TYPE_STRING:
		return false
	for item in options:
		if item["id"] == value:
			return true
	return false


static func _name(options: Array, id: String) -> String:
	for item in options:
		if item["id"] == id:
			return str(item["name"])
	return id
