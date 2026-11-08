extends Node2D
## Layered Eternia set dressing. Surface tiling stays borderless; cliffs,
## stones, water, flowers and ruins are independently placed continuous art.
const RIFT := Vector2(335, 245)
const LAKE := Vector2(985, 600)
const ORACLE := Vector2(1140, 275)
const TERMINAL := Vector2(1260, 560)
var t := 0.0
var animation_budget := 0.0
var _flowers: Array[Dictionary] = []
var _rocks: Array[Dictionary] = []
var _pollen: Array[Dictionary] = []

func _ready() -> void:
	_build_collision()
	_seed_decorations()
	_add_static_sprites()

func _process(delta: float) -> void:
	t += delta
	animation_budget += delta
	if animation_budget > 0.06:
		animation_budget = 0.0
		queue_redraw()

func _build_collision() -> void:
	var water := StaticBody2D.new()
	water.name = "WaterBoundary"
	add_child(water)
	var stream_shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(170, 282)
	stream_shape.shape = rect
	stream_shape.position = Vector2(565, 140)
	water.add_child(stream_shape)
	var lake := StaticBody2D.new()
	lake.name = "LakeBoundary"
	add_child(lake)
	var body := CollisionPolygon2D.new()
	var poly := PackedVector2Array()
	for i in range(24):
		var angle := float(i) / 24.0 * TAU
		poly.append(LAKE + Vector2(cos(angle), sin(angle)) * 79.0)
	body.polygon = poly
	lake.add_child(body)

func _seed_decorations() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261108
	for i in range(135):
		var pos := Vector2(rng.randf_range(20, 1452),rng.randf_range(95, 725))
		if pos.distance_to(RIFT) < 85 or pos.distance_to(LAKE) < 130 or (pos.x > 455 and pos.x < 660 and pos.y < 320):
			continue
		var color: String = ["#fca8e2","#fff5e9","#ffda89","#cba2f3","#91effa"][i % 5]
		_flowers.append({"pos":pos,"size":rng.randf_range(2.1,5.1),"color":Color(color),"phase":rng.randf_range(0,TAU)})
	for i in range(44):
		var pos := Vector2(rng.randf_range(30, 1440),rng.randf_range(105, 725))
		if pos.distance_to(LAKE) < 120 or pos.distance_to(RIFT) < 65:
			continue
		_rocks.append({"pos":pos,"size":rng.randf_range(5,13),"shade":i % 4})
	for i in range(32):
		_pollen.append({
			"center":Vector2(rng.randf_range(20,1440),rng.randf_range(90,700)),
			"phase":rng.randf_range(0, TAU),"speed":rng.randf_range(0.4,1.1),
			"radius":rng.randf_range(2,3.5)
		})

func _add_static_sprites() -> void:
	# Landmarks use original authored vegetation, varied by scale and tint.
	var illustrations := [
		{"file":"forest_tree","position":Vector2(20,560),"scale":0.81,"tint":"#c5eac7"},
		{"file":"forest_tree","position":Vector2(1436,555),"scale":0.82,"tint":"#d1f2cb"},
		{"file":"forest_tree","position":Vector2(1240,168),"scale":0.56,"tint":"#c9e6e5"},
		{"file":"forest_tree","position":Vector2(370,145),"scale":0.43,"tint":"#cde6ad"},
		{"file":"forest_tree","position":Vector2(1350,675),"scale":0.56,"tint":"#c7efb2"},
		{"file":"forest_tree","position":Vector2(305,700),"scale":0.58,"tint":"#c8e6ad"},
		{"file":"flower_bush","position":Vector2(332,493),"scale":0.52,"tint":"#ffebff"},
		{"file":"flower_bush","position":Vector2(815,286),"scale":0.46,"tint":"#d8f9ee"},
		{"file":"flower_bush","position":Vector2(1170,390),"scale":0.49,"tint":"#ffcfea"},
		{"file":"flower_bush","position":Vector2(1410,710),"scale":0.43,"tint":"#fbe3ff"},
		{"file":"crystal_cluster","position":Vector2(150,680),"scale":0.46,"tint":"#fff0ff"},
		{"file":"crystal_cluster","position":Vector2(1114,467),"scale":0.41,"tint":"#e5fffe"},
		{"file":"crystal_cluster","position":Vector2(708,143),"scale":0.35,"tint":"#f4eaff"},
		{"file":"crystal_cluster","position":Vector2(1395,683),"scale":0.35,"tint":"#fff0ff"}
	]
	for entry in illustrations:
		var filename := "res://assets/2d/props/%s.svg" % str(entry["file"])
		if not ResourceLoader.exists(filename):
			continue
		var sprite := Sprite2D.new()
		sprite.texture = load(filename)
		var factor: float = float(entry["scale"])
		sprite.scale = Vector2.ONE * factor
		sprite.position = entry["position"] - Vector2(0,sprite.texture.get_height()*factor*0.48)
		sprite.modulate = Color(str(entry["tint"]))
		add_child(sprite)
	# Optional approved raster replacements can be installed later without
	# changing map geometry or anything in the gameplay simulation.
	for spec in [
		{"id":"flower_bush","at":Vector2(260,500),"size":0.23},
		{"id":"pink_crystals","at":Vector2(1155,530),"size":0.20},
		{"id":"moss_arch","at":Vector2(704,170),"size":0.27}
	]:
		var filename := "res://assets/2d/eternia/props/%s.png" % str(spec["id"])
		if ResourceLoader.exists(filename):
			var decoration := Sprite2D.new()
			decoration.texture = load(filename)
			decoration.position = spec["at"] + Vector2(0,-60.0 * float(spec["size"]))
			decoration.scale = Vector2.ONE * float(spec["size"])
			add_child(decoration)

func _draw() -> void:
	_draw_upper_terraces()
	_draw_falls_cliffs()
	_draw_lower_cliffs()
	_draw_paths()
	_draw_stream_and_waterfall()
	_draw_lake()
	_draw_rocks_and_flowers()
	_draw_crystal_clusters()
	_draw_rift()
	_draw_oracle()
	_draw_terminal()
	_draw_pollen()

func _draw_upper_terraces() -> void:
	var edge := PackedVector2Array([
		Vector2(0, 100), Vector2(135, 105),Vector2(200,87),
		Vector2(330,95),Vector2(420,110),Vector2(470,114),
		Vector2(470,0),Vector2(0,0)
	])
	draw_colored_polygon(edge,Color("#6e4fa1",0.58))
	draw_polyline(PackedVector2Array([
		Vector2(0,104),Vector2(135,109),Vector2(200,91),Vector2(330,99),Vector2(420,114),Vector2(470,118)
	]),Color("#bfeb76"),8.0,true)
	var far := PackedVector2Array([
		Vector2(700,90),Vector2(805,78),Vector2(866,100),
		Vector2(956,79),Vector2(1044,94),Vector2(1133,81),
		Vector2(1220,90),Vector2(1320,84),Vector2(1472,105),
		Vector2(1472,0),Vector2(700,0)])
	draw_colored_polygon(far,Color("#7a559f",0.58))
	draw_polyline(PackedVector2Array([
		Vector2(700,93),Vector2(805,82),Vector2(866,104),
		Vector2(956,83),Vector2(1044,98),Vector2(1133,85),
		Vector2(1220,94),Vector2(1320,88),Vector2(1472,109)
	]),Color("#b6e16e"),9.0,true)
	# Brick strata in the distant wall (shapes, not tile borders).
	for x in range(718,1460,47):
		var y := 120.0 + sin(float(x) * 0.056) * 6.0
		draw_line(Vector2(x,y),Vector2(x+30,y+1),Color("#664180",0.34),3.0)

func _draw_lower_cliffs() -> void:
	var lip := PackedVector2Array()
	var bottom := PackedVector2Array()
	for x in range(0,1473,48):
		var y := 733.0 + sin(float(x)*0.017)*8.0 + cos(float(x)*0.051)*4.0
		lip.append(Vector2(x,y))
		bottom.append(Vector2(x,1024))
	var face := lip.duplicate()
	bottom.reverse()
	face.append_array(bottom)
	draw_colored_polygon(face, Color("#7758a1"))
	var lower := PackedVector2Array()
	for p in lip:
		lower.append(p+Vector2(0,70))
	draw_polyline(lower,Color("#5c428a",0.7),7.0,true)
	draw_polyline(lip,Color("#4eae65"),15.0,true)
	for i in range(1,lip.size()):
		var p: Vector2 = lip[i]
		draw_line(p+Vector2(-18,19),p+Vector2(-12,51),Color("#644b90",0.45),3)
	for x in range(0,1472,55):
		draw_line(Vector2(x,847),Vector2(x+39,853),Color("#513b79",0.28),4.0)

func _draw_paths() -> void:
	_paving(PackedVector2Array([Vector2(663,450),Vector2(535,433),Vector2(409,366),Vector2(355,296)]),46)
	_paving(PackedVector2Array([Vector2(680,456),Vector2(831,414),Vector2(995,357),Vector2(1144,319)]),42)
	_paving(PackedVector2Array([Vector2(838,480),Vector2(886,517),Vector2(931,563)]),22)

func _paving(points: PackedVector2Array, amount: int) -> void:
	# A continuous earth ribbon avoids the "pink square staircase" look.
	draw_polyline(points, Color("#558a64",0.36),42.0,true)
	draw_polyline(points, Color("#b89e7c",0.62),31.0,true)
	draw_polyline(points, Color("#c8b68c",0.31),18.0,true)
	var cumulative := 0.0
	var segments: Array[float] = [0.0]
	for i in range(points.size()-1):
		cumulative += points[i].distance_to(points[i+1])
		segments.append(cumulative)
	for n in range(maxi(7,amount/2)):
		var dist := float(n)/float(maxi(amount/2-1,1)) * cumulative
		var index := 0
		for i in range(segments.size()-1):
			if dist >= segments[i] and dist <= segments[i+1]:
				index = i
				break
		var step := (dist-segments[index])/maxf(segments[index+1]-segments[index],0.001)
		var p := points[index].lerp(points[index+1],step)
		p.y += sin(float(n)*1.78)*6.0
		p.x += cos(float(n)*2.31)*4.0
		var w := 4.6 + 2.1*sin(float(n)*1.48)
		var c := Color("#c6abbb") if n%5 == 0 else (Color("#b9a2a0") if n%3 == 1 else Color("#d6bbab"))
		draw_colored_polygon(PackedVector2Array([
			p+Vector2(-w,-5),p+Vector2(w,-4),p+Vector2(w-2,5),p+Vector2(-w+2,6)
		]),c)
		draw_line(p+Vector2(-w+1,-4),p+Vector2(w-1,-4),Color("#f0cae5",0.5),1.8)

func _draw_stream_and_waterfall() -> void:
	var channel := Rect2(480,0,170,282)
	draw_rect(channel, Color("#319ac1"))
	for stream in range(13):
		var x := 489.0 + float(stream)*12.0 + sin(t*2.2 + float(stream))*3.0
		var line := PackedVector2Array()
		for j in range(10):
			var y := float(j)*32.0
			line.append(Vector2(x+sin(y*0.08 + t*5.0 + stream)*3.0, y))
		draw_polyline(line,Color("#a3f8ff",0.47 + 0.18*sin(t*2.4+stream)),2.8,true)
	draw_rect(Rect2(480,278,170,12),Color("#dbfaff",0.76))
	for i in range(12):
		var theta := float(i)*TAU/12.0+t*0.5
		var at := Vector2(568,302)+Vector2(cos(theta)*76,sin(theta)*20)
		draw_circle(at,2.4,Color("#fcffff",0.8))
	draw_circle(Vector2(565,303),69,Color("#47bad8",0.58))
	draw_arc(Vector2(565,303),57,0,TAU,64,Color("#c2faff",0.46),3.0)

func _draw_lake() -> void:
	draw_set_transform(LAKE,0.0,Vector2(1.28,0.76))
	draw_circle(Vector2.ZERO,91,Color("#387fa9"))
	draw_circle(Vector2.ZERO,84,Color("#2da6c4"))
	draw_circle(Vector2(2,-2),76,Color("#63d5e3",0.72))
	for i in range(7):
		var radius := 18.0+float(i)*10.0+3.0*sin(t*2.3+i)
		draw_arc(Vector2.ZERO,radius,0.4,2.6,24,Color("#cbfaff",0.38),1.7)
	draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
	for i in range(6):
		var angle := (float(i)/6.0)*TAU + t*0.18
		var pos := LAKE+Vector2(cos(angle)*52.0,sin(angle)*41.0)
		draw_circle(pos,5.5,Color("#62b668"))
		draw_circle(pos+Vector2(-1,-1),3.0,Color("#a2eb91"))

func _draw_rocks_and_flowers() -> void:
	for entry in _rocks:
		var p: Vector2 = entry["pos"]
		var size: float = entry["size"]
		var shade: int = entry["shade"]
		var body_color: Color = [Color("#826eac"),Color("#a18fc4"),Color("#9781af"),Color("#7a6c9e")][shade]
		draw_colored_polygon(PackedVector2Array([
			p+Vector2(-size,4),p+Vector2(-size*0.65,-size*0.8),
			p+Vector2(size*0.35,-size),p+Vector2(size,size*0.3),
			p+Vector2(size*0.52,size*0.7),p+Vector2(-size*0.6,size*0.72)
		]),body_color)
		draw_line(p+Vector2(-size*0.5,-size*0.66),p+Vector2(size*0.22,-size*0.76),Color("#cdbfe2",0.78),2.5)
	for entry in _flowers:
		var p: Vector2 = entry["pos"]
		var size: float = entry["size"]
		var color: Color = entry["color"]
		for petal in range(5):
			var angle := float(petal)*TAU/5.0 + 0.11
			var at := p+Vector2(cos(angle),sin(angle))*size
			draw_circle(at,size*0.72,color)
		draw_circle(p,size*0.46,Color("#ffdc6e"))

func _draw_crystal_clusters() -> void:
	for origin in [Vector2(135,660),Vector2(1120,435),Vector2(1307,640),Vector2(733,113)]:
		for j in range(3):
			var shift := Vector2(float(j-1)*18,8.0)
			var p: Vector2 = origin+shift
			var height := float(28+j*12)
			var color := Color("#f38ff0") if j%2==0 else Color("#9ae9f9")
			draw_colored_polygon(PackedVector2Array([
				p+Vector2(-13,0),p+Vector2(-9,-height*0.72),p+Vector2(0,-height),
				p+Vector2(10,-height*0.72),p+Vector2(13,0)
			]),color)
			draw_polyline(PackedVector2Array([p+Vector2(-9,0),p+Vector2(0,-height),p+Vector2(0,0)]),Color("#fff1fc",0.68),2.0)

func _draw_rift() -> void:
	var strength := 0.25+0.07*sin(t*2.2)
	draw_circle(RIFT,57.0+3*sin(t*1.8),Color("#8855c9",strength))
	draw_circle(RIFT,49,Color("#372461"))
	draw_arc(RIFT,46.0+2*sin(t*3),0,TAU,72,Color("#c87bf4"),6)
	draw_arc(RIFT,30.0,0,TAU,68,Color("#80f1ff"),4)
	for n in range(8):
		var theta := t*0.42+TAU*float(n)/8.0
		var p := RIFT+Vector2(cos(theta),sin(theta))*37.0
		draw_circle(p,3,Color("#fff2ff"))
	draw_circle(RIFT,13.0+2*sin(t*3.0),Color("#ffb6f2"))

func _draw_oracle() -> void:
	draw_colored_polygon(PackedVector2Array([
		ORACLE+Vector2(-22,38),ORACLE+Vector2(-12,4),
		ORACLE+Vector2(13,4),ORACLE+Vector2(24,38)
	]),Color("#9c6bac"))
	draw_circle(ORACLE,24,Color("#daaa59"))
	draw_circle(ORACLE,18,Color("#8d60b2"))
	draw_circle(ORACLE,13,Color("#50cfe1"))
	draw_circle(ORACLE,7,Color("#e2ffff"))
	draw_arc(ORACLE,27,0,TAU,42,Color("#ffe5a3",0.8),3.0)

func _draw_pollen() -> void:
	for item in _pollen:
		var c: Vector2 = item["center"]
		var phase: float = item["phase"]
		var speed: float = item["speed"]
		var p: Vector2 = c+Vector2(sin(t*speed+phase)*12.0,cos(t*speed*0.75+phase)*9.0)
		var radius: float = item["radius"]
		draw_circle(p,radius*2,Color("#e8b5fc",0.07))
		draw_circle(p,radius,Color("#fff1c7",0.68))

func _draw_terminal() -> void:
	# A tangible magic network node. No programming syntax required.
	draw_rect(Rect2(TERMINAL+Vector2(-23,18),Vector2(46,40)),Color("#704b9d"))
	draw_colored_polygon(PackedVector2Array([
		TERMINAL+Vector2(-24,-41),TERMINAL+Vector2(23,-41),
		TERMINAL+Vector2(31,16),TERMINAL+Vector2(-32,16)
	]),Color("#9675ce"))
	draw_rect(Rect2(TERMINAL+Vector2(-18,-30),Vector2(36,33)),Color("#2e245e"))
	var center := TERMINAL + Vector2(0,-13)
	draw_circle(center,13,Color("#4de0eb",0.24))
	for i in range(5):
		var phase := float(i)*TAU/5.0 + t*0.7
		var p := center + Vector2(cos(phase),sin(phase))*11
		draw_circle(p,2.7,Color("#ecb2fd"))
	draw_arc(center,6.0,0,TAU,20,Color("#b9f8fd"),3.0)
	draw_line(TERMINAL+Vector2(-15,20),TERMINAL+Vector2(15,20),Color("#d29ded"),3.0)

func _draw_falls_cliffs() -> void:
	# Multi-tier purple masonry framing the turquoise waterfall.
	for column in [
		{"x":420.0,"width":62.0,"top":24.0,"bottom":296.0},
		{"x":648.0,"width":93.0,"top":35.0,"bottom":299.0}
	]:
		var x: float = column["x"]
		var w: float = column["width"]
		var top: float = column["top"]
		var bottom: float = column["bottom"]
		draw_colored_polygon(PackedVector2Array([
			Vector2(x,top),Vector2(x+w,top+7),Vector2(x+w-6,bottom),
			Vector2(x-7,bottom-12)
		]),Color("#8060a9"))
		draw_line(Vector2(x+7,top+8),Vector2(x+w-12,top+12),Color("#b395c4",0.70),5)
		for row in range(5):
			var yy := top + 35.0 + row*47.0
			draw_line(Vector2(x+6,yy),Vector2(x+w-9,yy+5),Color("#5c427d",0.63),4.0)
			var seam_x := x+19.0+(18.0 if row%2==0 else 3.0)
			draw_line(Vector2(seam_x,yy-36),Vector2(seam_x+2,yy),Color("#5c427d",0.55),3.0)
		draw_line(Vector2(x,top),Vector2(x+w,top+7),Color("#b6e976"),11,true)
		for j in range(4):
			var blade_x := x+8+j*(w-15)/3
			draw_line(Vector2(blade_x,top),Vector2(blade_x+4,top-10),Color("#9bd758"),3)
	# Ruined masonry arch suggests depth without creating a tile-shaped island.
	var center := Vector2(766,138)
	draw_rect(Rect2(center+Vector2(-51,-5),Vector2(26,119)),Color("#8d6ab1"))
	draw_rect(Rect2(center+Vector2(25,-5),Vector2(28,119)),Color("#8d6ab1"))
	draw_arc(center+Vector2(0,-3),37,PI,TAU,32,Color("#6c4b91"),26)
	draw_arc(center+Vector2(0,-3),39,PI,TAU,32,Color("#ba92cf",0.72),4)
	draw_line(center+Vector2(-49,99),center+Vector2(-26,101),Color("#b692c8"),4)
	draw_line(center+Vector2(28,99),center+Vector2(49,101),Color("#b692c8"),4)
