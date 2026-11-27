extends RefCounted
## Chapter VIII, three permanent bodies; the echoes are rendering only.
const FOX := "D2_GLITCH_FOX"
const CAT := "D3_RETURN_CAT"
const RABBIT := "D3_DOUBLE_RABBIT"
const DEFINITIONS := [
	{"id": FOX, "category": "glitch_fox", "label": "Глитч-лиса", "material": "FABRIC", "point": Vector2(3420, 1175), "size": 0.85, "speed": 0.85, "color": "684a96"},
	{"id": CAT, "category": "return_cat", "label": "Возвратный кот", "material": "FABRIC", "point": Vector2(3630, 1150), "size": 0.75, "speed": 0.65, "color": "b790dd"},
	{"id": RABBIT, "category": "double_rabbit", "label": "Двоящийся кролик", "material": "FABRIC", "point": Vector2(3740, 1180), "size": 0.6, "speed": 0.7, "color": "87bfe8"},
]
const FOX_ROUTE := [Vector2(3420, 1175), Vector2(3500, 1190), Vector2(3485, 1105), Vector2(3400, 1110)]
const CAT_ROUTE := [Vector2(3630, 1150), Vector2(3635, 1200), Vector2(3700, 1200), Vector2(3680, 1110)]
const RABBIT_ROUTE := [Vector2(3740, 1180), Vector2(3780, 1160), Vector2(3760, 1100), Vector2(3720, 1140)]
const FOX_BOUNDS := Rect2(3360, 1075, 220, 155)
const CAT_BOUNDS := Rect2(3590, 1080, 135, 145)
const RABBIT_BOUNDS := Rect2(3710, 1085, 105, 140)
const CAT_DELAYS := [2, 4, 6]

var blink := true
var cat_delay := 4
var fox_elapsed := 0.0
var cat_elapsed := 0.0
var rabbit_elapsed := 0.0
var fox_index := 0
var cat_index := 0
var rabbit_index := 0
var cat_history: Array[Vector2] = []
var fox_echo := Vector2.INF
var fox_echo_time := 0.0
var rabbit_echo := Vector2.INF


func snapshot() -> Dictionary:
	return {"blink": blink, "cat_delay": cat_delay, "fox_index": fox_index, "cat_index": cat_index, "rabbit_index": rabbit_index, "fox_elapsed": fox_elapsed, "cat_elapsed": cat_elapsed, "rabbit_elapsed": rabbit_elapsed}


static func number(value: Variant, maximum: float) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) and float(value) >= 0.0 and float(value) <= maximum


static func integer(value: Variant, maximum: int) -> bool:
	return number(value, maximum) and float(value) == floorf(float(value))


func restore(data: Variant) -> bool:
	if not data is Dictionary or data.size() != 8 or not data.get("blink") is bool or not integer(data.get("cat_delay"), 6) or int(data["cat_delay"]) not in CAT_DELAYS:
		return false
	for key in ["fox_index", "cat_index", "rabbit_index"]:
		if not integer(data.get(key), 3):
			return false
	for key in ["fox_elapsed", "cat_elapsed", "rabbit_elapsed"]:
		if not number(data.get(key), 6.0):
			return false
	blink = data["blink"]
	cat_delay = int(data["cat_delay"])
	fox_index = int(data["fox_index"])
	cat_index = int(data["cat_index"])
	rabbit_index = int(data["rabbit_index"])
	fox_elapsed = float(data["fox_elapsed"])
	cat_elapsed = float(data["cat_elapsed"])
	rabbit_elapsed = float(data["rabbit_elapsed"])
	return true
