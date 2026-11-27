extends RefCounted
## W8 temporary physical graybox; no production art or final map.
const PASSAGE := "ET_CRYSTAL_UNDERSIDE_PASSAGE"
const REFUGE := "ET_UNDERSIDE_REFUGE_01"
const BRIDGE_ID := "BRIDGE_UNDERSIDE_A"
const DOOR_ID := "DOOR_UNDERSIDE_REFUGE"
const APPROACH := Rect2(3040, 480, 90, 125)
const BRIDGE := {"bounds": Rect2(3040, 580, 90, 110), "height": 0.0, "safe": false, "feature_id": BRIDGE_ID}
const LANDING := Rect2(3030, 665, 120, 85)
const SEAM := {"bounds": Rect2(3036, 563, 98, 12), "height": 128.0, "layer": 16, "feature_id": DOOR_ID}
const ROOM := Rect2(4060, 555, 190, 145)
const NEAR := Vector2(3085, 540)
const FAR := Vector2(3085, 713)
const ENTRY := Vector2(4100, 655)
const NOTE := Vector2(4200, 610)


static func address(point: Vector2) -> String:
	if ROOM.has_point(point):
		return REFUGE
	if APPROACH.has_point(point) or LANDING.has_point(point) or BRIDGE["bounds"].has_point(point):
		return PASSAGE
	return ""


static func draw_on(canvas: Node2D, outside: bool) -> void:
	# Plain structural outlines, never imported art. Do not label hidden content
	# on the ordinary side of the seam.
	if outside:
		canvas.draw_rect(BRIDGE["bounds"], Color("527c9d"))
		canvas.draw_line(Vector2(3085, 563), Vector2(3085, 687), Color("9ccef0"), 2.0)
		canvas.draw_rect(Rect2(FAR - Vector2(11, 16), Vector2(22, 30)), Color("9ccef0"), false, 2.0)
	canvas.draw_rect(Rect2(NOTE - Vector2(18, 12), Vector2(36, 24)), Color("bdb0a5"))
