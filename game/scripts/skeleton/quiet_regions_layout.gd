extends RefCounted
## Temporary 2D+Z blockout for unstructured walks. Art and collision stay separate.
## These are extensions of existing canonical addresses, never secret entrances.

const FOREST := Rect2(1760, -350, 225, 255)
const COAST := Rect2(2215, 820, 125, 230)
const CITY := Rect2(5320, 420, 185, 270)
const MOUNTAIN := Rect2(1210, 1380, 300, 140)
const REGIONS := [
	{"bounds": FOREST, "address": "ET_FAIRY_FOREST", "entry": Vector2(1890, -75), "view": Vector2(1890, -300)},
	{"bounds": COAST, "address": "ET_COAST", "entry": Vector2(2290, 795), "view": Vector2(2290, 1010)},
	{"bounds": CITY, "address": "ET_LUMA_CITY", "entry": Vector2(5280, 530), "view": Vector2(5470, 530)},
	{"bounds": MOUNTAIN, "address": "ET_MOUNTAINS", "entry": Vector2(1560, 1460), "view": Vector2(1260, 1460)},
]
const FAUNA := {
	"F_QUIET_FOX": {"category": "fox", "label": "Лисичка", "point": Vector2(1815, -240), "size": 0.8, "speed": 0.8},
	"F_QUIET_TURTLE": {"category": "turtle", "label": "Черепашка", "point": Vector2(1940, -275), "size": 0.7, "speed": 0.3},
	"K_QUIET_CRAB": {"category": "crab", "label": "Краб", "point": Vector2(2250, 900), "size": 0.6, "speed": 0.5},
	"K_QUIET_TURTLE": {"category": "turtle", "label": "Черепашка", "point": Vector2(2305, 960), "size": 0.8, "speed": 0.3},
	"C_QUIET_CAT": {"category": "cat", "label": "Котик", "point": Vector2(5440, 620), "size": 0.7, "speed": 0.9},
}


static func address(point: Vector2) -> String:
	for region in REGIONS:
		var bounds: Rect2 = region["bounds"]
		if bounds.has_point(point):
			return region["address"]
	return ""


static func decks() -> Array[Rect2]:
	var result: Array[Rect2] = []
	for region in REGIONS:
		result.append(region["bounds"])
	return result
