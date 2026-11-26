extends RefCounted
## Permanent L1 ecology. The state of perception never creates or deletes a body.
const GIANT := "C6_WALKING_GIANT"
const JOY := "M2_JOY_EMOT"
const CURIOUS := "F3_CURIOUS_EMOT"
const SPECIES := {"emot": "Эмоты", "emot_giant": "Шагающие гиганты"}
const DEFINITIONS := [
	{"id": GIANT, "category": "emot_giant", "label": "Шагающий гигант", "material": "FABRIC", "point": Vector2(5310, 155), "size": 2.0, "speed": 0.65},
	{"id": JOY, "category": "emot", "label": "Радостный эмот", "material": "FABRIC", "point": Vector2(1745, 420), "size": 0.8, "speed": 0.7},
	{"id": CURIOUS, "category": "emot", "label": "Любопытный эмот", "material": "FABRIC", "point": Vector2(2150, 118), "size": 0.8, "speed": 0.6},
]
const GIANT_RANGE := Rect2(5205, 112, 145, 128)
const NICHE := Rect2(5055, 108, 85, 76)
const TOFFI_ROUTE := [Vector2(4620, 455), Vector2(4745, 455), Vector2(5020, 455), Vector2(5150, 320), Vector2(5150, 240), Vector2(5150, 145), Vector2(5095, 145)]
const MONUMENT := {"bounds": Rect2(2055, 118, 32, 22), "height": 85.0, "layer": 2}
const MONUMENT_ZONE := Rect2(1995, 80, 145, 82)
const MONUMENT_POINT := Vector2(2071, 129)
const COMMANDS := ["TIME_OF_DAY NIGHT", "TIME_OF_DAY DAY", "SPAWN FOX", "TELEPORT ET_MEADOWS_MAIN"]
const REVEAL_RANGE := 290.0
var stage := 0 # 0 no lantern, 1 original loan, 2 original gift
var active := false
var seen_giant := false
var station_seen := false
var route_index := 0
var seen: Array[String] = []
var monument_index := 0
var in_monument_zone := false


func observe(category: String) -> void:
	if SPECIES.has(category) and category not in seen:
		seen.append(category)


func visit(inside: bool) -> bool:
	var changed := inside and not in_monument_zone
	if changed:
		monument_index = (monument_index + 1) % COMMANDS.size()
	in_monument_zone = inside
	return changed


func snapshot() -> Dictionary:
	return {"stage": stage, "active": active, "seen_giant": seen_giant, "station_seen": station_seen, "route_index": route_index, "seen": seen.duplicate(), "monument_index": monument_index, "in_monument_zone": in_monument_zone}


static func _integer(value: Variant, maximum: int) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) and float(value) == floorf(float(value)) and float(value) >= 0 and float(value) <= maximum


func restore(data: Variant) -> bool:
	if not data is Dictionary or data.size() != 8:
		return false
	for key in ["active", "seen_giant", "station_seen", "in_monument_zone"]:
		if not data.get(key) is bool:
			return false
	if not _integer(data.get("stage"), 2) or not _integer(data.get("route_index"), TOFFI_ROUTE.size() - 1) or not _integer(data.get("monument_index"), COMMANDS.size() - 1):
		return false
	var forms: Variant = data.get("seen")
	if not forms is Array or forms.size() > SPECIES.size():
		return false
	var checked: Array[String] = []
	for form in forms:
		if not form is String or not SPECIES.has(form) or form in checked:
			return false
		checked.append(form)
	if int(data["stage"]) == 0 and (data["active"] or data["seen_giant"] or not checked.is_empty()):
		return false
	if int(data["stage"]) == 2 and not data["seen_giant"]:
		return false
	if data["seen_giant"] and "emot_giant" not in checked:
		return false
	stage = int(data["stage"])
	active = data["active"]
	seen_giant = data["seen_giant"]
	station_seen = data["station_seen"]
	route_index = int(data["route_index"])
	seen = checked
	monument_index = int(data["monument_index"])
	in_monument_zone = data["in_monument_zone"]
	return true


static func footfall() -> AudioStreamWAV:
	var sample := AudioStreamWAV.new()
	sample.format = AudioStreamWAV.FORMAT_16_BITS
	sample.mix_rate = 22050
	var frames := 3000
	var bytes := PackedByteArray()
	bytes.resize(frames * 2)
	for i in range(frames):
		var t := float(i) / float(sample.mix_rate)
		var envelope := minf(float(i) / 120.0, 1.0) * exp(-t * 32.0)
		bytes.encode_s16(i * 2, roundi((sin(TAU * 58.0 * t) + 0.3 * sin(TAU * 83.0 * t)) * envelope * 10000.0))
	sample.data = bytes
	return sample
