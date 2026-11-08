extends Node2D
## Art-driven cutout puppet: three directional source drawings, four facings,
## joint-animated legs/arms, independent idle/walk/run/cast/hit/turn states.
## Pixels are imported SVG; animation changes only bones and overlays.
const ART := "res://assets/2d/characters/luna/"
const PixelArt = preload("res://scripts/2d/pixel_art_pipeline_2d.gd")
const PIXEL_SHEET := "res://assets/2d/characters/luna/pixel/luna_sheet.png"
const PIXEL_SHEET_WEBP := "res://assets/2d/characters/luna/pixel/luna_sheet.webp"
const DRAWING_SCALE := 0.68
var front: Texture2D
var back: Texture2D
var side: Texture2D
var body: Sprite2D
var animated: AnimatedSprite2D
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
	# Install the authored pixel sheet if present; otherwise keep the legacy SVG skin.
	var source_path := PIXEL_SHEET if ResourceLoader.exists(PIXEL_SHEET) else PIXEL_SHEET_WEBP
	if ResourceLoader.exists(source_path):
		install_pixel_sprite(load(source_path) as Texture2D)

func _arm(tint: Color, width: float) -> Line2D:
	var line := Line2D.new()
	line.width = width
	line.default_color = tint
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	add_child(line)
	return line

func _rig_sprite(id: String, factor: float) -> Sprite2D:
	var icon := Sprite2D.new()
	icon.texture = load(ART + id + ".svg")
	icon.scale = Vector2.ONE * factor
	add_child(icon)
	return icon

func install_pixel_sprite(source: Texture2D) -> bool:
	# Three drawn views: down, side (mirrored for left), and up. Two frames each.
	var names := ["idle_down", "idle_right", "idle_up", "walk_down", "walk_right", "walk_up", "cast_down", "cast_right", "cast_up"]
	var plan := {}
	for i in range(names.size()):
		plan[names[i]] = {"row":i, "frames":2, "loop":true}
	var frames: SpriteFrames = PixelArt.build_sprite_frames(source, Vector2i(48, 64), plan, 6.0)
	if frames == null:
		push_warning("Luna pixel sheet must be 96x576 for the first two-frame prototype.")
		return false
	if not is_instance_valid(animated):
		animated = AnimatedSprite2D.new()
		animated.name = "PixelFrames"
		add_child(animated)
	if not PixelArt.configure_animated_sprite(animated, frames, 2):
		return false
	animated.position = Vector2(0, -64)
	for item in [body, left_arm, right_arm, left_hand, right_hand, boot_left, boot_right, wand]:
		if is_instance_valid(item):
			item.visible = false
	animated.play("idle_down")
	return true

func _update_pixel_animation(moving: bool, running: bool) -> void:
	if not is_instance_valid(animated):
		return
	var direction := "right" if facing in ["left","right"] else facing
	var action := "cast" if mode in ["cast","interact","surprise"] else ("walk" if moving else "idle")
	var animation_name := action + "_" + direction
	if animated.animation != animation_name:
		animated.play(animation_name)
	animated.flip_h = facing == "left"
	animated.speed_scale = 1.4 if running and action == "walk" else 1.0

func trigger_action(action: String, duration: float = 0.5) -> void:
	if action in ["cast", "hurt", "interact", "surprise"]:
		mode = action
		action_remaining = maxf(0.1, duration)
		animation_time = 0.0

func set_motion(movement: Vector2, running: bool, delta: float, aim: Vector2 = Vector2.ZERO) -> void:
	elapsed += delta
	var moving := movement.length_squared() > 16.0
	var changed_direction := false
	# Cursor aim takes priority over WASD; older tests/callers can omit aim.
	var looking := aim if aim.length_squared() > 625.0 else (movement if moving else Vector2.ZERO)
	if looking.length_squared() > 0.01:
		if absf(looking.x) > absf(looking.y) * 1.18:
			facing = "right" if looking.x > 0.0 else "left"
		else:
			facing = "down" if looking.y > 0.0 else "up"
		changed_direction = facing != _last_facing
	_last_facing = facing
	if action_remaining > 0.0:
		action_remaining = maxf(0.0, action_remaining - delta)
	else:
		mode = "run" if moving and running else ("walk" if moving else "idle")
	animation_time += delta
	if is_instance_valid(animated):
		_update_pixel_animation(moving, running)
		queue_redraw()
		return
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
	var step := sin(phase)*7.0*weight
	var foot_lift := absf(cos(phase))*4.0*weight
	boot_left.position = Vector2(-9.0+step,13.0-foot_lift+body_shift)
	boot_right.position = Vector2(15.0-step,11.0+foot_lift+body_shift)
	boot_left.flip_h = facing == "left"
	boot_right.flip_h = facing == "left"
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
	left_hand.position = left_arm.points[1]
	right_hand.position = right_arm.points[1]
	left_hand.visible = left_arm.visible
	right_hand.visible = right_arm.visible

func _draw() -> void:
	if is_instance_valid(animated):
		draw_ellipse_shadow()
		return
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
	
