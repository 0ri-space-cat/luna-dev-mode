extends Node2D
## Animated 2D creature with the anatomy locked into authored SVG illustrations.
## Repeated motion only animates joints and transforms; no regenerated limbs.
const ART := "res://assets/2d/creatures/"
const UniversalLegs = preload("res://scripts/2d/universal_round_legs_2d.gd")
const PIXEL_DECOR := "res://assets/2d/eternia/pixel/decor/"
var kind := "slime"
var sprite: Sprite2D
var legs: Node2D
var t := 0.0
var foot_phase := 0.0
var direction := Vector2.DOWN
var current_art := ""
var frame_cache: Dictionary = {}
var state := "idle"
var action_time := 0.0
var blink_clock := 0.0
var visual_tint := Color.WHITE
var selected := false

func configure(species: String) -> void:
	kind = species
	if is_instance_valid(sprite):
		_assign_texture()

func _ready() -> void:
	legs = UniversalLegs.new()
	add_child(legs)
	legs.configure(kind)
	sprite = Sprite2D.new()
	add_child(sprite)
	_assign_texture()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

func _assign_texture() -> void:
	if kind not in ["sheep", "fridge", "duck", "slime", "tree", "flower", "crystal"]:
		kind = "slime"
	current_art = ""
	_update_directional_texture()
	var sizes := {"sheep": 0.62, "fridge": 0.56, "duck": 0.67, "slime": 0.63, "tree": 0.78, "flower": 0.20, "crystal": 0.23}
	var k: float = float(sizes.get(kind, 0.60))
	sprite.scale = Vector2.ONE * k
	var y: Dictionary = {"sheep": -35.0, "fridge": -52.0, "duck": -40.0, "slime": -32.0, "tree": -74.0, "flower": -24.0, "crystal": -28.0}
	sprite.position = Vector2(0, float(y.get(kind, -38.0)))

func react(kind_of_reaction: String = "surprised") -> void:
	state = kind_of_reaction
	action_time = 0.45

func _process(delta: float) -> void:
	t += delta
	var actor: CharacterBody2D = get_parent() as CharacterBody2D
	if actor == null or actor.get("record") == null or not is_instance_valid(sprite):
		return
	var alive := bool(actor.call("get_parameter", "alive"))
	var moving := alive and actor.velocity.length_squared() > 80.0
	if action_time > 0.0:
		action_time = maxf(0.0, action_time - delta)
		if action_time <= 0.0:
			state = "idle"
	else:
		state = "walk" if moving else "idle"
	if moving:
		direction = actor.velocity.normalized()
	var magnitude := 1.0 if moving else 0.0
	var phase := t * (11.0 if kind in ["duck","fridge"] else 9.0)
	foot_phase = phase
	var hop := absf(sin(phase)) * magnitude * (4.0 if kind in ["sheep", "duck", "slime"] else 2.0)
	sprite.position.y = ({"sheep": -35.0,"fridge": -52.0,"duck": -40.0,"slime": -32.0,"tree": -74.0}.get(kind, -38.0)) - hop + sin(t * 2.0) * (1.4 if alive else 0.5)
	sprite.rotation = (0.055 if kind == "tree" else 0.04) * sin(phase) * magnitude
	if kind == "slime":
		sprite.scale.y = 0.63 + (0.065 * sin(t * 4.5))
	elif kind == "tree":
		sprite.rotation += 0.025 * sin(t * 1.5)
	else:
		sprite.scale.y = absf(sprite.scale.x) * (1.0 + 0.015 * sin(t*3.0))
	_update_directional_texture()
	if is_instance_valid(legs):
		legs.call("set_motion", alive, actor.velocity, t)
	var color: Color = actor.call("get_parameter", "color")
	visual_tint = Color.WHITE.lerp(color, 0.28)
	sprite.modulate = visual_tint
	if not alive:
		sprite.modulate = sprite.modulate.darkened(0.17)
	if state == "surprised":
		sprite.modulate = Color.WHITE
	queue_redraw()

func _draw() -> void:
	var actor: CharacterBody2D = get_parent() as CharacterBody2D
	if actor == null or actor.get("record") == null:
		return
	var alive := bool(actor.call("get_parameter", "alive"))
	var moving := alive and actor.velocity.length_squared() > 80.0
	var stride := sin(foot_phase) * (6.0 if kind == "fridge" else 4.5) if moving else 0.0
	var shadow := Color(0.10,0.04,0.19,0.22)
	draw_set_transform(Vector2(0,11),0.0,Vector2(1.3,0.36))
	draw_circle(Vector2.ZERO, 20.0 if kind == "tree" else 15.0, shadow)
	draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
	if selected:
		draw_arc(Vector2(0,-34),54,0,TAU,48,Color("#72fcff",0.8),2)
	var base_y: float = float({"sheep":-35.0,"fridge":-52.0,"duck":-40.0,"slime":-32.0,"tree":-74.0}.get(kind,-38.0))
	draw_set_transform(Vector2(0,sprite.position.y-base_y),0.0,Vector2.ONE)
	if kind == "slime":
		if moving:
			draw_arc(Vector2(0,0),27,0,PI,16,Color("#79f2ff",0.7),3)
		return
	if kind == "tree" or kind in ["flower", "crystal"]:
		return
	if kind == "fridge" and alive:
		var arm_wiggle := sin(t*5) * (8.0 if moving else 3.0)
		draw_line(Vector2(-33,-35),Vector2(-48,-19 + arm_wiggle),Color("#493068"),11,true)
		draw_line(Vector2(-33,-35),Vector2(-48,-19 + arm_wiggle),Color("#c9a4df"),7,true)
		draw_line(Vector2(33,-35),Vector2(47,-19 - arm_wiggle),Color("#493068"),11,true)
		draw_line(Vector2(33,-35),Vector2(47,-19 - arm_wiggle),Color("#c9a4df"),7,true)
	elif kind in ["sheep","duck"]:
		var leg_color := Color("#f5bcde") if kind == "sheep" else Color("#ed943b")
		if kind == "sheep":
			# Exactly four legs in every state: two hind + two front.
			_draw_boot(-29.0 + stride*0.7, 6.0, leg_color.darkened(0.16), 7)
			_draw_boot(27.0 - stride*0.7, 6.0, leg_color.darkened(0.16), 7)
			_draw_boot(-16.0 - stride, 11.0, leg_color, 8)
			_draw_boot(16.0 + stride, 11.0, leg_color, 8)
		else:
			# Ducks have exactly two legs; no generative extra appendages.
			_draw_boot(-12.0 + stride, 9.0,leg_color, 8)
			_draw_boot(12.0 - stride, 9.0,leg_color, 8)

func _draw_boot(x: float, y: float, tint: Color, radius: float) -> void:
	draw_line(Vector2(x*0.65,-7),Vector2(x,y-1),Color("#41265c"),radius+5.0,true)
	draw_line(Vector2(x*0.65,-7),Vector2(x,y-1),tint,radius+1.0,true)
	draw_circle(Vector2(x+3,y),radius*0.5,Color("#41265c"))
	draw_circle(Vector2(x+3,y-1),radius*0.37,tint.lightened(0.2))

func _update_directional_texture() -> void:
	if not is_instance_valid(sprite):
		return
	var variant := kind
	if kind in ["flower", "crystal"]:
		var px := PIXEL_DECOR + kind + ".png"
		var source := px if ResourceLoader.exists(px) else "res://assets/2d/eternia/props/%s.webp" % ("flower_bush" if kind == "flower" else "pink_crystals")
		if variant != current_art and ResourceLoader.exists(source):
			sprite.texture = load(source) as Texture2D
			current_art = variant
		return
	var actor: CharacterBody2D = get_parent() as CharacterBody2D
	var alive := true
	if actor != null and actor.get("record") != null:
		alive = bool(actor.call("get_parameter","alive"))
	if not alive and kind in ["tree","fridge"]:
		variant = kind + "_dormant"
	elif kind in ["sheep","duck","fridge"]:
		if absf(direction.y) >= absf(direction.x) * 1.05:
			var suffix := "_front" if direction.y >= 0.0 else "_back"
			if kind == "fridge" and suffix == "_front":
				variant = "fridge"
			else:
				variant = kind + suffix
		elif kind == "fridge":
			variant = "fridge_side"
	if variant != current_art:
		var filename := ART + variant + ".svg"
		if not frame_cache.has(variant) and ResourceLoader.exists(filename):
			frame_cache[variant] = load(filename)
		if frame_cache.has(variant):
			sprite.texture = frame_cache[variant]
			current_art = variant
	sprite.flip_h = direction.x < -0.05 and variant in ["sheep","duck","fridge_side"]
