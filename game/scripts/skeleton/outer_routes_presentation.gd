extends Node2D
## Temporary 2D stage dressing. All usable footprints come from the room data.

const Routes = preload("res://scripts/skeleton/outer_routes_fixture.gd")
const CELL := Vector2(48, 76)
const VIEW_ROWS := [2, 1, 0, 1, 2, 3, 4, 3]
var _cracks: Array[PackedVector2Array] = [
	PackedVector2Array([Vector2(108, 184), Vector2(290, 267), Vector2(340, 249),
		Vector2(483, 365), Vector2(637, 327), Vector2(709, 438), Vector2(844, 395), Vector2(1172, 616)]),
	PackedVector2Array([Vector2(637, 327), Vector2(654, 265), Vector2(744, 253), Vector2(809, 184)]),
	PackedVector2Array([Vector2(483, 365), Vector2(454, 454), Vector2(491, 498), Vector2(377, 616)]),
]

var world: Routes
var _animated_time := 0.0
var _walk_cycle := 0.0
var _facing := 2


func _ready() -> void:
	world = get_parent() as Routes


func _process(delta: float) -> void:
	if not is_instance_valid(world.actor):
		return
	_animated_time += delta
	var actor := world.actor
	var traveler := world.traveler_visual
	var movement := actor.direction
	var running := world.current_address == Routes.BUFFER and not world.cracking
	var walking := (running or actor.motion.grounded) and movement.length_squared() > 0.08
	if movement.length_squared() > 0.08:
		_facing = posmod(roundi(movement.angle() / (PI / 4.0)), 8)
	var column := 0
	if walking:
		_walk_cycle = fposmod(_walk_cycle + delta * (12.0 if running else 8.0), 4.0)
		column = 1 + floori(_walk_cycle)
	else:
		_walk_cycle = 0.0
	traveler.region_rect = Rect2(Vector2(column, VIEW_ROWS[_facing]) * CELL, CELL)
	traveler.flip_h = _facing in [3, 4, 5]
	traveler.position = (actor.position - Vector2(0, actor.motion.elevation)).round()
	queue_redraw()


func _draw() -> void:
	if not is_instance_valid(world) or not is_instance_valid(world.actor):
		return
	match world.current_address:
		Routes.BUFFER:
			_draw_buffer()
		Routes.SUBSPACE:
			_draw_subspace()
		Routes.TRASH:
			_draw_trash()
		_:
			_draw_ground()
	if world.current_address != Routes.SUBSPACE and world.actor.motion.grounded:
		draw_set_transform(world.actor.position, 0.0, Vector2(1.0, 0.38))
		draw_circle(Vector2.ZERO, 21.0, Color(0.04, 0.03, 0.12, 0.49))
		draw_set_transform(Vector2.ZERO)


func _draw_buffer() -> void:
	var frame := Routes.FRAME
	var progress := world.crack_elapsed / Routes.CRACK_SECONDS if world.cracking else 0.0
	draw_rect(Rect2(0, 0, 1280, 800), Color("171529"))
	draw_rect(frame, Color("29243e").lerp(Color("120f20"), progress))
	for index in 12:
		var offset := fposmod(float(index) * 99.0 - _animated_time * 145.0, frame.size.x)
		var x := frame.position.x + offset
		draw_line(Vector2(x, 475), Vector2(x, 521), Color("473960"), 2.0)
	if progress < 0.58:
		draw_rect(frame, Color(0.53, 0.36, 0.85, 0.29), false, 18.0)
		draw_rect(frame, Color("d593ff"), false, 4.0)
	elif progress < 0.92:
		for index in 10:
			var start := Vector2(frame.position.x + float(index) * 105.0, frame.position.y + progress * 17.0 * index)
			draw_line(start, start + Vector2(69.0, progress * 24.0), Color("d593ff"), 4.0)
	if world.cracking:
		for index in clampi(1 + floori(progress * 3.0), 1, _cracks.size()):
			draw_polyline(_cracks[index], Color(0.83, 0.69, 1.0, 1.0 - progress * 0.65), 4.0)


func _draw_subspace() -> void:
	draw_rect(Rect2(0, 0, 1280, 800), Color("1b192d"))
	for index in 18:
		var x := 65.0 + float(index) * 67.0
		var y := fposmod(float(index * index) * 17.0 - _animated_time * 510.0, 826.0)
		draw_line(Vector2(x, y), Vector2(x + 12.0, y + 62.0), Color("686482"), 3.0)
	draw_polygon(PackedVector2Array([Vector2(98, 713), Vector2(418, 665), Vector2(608, 711),
		Vector2(857, 645), Vector2(1188, 703), Vector2(1188, 800), Vector2(98, 800)]),
		PackedColorArray([Color("4a4261")]))


func _draw_ground() -> void:
	var room := world._room as Routes.RouteRoom
	var edge := world.current_address == Routes.EDGE
	var palette := Color("666281") if edge else Color("708988")
	_gradient(Color("28263d"), palette.darkened(0.45))
	_draw_floor(room.floor_bounds, palette)
	for y in range(int(room.floor_bounds.position.y) + 31, int(room.floor_bounds.end.y), 44):
		draw_line(Vector2(room.floor_bounds.position.x, y), Vector2(room.floor_bounds.end.x, y),
			palette.darkened(0.14), 1.0)
	if world.current_address != Routes.COAST:
		var area := room.action_bounds
		draw_rect(area, Color("c9a980").darkened(0.13), true)
		draw_rect(area.grow(-5.0), Color("ebcca0"), false, 2.0)
		var center := area.get_center()
		draw_polyline(PackedVector2Array([center + Vector2(-13, 19), center + Vector2(15, 0),
			center + Vector2(-13, -19)]), Color("473144"), 4.0)


func _draw_trash() -> void:
	var room := world._room as Routes.RouteRoom
	_gradient(Color("151224"), Color("201a37"))
	for index in 44:
		var place := Vector2(60 + (index * 239) % 1160, 160 + (index * index * 37) % 568)
		draw_circle(place, 1 if index % 7 else 2, Color("61547d"))
	for surface in room.support_surfaces():
		_draw_floor(surface["bounds"], Color("504660"))
	for index in 9:
		var point := Vector2(378.0 + float(index) * 53.0, 442 + sin(float(index) * 0.82) * 16.0)
		var glow := 0.55 + 0.35 * sin(_animated_time * 3.0 - float(index) * 0.54)
		draw_circle(point, 4.0, Color(0.95, 0.79, 0.60, glow))
	var pad := room.action_bounds
	draw_rect(pad, Color("947652"))
	draw_rect(pad.grow(-5.0), Color("f0d1a0"), false, 3.0)
	draw_arc(pad.get_center(), 25.0, -0.6, PI * 1.45, 30, Color("f5dcb7"), 3.0)


func _draw_floor(bounds: Rect2, color: Color) -> void:
	draw_rect(bounds.grow(3.0), color.darkened(0.5))
	draw_rect(bounds, color)
	draw_line(bounds.end, Vector2(bounds.position.x, bounds.end.y), color.lightened(0.23), 3.0)


func _gradient(top: Color, bottom: Color) -> void:
	draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(1280, 0), Vector2(1280, 800), Vector2(0, 800)]),
		PackedColorArray([top, top, bottom, bottom]))
