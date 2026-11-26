extends RefCounted
## C0/C1 and the public interiors. Only approved canonical addresses are exposed.
const CITY_ID := "ET_LUMA_CITY"
const CAFE_ID := "ET_LUMA_CAFE"
const HOME_ID := "ET_LUNA_ROOM"
const MEADOWS_STATION := Vector2(1945, 590)
const STATION := Rect2(4500, 320, 265, 240)
const STREET := Rect2(4720, 375, 320, 165)
const PLAZA := Rect2(4990, 260, 370, 335)
const NORTH := Rect2(4700, 210, 350, 180)
const SOUTH := Rect2(4930, 515, 430, 220)
const ARRIVAL := Vector2(4560, 448)
const BOARD := Vector2(4540, 395)
const CAFE := Rect2(5550, 220, 275, 205)
const ROOM := Rect2(5890, 220, 245, 205)
const WORKSHOP := Rect2(5550, 515, 280, 205)
const SHOP := Rect2(5890, 515, 280, 205)
const MAP := Rect2(4735, 240, 110, 90)
const TABLE := {"bounds": Rect2(5680, 270, 92, 60), "height": 6.0, "walk_up": true}
const DECKS := [STATION, STREET, PLAZA, NORTH, SOUTH, CAFE, ROOM, WORKSHOP, SHOP]
const DOORS := [
	{"id": "cafe", "name": "Кафе", "outside": Vector2(5130, 315), "inside": Vector2(5590, 390), "address": CAFE_ID},
	{"id": "room", "name": "Комната Луны", "outside": Vector2(5295, 550), "inside": Vector2(5930, 390), "address": HOME_ID},
	{"id": "workshop", "name": "Мастерская Юки", "outside": Vector2(4935, 260), "inside": Vector2(5590, 685), "address": CITY_ID},
	{"id": "shop", "name": "Магазин Ори", "outside": Vector2(5165, 660), "inside": Vector2(5930, 685), "address": CITY_ID},
]
const WALLS := [
	{"bounds": Rect2(5615, 228, 130, 20), "height": 80.0, "layer": 2},
	{"bounds": Rect2(5975, 240, 100, 45), "height": 24.0, "layer": 2},
	{"bounds": Rect2(5680, 530, 125, 35), "height": 36.0, "layer": 2},
	{"bounds": Rect2(6025, 530, 115, 32), "height": 36.0, "layer": 2},
]
const BREAD := "C2_BREAD"
const BENCH := "C1_BENCH"
const CAT := "C1_CAT"
const RAY := "C0_RESTING_RAY"
const TOFFI := "C0_TOFFI"
const YUKI := "C4_YUKI"
const ORI := "C3_ORI"
const CRATE := "C0_CRATE"
const BENCH_ROUTE := [Vector2(5020, 465), Vector2(4830, 465), Vector2(4685, 465)]
const RAY_REST := Vector2(4615, 500)
const DEFINITIONS := [
	{"id": BREAD, "category": "prop", "label": "Хлебушек", "material": "FABRIC", "point": Vector2(5720, 300), "height": 6.0},
	{"id": BENCH, "category": "prop", "label": "Скамейка", "material": "WOOD", "point": Vector2(5020, 465), "height": 0.0},
	{"id": CAT, "category": "cat", "label": "Котик", "material": "FABRIC", "point": Vector2(5200, 425), "height": 0.0},
	{"id": RAY, "category": "ray", "label": "Маленький скат", "material": "FABRIC", "point": Vector2(4690, 500), "height": 0.0},
	{"id": TOFFI, "category": "toffi", "label": "Тоффи", "material": "FABRIC", "point": Vector2(4620, 455), "height": 0.0},
	{"id": YUKI, "category": "yuki", "label": "Юки", "material": "FABRIC", "point": Vector2(5700, 620), "height": 0.0},
	{"id": ORI, "category": "ori", "label": "Ори", "material": "FABRIC", "point": Vector2(6050, 620), "height": 0.0},
	{"id": CRATE, "category": "prop", "label": "Ящик", "material": "WOOD", "point": Vector2(4670, 355), "height": 0.0},
]


static func location_at(point: Vector2) -> String:
	if CAFE.has_point(point):
		return CAFE_ID
	if ROOM.has_point(point):
		return HOME_ID
	for deck in DECKS:
		if deck.has_point(point):
			return CITY_ID
	return ""


static func draw_on(canvas: Node2D) -> void:
	var font := ThemeDB.fallback_font
	for deck in DECKS:
		canvas.draw_rect(deck, Color("8984a2") if deck in [CAFE, ROOM, WORKSHOP, SHOP] else Color("a6a0b5"))
		canvas.draw_rect(deck.grow(-4.0), Color("bdb2c8"), false, 1.0)
	canvas.draw_rect(Rect2(4510, 335, 225, 35), Color("756b94"))
	for x in range(4530, 4730, 43):
		canvas.draw_rect(Rect2(x, 341, 22, 20), Color("e5d7a7"))
	canvas.draw_string(font, Vector2(4518, 380), "Вокзал скатов")
	canvas.draw_circle(BOARD, 12.0, Color("85b9c4"), false, 2.0)
	canvas.draw_circle(MEADOWS_STATION, 12.0, Color("85b9c4"), false, 2.0)
	canvas.draw_string(font, MEADOWS_STATION + Vector2(-70, -19), "Рейс в Люму")
	canvas.draw_string(font, Vector2(5020, 400), "Площадь")
	canvas.draw_rect(MAP, Color("778a9e"))
	canvas.draw_string(font, Vector2(4740, 265), "Карты")
	for wall in WALLS:
		canvas.draw_rect(wall["bounds"], Color("776679"))
		canvas.draw_rect(wall["bounds"], Color("bba8ba"), false, 1.5)
	canvas.draw_rect(TABLE["bounds"], Color("977b75"))
	canvas.draw_rect(TABLE["bounds"].grow(-4), Color("bfa299"))
	for doorway in DOORS:
		for key in ["outside", "inside"]:
			var point: Vector2 = doorway[key]
			canvas.draw_rect(Rect2(point + Vector2(-18, -35), Vector2(36, 35)), Color("665878"))
			canvas.draw_rect(Rect2(point + Vector2(-16, -33), Vector2(32, 31)), Color("e5c79b"), false, 2.0)
		canvas.draw_string(font, doorway["outside"] + Vector2(-42, -42), doorway["name"])
	canvas.draw_string(font, Vector2(5565, 252), "Кафе")
	canvas.draw_string(font, Vector2(5905, 252), "Комната Луны")
	canvas.draw_string(font, Vector2(5565, 550), "Мастерская Юки")
	canvas.draw_string(font, Vector2(5905, 550), "Магазин Ори")
