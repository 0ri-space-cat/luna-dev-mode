extends "res://scripts/skeleton/address_fixture.gd"
## External routes share the same traveler, safe placement and world clock.

const BorrowedEntity = preload("res://scripts/skeleton/entity_body_2d.gd")
const RouteRoom = preload("res://scripts/skeleton/outer_route_room.gd")
const VoidExploration = preload("res://scripts/skeleton/void_exploration_2d.gd")
const Clock = preload("res://scripts/runtime2d/world_clock_2d.gd")
const MEADOWS := "DEV_OUTER_MEADOWS"
const LUMA := "DEV_OUTER_LUMA"
const COAST := "DEV_OUTER_COAST"
const BUFFER := "DEV_OUTER_BUFFER"
const SUBSPACE := "DEV_OUTER_SUBSPACE"
const EDGE := "DEV_OUTER_EDGE"
const BLACK_VOID := "DEV_OUTER_BLACK_VOID"
const HOUSE_04 := "ET_LUMA_RES_04"
const WHITE_ADDRESS := "META_WHITE_VOID"
const ORDINARY_STOPS := [MEADOWS, LUMA, COAST]
const FRAME := Rect2(108, 184, 1064, 432)
const RIDE_SECONDS := 6.0
const OUTWARD_SECONDS := 0.44
const CRACK_SECONDS := 0.63
const FALL_HEIGHT := 296.0
const OUTER_SAVE := "user://luna_p907_outer_routes.json"

var world_clock := Clock.new()
var exploration := VoidExploration.new()
var _record_text := ""
var last_safe_address := ""
var last_safe_point := Vector2.ZERO
var ride_destination := ""
var ride_elapsed := 0.0
var outward_elapsed := 0.0
var crack_elapsed := 0.0
var cracking := false
var _drift := Vector2.ZERO
var return_to_host: Callable

@onready var traveler_visual: Sprite2D = $TravelerVisual
@onready var _action_hint: Label = $Interface/Action


func _fixture_key() -> String:
	return "p9_07_outer_routes"


func _catalog_path() -> String:
	return "res://data/skeleton/DEV_OUTER_LOCATIONS.json"


func _start_address() -> String:
	return MEADOWS


func _ready() -> void:
	if return_to_host.is_valid():
		_address_input.text_submitted.connect(_submit_address)
		if not router.load_catalog_json(_catalog_path()):
			_startup_error(router.last_error)
		$Interface/Controls.text = "WASD / стрелки · парение    Пробел · торможение    E · действие"
		return
	super._ready()
	if is_instance_valid(actor):
		_remember_safe_point()


func mount_host_traveler(body: ElevationBody, host_access: Access, host_clock: Clock) -> bool:
	if not return_to_host.is_valid() or actor != null or body.is_attached():
		return false
	actor = body
	access = host_access
	world_clock = host_clock
	last_safe_address = MEADOWS
	last_safe_point = router.locations[MEADOWS]["entries"]["entry"]
	if not _enter_void("entry"):
		actor = null
		return false
	for traveler in actor.map_travelers():
		traveler.surfaces = _surfaces
		traveler.walls = _walls
		traveler.water_volumes = _water_volumes
		traveler.reparent_for_map(self)
		traveler.hide()
	actor._update_rider_position()
	return true


func _configure_body(body: ElevationBody, entity_id: String) -> void:
	super._configure_body(body, entity_id)
	if return_to_host.is_valid() and is_instance_valid(actor):
		body._apply_body_size(actor.body_size)
	body.hide()


func _place_actor(point: Vector2) -> void:
	super._place_actor(point)
	if actor is BorrowedEntity:
		for traveler in actor.map_travelers():
			(traveler as BorrowedEntity).location_id = current_address
	_record_text = ""
	if current_address != exploration.station_ghost:
		exploration.station_ghost = ""
	actor.gravity_scale = 0.0 if current_address == BLACK_VOID else 1.0
	_drift = Vector2.ZERO
	if current_address == SUBSPACE:
		actor.motion.elevation = FALL_HEIGHT
		actor.motion.grounded = false
		actor.motion.vertical_speed = -36.0


func _can_place(room: Room, point: Vector2) -> bool:
	if super._can_place(room, point):
		return true
	for other_floor in (room as RouteRoom).other_floors:
		if other_floor.grow(-actor.motion.safe_margin).has_point(point):
			return ElevationBody.clears_walls(point, room.floor_height, actor.foot_radius(), room.walls())
	return false


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
	if melody_id != "M08" or (current_address not in ORDINARY_STOPS and current_address != HOUSE_04):
		return false
	var from_house := current_address == HOUSE_04
	_remember_safe_point()
	if not _move_to_address(BUFFER):
		return false
	exploration.buffer_from_house = from_house
	return true


## Integration point for a completed administrative intervention.
func send_to_black_void() -> bool:
	if current_address not in ORDINARY_STOPS:
		return false
	_remember_safe_point()
	return not last_safe_address.is_empty() and _enter_void("entry")


func play_station_melody(melody_id: String) -> bool:
	if melody_id != "M02" or current_address not in [MEADOWS, LUMA] \
		or world_clock.phase() != Clock.Phase.NIGHT or not _at_action():
		return false
	exploration.station_ghost = current_address
	return true


func station_ghost_available() -> bool:
	return not exploration.station_ghost.is_empty() and exploration.station_ghost == current_address \
		and world_clock.phase() == Clock.Phase.NIGHT


func void_ghost_available() -> bool:
	return current_address == BLACK_VOID and exploration.ghost_waiting()


func request_door_address(destination: String) -> bool:
	if current_address != LUMA or destination != HOUSE_04 or not _door_nearby() \
		or access.wand_mode == Access.ORDINARY or not _can_place(_room, actor.position):
		return false
	var source := actor.position
	_remember_safe_point()
	if not _move_to_address(HOUSE_04):
		return false
	exploration.begin_natural_door()
	exploration.house_source = source
	return true


func toggle_local_door() -> bool:
	if current_address not in [LUMA, HOUSE_04] or not _door_nearby():
		return false
	if exploration.house_source != null:
		exploration.house_source = null
		exploration.begin_natural_door()
		return true
	if current_address != HOUSE_04:
		return false
	exploration.toggle_natural_door()
	return true


func enter_nearby_door() -> bool:
	if not _door_nearby():
		return false
	if current_address == LUMA:
		if exploration.house_source == null:
			return false
		_remember_safe_point()
		return _move_to_address(HOUSE_04)
	if current_address != HOUSE_04:
		return false
	if exploration.house_source is Vector2:
		return _arrive_at(LUMA, exploration.house_source) or _move_to_address(LUMA)
	if not exploration.door_open:
		exploration.toggle_natural_door()
	var glowing := exploration.door_glowing()
	var crossed := _move_to_address(LUMA, "former_house") if glowing else super.enter_nearby_door()
	if crossed:
		exploration.begin_natural_door()
		if not glowing:
			exploration.begin_void_visit()
	return crossed


func read_local_record() -> String:
	if not _near_record():
		return ""
	if current_address == BLACK_VOID:
		return WHITE_ADDRESS
	if current_address == HOUSE_04:
		return "M08"
	return ""


func _enter_void(entry_id: String) -> bool:
	if not _move_to_address(BLACK_VOID, entry_id):
		return false
	exploration.begin_void_visit()
	return true


func _board_station_ghost() -> bool:
	if not station_ghost_available() or not _at_area((_room as RouteRoom).ghost_bounds):
		return false
	_remember_safe_point()
	return _enter_void("ghost")


func _board_void_ghost() -> bool:
	if not void_ghost_available() or not _at_area((_room as RouteRoom).ghost_bounds):
		return false
	if not _move_to_address(LUMA, "ghost"):
		return false
	world_clock.set_time_of_day(Clock.NIGHT_MINUTE)
	_remember_safe_point()
	return true


func _near_record() -> bool:
	return current_address in [HOUSE_04, BLACK_VOID] and _at_area((_room as RouteRoom).record_bounds)


func use_route() -> bool:
	match current_address:
		MEADOWS, LUMA:
			return _board_station_ghost() or enter_nearby_door() or begin_station_ride()
		BUFFER:
			return not cracking and ride_destination.is_empty() and _finish_buffer()
		EDGE:
			return _at_action() and _move_to_address(COAST)
		BLACK_VOID:
			if _at_action():
				return _return_to_safe_point()
			if _board_void_ghost():
				return true
		HOUSE_04:
			if enter_nearby_door():
				return true
	_record_text = read_local_record()
	return not _record_text.is_empty()


func _at_action() -> bool:
	return _at_area((_room as RouteRoom).action_bounds)


func _at_area(area: Rect2) -> bool:
	return actor.motion.grounded and area.has_point(actor.position)


func _remember_safe_point() -> void:
	if current_address in ORDINARY_STOPS and actor.motion.grounded \
		and _can_place(_room, actor.position):
		last_safe_address = current_address
		last_safe_point = actor.position


func _return_to_safe_point() -> bool:
	if current_address == BLACK_VOID and return_to_host.is_valid():
		return return_to_host.call()
	if last_safe_address not in ORDINARY_STOPS:
		return false
	# The exact checkpoint is preferred. Its authored entry is a bounded fallback
	# if a level revision changed the footprint of an old safe point.
	return _arrive_at(last_safe_address, last_safe_point) or _move_to_address(last_safe_address)


func _finish_buffer() -> bool:
	var moved: bool
	if exploration.buffer_from_house:
		moved = _move_to_address(HOUSE_04)
	elif ride_destination.is_empty():
		moved = _return_to_safe_point()
	elif ride_destination == MEADOWS and return_to_host.is_valid():
		moved = return_to_host.call()
	else:
		moved = _move_to_address(ride_destination)
	if moved:
		_reset_frame()
	return moved


func _reset_frame() -> void:
	ride_destination = ""
	ride_elapsed = 0.0
	outward_elapsed = 0.0
	crack_elapsed = 0.0
	cracking = false
	exploration.buffer_from_house = false


func _physics_process(delta: float) -> void:
	if not is_instance_valid(actor):
		return
	world_clock.advance(delta)
	if world_clock.phase() != Clock.Phase.NIGHT:
		exploration.station_ghost = ""
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
		BLACK_VOID:
			exploration.advance_void(delta)
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
	var beyond := (actor.position.y < FRAME.position.y and input.y < -0.59) \
		or (actor.position.y > FRAME.end.y and input.y > 0.59)
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
	if not keyboard or not event is InputEventKey or not event.pressed or event.echo \
		or not is_instance_valid(actor):
		return
	var key: Key = event.physical_keycode if event.physical_keycode != KEY_NONE else event.keycode
	if return_to_host.is_valid() and key not in [KEY_E, KEY_C, KEY_TAB, KEY_ESCAPE]:
		return
	match key:
		KEY_E:
			use_route()
		KEY_F4:
			send_to_black_void()
		KEY_F8:
			play_buffer_melody("M08")
		KEY_F7:
			play_station_melody("M02")
		KEY_C:
			toggle_local_door()
		KEY_TAB:
			if current_address == LUMA and _door_nearby() and access.wand_mode != Access.ORDINARY:
				_address_input.clear()
				_address_input.show()
				_address_input.grab_focus()
		KEY_ESCAPE:
			_address_input.hide()
		KEY_T:
			var minute := Clock.START_MINUTE if world_clock.phase() == Clock.Phase.NIGHT else Clock.NIGHT_MINUTE
			world_clock.set_time_of_day(minute)
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
		BLACK_VOID:
			_status.text = "Чёрная Пустота"
		HOUSE_04:
			_status.text = "Дом №04"
	_action_hint.text = _contextual_action()


func _contextual_action() -> String:
	var room := _room as RouteRoom
	if _near_record():
		return "E · прочесть запись" if _record_text.is_empty() else _record_text
	_record_text = ""
	if (station_ghost_available() or void_ghost_available()) and _at_area(room.ghost_bounds):
		return "E · сесть на призрачного ската"
	if current_address == HOUSE_04 and _door_nearby():
		if exploration.house_source != null:
			return "E · вернуться по связи     C · закрыть связь"
		return "E · пройти     C · открыть или закрыть дверь"
	if current_address == LUMA and _door_nearby():
		if exploration.house_source != null:
			return "E · пройти     C · закрыть связь"
		if access.wand_mode != Access.ORDINARY:
			return "Tab · ввести адрес"
	if not _at_action():
		return ""
	match current_address:
		BLACK_VOID:
			return "E · восстановиться"
		EDGE:
			return "E · на побережье"
		MEADOWS, LUMA:
			return "E · сесть на обычного ската"
	return ""


func make_snapshot() -> Dictionary:
	var data := super.make_snapshot()
	data["last_safe"] = {"address": last_safe_address, "point": [last_safe_point.x, last_safe_point.y]}
	data["clock"] = world_clock.snapshot()
	data["outer_exploration"] = exploration.snapshot()
	data["journey"] = {
		"destination": ride_destination, "elapsed": ride_elapsed, "outward": outward_elapsed,
		"cracking": cracking, "crack_elapsed": crack_elapsed, "drift": [_drift.x, _drift.y],
	}
	return data


func apply_snapshot(data: Dictionary) -> bool:
	data = _migrate_void_address(data)
	var safe: Variant = data.get("last_safe")
	var journey: Variant = data.get("journey")
	var clock := Clock.new()
	var next_exploration := VoidExploration.new()
	var address: Variant = data.get("address")
	if data.has("outer_exploration"):
		if not next_exploration.restore(data["outer_exploration"]) or data.get("routes") != router.snapshot_routes():
			return false
	elif data.get("routes") == {} and address != HOUSE_04:
		data = data.duplicate(true)
		data["routes"] = router.snapshot_routes()
	else:
		return false
	if not safe is Dictionary or not _valid_pair(safe.get("point"), 2000.0) \
		or safe.get("address") not in ORDINARY_STOPS \
		or not _valid_journey(address, journey) or not clock.restore(data.get("clock")):
		return false
	if not _valid_exploration(address, journey, next_exploration):
		return false
	var safe_point := Vector2(float(safe["point"][0]), float(safe["point"][1]))
	var safe_room := _load_room(safe["address"])
	if safe_room == null:
		return false
	var can_return := _can_place(safe_room, safe_point)
	safe_room.free()
	if not can_return or not super.apply_snapshot(data):
		return false
	exploration = next_exploration
	_record_text = ""
	last_safe_address = safe["address"]
	last_safe_point = safe_point
	world_clock.restore(clock.snapshot())
	ride_destination = journey["destination"]
	ride_elapsed = journey["elapsed"]
	outward_elapsed = journey["outward"]
	cracking = journey["cracking"]
	crack_elapsed = journey["crack_elapsed"]
	_drift = Vector2(float(journey["drift"][0]), float(journey["drift"][1]))
	actor.gravity_scale = 0.0 if current_address == BLACK_VOID else 1.0
	return true


func _restore_traveler(next_actor: ElevationBody) -> void:
	if not return_to_host.is_valid():
		super._restore_traveler(next_actor)
		return
	actor.position = next_actor.position
	actor.motion = next_actor.motion
	actor.emergency_anchor = next_actor.emergency_anchor
	actor.direction = Vector2.ZERO
	actor.velocity = Vector2.ZERO
	actor._impulse_velocity = Vector2.ZERO
	actor._sync_projection()
	for traveler in actor.map_travelers():
		(traveler as BorrowedEntity).location_id = current_address
	actor._update_rider_position()
	next_actor.free()


func _restore_access(next_access: Access) -> void:
	if not return_to_host.is_valid():
		super._restore_access(next_access)


func _migrate_void_address(data: Dictionary) -> Dictionary:
	const OLD_ADDRESS := "DEV_OUTER_TRASH"
	var routes: Variant = data.get("routes")
	if data.get("address") != OLD_ADDRESS and (not routes is Dictionary \
			or routes.get("DEV_RES_04_NATURAL_DOOR") != OLD_ADDRESS):
		return data
	var migrated := data.duplicate(true)
	if migrated.get("address") == OLD_ADDRESS:
		migrated["address"] = BLACK_VOID
	if routes is Dictionary and routes.get("DEV_RES_04_NATURAL_DOOR") == OLD_ADDRESS:
		migrated["routes"]["DEV_RES_04_NATURAL_DOOR"] = BLACK_VOID
	return migrated


func _valid_exploration(address: Variant, journey: Dictionary, candidate: VoidExploration) -> bool:
	if not candidate.station_ghost.is_empty() and (candidate.station_ghost != address \
		or address not in [MEADOWS, LUMA]):
		return false
	if candidate.buffer_from_house and (address != BUFFER or not journey["destination"].is_empty()):
		return false
	if candidate.house_source == null:
		return true
	var source := _load_room(LUMA)
	if source == null:
		return false
	var door := source.get_node("Door") as Doorway
	var point: Vector2 = candidate.house_source
	var valid := _can_place(source, point) \
		and point.distance_to(door.position) <= door.interaction_radius
	source.free()
	return valid


func _valid_journey(address: Variant, data: Variant) -> bool:
	if not data is Dictionary or data.get("destination") not in ["", MEADOWS, LUMA] \
		or not _in_range(data.get("elapsed"), RIDE_SECONDS) \
		or not _in_range(data.get("outward"), OUTWARD_SECONDS) \
		or not _in_range(data.get("crack_elapsed"), CRACK_SECONDS) \
		or not data.get("cracking") is bool or not _valid_pair(data.get("drift"), 1.0):
		return false
	if address != BLACK_VOID and (float(data["drift"][0]) != 0.0 or float(data["drift"][1]) != 0.0):
		return false
	if address != BUFFER:
		return data["destination"] == "" and data["elapsed"] == 0.0 \
		and data["outward"] == 0.0 and not data["cracking"] and data["crack_elapsed"] == 0.0
	if data["cracking"]:
		return is_equal_approx(float(data["outward"]), OUTWARD_SECONDS)
	return data["crack_elapsed"] == 0.0 and float(data["outward"]) < OUTWARD_SECONDS


func _valid_pair(value: Variant, limit: float) -> bool:
	return value is Array and value.size() == 2 and _in_range(value[0], limit, -limit) \
		and _in_range(value[1], limit, -limit)


func _in_range(value: Variant, maximum: float, minimum: float = 0.0) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) \
		and float(value) >= minimum and float(value) <= maximum


func _draw() -> void:
	pass
