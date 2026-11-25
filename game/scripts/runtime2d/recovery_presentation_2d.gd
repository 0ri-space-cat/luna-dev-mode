extends CanvasLayer
## One in-game report sequence. The caller commits the shared recovery afterward.

signal finished
const DURATION := 1.65
const COLLAPSE_END := 0.55
const BOOT_END := 1.18

var elapsed := 0.0
var active := false

@onready var _veil: ColorRect = $Veil
@onready var _text: Label = $Message
@onready var _shards: Node2D = $Fractures


func _ready() -> void:
	_shards.draw.connect(_draw_fractures)
	hide()


func begin() -> void:
	elapsed = 0.0
	active = true
	show()
	_update_frame()


func _process(delta: float) -> void:
	if not active:
		return
	elapsed = minf(elapsed + delta, DURATION)
	_update_frame()
	if elapsed >= DURATION:
		active = false
		finished.emit()


func _update_frame() -> void:
	_shards.visible = elapsed < COLLAPSE_END
	if _shards.visible:
		_veil.color = Color(0.08, 0.06, 0.16, 0.25 + 0.71 * elapsed / COLLAPSE_END)
		_text.text = ""
		_shards.queue_redraw()
	elif elapsed < BOOT_END:
		_veil.color = Color("171321")
		_text.text = "ETERNIA  /  LOADING %02d%%" % int(100.0 * (elapsed - COLLAPSE_END) / (BOOT_END - COLLAPSE_END))
	else:
		_veil.color = Color("171321")
		_text.text = "ERROR. CHARACTER NOT FOUND."


func _draw_fractures() -> void:
	var bounds := get_viewport().get_visible_rect().size
	var spread := elapsed / COLLAPSE_END
	var center := bounds * Vector2(0.52, 0.47)
	for index in 9:
		var direction := Vector2.from_angle(float(index) * TAU / 9.0)
		var bend := direction.rotated(0.34 if index % 2 == 0 else -0.34)
		var points := PackedVector2Array([center, center + direction * 190.0 * spread,
			center + bend * 330.0 * spread + direction * 100.0 * spread,
			center + direction * 840.0 * spread])
		_shards.draw_polyline(points, Color("d2b9ee"), 2.0)
