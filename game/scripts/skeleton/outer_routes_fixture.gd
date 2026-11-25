extends "res://scripts/skeleton/address_fixture.gd"
## P01 and administrative removal share normal placement, then diverge in-world.

const RouteRoom = preload("res://scripts/skeleton/outer_route_room.gd")
const Clock = preload("res://scripts/runtime2d/world_clock_2d.gd")
const MEADOWS := "DEV_OUTER_MEADOWS"
const LUMA := "DEV_OUTER_LUMA"
const COAST := "DEV_OUTER_COAST"
const BUFFER := "DEV_OUTER_BUFFER"
const SUBSPACE := "DEV_OUTER_SUBSPACE"
const EDGE := "DEV_OUTER_EDGE"
const TRASH := "DEV_OUTER_TRASH"
const ORDINARY_STOPS := [MEADOWS, LUMA, COAST]
const FRAME := Rect2(108, 184, 1064, 432)
const RIDE_SECONDS := 6.0
const OUTWARD_SECONDS := 0.44
const CRACK_SECONDS := 0.63
const FALL_HEIGHT := 296.0
const OUTER_SAVE := "user://luna_p907_outer_routes.json"

var world_clock := Clock.new()
var last_safe_address := ""
var last_safe_point := Vector2.ZERO
var ride_destination := ""
var ride_elapsed := 0.0
var outward_elapsed := 0.0
var crack_elapsed := 0.0
var cracking := false
var _drift := Vector2.ZERO

@onready var traveler_visual: Sprite2D = $TravelerVisual
@onready var _action_hint: Label = $Interface/Action


func _fixture_key() -> String:
	return "p9_07_outer_routes"


func _catalog_path() -> String:
	return "res://data/skeleton/DEV_OUTER_LOCATIONS.json"


func _start_address() -> String:
	return MEADOWS


func _ready() -> void:
	super._ready()
	if is_instance_valid(actor):
		_remember_safe_point()


func _configure_body(body: ElevationBody, entity_id: String) -> void:
	super._configure_body(body, entity_id)
	body.hide()


func _place_actor(point: Vector2) -> void:
	super._place_actor(point)
	actor.gravity_scale = 0.0 if current_address == TRASH else 1.0
	_drift = Vector2.ZERO
	if current_address == SUBSPACE:
		actor.motion.elevation = FALL_HEIGHT
		actor.motion.grounded = false
		actor.motion.vertical_speed = -36.0


func _can_restore_at(room: Room, body: ElevationBody) -> bool:
	return (room as RouteRoom).travel_bounds.grow(4.0).has_point(body.position)


func begin_station_ride() -> bool:
	if current_address not in [MEADOWS, LUMA] or not _at_action():
		return false
	_remember_safe_point()
	var destination := LUMA if current_address == MEADOWS else MEADOWS
	if not _move_to_address(BUFFER):
		return false
	ride_destination = destination
	return true


## Call this after a music adapter recognizes the known melody. F8 in this
## fixture only simulates that event.
func play_buffer_melody(melody_id: String) -> bool:
	if melody_id != "M08" or current_address not in ORDINARY_STOPS:
		return false
	_remember_safe_point()
	return _move_to_address(BUFFER)


## Integration point for a completed administrative intervention.
func send_to_trash() -> bool:
	if current_address not in ORDINARY_STOPS:
		return false
	_remember_safe_point()
	return not last_safe_address.is_empty() and _move_to_address(TRASH)


func use_route() -> bool:
	match current_address:
		MEADOWS, LUMA:
			return begin_station_ride()
		BUFFER:
			return not cracking and ride_destination.is_empty() and _finish_buffer()
		EDGE:
			return _at_action() and _move_to_address(COAST)
		TRASH:
			return _at_action() and _return_to_safe_point()
	return false


func _at_action() -> bool:
	return actor.motion.grounded and (_room as RouteRoom).action_bounds.has_point(actor.position)


func _remember_safe_point() -> void:
	if current_address in ORDINARY_STOPS and actor.motion.grounded 			and _can_place(_room, actor.position):
		last_safe_address = current_address
		last_safe_point = actor.position


func _return_to_safe_point() -> bool:
	if last_safe_address not in ORDINARY_STOPS:
		return false
	# The exact checkpoint is preferred. Its authored entry is a bounded fallback
	# if a level revision changed the footprint of an old safe point.
	return _arrive_at(last_safe_address, last_safe_point) or _move_to_address(last_safe_address)


func _finish_buffer() -> bool:
	var moved := _return_to_safe_point() if ride_destination.is_empty() else _move_to_address(ride_destination)
	if moved:
		_reset_frame()
	return moved


func _reset_frame() -> void:
	ride_destination = ""
	ride_elapsed = 0.0
	outward_elapsed = 0.0
	crack_elapsed = 0.0
	cracking = false


func _physics_process(delta: float) -> void:
	if not is_instance_valid(actor):
		return
	world_clock.advance(delta)
	var bounds := (_room as RouteRoom).travel_bounds.grow(-1.0)
	actor.position = actor.position.clamp(bounds.position, bounds.end)
	var input := _keyboard_movement().limit_length() if keyboard else Vector2.ZERO
	match current_address:
		BUFFER:
			_tick_frame(delta, input)
		SUBSPACE:
			actor.direction = Vector2.ZERO
			if actor.motion.grounded:
				_move_to_address(EDGE)
		TRASH:
			_tick_drift(delta, input, keyboard and Input.is_physical_key_pressed(KEY_SPACE))
		_:
			if keyboard:
				_apply_keyboard_input()
			_remember_safe_point()
	_update_interface()


func _tick_frame(delta: float, input: Vector2) -> void:
	if cracking:
		crack_elapsed = minf(crack_elapsed + delta, CRACK_SECONDS)
		if crack_elapsed >= CRACK_SECONDS and _move_to_address(SUBSPACE):
			_reset_frame()
		return
	actor.position.x = clampf(actor.position.x, FRAME.position.x + 25.0, FRAME.end.x - 25.0)
	actor.direction = Vector2(0.52, input.y).limit_length()
	if not is_zero_approx(input.x):
		actor.direction = input
	var beyond := (actor.position.y < FRAME.position.y and input.y < -0.59) 		or (actor.position.y > FRAME.end.y and input.y > 0.59)
	if beyond:
		outward_elapsed = minf(outward_elapsed + delta, OUTWARD_SECONDS)
		if outward_elapsed >= OUTWARD_SECONDS:
			cracking = true
			actor.direction = Vector2.ZERO
			return
	else:
		outward_elapsed = 0.0
		if not FRAME.has_point(actor.position):
			actor.position.y = clampf(actor.position.y, FRAME.position.y + 1.0, FRAME.end.y - 1.0)
	ride_elapsed = minf(ride_elapsed + delta, RIDE_SECONDS)
	if ride_elapsed >= RIDE_SECONDS:
		_finish_buffer()


func _tick_drift(delta: float, input: Vector2, brake: bool) -> void:
	if not actor.motion.grounded:
		actor.motion.start_on_safe_support(actor.position, _room.floor_height, _surfaces)
	var target := Vector2.ZERO if brake else input
	var rate := 10.0 if brake else (2.6 if input.is_zero_approx() else 4.8)
	_drift = _drift.lerp(target, 1.0 - exp(-rate * delta))
	actor.direction = _drift


func _unhandled_key_input(event: InputEvent) -> void:
	if not keyboard or not event is InputEventKey or not event.pressed or event.echo 			or not is_instance_valid(actor):
		return
	var key: Key = event.physical_keycode if event.physical_keycode != KEY_NONE else event.keycode
	match key:
		KEY_E:
			use_route()
		KEY_F4:
			send_to_trash()
		KEY_F8:
			play_buffer_melody("M08")
		KEY_F5:
			_feedback.text = "Снимок записан" if _store.write_snapshot(make_snapshot(), OUTER_SAVE) else "Снимок отклонён"
		KEY_F9:
			_feedback.text = "Снимок восстановлен" if apply_snapshot(_store.read_snapshot(OUTER_SAVE)) else "Снимок отклонён"
		_:
			return
	get_viewport().set_input_as_handled()


func _update_interface() -> void:
	match current_address:
		MEADOWS:
			_status.text = "Большие луга"
		LUMA:
			_status.text = "Люма"
		COAST:
			_status.text = "Побережье"
		BUFFER:
			_status.text = "" if not ride_destination.is_empty() or cracking else "E · вернуться"
		SUBSPACE:
			_status.text = ""
		EDGE:
			_status.text = "Забытый край"
		TRASH:
			_status.text = "Чёрная Пустота · Корзина"
	if _at_action() and current_address in [MEADOWS, LUMA, EDGE, TRASH]:
		if current_address == TRASH:
			_action_hint.text = "E · восстановиться"
		elif current_address == EDGE:
			_action_hint.text = "E · на побережье"
		else:
			_action_hint.text = "E · сесть на ската"
	else:
		_action_hint.text = ""


func make_snapshot() -> Dictionary:
	var data := super.make_snapshot()
	data["last_safe"] = {"address": last_safe_address, "point": [last_safe_point.x, last_safe_point.y]}
	data["clock"] = world_clock.snapshot()
	data["journey"] = {
		"destination": ride_destination, "elapsed": ride_elapsed, "outward": outward_elapsed,
		"cracking": cracking, "crack_elapsed": crack_elapsed, "drift": [_drift.x, _drift.y],
	}
	return data


func apply_snapshot(data: Dictionary) -> bool:
	var safe: Variant = data.get("last_safe")
	var journey: Variant = data.get("journey")
	var clock := Clock.new()
	if not safe is Dictionary or not _valid_pair(safe.get("point"), 2000.0) 			or safe.get("address") not in ORDINARY_STOPS 			or not _valid_journey(data.get("address"), journey) or not clock.restore(data.get("clock")):
		return false
	var safe_point := Vector2(float(safe["point"][0]), float(safe["point"][1]))
	var safe_room := _load_room(safe["address"])
	if safe_room == null:
		return false
	var can_return := _can_place(safe_room, safe_point)
	safe_room.free()
	if not can_return or not super.apply_snapshot(data):
		return false
	last_safe_address = safe["address"]
	last_safe_point = safe_point
	world_clock.restore(clock.snapshot())
	ride_destination = journey["destination"]
	ride_elapsed = journey["elapsed"]
	outward_elapsed = journey["outward"]
	cracking = journey["cracking"]
	crack_elapsed = journey["crack_elapsed"]
	_drift = Vector2(float(journey["drift"][0]), float(journey["drift"][1]))
	actor.gravity_scale = 0.0 if current_address == TRASH else 1.0
	return true


func _valid_journey(address: Variant, data: Variant) -> bool:
	if not data is Dictionary or data.get("destination") not in ["", MEADOWS, LUMA] 			or not _in_range(data.get("elapsed"), RIDE_SECONDS) 			or not _in_range(data.get("outward"), OUTWARD_SECONDS) 			or not _in_range(data.get("crack_elapsed"), CRACK_SECONDS) 			or not data.get("cracking") is bool or not _valid_pair(data.get("drift"), 1.0):
		return false
	if address != TRASH and (float(data["drift"][0]) != 0.0 or float(data["drift"][1]) != 0.0):
		return false
	if address != BUFFER:
		return data["destination"] == "" and data["elapsed"] == 0.0 			and data["outward"] == 0.0 and not data["cracking"] and data["crack_elapsed"] == 0.0
	if data["cracking"]:
		return is_equal_approx(float(data["outward"]), OUTWARD_SECONDS)
	return data["crack_elapsed"] == 0.0 and float(data["outward"]) < OUTWARD_SECONDS


func _valid_pair(value: Variant, limit: float) -> bool:
	return value is Array and value.size() == 2 and _in_range(value[0], limit, -limit) 		and _in_range(value[1], limit, -limit)


func _in_range(value: Variant, maximum: float, minimum: float = 0.0) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) 		and float(value) >= minimum and float(value) <= maximum


func _draw() -> void:
	pass
