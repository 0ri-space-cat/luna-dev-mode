extends RefCounted
## Temporary 2D+Z blockout for unstructured walks. Art and collision stay separate.
## These are extensions of existing canonical addresses, never secret entrances.

const FOREST := Rect2(1760, -350, 225, 255)
const COAST := Rect2(2215, 820, 125, 230)
const CITY := Rect2(5320, 420, 185, 270)
const MOUNTAIN := Rect2(1210, 1380, 300, 140)
# Above the existing lake shore, clear of the forest service room and crystal bridge.
const LAKE := Rect2(2600, 125, 145, 175)
# A dead-end terrace inside D1, never an alternate entrance to the Edge.
const EDGE := Rect2(3510, 795, 110, 175)
const V1_REGION_COUNT := 4
const V2_FAUNA_IDS := ["W_QUIET_LIZARD", "W_QUIET_TURTLE"]
const REGIONS := [
	{"bounds": FOREST, "address": "ET_FAIRY_FOREST", "entry": Vector2(1890, -75), "view": Vector2(1890, -300)},
	{"bounds": COAST, "address": "ET_COAST", "entry": Vector2(2290, 795), "view": Vector2(2290, 1010)},
	{"bounds": CITY, "address": "ET_LUMA_CITY", "entry": Vector2(5280, 530), "view": Vector2(5470, 530)},
	{"bounds": MOUNTAIN, "address": "ET_MOUNTAINS", "entry": Vector2(1560, 1460), "view": Vector2(1260, 1460)},
	{"bounds": LAKE, "address": "ET_DUPLICATE_LAKE_CAVERN", "entry": Vector2(2670, 315), "view": Vector2(2670, 160)},
	{"bounds": EDGE, "address": "ET_FORGOTTEN_EDGE", "entry": Vector2(3565, 1000), "view": Vector2(3565, 825)},
]
const FAUNA := {
	"F_QUIET_FOX": {"category": "fox", "label": "Лисичка", "point": Vector2(1815, -240), "size": 0.8, "speed": 0.8},
	"F_QUIET_TURTLE": {"category": "turtle", "label": "Черепашка", "point": Vector2(1940, -275), "size": 0.7, "speed": 0.3},
	"K_QUIET_CRAB": {"category": "crab", "label": "Краб", "point": Vector2(2250, 900), "size": 0.6, "speed": 0.5},
	"K_QUIET_TURTLE": {"category": "turtle", "label": "Черепашка", "point": Vector2(2305, 960), "size": 0.8, "speed": 0.3},
	"C_QUIET_CAT": {"category": "cat", "label": "Котик", "point": Vector2(5440, 620), "size": 0.7, "speed": 0.9},
	"W_QUIET_LIZARD": {"category": "lizard", "label": "Ящерка", "point": Vector2(2630, 205), "size": 0.6, "speed": 0.8},
	"W_QUIET_TURTLE": {"category": "turtle", "label": "Черепашка", "point": Vector2(2710, 240), "size": 0.9, "speed": 0.4},
}


static func address(point: Vector2, include_v2: bool = true) -> String:
	for index in range(REGIONS.size() if include_v2 else V1_REGION_COUNT):
		var region: Dictionary = REGIONS[index]
		var bounds: Rect2 = region["bounds"]
		if bounds.has_point(point):
			return region["address"]
	return ""


static func decks() -> Array[Rect2]:
	var result: Array[Rect2] = []
	for region in REGIONS:
		result.append(region["bounds"])
	return result
