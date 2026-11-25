extends Node2D
## Native geometry for the projection sample. The door and solid props are
## drawn from their authored world positions alongside the physical supports.

const RoomProjection = preload("res://scripts/skeleton/art_probe_projection.gd")
const ArtRoom = preload("res://scripts/skeleton/art_probe_room.gd")

var view: RoomProjection
var room: ArtRoom


func show_room(next_room: ArtRoom, next_view: RoomProjection) -> void:
	room = next_room
	view = next_view
	for layer in get_children():
		layer.free()
	for obstacle in room.obstacles:
		var visual: String = obstacle.get("visual", "")
		if visual.is_empty():
			continue
		var layer := Node2D.new()
		var bounds: Rect2 = obstacle["bounds"]
		layer.z_as_relative = false
		layer.z_index = view.depth(Vector2(bounds.get_center().x, bounds.end.y)) * 2 + 1
		add_child(layer)
		if visual == "shelter":
			layer.draw.connect(_draw_shelter.bind(layer, bounds, float(obstacle["height"])))
		else:
			layer.draw.connect(_draw_prop.bind(layer, bounds, float(obstacle["height"])))
	queue_redraw()


func _draw() -> void:
	if not is_instance_valid(room):
		return
	if room.isometric:
		_draw_interior()
	else:
		_draw_exterior()


func _draw_exterior() -> void:
	_gradient(Color("8c9fc1"), Color("c4c7b6"))
	draw_circle(Vector2(1032, 146), 52.0, Color("eee3c5"))
	_ridge(273.0, 75.0, Color("7988ac"), 17)
	_ridge(329.0, 53.0, Color("708f96"), 37)
	draw_rect(Rect2(0, 348, 1280, 452), Color("3b625c"))
	_plane(room.floor_bounds.grow(10), Color("426f67"))
	_plane(room.floor_bounds, Color("527e68"))
	_poly(self, [
		view.point(Vector2(30, 276)), view.point(Vector2(180, 215)),
		view.point(Vector2(360, 191)), view.point(room.door.position + Vector2(22, 0)),
		view.point(room.door.position + Vector2(30, 35)), view.point(Vector2(365, 226)),
		view.point(Vector2(180, 249)), view.point(Vector2(32, 320)),
	], Color("98997a"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 41
	for index in 205:
		var point := Vector2(rng.randf_range(14, 564), rng.randf_range(12, 348))
		if point.x > 35 and point.x < 460 and absf(point.y - (289.0 - point.x * 0.24)) < 25:
			continue
		var pixel := view.point(point)
		var sprig := Color("6b9375") if index % 3 else Color("91a588")
		draw_line(pixel, pixel + Vector2(-4, -5), sprig, 2.0)
		draw_line(pixel, pixel + Vector2(3, -7), sprig, 2.0)
		if index % 13 == 0:
			draw_rect(Rect2(pixel + Vector2(2, -9), Vector2(3, 3)), Color("d8bdad"))


func _draw_shelter(layer: Node2D, bounds: Rect2, height: float) -> void:
	var eave := height - 25.0
	_prism(layer, bounds, 0.0, eave, Color("ada3aa"), Color("677587"), Color("87919d"))
	var left := bounds.position.x
	var right := bounds.end.x
	var near := bounds.end.y + 8.0
	var middle := bounds.get_center().y
	_poly(layer, [view.point(Vector2(left - 7, near), eave), view.point(Vector2(right + 7, near), eave),
		view.point(Vector2(right + 7, middle), height), view.point(Vector2(left - 7, middle), height)],
		Color("544e70"))
	layer.draw_line(view.point(Vector2(left - 7, near), eave), view.point(Vector2(right + 7, near), eave),
		Color("c398a1"), 4.0)
	for band in [0.30, 0.64]:
		var y := lerpf(near, middle, band)
		var z := lerpf(eave, height, band)
		layer.draw_line(view.point(Vector2(left - 5, y), z), view.point(Vector2(right + 5, y), z),
			Color("6e6586"), 2.0)
	_door(layer, Vector2(16, 0))
	for x in [380.0, 495.0]:
		var start := Vector2(x, bounds.end.y)
		_upright(layer, start - Vector2(9, 0), start + Vector2(9, 0), 36.0, 58.0, Color("474761"))
		_upright(layer, start - Vector2(6, 0), start + Vector2(6, 0), 39.0, 55.0, Color("e6c294"))


func _draw_interior() -> void:
	_gradient(Color("2d3049"), Color("50465d"))
	_prism(self, room.floor_bounds, -22.0, 0.0, Color("8c6c61"), Color("4d3b4e"), Color("625061"))
	for y in range(0, 320, 20):
		var tone := Color("99796a") if (y / 20) % 2 == 0 else Color("a07d69")
		_plane(Rect2(0, y, 448, 19), tone)
		for x in range(32 + (y % 3) * 23, 448, 72):
			draw_line(view.point(Vector2(x, y)), view.point(Vector2(x, y + 19)), Color("856859"), 1.0)
	_upright(self, Vector2.ZERO, Vector2(0, 320), 0.0, 132.0, Color("68657f"))
	_upright(self, Vector2.ZERO, Vector2(448, 0), 0.0, 132.0, Color("84819b"))
	for z in [9.0, 120.0, 131.0]:
		draw_polyline(PackedVector2Array([view.point(Vector2(0, 320), z), view.point(Vector2.ZERO, z),
			view.point(Vector2(448, 0), z)]), Color("baa4a9"), 3)
	for x in [92.0, 221.0, 350.0]:
		_upright(self, Vector2(x - 18, 0), Vector2(x + 18, 0), 57.0, 102.0, Color("535773"))
		_upright(self, Vector2(x - 13, 0), Vector2(x + 13, 0), 62.0, 97.0, Color("a4c2b7"))
		draw_line(view.point(Vector2(x, 0), 63.0), view.point(Vector2(x, 0), 98.0), Color("666b83"), 3)
	_door(self, Vector2(0, 19))
	var supports := room.support_surfaces()
	for index in range(1, supports.size()):
		var tread := supports[index]
		var z: float = tread["height"]
		var bounds: Rect2 = tread["bounds"]
		var deck := index == supports.size() - 1
		_prism(self, bounds, 0.0 if deck else z - 6.0, z, Color("b5997e"), Color("6e5260"), Color("897064"))
		if not deck:
			var nose := Vector2(bounds.position.x, bounds.end.y)
			draw_line(view.point(bounds.position, z - 1.0), view.point(nose, z - 1.0), Color("8d7067"), 3.0)
			draw_line(view.point(bounds.position, z), view.point(nose, z), Color("d0b398"), 2.0)
	_plane(Rect2(52, 211, 153, 72), Color("745d73"))
	_plane(Rect2(59, 218, 139, 58), Color("987384"))
	_plane(Rect2(69, 225, 119, 44), Color("a17d8a"))


func _draw_prop(layer: Node2D, bounds: Rect2, height: float) -> void:
	_prism(layer, bounds, 0.0, height, Color("7e7e96"), Color("4e465d"), Color("636075"))
	var inset := bounds.grow(-5)
	_poly(layer, _corners(inset, height), Color("9695a7"))
	for factor in [0.25, 0.5, 0.75]:
		var x := lerpf(bounds.position.x, bounds.end.x, factor)
		layer.draw_line(view.point(Vector2(x, bounds.position.y), height),
			view.point(Vector2(x, bounds.end.y), height), Color("77758a"), 1.0)


func _door(layer: Node2D, half_width: Vector2) -> void:
	var point := room.door.position
	_upright(layer, point - half_width * 1.2, point + half_width * 1.2, 0.0, 58.0, Color("d3ae92"))
	_upright(layer, point - half_width, point + half_width, 0.0, 53.0, Color("463d5a"))
	_upright(layer, point - half_width * 0.82, point + half_width * 0.82, 1.0, 50.0, Color("6b5876"))
	layer.draw_circle(view.point(point + half_width * 0.57, 24.0), 2.5, Color("f6d594"))


func _gradient(top: Color, bottom: Color) -> void:
	draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(1280, 0), Vector2(1280, 800),
		Vector2(0, 800)]), PackedColorArray([top, top, bottom, bottom]))


func _ridge(y: float, amplitude: float, color: Color, seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var points := PackedVector2Array()
	for x in range(0, 1281, 40):
		points.append(Vector2(x, y + sin(x / 157.0 + seed_value) * amplitude + rng.randf_range(-4, 4)))
	points.append(Vector2(1280, 800))
	points.append(Vector2(0, 800))
	draw_colored_polygon(points, color)


func _plane(bounds: Rect2, color: Color) -> void:
	_poly(self, _corners(bounds, 0.0), color)


func _corners(bounds: Rect2, height: float) -> Array[Vector2]:
	return [
		view.point(bounds.position, height), view.point(Vector2(bounds.end.x, bounds.position.y), height),
		view.point(bounds.end, height), view.point(Vector2(bounds.position.x, bounds.end.y), height),
	]


func _prism(layer: Node2D, bounds: Rect2, bottom: float, top: float, top_color: Color,
		right_color: Color, front_color: Color) -> void:
	_upright(layer, Vector2(bounds.end.x, bounds.position.y), bounds.end, bottom, top, right_color)
	_upright(layer, bounds.end, Vector2(bounds.position.x, bounds.end.y), bottom, top, front_color)
	_poly(layer, _corners(bounds, top), top_color)


func _upright(layer: Node2D, a: Vector2, b: Vector2, bottom: float, top: float, color: Color) -> void:
	_poly(layer, [view.point(a, bottom), view.point(b, bottom), view.point(b, top),
		view.point(a, top)], color)


func _poly(layer: Node2D, points: Array[Vector2], color: Color) -> void:
	layer.draw_colored_polygon(PackedVector2Array(points), color)
