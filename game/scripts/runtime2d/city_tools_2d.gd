extends RefCounted
## Ordinary discoveries, experiment provenance and temporary grants. No rare
## module is copied into ABILITY_SET; the stamp only creates a timed adapter.
const TOOLS := ["BESTIARY", "REALITY_STAMP", "GRAVITY_GUN", "PIXEL_GLOBE", "LUNA_ROOM_DOOR"]
const SPECIES := {"cat": "Коты", "fox": "Лисы", "ray": "Скаты", "lizard": "Ящерицы", "trollik": "Троллики", "fish": "Рыбы", "mirror_snail": "Зеркальные улитки", "crab": "Крабы", "turtle": "Черепахи", "yeti": "Йетти", "mouse": "Мыши"}
const STAMP_SECONDS := 8.0
var owned: Array[String] = []
var seen: Array[String] = []
var visited: Array[String] = []
var stamped: Dictionary = {}
var cat_sizes: Dictionary = {}
var cleanup := 0.0
var mouse_size := 0.0
var mouse_time := 0.0
var ori_stage := 0


func acquire(key: String) -> bool:
	if key not in TOOLS or key in owned:
		return false
	owned.append(key)
	return true


func observe(form: String) -> void:
	if SPECIES.has(form) and form not in seen:
		seen.append(form)


func snapshot() -> Dictionary:
	return {"owned": owned.duplicate(), "seen": seen.duplicate(), "visited": visited.duplicate(),
		"stamped": stamped.duplicate(true), "cat_sizes": cat_sizes.duplicate(true), "cleanup": cleanup,
		"mouse_size": mouse_size, "mouse_time": mouse_time, "ori_stage": ori_stage}


static func number(value: Variant, low: float, high: float) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) and float(value) >= low and float(value) <= high


static func checked_ids(value: Variant, limit: int, allowed: Array = []) -> bool:
	if not value is Array or value.size() > limit:
		return false
	var unique := {}
	for id in value:
		if not id is String or id.length() > 96 or not id.is_valid_identifier() or unique.has(id) or (not allowed.is_empty() and id not in allowed):
			return false
		unique[id] = true
	return true


func restore(data: Variant) -> bool:
	if not data is Dictionary or data.size() != 9:
		return false
	if not checked_ids(data.get("owned"), TOOLS.size(), TOOLS) or not checked_ids(data.get("seen"), SPECIES.size(), SPECIES.keys()) or not checked_ids(data.get("visited"), 16):
		return false
	if not number(data.get("cleanup"), 0.0, 10.0) or not number(data.get("mouse_size"), 0.0, 2.0) or not number(data.get("mouse_time"), 0.0, 10.0):
		return false
	if float(data["mouse_size"]) > 0.0 and float(data["mouse_size"]) < 0.5:
		return false
	var stage: Variant = data.get("ori_stage")
	if not number(stage, 0.0, 3.0) or float(stage) != floorf(float(stage)):
		return false
	var grants: Variant = data.get("stamped")
	var cats: Variant = data.get("cat_sizes")
	if not grants is Dictionary or grants.size() > 12 or not cats is Dictionary or cats.size() > 8:
		return false
	for id in grants:
		var grant: Variant = grants[id]
		if not id is String or not id.is_valid_identifier() or id.length() > 96 or not grant is Dictionary or grant.size() != 2 or grant.get("ability") not in ["GLOW", "FLY"] or not number(grant.get("remaining"), 0.0, STAMP_SECONDS):
			return false
	for id in cats:
		if not id is String or not id.begins_with("YUKI_CAT_") or not id.trim_prefix("YUKI_CAT_").is_valid_int() or not number(cats[id], 0.5, 2.0):
			return false
	owned.assign(data["owned"])
	seen.assign(data["seen"])
	visited.assign(data["visited"])
	stamped = grants.duplicate(true)
	cat_sizes = cats.duplicate(true)
	cleanup = float(data["cleanup"])
	mouse_size = float(data["mouse_size"])
	mouse_time = float(data["mouse_time"])
	ori_stage = int(stage)
	return true
