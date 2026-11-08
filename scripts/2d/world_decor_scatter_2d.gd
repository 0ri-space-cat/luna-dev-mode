extends Node2D
## Deterministic lightweight set dressing using individually authored textures.
## Future ImageGen exports take priority. Static decorations are not AI/physics.
const WORLD_SIZE := Vector2(1472, 1024)
const SEED := 20261108
const SOURCES := [
	{"id":"flower","new":"res://assets/2d/eternia/pixel/decor/flower.png","fallback":"res://assets/2d/eternia/props/flower_bush.webp","count":11,"scale_new":1.0,"scale_fallback":0.19},
	{"id":"crystal","new":"res://assets/2d/eternia/pixel/decor/crystal.png","fallback":"res://assets/2d/eternia/props/pink_crystals.webp","count":5,"scale_new":1.0,"scale_fallback":0.21}
]
var spawned: Array[Sprite2D] = []

func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	for entry in SOURCES:
		var path: String = str(entry["new"]) if ResourceLoader.exists(str(entry["new"])) else str(entry["fallback"])
		if not ResourceLoader.exists(path):
			continue
		var tex := load(path) as Texture2D
		if tex == null:
			continue
		var scale_factor := float(entry["scale_new"]) if path == str(entry["new"]) else float(entry["scale_fallback"])
		var made := 0
		var tries := 0
		while made < int(entry["count"]) and tries < int(entry["count"]) * 20:
			tries += 1
			var spot := Vector2(rng.randf_range(36.0, WORLD_SIZE.x - 36.0), rng.randf_range(135.0, 710.0))
			if not _is_safe(spot):
				continue
			var item := Sprite2D.new()
			item.name = "Decor_%s_%02d" % [str(entry["id"]), made]
			item.texture = tex
			item.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			item.scale = Vector2.ONE * scale_factor * rng.randf_range(0.90, 1.08)
			item.flip_h = rng.randf() > 0.5
			item.position = spot - Vector2(0.0, tex.get_height() * item.scale.y * 0.5)
			item.set_meta("ground_point", spot)
			item.set_meta("decor_kind", entry["id"])
			add_child(item)
			spawned.append(item)
			made += 1

func _is_safe(spot: Vector2) -> bool:
	for zone in [
		{"point":Vector2(335,245),"radius":95.0},
		{"point":Vector2(985,600),"radius":145.0},
		{"point":Vector2(1140,275),"radius":85.0},
		{"point":Vector2(670,440),"radius":100.0}
	]:
		if spot.distance_to(zone["point"]) < float(zone["radius"]):
			return false
	# Temporary protected traversal strip between the main landmarks.
	if spot.x >= 465.0 and spot.x <= 785.0 and spot.y >= 250.0 and spot.y <= 320.0:
		return false
	return true

func decoration_at(point: Vector2, radius: float = 28.0) -> Sprite2D:
	var closest: Sprite2D = null
	var best := radius * radius
	for item in spawned:
		if not is_instance_valid(item):
			continue
		var distance := (item.get_meta("ground_point") as Vector2).distance_squared_to(point)
		if distance < best:
			best = distance
			closest = item
	return closest
