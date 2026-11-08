extends Node2D
## Art-driven cutout puppet: three directional source drawings, four facings,
## joint-animated legs/arms, independent idle/walk/run/cast/hit/turn states.
## Pixels are imported SVG; animation changes only bones and overlays.
const ART := "res://assets/2d/characters/luna/"
const DRAWING_SCALE := 0.68
var front: Texture2D
var back: Texture2D
var side: Texture2D
var body: Sprite2D
var left_arm: Line2D
var right_arm: Line2D
var wand: Node2D
var left_hand: Sprite2D
var right_hand: Sprite2D
var boot_left: Sprite2D
var boot_right: Sprite2D
var facing := "down"
var mode := "idle"
var elapsed := 0.0
var animation_time := 0.0
var action_remaining := 0.0
var _blink_timer := 0.0
var _foot_color := Color("#7844b1")
var _outline := Color("#3d225a")
var _last_facing := "down"

func _ready() -> void:
	front = load(ART + "luna_front.svg")
	back = load(ART + "luna_back.svg")
	side = load(ART + "luna_side.svg")
	body = Sprite2D.new()
	body.texture = front
	body.scale = Vector2.ONE * DRAWING_SCALE
	body.position = Vector2(0, -59)
	add_child(body)
	left_arm = _arm(Color("#af72dd"), 9.0)
	right_arm = _arm(Color("#ad6cdb"), 9.0)
	left_hand = _rig_sprite("hand",0.42)
	right_hand = _rig_sprite("hand",0.42)
	boot_left = _rig_sprite("boot",0.45)
	boot_right = _rig_sprite("boot",0.45)
	wand = Node2D.new()
	wand.set_script(preload("res://scripts/2d/wand_visual_2d.gd"))
	add_child(wand)
	wand.position = Vector2(39, -36)
	_select_drawing()

func _arm(tint: Color, width: float) -> Line2D:
	var line := Line2D.new()
	line.width = width
	line.default_color = tint
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	add_child(line)
	return line

func trigger_action(action: String, duration: float = 0.5) -> void:
	if action in ["cast", "hurt", "interact", "surprise"]:
		mode = action
		action_remaining = maxf(0.1, duration)
		animation_time = 0.0

func set_motion(movement: Vector2, running: bool, delta: float) -> void:
	elapsed += delta
	var moving := movement.length_squared() > 16.0
	var changed_direction := false
	if moving:
		if absf(movement.x) > absf(movement.y) * 1.18:
			facing = "right" if movement.x > 0.0 else "left"
		else:
			facing = "down" if movement.y > 0.0 else "up"
		changed_direction = facing != _last_facing
	_last_facing = facing
	if action_remaining > 0.0:
		action_remaining = maxf(0.0, action_remaining - delta)
	else:
		mode = "run" if moving and running else ("walk" if moving else "idle")
	animation_time += delta
	_select_drawing()
	var stride_speed := 14.5 if mode == "run" else 9.2
	var weight := 1.0 if mode == "run" else (0.72 if mode == "walk" else 0.0)
	var phase := elapsed * stride_speed
	var leg_swing := sin(phase) * 7.0 * weight
	var shoulder_swing := sin(phase) * 5.0 * weight
	var breathing := sin(elapsed * 2.4) * 1.7
	var bounce := absf(sin(phase)) * 2.9 * weight
	var action_lift := (sin(animation_time * 12.0) * 3.0) if mode == "cast" else 0.0
	body.position.y = -59.0 + breathing - bounce - action_lift
	body.rotation = (0.085 * sin(elapsed * 14.5)) if mode == "hurt" else (0.015 * sin(elapsed * 3.0))
	if changed_direction:
		body.rotation += 0.11 if facing in ["right", "down"] else -0.11
	body.modulate = Color("#ffb6ca") if mode == "hurt" else Color.WHITE
	# Stylized bone positions; never create or remove limbs mid-animation.
	_update_hands(shoulder_swing)
	var body_shift := body.position.y + 59.0
	var wrist := Vector2(-37,-19-shoulder_swing+body_shift) if facing == "left" else Vector2(34,-22+shoulder_swing+body_shift)
	if mode == "cast":
		wrist.y -= 29.0
	wand.position = wrist - Vector2(0,16)
	wand.rotation = -0.4 if mode == "cast" else (0.16 * sin(phase) * weight)
	wand.visible = facing != "up"

	queue_redraw()

func _select_drawing() -> void:
	if not is_instance_valid(body):
		return
	match facing:
		"up":
			body.texture = back
			body.flip_h = false
		"right":
			body.texture = side
			body.flip_h = false
		"left":
			body.texture = side
			body.flip_h = true
		_:
			body.texture = front
			body.flip_h = false

func _update_hands(swing: float) -> void:
	var body_shift := body.position.y + 59.0
	var lift := -29.0 if mode == "cast" else 0.0
	left_arm.points = PackedVector2Array([Vector2(-25,-37+body_shift),Vector2(-37,-19-swing+body_shift+(lift if facing == "left" else 0.0))])
	right_arm.points = PackedVector2Array([Vector2(24,-37+body_shift),Vector2(34,-22+swing+body_shift+(lift if facing != "left" else 0.0))])
	left_arm.visible = facing != "up"
	right_arm.visible = facing != "up"

func _draw() -> void:
	var weight := 1.0 if mode == "run" else (0.68 if mode == "walk" else 0.0)
	var phase := elapsed * (14.5 if mode == "run" else 9.2)
	var left_x := -12.0 + sin(phase) * 7.0 * weight
	var right_x := 12.0 - sin(phase) * 7.0 * weight
	var leg_bob := absf(cos(phase)) * 4.0 * weight
	draw_ellipse_shadow()
	var body_shift := body.position.y + 59.0
	draw_set_transform(Vector2(0,body_shift),0,Vector2.ONE)
	_draw_leg(left_x, -leg_bob)
	_draw_leg(right_x, -2.0 + leg_bob)
	draw_set_transform(Vector2.ZERO,0,Vector2.ONE)

func draw_ellipse_shadow() -> void:
	var shadow := Color(0.08,0.04,0.17,0.22)
	draw_set_transform(Vector2(0,15),0.0,Vector2(1.35,0.32))
	draw_circle(Vector2.ZERO, 22.0, shadow)
	draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)

func _draw_leg(x: float, up: float) -> void:
	var y := 3.0 + up
	draw_line(Vector2(x * 0.68,-8),Vector2(x,y),_outline,13.0,true)
	draw_line(Vector2(x * 0.68,-8),Vector2(x,y),Color("#efd0e9"),9.0,true)
	draw_line(Vector2(x,y),Vector2(x + (3 if facing in ["right","down"] else -3), 15.0 + up),_outline,17.0,true)
	draw_line(Vector2(x,y),Vector2(x + (3 if facing in ["right","down"] else -3), 15.0 + up),_foot_color,13.0,true)
	draw_circle(Vector2(x + 4, 13.0 + up), 3.3, Color("#f4a6e6"))
