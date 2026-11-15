extends Node2D
## One logical rectangle, two authored background plates. Neither affects collision.
## The two textures must share pixel dimensions and registration/origin.

@export var normal_plate: Texture2D
@export var underside_plate: Texture2D
@export var level_size := Vector2(1536, 1024)

var underside := false
var normal_sprite: Sprite2D
var underside_sprite: Sprite2D


func _ready() -> void:
	normal_sprite = Sprite2D.new()
	underside_sprite = Sprite2D.new()
	for sprite in [normal_sprite, underside_sprite]:
		sprite.centered = false
		sprite.position = -level_size * 0.5
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(sprite)
	_apply_textures()


func set_plates(ordinary: Texture2D, hidden: Texture2D) -> bool:
	if (ordinary == null) != (hidden == null):
		return false
	if ordinary != null and ordinary.get_size() != hidden.get_size():
		return false
	if ordinary != null and Vector2(ordinary.get_size()) != level_size:
		return false
	normal_plate = ordinary
	underside_plate = hidden
	if is_node_ready():
		_apply_textures()
	return true


func set_underside(value: bool) -> void:
	if underside == value:
		return
	underside = value
	if is_node_ready():
		_apply_textures()


func _apply_textures() -> void:
	normal_sprite.texture = normal_plate
	underside_sprite.texture = underside_plate
	normal_sprite.visible = not underside
	underside_sprite.visible = underside
	queue_redraw()


func _draw() -> void:
	# Debug-only grid when production art is absent; it is never collision data.
	if normal_plate != null and underside_plate != null:
		return
	var half: Vector2 = level_size * 0.5
	var rect := Rect2(-half, level_size)
	var base := Color("081421") if underside else Color("263044")
	var line := Color("1be6ed", 0.45) if underside else Color("71839a", 0.14)
	draw_rect(rect, base)
	for x in range(0, int(level_size.x) + 1, 64):
		var xx: float = float(x) - half.x
		draw_line(Vector2(xx, -half.y), Vector2(xx, half.y), line, 1.0)
	for y in range(0, int(level_size.y) + 1, 64):
		var yy: float = float(y) - half.y
		draw_line(Vector2(-half.x, yy), Vector2(half.x, yy), line, 1.0)
	draw_rect(rect, Color("45f6ff") if underside else Color("7486af"), false, 3.0)
