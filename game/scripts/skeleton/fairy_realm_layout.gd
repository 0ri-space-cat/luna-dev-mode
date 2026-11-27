extends RefCounted
## F4: physical paths inside the existing Fairy Realm address.

const ID := "ET_FAIRY_REALM"
const ENTRY := Vector2(2005, -92)
const FOREST_RETURNS := [Vector2(1978, -80), Vector2(1940, 24), Vector2(1888, 52)]
const ROOTS := Rect2(7080, 180, 540, 258)
const ROOT_ENTRY := Vector2(7115, 317)
const ROOT_FAR := Vector2(7550, 317)
const ROOT_END_X := 7490.0
const ROOT_START_X := 7210.0
const ROOT_WALLS := [
	{"bounds": Rect2(7285, 248, 180, 61), "height": 108.0, "layer": 2},
	{"bounds": Rect2(7285, 327, 180, 80), "height": 108.0, "layer": 2},
]
const GROVE := Rect2(7080, 1390, 492, 265)
const GROVE_OFFSET := Vector2(0, 1190)
const GROVE_COUNT := 4
const GROVE_ARRIVAL := Vector2(7315, 1603)
const GROVE_RETURN := Vector2(7120, 1603)
const GROVE_EXIT := Vector2(7524, 1603)
const THRESHOLDS := [Vector2(7135, 1440), Vector2(7251, 1440), Vector2(7367, 1440), Vector2(7483, 1440)]
const MOTIFS := [0, 1, 2, 3]
const EARLY := Rect2(7080, 6280, 510, 310)
const LATE := Rect2(7080, 7500, 510, 290)
const EARLY_WATCH := Vector2(7145, 6485)
const EARLY_REPLAY := Vector2(7250, 6436)
const EARLY_EXIT := Vector2(7120, 6518)
const EARLY_TO_LATE := Vector2(7548, 6460)
const FOX_RUSH := Vector2(7130, 6436)
const FOX_LATE := Vector2(7395, 7648)
const LATE_ARRIVAL := Vector2(7505, 7700)
const LATE_EXIT := Vector2(7120, 7725)
const LATE_SEAM := Vector2(7185, 7648)
const BARRIER := {"bounds": Rect2(7350, 6370, 18, 116), "height": 92.0, "layer": 32}
const FOX_ID := "Q12C_SLIME_FOX"
const CANOPY := Rect2(7080, 8640, 200, 160)
const CANOPY_FAR := Rect2(7370, 8640, 240, 160)
const CANOPY_SPAN := {"bounds": Rect2(7270, 8700, 111, 49), "height": 0.0,
	"safe": false, "feature_id": "BRIDGE_II_FAIRY_CANOPY"}
const CANOPY_LOWER := {"bounds": Rect2(7240, 8645, 180, 150), "height": -30.0, "safe": false}
const CANOPY_DOOR := {"bounds": Rect2(7452, 8637, 14, 166), "height": 85.0,
	"layer": 64, "feature_id": "DOOR_EYES_CLOSED_FAIRY"}
const CANOPY_ENTRY := Vector2(7140, 8724)
const CANOPY_EXIT := Vector2(7120, 8755)
const CANOPY_SIDE_EXIT := Vector2(7410, 8755)
const CANOPY_NEAR := Vector2(7548, 6518)
const CANOPY_RESIDENT := "F4_CANOPY_FAIRY"
const CANOPY_RESIDENT_START := Vector2(7412, 8682)
const CANOPY_RESIDENT_END := Vector2(7512, 8682)
const REACH := 25.0

static func grove(index: int) -> Rect2:
	return Rect2(GROVE.position + GROVE_OFFSET * index, GROVE.size)


static func decks() -> Array[Rect2]:
	var result: Array[Rect2] = [ROOTS, EARLY, LATE, CANOPY, CANOPY_FAR]
	for index in GROVE_COUNT:
		result.append(grove(index))
	return result


static func owns(point: Vector2) -> bool:
	return room_at(point).has_area() or CANOPY_LOWER["bounds"].has_point(point)


static func room_at(point: Vector2) -> Rect2:
	for candidate: Rect2 in [ROOTS, EARLY, LATE, CANOPY, CANOPY_FAR]:
		if candidate.has_point(point):
			return candidate
	for index in GROVE_COUNT:
		var candidate := grove(index)
		if candidate.has_point(point):
			return candidate
	return Rect2()


static func grove_index(point: Vector2) -> int:
	for index in GROVE_COUNT:
		if grove(index).has_point(point):
			return index
	return -1


static func take_near(point: Vector2, target: Vector2) -> bool:
	return point.distance_squared_to(target) <= REACH * REACH
