extends Node2D
## DEV visual adapter: reads existing bodies and never changes physics, modules or saves.
const LUNA := preload("res://assets/art_probe/luna.png")
const ONI := preload("res://assets/art_probe/oni.png")
const CELL := Vector2(48, 76)
const FOOT := Vector2(24, 70)
const VIEW_ROWS := [2, 1, 0, 1, 2, 3, 4, 3]
const FRAME_RATE := 8.0

var sprite := Sprite2D.new()
var facing := 2
var frame := 0
var walk_cycle := 0.0
var installed_walk := false
var enabled_walk := false
var installed_fly := false
var enabled_fly := false
var _last_point := Vector2.ZERO
var _marker: Polygon2D
var _category := ""
var _limb_color := Color.WHITE
var _alive := false


static func facing_for(travel: Vector2) -> int:
	return posmod(roundi(travel.angle() / (PI / 4.0)), 8)


static func atlas_rect(direction: int, column: int) -> Rect2:
	return Rect2(Vector2(clampi(column, 0, 4), VIEW_ROWS[posmod(direction, 8)]) * CELL, CELL)


static func mirrored(direction: int) -> bool:
	return posmod(direction, 8) in [3, 4, 5]


static func module_state(instances: Dictionary, ability: String) -> Vector2i:
	var state := Vector2i.ZERO
	for item in instances.values():
		if item.get("ability_id") == ability:
			state.x = 1
			if item.get("enabled", false):
				state.y = 1
	return state


func mount(marker: Polygon2D, point: Vector2, preview_scale: float) -> void:
	_marker = marker
	_last_point = point
	name = "DEVBodyVisual"
	sprite.centered = false
	sprite.offset = -FOOT
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.region_filter_clip_enabled = true
	sprite.scale = Vector2.ONE * preview_scale
	add_child(sprite)
	marker.add_child(self)


func sync(body, delta: float) -> void:
	var travel: Vector2 = body.position - _last_point
	_last_point = body.position
	# Large XY changes are travel or restore, not footsteps.
	var walking: bool = body.motion.grounded and not body.is_attached() and body.get_parameter("alive") and not body.get_parameter("asleep") and travel.length_squared() > 0.16 and travel.length_squared() < 4096.0
	if walking:
		facing = facing_for(travel)
		walk_cycle = fposmod(walk_cycle + maxf(delta, 0.0) * FRAME_RATE, 4.0)
		frame = 1 + floori(walk_cycle)
	else:
		walk_cycle = 0.0
		frame = 0
	var category: String = body.record.category
	var category_changed := category != _category
	if category_changed:
		_category = category
		sprite.texture = LUNA if category == "player" else (ONI if category == "oni" else null)
		sprite.region_enabled = category == "player"
		sprite.visible = sprite.texture != null
		# self_modulate hides just the polygon, not sprite, appendages or GLOW.
		_marker.self_modulate = Color(1, 1, 1, 0) if sprite.visible else Color.WHITE
	if sprite.visible:
		if category == "player":
			sprite.region_rect = atlas_rect(facing, frame)
			sprite.flip_h = mirrored(facing)
		else:
			sprite.flip_h = false
		var default_color: Color = body.record.registry.get_spec(category, "color").get("default", Color.WHITE)
		sprite.modulate = Color.WHITE if _marker.color == default_color else _marker.color
	var instances: Dictionary = body.record.get_component("ABILITY_SET").get("instances", {})
	var walk := module_state(instances, "WALK")
	var fly := module_state(instances, "FLY")
	var alive: bool = body.get_parameter("alive")
	var next_color: Color = _marker.color
	var changed := category_changed or installed_walk != bool(walk.x) or enabled_walk != bool(walk.y) or installed_fly != bool(fly.x) or enabled_fly != bool(fly.y) or _alive != alive or _limb_color != next_color
	installed_walk = bool(walk.x)
	enabled_walk = bool(walk.y)
	installed_fly = bool(fly.x)
	enabled_fly = bool(fly.y)
	_alive = alive
	_limb_color = next_color
	if changed or installed_walk:
		queue_redraw()


func _draw() -> void:
	# DEV placeholders only for ordinary props. Do not infer species anatomy
	# or turn a temporary effect into an owned module.
	if _category not in ["prop", "fridge"]:
		return
	if installed_fly:
		var wing := _limb_color.lightened(0.28)
		if not enabled_fly or not _alive:
			wing = wing.darkened(0.25)
		draw_colored_polygon(PackedVector2Array([Vector2(-8, -21), Vector2(-25, -28), Vector2(-21, -15), Vector2(-9, -12)]), wing)
		draw_colored_polygon(PackedVector2Array([Vector2(8, -21), Vector2(25, -28), Vector2(21, -15), Vector2(9, -12)]), wing)
	if installed_walk:
		var leg := _limb_color.darkened(0.25)
		var stride := 3.0 if _alive and enabled_walk and frame % 2 == 1 else 0.0
		draw_polyline(PackedVector2Array([Vector2(-6, -9), Vector2(-6 - stride, -3), Vector2(-9 - stride, 0)]), leg, 3.0)
		draw_polyline(PackedVector2Array([Vector2(6, -9), Vector2(6 + stride, -3), Vector2(9 + stride, 0)]), leg, 3.0)
