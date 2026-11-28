extends Node2D
## M01 remembers the actual point of performance on the existing map.

const Meadows = preload("res://scripts/skeleton/meadows_layout.gd")
const City = preload("res://scripts/skeleton/luma_city_layout.gd")
const Forest = preload("res://scripts/skeleton/forest_bank_2d.gd")
const Valley = preload("res://scripts/skeleton/valley_dry_layout.gd")
const Coast = preload("res://scripts/skeleton/coast_layout.gd")
const Mountain = preload("res://scripts/skeleton/mountain_layout.gd")

const ID := "ET_MUSIC_PAVILION"
const ROOM := Rect2(9250, 520, 500, 295)
const CENTER := Vector2(9500, 669)
const EXIT := Vector2(9500, 784)
const PORTS := [
	{"point": Vector2(9320, 598), "address": Meadows.LOCATION_ID, "name": "Большие луга", "color": Color("b5cd93")},
	{"point": Vector2(9500, 598), "address": City.CITY_ID, "name": "Люма", "color": Color("e7a2c8")},
	{"point": Vector2(9680, 598), "address": Forest.LOCATION_ID, "name": "Лес фей", "color": Color("99bea7")},
	{"point": Vector2(9320, 736), "address": Valley.LOCATION_ID, "name": "Долина водопадов", "color": Color("a4cddb")},
	{"point": Vector2(9500, 736), "address": Coast.LOCATION_ID, "name": "Побережье", "color": Color("e2be98")},
	{"point": Vector2(9680, 736), "address": Mountain.MOUNTAIN, "name": "Горы", "color": Color("c0b0e0")},
]
const REACH := 24.0
const RETURN_OFFSETS := [Vector2.ZERO, Vector2(25, 0), Vector2(-25, 0), Vector2(0, 24), Vector2(0, -24)]

var home: Node
var origin := Vector3.INF


func play() -> bool:
	var point: Vector2 = home.actor.position
	if ROOM.has_point(point):
		return true
	var height: float = home.actor.motion.elevation
	var next_origin := Vector3(point.x, point.y, height)
	if not home.can_return_traveler(point, height):
		var safe: Array = home.actor.motion.snapshot()["anchor"]
		next_origin = Vector3(safe[0], safe[1], safe[2])
	if not _move(CENTER, ID):
		return false
	origin = next_origin
	return true


func action(point: Vector2) -> Dictionary:
	if not ROOM.has_point(point):
		return {}
	if point.distance_squared_to(EXIT) <= REACH * REACH:
		return {"address": "", "name": "Обратно к месту исполнения"}
	for port in PORTS:
		if point.distance_squared_to(port["point"]) <= REACH * REACH:
			return port
	return {}


func interact(port: Dictionary) -> bool:
	var address: String = port["address"]
	if not address.is_empty():
		return _travel_to_region(address)
	if origin.is_finite():
		var place := Vector2(origin.x, origin.y)
		var source: String = home._entity_location(place)
		for offset: Vector2 in RETURN_OFFSETS:
			if _move(place + offset, source, origin.z):
				return true
		if _travel_to_region(source):
			return true
	return _travel_to_region(PORTS[0]["address"])


func _travel_to_region(address: String) -> bool:
	for destination: Vector2 in home._ordinary_arrival_points(address):
		if _move(destination, address):
			return true
	return false


func _move(point: Vector2, address: String, height: float = 0.0) -> bool:
	if not home._ordinary_arrival_is_safe(address, point, height):
		return false
	home._move_home_travelers(point, address, height)
	if address != ID:
		origin = Vector3.INF
	return true


func snapshot() -> Array:
	if origin.is_finite() and ROOM.has_point(home.actor.position):
		return [origin.x, origin.y, origin.z]
	return []


static func valid_snapshot(value: Variant) -> bool:
	if not value is Array or value.size() not in [0, 3]:
		return false
	for component in value:
		if typeof(component) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(component)) or absf(float(component)) > 100000.0:
			return false
	return value.is_empty() or not ROOM.has_point(Vector2(value[0], value[1]))


func restore(value: Array) -> void:
	origin = Vector3.INF if value.is_empty() else Vector3(value[0], value[1], value[2])


func _draw() -> void:
	draw_rect(ROOM, Color("685569"))
	draw_rect(ROOM.grow(-7.0), Color("c09a86"), false, 2.0)
	for radius in [32.0, 39.0, 52.0]:
		draw_arc(CENTER, radius, 0.0, TAU, 48, Color("ba919d"), 1.5, true)
	for index in PORTS.size():
		var port: Dictionary = PORTS[index]
		_draw_arch(port["point"], port["color"], index)
	_draw_arch(EXIT, Color("eed7ae"), -1)


func _draw_arch(point: Vector2, color: Color, motif: int) -> void:
	var arch := point + Vector2(0, -14)
	draw_arc(arch, 17.0, PI, TAU, 32, color, 3.0, true)
	draw_line(arch - Vector2(17, 0), point - Vector2(17, 0), color, 3.0)
	draw_line(arch + Vector2(17, 0), point + Vector2(17, 0), color, 3.0)
	var glyph := arch + Vector2(0, -2)
	match motif:
		0, 2:
			draw_polyline(PackedVector2Array([glyph + Vector2(-7, 4), glyph + Vector2(-3, -6),
				glyph + Vector2(0, 4), glyph + Vector2(4, -8), glyph + Vector2(7, 4)]), color, 2.0, true)
		1:
			draw_rect(Rect2(glyph - Vector2(6, 7), Vector2(12, 15)), color, false, 2.0)
		3, 4:
			for offset in [-2.0, 4.0]:
				draw_arc(glyph + Vector2(0, offset), 6.5, PI * 0.2, PI * 0.8, 10, color, 2.0)
		5:
			draw_polyline(PackedVector2Array([glyph + Vector2(-8, 6), glyph - Vector2(0, 8),
				glyph + Vector2(8, 6)]), color, 2.0, true)
		_:
			draw_arc(glyph, 6, 0, TAU, 18, color, 2.0)
