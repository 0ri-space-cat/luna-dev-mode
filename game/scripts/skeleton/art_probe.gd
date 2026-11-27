extends "res://scripts/skeleton/address_fixture.gd"
## Switch projection with the room, keeping the same traveler and address state.

const RoomProjection = preload("res://scripts/skeleton/art_probe_projection.gd")
const ArtRoom = preload("res://scripts/skeleton/art_probe_room.gd")
const Clock = preload("res://scripts/runtime2d/world_clock_2d.gd")
const ART_CATALOG := "res://data/skeleton/DEV_ART_LOCATIONS.json"
const EXTERIOR := "DEV_ART_EXTERIOR"
const CELL := Vector2(48, 76)
const FOOT := Vector2(24, 70)
const LUNA := preload("res://assets/art_probe/luna.png")
const ONI := preload("res://assets/art_probe/oni.png")
# Clockwise from screen-right. Left facings reuse the corresponding art.
const VIEW_ROWS := [2, 1, 0, 1, 2, 3, 4, 3]

var view: RoomProjection
var world_clock := Clock.new()
var luna_art := Sprite2D.new()
var oni_art := Sprite2D.new()
var luna_shadow := Node2D.new()
var oni_shadow := Node2D.new()
var _walk_cycle := 0.0
var _facing := 2
var _walk_frame := 0
var _last_point := Vector2.ZERO

@onready var _backdrop: Node2D = $Backdrop
@onready var _hint: Label = $Interface/DoorHint


func _fixture_key() -> String:
	return "p9_06_art_probe"


func _catalog_path() -> String:
	return ART_CATALOG


func _start_address() -> String:
	return EXTERIOR


func _ready() -> void:
	for sprite in [luna_art, oni_art]:
		sprite.centered = false
		sprite.offset = -FOOT
		add_child(sprite)
	luna_art.texture = LUNA
	luna_art.region_enabled = true
	luna_art.region_filter_clip_enabled = true
	oni_art.texture = ONI
	for shadow in [luna_shadow, oni_shadow]:
		add_child(shadow)
		shadow.draw.connect(_draw_shadow.bind(shadow))
	super._ready()
	_last_point = actor.position if is_instance_valid(actor) else Vector2.ZERO


func _configure_body(body: ElevationBody, entity_id: String) -> void:
	super._configure_body(body, entity_id)
	body.hide()


func _mount_room(room: Room, address: String) -> void:
	super._mount_room(room, address)
	var art_room := room as ArtRoom
	view = RoomProjection.new(art_room.isometric)
	_backdrop.show_room(art_room, view)
	_place_visual(oni_art, oni_shadow, art_room.oni_position, 0.0, 0.0)
	_walk_cycle = 0.0
	_walk_frame = 0


func _place_actor(point: Vector2) -> void:
	super._place_actor(point)
	_last_point = point


func _can_restore_at(room: Room, body: ElevationBody) -> bool:
	# The shared body restore already validates support, height and solid obstacles.
	return room.floor_bounds.has_point(body.position)


func _physics_process(delta: float) -> void:
	if not is_instance_valid(actor):
		return
	if keyboard:
		_apply_keyboard_input()
	world_clock.advance(delta)
	_advance_walk(delta)


func _advance_walk(delta: float) -> void:
	var travel := view.point(actor.position) - view.point(_last_point)
	var walking := actor.motion.grounded and travel.length_squared() > 0.16
	_walk_frame = 0
	if walking:
		_facing = posmod(roundi(travel.angle() / (PI / 4.0)), 8)
		_walk_cycle = fposmod(_walk_cycle + delta * 8.0, 4.0)
		_walk_frame = 1 + floori(_walk_cycle)
	else:
		_walk_cycle = 0.0
	_last_point = actor.position


func _process(_delta: float) -> void:
	if view == null or not is_instance_valid(actor):
		return
	luna_art.region_rect = Rect2(Vector2(_walk_frame, VIEW_ROWS[_facing]) * CELL, CELL)
	luna_art.flip_h = _facing in [3, 4, 5]
	var height := actor.motion.elevation
	_place_visual(luna_art, luna_shadow, actor.position, height, _support_below(actor.position, height))
	_hint.visible = _door_nearby()
	if _hint.visible:
		_hint.text = "E · выйти" if (_room as ArtRoom).isometric else "E · войти"
		_hint.size = _hint.get_minimum_size()
		_hint.position = view.point(_room.door.position, 74.0).round() - Vector2(_hint.size.x / 2, 0)


func _apply_keyboard_input() -> void:
	actor.direction = view.movement(_keyboard_movement())
	var jump_down := Input.is_physical_key_pressed(KEY_SPACE)
	if jump_down and not _jump_down:
		actor.jump()
	_jump_down = jump_down


func _unhandled_key_input(event: InputEvent) -> void:
	if keyboard and event is InputEventKey and event.pressed and not event.echo 			and event.physical_keycode == KEY_E and is_instance_valid(actor) and enter_nearby_door():
		get_viewport().set_input_as_handled()


func _place_visual(sprite: Sprite2D, shadow: Node2D, point: Vector2, height: float,
		support_height: float) -> void:
	var depth := view.depth(point) * 2
	sprite.position = view.point(point, height).round()
	sprite.z_index = depth
	shadow.visible = is_finite(support_height)
	if shadow.visible:
		shadow.position = view.point(point, support_height).round()
		shadow.z_index = depth - 1


func _draw_shadow(shadow: Node2D) -> void:
	shadow.draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.38))
	shadow.draw_circle(Vector2.ZERO, 13.0, Color(0.12, 0.11, 0.18, 0.49))


func _support_below(point: Vector2, height: float) -> float:
	var closest := -INF
	for support in _surfaces:
		var bounds: Rect2 = support["bounds"]
		var z: float = support["height"]
		if bounds.has_point(point) and z <= height + 0.00001:
			closest = maxf(closest, z)
	return closest


func make_snapshot() -> Dictionary:
	var data := super.make_snapshot()
	data["world_clock"] = world_clock.snapshot()
	return data


func apply_snapshot(data: Dictionary) -> bool:
	var clock := Clock.new()
	if not clock.restore(data.get("world_clock")) or not super.apply_snapshot(data):
		return false
	world_clock.restore(clock.snapshot())
	_last_point = actor.position
	return true


func _draw() -> void:
	pass
