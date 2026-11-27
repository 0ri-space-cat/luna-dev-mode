extends Node2D
## The garden and the two ways of visiting the same damaged forest.

const Music = preload("res://scripts/runtime2d/flute_2d.gd")
const Runes = preload("res://scripts/runtime2d/latin_runes_2d.gd")
const ID := "ET_FOREST_DREAM_01"
const GARDEN_TRAIL := Rect2(1850, -267, 66, 170)
const GARDEN := Rect2(1830, -376, 290, 152)
const ARCH := {"bounds": Rect2(1951, -376, 16, 109), "layer": 32, "height": 112.0}
const ROOT := {"bounds": Rect2(1951, -267, 16, 24), "layer": 2, "height": 112.0}
const CAMP := Vector2(2125, 4)
const NICHE_TRAIL := Rect2(2155, -120, 38, 112)
const NICHE := Vector2(2171, -92)
const SHRINE := Vector2(2084, -318)
const DREAM_CAMP := Rect2(8300, 410, 305, 200)
const DREAM_FALL := Rect2(8605, 455, 145, 106)
const DREAM_BANK := Rect2(8300, 1020, 290, 172)
const DREAM_WATER := Rect2(8300, 1020, 125, 54)
const FRAGMENTS := [Rect2(8540, 1101, 140, 72), Rect2(8650, 1130, 135, 112),
	Rect2(8750, 1189, 126, 87)]
const DREAM_SQUARE := Rect2(8840, 1178, 230, 156)
const ARRIVAL := Vector2(8428, 508)
const BANK_ARRIVAL := Vector2(8370, 1139)
const SQUARE := Vector2(8981, 1260)
const RETURNS := [Vector2(2100, 24), Vector2(2070, 53), Vector2(2018, 62)]
const START := {"gate_open": false, "asleep": false, "return_from": []}

var home: Node
var _gate: StaticBody2D
var _gate_top: Dictionary
var gate_open := false
var asleep := false
var _first_glimpse := 0.0
var _previous_prism := false
var _return_from := Vector2.INF


static func decks() -> Array[Rect2]:
	var result: Array[Rect2] = [GARDEN_TRAIL, GARDEN, DREAM_CAMP, DREAM_BANK, DREAM_SQUARE]
	result.append_array(FRAGMENTS)
	return result


static func is_dream(point: Vector2) -> bool:
	return DREAM_CAMP.has_point(point) or DREAM_FALL.has_point(point) or DREAM_BANK.has_point(point) \
		or DREAM_SQUARE.has_point(point) or FRAGMENTS.any(func(deck): return deck.has_point(point))


func mount(world: Node) -> void:
	home = world
	home._walls.append(ARCH)
	_gate = home._build_wall(ARCH, self)
	_gate_top = home._surfaces.back()
	queue_redraw()


func snapshot() -> Dictionary:
	var inside := is_dream(home.actor.position)
	return {"gate_open": gate_open, "asleep": asleep and inside,
		"return_from": [_return_from.x, _return_from.y] if inside and _return_from.is_finite() else []}


static func valid_snapshot(data: Variant, entities: Variant, actor_id: String) -> bool:
	if not data is Dictionary or data.size() != START.size() \
			or not data.get("gate_open") is bool or not data.get("asleep") is bool or not entities is Array:
		return false
	var origin: Variant = data.get("return_from")
	if not origin is Array or (origin.size() != 0 and origin.size() != 2):
		return false
	for coordinate in origin:
		if typeof(coordinate) not in [TYPE_FLOAT, TYPE_INT] or not is_finite(float(coordinate)):
			return false
	if data["asleep"] and not origin.is_empty():
		return false
	if not data["asleep"] and origin.is_empty():
		return true
	for entity in entities:
		if entity is Dictionary and entity.get("id") == actor_id:
			return entity.get("location_id") == ID
	return false


func restore(data: Dictionary) -> void:
	asleep = data["asleep"]
	var origin: Array = data["return_from"]
	_return_from = Vector2(origin[0], origin[1]) if not origin.is_empty() else Vector2.INF
	_first_glimpse = 0.0
	_set_gate(data["gate_open"])


func _set_gate(open: bool) -> void:
	if gate_open == open:
		return
	gate_open = open
	_gate.collision_layer = 0 if open else ARCH["layer"]
	if open:
		home._walls.erase(ARCH)
		home._surfaces.erase(_gate_top)
	else:
		home._walls.append(ARCH)
		home._surfaces.append(_gate_top)
	queue_redraw()


func action(point: Vector2) -> String:
	if point.distance_squared_to(CAMP) <= 24.0 * 24.0:
		return "Отдохнуть"
	if point.distance_squared_to(SQUARE) <= 25.0 * 25.0:
		return "Остановиться" if asleep else "В лес"
	if point.distance_squared_to(ARRIVAL) <= 24.0 * 24.0 \
			or point.distance_squared_to(BANK_ARRIVAL) <= 22.0 * 22.0:
		return "Проснуться" if asleep else "В лес"
	return ""


func interact(point: Vector2) -> bool:
	if is_dream(point):
		var destinations: Array = [CAMP] if asleep else []
		if _return_from.is_finite():
			destinations.append(_return_from)
		destinations.append_array(RETURNS)
		for destination: Vector2 in destinations:
			var address: String = home._entity_location(destination)
			if home._ordinary_arrival_is_safe(address, destination):
				asleep = false
				_return_from = Vector2.INF
				_first_glimpse = 0.0
				home._move_home_travelers(destination, address)
				return true
		return false
	if not _arrive():
		return false
	asleep = true
	_return_from = Vector2.INF
	_first_glimpse = 3.0
	return true


func perform(identity: String, point: Vector2) -> bool:
	match identity:
		"M05":
			if GARDEN.has_point(point) and point.distance_squared_to(ARCH["bounds"].get_center()) <= 110.0 * 110.0:
				_set_gate(true)
				return true
		"M10":
			return enter_awake()
	return false


func enter_awake() -> bool:
	var origin: Vector2 = home.actor.position
	if is_dream(origin) or not _arrive():
		return false
	_return_from = origin
	return true


func _arrive() -> bool:
	if not home._ordinary_arrival_is_safe(ID, ARRIVAL):
		return false
	home._move_home_travelers(ARRIVAL, ID)
	return true


func tick(delta: float, prism: bool) -> void:
	if _previous_prism != prism:
		_previous_prism = prism
		queue_redraw()
	_first_glimpse = maxf(0.0, _first_glimpse - delta)
	var actor = home.actor
	if not is_dream(actor.position):
		asleep = false
		_return_from = Vector2.INF
	if DREAM_FALL.has_point(actor.position) and actor.motion.elevation < -20.0 \
			and home._ordinary_arrival_is_safe(ID, BANK_ARRIVAL):
		home._move_home_travelers(BANK_ARRIVAL, ID)


func address_glimpse() -> String:
	return ID if _first_glimpse > 0.0 else ""


func _draw() -> void:
	draw_rect(GARDEN_TRAIL, Color("63836a"))
	draw_rect(GARDEN, Color("8a927d"))
	draw_rect(GARDEN.grow(-8.0), Color("d0ccb0"), false, 2.0)
	draw_rect(ROOT["bounds"], Color("857064"))
	var stone: Rect2 = ARCH["bounds"]
	if gate_open:
		draw_rect(Rect2(stone.position.x, stone.position.y, stone.size.x, 19), Color("a2a29d"))
	else:
		draw_rect(stone, Color("b4ada3"))
		draw_string(ThemeDB.fallback_font, stone.get_center() + Vector2(-8, 4), "♪", HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color("423b49"))
	for point: Vector2 in [Vector2(1855, -355), Vector2(1895, -355), Vector2(2010, -353), Vector2(2078, -350)]:
		draw_arc(point, 14.0, PI, TAU, 14, Color("e0d2b6"), 3.0, true)
		draw_line(point + Vector2(15, -1), point + Vector2(15, 28), Color("e0d2b6"), 3.0, true)
	draw_circle(CAMP, 8.0, Color("e8a279"))
	draw_rect(Rect2(CAMP + Vector2(10, -13), Vector2(23, 19)), Color("bca6a3"))
	draw_rect(NICHE_TRAIL.grow(-6.0), Color("55795b"), false, 1.5)
	Runes.draw_encoded(self, Runes.encode(ID), NICHE + Vector2(-36, -19),
		Color("b0cef1") if _previous_prism else Color("737d77"), 0.52)
	if _previous_prism:
		_draw_notes("M05", Vector2(1888, -330))
		_draw_notes("M10", SHRINE)
		Runes.draw_encoded(self, Runes.encode("TELEPORT ET_MEADOWS_MAIN"), Vector2(1842, -289), Color("b0cef1"), 0.47)
	draw_rect(DREAM_CAMP, Color("38394a"))
	draw_line(Vector2(8450, 508), Vector2(8605, 508), Color("77778c"), 19.0, true)
	draw_rect(Rect2(ARRIVAL + Vector2(10, -13), Vector2(23, 19)), Color("857d8a"))
	draw_rect(DREAM_BANK, Color("51495a"))
	draw_rect(DREAM_WATER, Color("2e344a"))
	draw_line(Vector2(8300, 1074), Vector2(8423, 1074), Color("7d778b"), 3.0)
	for index in FRAGMENTS.size():
		var fragment: Rect2 = FRAGMENTS[index]
		draw_rect(fragment, [Color("66697c"), Color("575f7c"), Color("695b72")][index])
		draw_polyline(PackedVector2Array([fragment.position + Vector2(12, 13), fragment.get_center(), fragment.end - Vector2(11, 15)]),
			Color("9391b1"), 1.5, true)
	draw_rect(DREAM_SQUARE, Color("6e6378"))
	draw_arc(SQUARE, 25.0, 0, TAU, 36, Color("c4b3d3"), 2.0, true)


func _draw_notes(identity: String, point: Vector2) -> void:
	draw_string(ThemeDB.fallback_font, point - Vector2(30, 0),
		Music.arrows(Music.PHRASES[identity]), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("b0cef1"))
