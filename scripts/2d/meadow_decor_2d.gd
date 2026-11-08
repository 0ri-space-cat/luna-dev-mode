extends Node2D
## Geometry-layer prototype. This will accept production assets via the importer.
const RIFT := Vector2(265, 245)
const LAKE := Vector2(985, 600)
const ORACLE := Vector2(1140, 275)
func _draw() -> void:
	# One continuous river and cliff contours; never tile-edge borders.
	draw_rect(Rect2(0, 740, 1472, 284), Color("#7653a6"))
	draw_rect(Rect2(0, 728, 1472, 18), Color("#bbe678"))
	draw_rect(Rect2(0, 804, 1472, 220), Color("#564180"))
	# Water flows across tiled ground as an independent translucent layer.
	draw_rect(Rect2(480, 0, 170, 290), Color("#39bada"))
	draw_rect(Rect2(505, 0, 60, 300), Color("#8af7ff"))
	draw_rect(Rect2(480, 280, 180, 13), Color("#e2fcff"))
	draw_circle(Vector2(580, 300), 57, Color("#49c3e1"))
	draw_circle(Vector2(580, 300), 44, Color("#75e5f3"))
	draw_circle(LAKE, 86, Color("#42b8df"))
	draw_circle(LAKE, 70, Color("#69daee"))
	draw_circle(LAKE, 40, Color("#88edf5"))
	# Hand-painted cutout-style boulders, foliage and crystals.
	for i in range(35):
		var x := 27 + (i * 173) % 1420
		var y := 112 + (i * 151) % 580
		if Vector2(x,y).distance_to(RIFT) < 85 or Vector2(x,y).distance_to(LAKE) < 110:
			continue
		draw_circle(Vector2(x,y), 4 + (i % 4), Color("#f4a0d2") if i % 3 == 0 else Color("#f8f3e6"))
		draw_circle(Vector2(x + 2,y - 2), 2, Color("#ffee91"))
	for p in [Vector2(100,610),Vector2(1090,410),Vector2(1380,610)]:
		draw_colored_polygon(PackedVector2Array([p+Vector2(-16,20),p+Vector2(-2,-44),p+Vector2(26,20)]),Color("#ce80ef"))
		draw_line(p+Vector2(-2,-38),p+Vector2(12,8),Color("#f5c2ff"),3)
	# The rift is a physical discovery point, with a stable address.
	draw_circle(RIFT, 49, Color("#3d286d"))
	draw_arc(RIFT, 47, 0, TAU, 48, Color("#b86bf1"), 6)
	draw_arc(RIFT, 32, 0, TAU, 48, Color("#51f5ff"), 5)
	draw_circle(RIFT, 12, Color("#f8a8fa"))
	# Oracle stand and visible mechanical Eye, even before the rift.
	draw_rect(Rect2(ORACLE + Vector2(-18, 11), Vector2(36, 41)), Color("#6d4b9e"))
	draw_circle(ORACLE, 22, Color("#d59a57"))
	draw_circle(ORACLE, 13, Color("#54e2e5"))
	draw_circle(ORACLE, 6, Color("#353364"))
