extends RefCounted
## Arcane vocabulary. Friendly magical blocks and the typed simulation share
## one recipe. Legacy five-field recipes are normalized in memory on loading.

const CREATIONS = [
	{"id": "ENERGY", "name": "Энергия"},
	{"id": "OBJECT", "name": "Предмет"},
	{"id": "CREATURE", "name": "Существо"}
]
const SHAPES = [
	{"id": "ORB", "name": "Сфера"},
	{"id": "SHARD", "name": "Кристалл"},
	{"id": "BOLT", "name": "Разряд"}
]
const ELEMENTS = [
	{"id": "FIRE", "name": "Огонь", "tint": Color("ff884a")},
	{"id": "FROST", "name": "Лёд", "tint": Color("9edffa")},
	{"id": "STORM", "name": "Молния", "tint": Color("e6d77a")}
]
const BEHAVIORS = [
	{"id": "SEEK", "name": "Искать цель"},
	{"id": "STRAIGHT", "name": "Лететь прямо"},
	{"id": "WANDER", "name": "Бродить"},
	{"id": "FOLLOW", "name": "Следовать"},
	{"id": "CHASE", "name": "Преследовать"},
	{"id": "FLEE", "name": "Убегать"},
	{"id": "IDLE", "name": "Бездействовать"}
]
const RELEASES = [
	{"id": "PROJECTILE", "name": "Запустить"},
	{"id": "PLACE", "name": "Создать рядом с целью"}
]
# Previous spell definitions used FORMS / ESSENCES / DELIVERIES.
const FORMS = SHAPES
const ESSENCES = ELEMENTS
const DELIVERIES = RELEASES

const DEFAULT_SPEED := 14.0
const DEFAULT_SIZE := 0.42

const LEGACY_KEYS = ["form", "essence", "delivery", "speed", "size"]
const CURRENT_KEYS = ["create", "shape", "element", "behavior", "release", "speed", "size"]


static func make(shape: String, element: String, speed: float = DEFAULT_SPEED, size: float = DEFAULT_SIZE) -> Dictionary:
	# Keeping this signature preserves existing game tests and spell definitions.
	return make_recipe("ENERGY", shape, element, "SEEK", "PROJECTILE", speed, size)


static func make_recipe(create: String, shape: String, element: String, behavior: String, release: String, speed: float = DEFAULT_SPEED, size: float = DEFAULT_SIZE) -> Dictionary:
	return {
		"create": create, "shape": shape, "element": element,
		"behavior": behavior, "release": release,
		"speed": speed, "size": size
	}


static func normalize(recipe: Dictionary) -> Dictionary:
	if recipe.is_empty():
		return {}
	if _has_exact_fields(recipe, LEGACY_KEYS):
		if recipe["delivery"] != "PROJECTILE":
			return {}
		for number in ["speed", "size"]:
			if typeof(recipe[number]) not in [TYPE_INT, TYPE_FLOAT]:
				return {}
		return make(str(recipe["form"]), str(recipe["essence"]),
			float(recipe["speed"]), float(recipe["size"]))
	if _has_exact_fields(recipe, CURRENT_KEYS):
		return recipe.duplicate(true)
	return {}


static func valid(recipe: Dictionary) -> bool:
	if recipe.is_empty():
		return true # Existing instant-effect spells remain valid.
	var parsed := normalize(recipe)
	if parsed.is_empty():
		return false
	if not _has_id(CREATIONS, parsed["create"]):
		return false
	if not _has_id(SHAPES, parsed["shape"]):
		return false
	if not _has_id(ELEMENTS, parsed["element"]):
		return false
	if not _has_id(BEHAVIORS, parsed["behavior"]):
		return false
	if not _has_id(RELEASES, parsed["release"]):
		return false
	for key in ["speed", "size"]:
		if typeof(parsed[key]) not in [TYPE_FLOAT, TYPE_INT]:
			return false
		var amount: float = float(parsed[key])
		if is_nan(amount) or is_inf(amount):
			return false
	return float(parsed["speed"]) >= 3.0 and float(parsed["speed"]) <= 30.0 \
		and float(parsed["size"]) >= 0.15 and float(parsed["size"]) <= 0.9


static func readable(recipe: Dictionary) -> String:
	if recipe.is_empty():
		return "Прямое воздействие"
	var parsed := normalize(recipe)
	if not valid(parsed):
		return "Неизвестная магия"
	return "%s · %s · %s · %s" % [
		_name(CREATIONS, str(parsed["create"])),
		_name(SHAPES, str(parsed["shape"])),
		_name(ELEMENTS, str(parsed["element"])),
		_name(RELEASES, str(parsed["release"]))
	]


static func tint(element: String) -> Color:
	for item in ELEMENTS:
		if item["id"] == element:
			return item["tint"]
	return Color("d8b8f8")


static func _has_exact_fields(source: Dictionary, fields: Array) -> bool:
	if source.size() != fields.size():
		return false
	for key in fields:
		if not source.has(key):
			return false
	return true


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
