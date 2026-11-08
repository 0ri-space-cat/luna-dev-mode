extends Control
## Runtime map projection. Every dot is an actual Entity, not baked map art.
var player: Node2D
var markers: Array = []
const CENTER := Vector2(64,64)
const RADIUS := 57.0
func set_targets(actor: Node2D, things: Array) -> void:
	player = actor
	markers = things
func _process(_delta: float) -> void:
	queue_redraw()
func _project(world_pos: Vector2) -> Vector2:
	return CENTER + (world_pos - Vector2(640,400))/12.5
func _draw() -> void:
	draw_circle(CENTER,63,Color("#261b45"))
	draw_circle(CENTER,RADIUS,Color("#8ac65b"))
	draw_circle(CENTER+Vector2(-18,-24),29,Color("#6ea656",0.37))
	draw_circle(CENTER+Vector2(25,17),25,Color("#b6dc69",0.4))
	# Ground geometry on the same coordinate projection used for live markers.
	var stream := PackedVector2Array([
		_project(Vector2(560,20)),_project(Vector2(560,150)),
		_project(Vector2(560,245)),_project(Vector2(560,305))
	])
	draw_polyline(stream,Color("#298db1"),8.0,true)
	draw_polyline(stream,Color("#62d9f3"),5.0,true)
	draw_circle(_project(Vector2(985,600)),7.2,Color("#2f9cc2"))
	draw_circle(_project(Vector2(985,600)),5.7,Color("#7adcea"))
	var roads := [
		PackedVector2Array([_project(Vector2(355,296)),_project(Vector2(540,432)),_project(Vector2(680,450))]),
		PackedVector2Array([_project(Vector2(680,450)),_project(Vector2(1000,356)),_project(Vector2(1140,320))])
	]
	for road in roads:
		draw_polyline(road,Color("#d7a0d5",0.65),2.0,true)
	draw_circle(_project(Vector2(335,245)),4.8,Color("#e777fb"))
	draw_circle(_project(Vector2(1140,275)),4.5,Color("#fce1a2"))
	for item in markers:
		if is_instance_valid(item):
			var where: Vector2 = _project((item as Node2D).global_position)
			if where.distance_to(CENTER) < RADIUS - 6:
				draw_circle(where,4.7,Color("#47305f"))
				draw_circle(where,3.2,Color("#ed98db"))
	if is_instance_valid(player):
		var where: Vector2 = _project(player.global_position)
		if where.distance_to(CENTER) < RADIUS - 5:
			draw_colored_polygon(PackedVector2Array([
				where+Vector2(0,-7),where+Vector2(-5,5),where+Vector2(5,5)
			]),Color("#fff1fd"))
			draw_polyline(PackedVector2Array([
				where+Vector2(0,-7),where+Vector2(-5,5),where+Vector2(5,5),where+Vector2(0,-7)
			]),Color("#6532ad"),2.0)
	draw_arc(CENTER,59.5,0,TAU,72,Color("#e9b5f7"),5.0)
	draw_arc(CENTER,52.8,0,TAU,64,Color("#6ed8f6",0.65),1.5)
