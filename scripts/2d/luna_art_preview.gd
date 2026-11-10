extends Node2D
## Experimental classic controls; disable in the Inspector to restore mouse facing.
@export var face_movement_direction := true
## Chunky pixel art playground. Views are kept on their full source canvases;
## Authored whole-body cels share one state clock; classic movement facing is default.
signal cast_released(direction: Vector2)

const BASE_SCALE := 0.1875
const MOVE_SPEED := 210.0
const WORLD_SIZE := Vector2(1472.0, 1024.0)
const FEET_Y := {"side_right.png": 1495, "front_right.png": 1510, "back_right.png": 1495, "back.png": 1498, "front.png": 1489}
const ASSETS := {
	"back_right": "res://assets/2d/characters/luna/explorer_v1/back_right.png",
	"back": "res://assets/2d/characters/luna/explorer_v1/back.png",
	"front": "res://assets/2d/characters/luna/explorer_v1/front.png",
	"front_right": "res://assets/2d/characters/luna/explorer_v1/front_right.png",
	"side_right": "res://assets/2d/characters/luna/explorer_v1/side_right.png",
}

@onready var back_right: Sprite2D = $LunaRig/BackRight
@onready var back: Sprite2D = $LunaRig/Back
@onready var luna: Node2D = $LunaRig
@onready var camera: Camera2D = $LunaRig/Camera2D
@onready var front: Sprite2D = $LunaRig/Front
@onready var front_right: Sprite2D = $LunaRig/FrontRight
@onready var side_right: Sprite2D = $LunaRig/SideRight

var current_view := "front"
var size_multiplier := 1.0
var elapsed := 0.0
var walk_phase := 0.0
var animator = preload("res://scripts/2d/luna_sprite_animator.gd").new()
var animation_state := "idle"
var cast_active := false
var cast_time := 0.0
var cast_fired := false
var cast_direction := Vector2.DOWN
var blink_time := -1.0
var hair_time := -1.0
var blink_wait := 3.7
var hair_wait := 7.1
var random := RandomNumberGenerator.new()

func _ready() -> void:
	get_window().title = "LUNA — движение и магия"
	animator.configure(ASSETS, FEET_Y)
	random.seed = 43021
	_load_sprite(back_right, ASSETS["back_right"])
	_load_sprite(back, ASSETS["back"])
	_load_sprite(front, ASSETS["front"])
	_load_sprite(front_right, ASSETS["front_right"])
	_load_sprite(side_right, ASSETS["side_right"])
	animator.preload_cels()
	_apply_size()
	_show_view("front")

func _load_sprite(sprite: Sprite2D, path: String) -> void:
	sprite.texture = animator.texture_for_path(path)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.set_meta("feet_y", FEET_Y[path.get_file()])
	sprite.scale = Vector2.ONE * BASE_SCALE * size_multiplier
	_update_anchor(sprite)

func _update_anchor(sprite: Sprite2D, bounce := 0.0) -> void:
	var feet_offset := float(sprite.get_meta("feet_y")) - sprite.texture.get_height() * 0.5
	sprite.position.y = -feet_offset * sprite.scale.y - bounce

func _process(delta: float) -> void:
	var aim := Vector2.ZERO if face_movement_direction else get_global_mouse_position() - luna.global_position
	advance_animation(delta, _movement_input(), aim)

func advance_animation(delta: float, movement: Vector2, aim: Vector2) -> void:
	# Keep the last direction when the keys are released; mouse motion is ignored.
	var facing := movement.normalized() * 10.0 if face_movement_direction else aim
	elapsed += delta
	if cast_active:
		cast_time += delta
		if cast_time >= animator.CAST_RELEASE_TIME and not cast_fired:
			cast_fired = true
			cast_released.emit(cast_direction)
		if cast_time >= animator.CAST_DURATION:
			cast_active = false
	var is_walking := not movement.is_zero_approx() and not cast_active
	if is_walking:
		luna.position += movement.normalized() * MOVE_SPEED * delta
		_clamp_position()
		walk_phase += delta * (-1.0 if movement.dot(facing.normalized()) < -0.2 else 1.0)
	else:
		walk_phase = 0.0
	if not cast_active:
		var requested_view := _stable_view_from_aim(facing)
		if not requested_view.is_empty() and requested_view != current_view:
			_show_view(requested_view)
	if not is_walking and not cast_active:
		blink_wait -= delta
	if blink_wait <= 0.0 and not cast_active and not is_walking:
		request_blink()
	if blink_time >= 0.0:
		blink_time += delta
		if blink_time > 0.18: blink_time = -1.0
	if not is_walking and not cast_active:
		hair_wait -= delta
		if hair_wait <= 0.0:
			request_hair_flutter()
	else:
		hair_time = -1.0
	if hair_time >= 0.0:
		hair_time += delta
		if hair_time > 0.42: hair_time = -1.0
	animation_state = "cast" if cast_active else ("walk" if is_walking else "idle")
	_refresh_animation()

func request_blink() -> void:
	if cast_active: return
	blink_time = 0.0
	blink_wait = random.randf_range(3.0, 6.0)

func request_hair_flutter() -> void:
	if cast_active: return
	hair_time = 0.0
	hair_wait = random.randf_range(5.0, 10.0)

func request_cast() -> void:
	if cast_active: return
	cast_active = true
	cast_time = 0.0
	cast_fired = false
	cast_direction = direction_for_view(current_view)
	blink_time = -1.0
	hair_time = -1.0
	animation_state = "cast"
	_refresh_animation()

func _refresh_animation() -> void:
	var canonical := current_view.replace("_left", "_right")
	var sprite := sprite_for_view(canonical)
	var clip := animation_state
	var time := cast_time if cast_active else walk_phase
	var bounce := absf(sin(walk_phase * TAU * 2.0)) * 1.5 if clip == "walk" else sin(elapsed * 2.5) * 0.8
	if clip == "idle":
		if blink_time >= 0.0 and canonical in ["front", "front_right", "side_right"]:
			clip = "blink"
			time = blink_time
		elif hair_time >= 0.0:
			clip = "hair"
			time = hair_time
	animator.apply(sprite, canonical, clip, time, BASE_SCALE * size_multiplier, bounce)

func sprite_for_view(view: String) -> Sprite2D:
	match view:
		"front": return front
		"front_right": return front_right
		"side_right": return side_right
		"back": return back
		_: return back_right

func _movement_input() -> Vector2:
	var value := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): value.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): value.x += 1.0
	if Input.is_physical_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): value.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): value.y += 1.0
	return value.limit_length(1.0)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_B or event.keycode == KEY_B:
			request_blink()
			return
		if event.physical_keycode == KEY_H or event.keycode == KEY_H:
			request_hair_flutter()
			return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		request_cast()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		request_cast()
		return
	if not (event is InputEventMouseButton) or not event.pressed:
		return
	if event.button_index == MOUSE_BUTTON_WHEEL_UP:
		size_multiplier = minf(2.0, size_multiplier + 0.1)
		_apply_size()
	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		size_multiplier = maxf(0.5, size_multiplier - 0.1)
		_apply_size()

func _clamp_position() -> void:
	var margin := Vector2(96.0 * size_multiplier + 16.0, 288.0 * size_multiplier + 16.0)
	luna.position = luna.position.clamp(margin, WORLD_SIZE - Vector2(margin.x, 32.0))

func _apply_size() -> void:
	camera.position = Vector2(0.0, -144.0 * size_multiplier)
	_clamp_position()
	for sprite in [front, front_right, side_right, back, back_right]:
		sprite.scale = Vector2.ONE * BASE_SCALE * size_multiplier
		_update_anchor(sprite)

func _show_view(view_name: String) -> void:
	current_view = view_name
	back_right.visible = view_name in ["back_right", "back_left"]
	back_right.flip_h = view_name == "back_left"
	back.visible = view_name == "back"
	front.visible = view_name == "front"
	front_right.visible = view_name in ["front_right", "front_left"]
	side_right.visible = view_name in ["side_right", "side_left"]
	front_right.flip_h = view_name == "front_left"
	side_right.flip_h = view_name == "side_left"

func _stable_view_from_aim(aim: Vector2) -> String:
	var desired := view_from_aim(aim)
	if desired.is_empty() or desired == current_view: return desired
	var angle_error := absf(wrapf(aim.angle() - direction_for_view(current_view).angle(), -PI, PI))
	return current_view if angle_error < PI / 8.0 + deg_to_rad(4.0) else desired

static func direction_for_view(view: String) -> Vector2:
	return {"front": Vector2.DOWN, "front_right": Vector2(1,1).normalized(), "front_left": Vector2(-1,1).normalized(), "side_right": Vector2.RIGHT, "side_left": Vector2.LEFT, "back": Vector2.UP, "back_right": Vector2(1,-1).normalized(), "back_left": Vector2(-1,-1).normalized()}[view]

static func view_from_aim(aim: Vector2) -> String:
	if aim.length_squared() < 1.0:
		return ""
	if aim.y < 0.0 and absf(aim.x) < absf(aim.y) * 0.42:
		return "back"
	var ratio := absf(aim.x) / maxf(absf(aim.y), 0.001)
	if aim.y >= 0.0 and ratio < 0.42:
		return "front"
	if ratio < 2.4:
		if aim.y < 0.0:
			return "back_right" if aim.x >= 0.0 else "back_left"
		return "front_right" if aim.x >= 0.0 else "front_left"
	return "side_right" if aim.x >= 0.0 else "side_left"
