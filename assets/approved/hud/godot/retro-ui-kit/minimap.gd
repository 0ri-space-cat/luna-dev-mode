extends Control
## Marker positions are normalized in map space. The host controls discovery.
const Retro = preload("res://retro_ui_2d.gd")
const KINDS := ["player", "passage", "bridge", "quest", "pin"]
const MAP_SHADER := """
shader_type canvas_item;
uniform float zoom = 1.0;
void fragment() {
	vec2 centered = UV - vec2(0.5);
	COLOR = texture(TEXTURE, centered / zoom + vec2(0.5));
	COLOR.a *= step(length(centered), 0.445);
}
"""

var _zoom := 1.0
var _markers: Array = []
var _icons: Dictionary = {}
var _ring: Texture2D
var _map: TextureRect

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for kind in KINDS:
		_icons[kind] = Retro.texture("common/map_" + kind)
	_map = TextureRect.new()
	_map.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_map.stretch_mode = TextureRect.STRETCH_SCALE
	_map.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map.show_behind_parent = true
	var shader := Shader.new()
	shader.code = MAP_SHADER
	var mask := ShaderMaterial.new()
	mask.shader = shader
	_map.material = mask
	add_child(_map)
	_map.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(queue_redraw)

func set_data(id: String, source: Texture2D, markers: Array) -> void:
	_ring = Retro.texture(Retro.part(id, "minimap_ring"))
	_map.texture = source
	_markers = markers.duplicate()
	queue_redraw()

func change_zoom(step: float) -> void:
	_zoom = clampf(_zoom + step, 1.0, 2.5)
	_map.material.set_shader_parameter("zoom", _zoom)
	queue_redraw()

func _draw() -> void:
	if _map == null or _map.texture == null:
		draw_circle(size * 0.5, size.x * 0.45, Color("#252542"))
	# Draw order is made explicit by the transparent map layer being behind this control.
	if _ring != null:
		draw_texture_rect(_ring, Rect2(Vector2.ZERO, size), false)
	for marker in _markers:
		var icon: Texture2D = _icons.get(str(marker.get("kind", "")))
		if icon == null:
			continue
		var uv: Vector2 = marker.get("uv", Vector2(0.5, 0.5))
		var offset := (uv - Vector2(0.5, 0.5)) * _zoom
		if offset.length() > 0.38:
			continue
		var marker_size := 26.0 if marker.get("kind") == "player" else 22.0
		var at := size * (Vector2(0.5, 0.5) + offset) - Vector2.ONE * marker_size / 2.0
		draw_texture_rect(icon, Rect2(at.round(), Vector2.ONE * marker_size), false)
