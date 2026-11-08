extends Node2D
## Shared removable limb module for hacked objects.
## Pixel source is optional; until ImageGen art arrives, reuse existing authored boot.
const PIXEL_LEG := "res://assets/2d/eternia/pixel/shared/round_leg.png"
const LEGACY_LEG := "res://assets/2d/characters/luna/boot.svg"
var left: Sprite2D
var right: Sprite2D
var kind := "fridge"
var current_source := ""
const STANCE := {
	"fridge":{"offset":20.0,"base_y":8.0,"scale":0.32},
	"tree":{"offset":15.0,"base_y":7.0,"scale":0.30},
	"flower":{"offset":10.0,"base_y":5.0,"scale":0.23},
	"crystal":{"offset":10.0,"base_y":5.0,"scale":0.25}
}

func configure(species: String) -> void:
	kind = species if STANCE.has(species) else ""
	if is_instance_valid(left):
		_apply_stance()

func _ready() -> void:
	var path := PIXEL_LEG if ResourceLoader.exists(PIXEL_LEG) else LEGACY_LEG
	if not ResourceLoader.exists(path):
		push_warning("No authored universal leg: " + path)
		visible = false
		return
	current_source = path
	var tex := load(path) as Texture2D
	if tex == null:
		visible = false
		return
	left = _new_leg(tex, "LegLeft")
	right = _new_leg(tex, "LegRight")
	_apply_stance()
	visible = false

func _new_leg(tex: Texture2D, node_name: String) -> Sprite2D:
	var leg := Sprite2D.new()
	leg.name = node_name
	leg.texture = tex
	leg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	leg.centered = true
	add_child(leg)
	return leg

func _apply_stance() -> void:
	if not is_instance_valid(left) or not is_instance_valid(right):
		return
	if not STANCE.has(kind):
		visible = false
		return
	var setting: Dictionary = STANCE[kind]
	var size := float(setting["scale"])
	# New ImageGen pixel legs are native ~22px, while SVG fallback boots are larger.
	if current_source == PIXEL_LEG:
		size *= 3.0
	left.scale = Vector2.ONE * size
	right.scale = Vector2.ONE * size
	right.flip_h = true

func set_motion(alive: bool, velocity: Vector2, seconds: float) -> void:
	visible = alive and STANCE.has(kind) and is_instance_valid(left) and is_instance_valid(right)
	if not visible:
		return
	var setting: Dictionary = STANCE[kind]
	var spread: float = float(setting["offset"])
	var ground_y: float = float(setting["base_y"])
	var speed_ratio := clampf(velocity.length() / 90.0, 0.0, 1.0)
	var step := sin(seconds * 11.0) * speed_ratio
	left.position = Vector2(-spread + step * 6.0, ground_y - maxf(0.0,step) * 3.0)
	right.position = Vector2(spread - step * 6.0, ground_y + minf(0.0,step) * 3.0)
	left.rotation = step * 0.15
	right.rotation = -step * 0.15
