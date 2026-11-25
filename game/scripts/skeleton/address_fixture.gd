extends "res://scripts/skeleton/elevation_fixture.gd"
## Two authored 2D+Z rooms sharing the existing address router and one traveler.

const Router = preload("res://scripts/runtime2d/location_router_2d.gd")
const Access = preload("res://scripts/runtime2d/access_state_2d.gd")
const Room = preload("res://scripts/skeleton/address_room.gd")
const Doorway = preload("res://scripts/runtime2d/doorway_2d.gd")
const CATALOG := "res://data/skeleton/DEV_ADDRESS_LOCATIONS.json"
const SAVE_PATH := "user://luna_p905_address.json"
const HALL := "DEV_ADDRESS_HALL"

var router := Router.new()
var access := Access.new()
var current_address := ""
var _room: Room
var _store := SaveStore.new()

@onready var _status: Label = $Interface/Status
@onready var _feedback: Label = $Interface/Feedback
@onready var _address_input: LineEdit = $Interface/AddressInput


func _fixture_key() -> String:
	return "p9_05_address"


func _ready() -> void:
	_address_input.text_submitted.connect(_submit_address)
	if not router.load_catalog_json(CATALOG):
		_startup_error(router.last_error)
		return
	var plan := router.resolve_address(HALL, access.avatar_access_level)
	var room := _load_room(HALL)
	actor = _new_body(ENTITY_ID)
	if room == null or not plan.get("ok", false) or not _can_place(room, plan["position"]):
		if room != null:
			room.free()
		actor.free()
		_startup_error("Hall has no valid starting point")
		return
	_mount_room(room, HALL)
	_place_actor(plan["position"])
	actor.z_index = 1
	add_child(actor)


func _startup_error(reason: String) -> void:
	set_physics_process(false)
	push_error("Could not start the address fixture: " + reason)


func _load_room(address: String) -> Room:
	if not router.locations.has(address):
		return null
	var scene := load(router.locations[address]["scene"]) as PackedScene
	if scene == null:
		return null
	var instance := scene.instantiate()
	var room := instance as Room
	var door := instance.get_node_or_null("Door") as Doorway
	if room == null or not room.floor_bounds.has_area() or not is_finite(room.floor_height) \
			or (room.column_bounds.has_area() and (not is_finite(room.column_top) or room.column_top <= room.floor_height)) \
			or door == null or not router.door_destinations.has(door.entity_id):
		instance.free()
		return null
	return room


func _can_place(room: Room, point: Vector2) -> bool:
	return room.floor_bounds.grow(-actor.motion.safe_margin).has_point(point) \
		and ElevationBody.clears_walls(point, room.floor_height, actor.foot_radius(), room.walls())


func _mount_room(room: Room, address: String) -> void:
	if is_instance_valid(_room):
		_room.free()
	_room = room
	current_address = address
	_decks.assign([_room.floor_surface()])
	_surfaces.assign(_decks)
	_walls.assign(_room.walls())
	add_child(_room)
	for wall in _walls:
		_build_wall(wall, _room)
	queue_redraw()


func _place_actor(point: Vector2) -> void:
	actor.position = point
	actor.motion.reset_on_surface(point, _room.floor_height)
	actor.emergency_anchor = Vector3(point.x, point.y, _room.floor_height)
	actor.direction = Vector2.ZERO
	actor.velocity = Vector2.ZERO
	actor._impulse_velocity = Vector2.ZERO
	if actor.is_inside_tree():
		actor._sync_projection()


func _door_nearby() -> bool:
	return _room != null and actor.motion.grounded \
		and is_equal_approx(actor.motion.elevation, _room.floor_height) \
		and _room.door.can_interact_from(actor.global_position)


func request_door_address(destination: String) -> bool:
	if not _door_nearby():
		return false
	return router.redirect_door(_room.door.entity_id, destination, access.wand_mode)


func enter_nearby_door() -> bool:
	if not _door_nearby():
		return false
	var plan := router.resolve_door(_room.door.entity_id, access.avatar_access_level,
		_room.door.destination_entry_id)
	if not plan.get("ok", false):
		return false
	var candidate := _load_room(plan["address"])
	if candidate == null:
		return false
	if not _can_place(candidate, plan["position"]):
		candidate.free()
		return false
	_mount_room(candidate, plan["address"])
	_place_actor(plan["position"])
	return true


func _physics_process(_delta: float) -> void:
	if keyboard:
		_apply_keyboard_input()
	_status.text = "%s  ·  %s  ·  Доступ героя %d" % [
		current_address, access.wand_mode, access.avatar_access_level,
	]


func _apply_keyboard_input() -> void:
	if _address_input.visible:
		actor.direction = Vector2.ZERO
		return
	var movement := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	movement.x += float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A))
	movement.y += float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))
	actor.direction = movement.limit_length()
	var jump_down := Input.is_physical_key_pressed(KEY_SPACE)
	if jump_down and not _jump_down:
		actor.jump()
	_jump_down = jump_down


func _unhandled_key_input(event: InputEvent) -> void:
	if not keyboard or not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_E:
			if _door_nearby():
				_feedback.text = "" if enter_nearby_door() else "Дверь не открылась"
		KEY_TAB:
			if _door_nearby() and access.wand_mode != Access.ORDINARY:
				_address_input.clear()
				_address_input.show()
				_address_input.grab_focus()
		KEY_ESCAPE:
			_address_input.hide()
		KEY_F2:
			access.set_wand_mode(Access.PLAYFUL if access.wand_mode == Access.DEVELOPER else Access.DEVELOPER)
		KEY_F3:
			access.set_avatar_access_level(0 if access.avatar_access_level > 0 else 1)
		KEY_F5:
			if actor.motion.grounded and _can_place(_room, actor.position):
				_feedback.text = "Сохранено" if _store.write_snapshot(make_snapshot(), SAVE_PATH) else "Сохранение отклонено"
		KEY_F9:
			_feedback.text = "Загружено" if apply_snapshot(_store.read_snapshot(SAVE_PATH)) else "Загрузка отклонена"
		_:
			return
	get_viewport().set_input_as_handled()


func _submit_address(destination: String) -> void:
	if request_door_address(destination):
		_address_input.hide()
		_feedback.text = "Адрес установлен"
	else:
		_feedback.text = "Адрес отклонён"


func make_snapshot() -> Dictionary:
	var data := super.make_snapshot()
	data["address"] = current_address
	data["access"] = access.snapshot()
	data["routes"] = router.snapshot_routes()
	return data


func apply_snapshot(data: Dictionary) -> bool:
	if data.get("format") != SaveStore.FORMAT or data.get("fixture") != _fixture_key():
		return false
	var saved_access: Variant = data.get("access")
	var saved_routes: Variant = data.get("routes")
	var address: Variant = data.get("address")
	var body: Variant = data.get("actor")
	var next_access := Access.new()
	if not saved_access is Dictionary or not next_access.restore(saved_access) \
			or not router.validate_routes(saved_routes) or not address is String \
			or not body is Dictionary or body.get("id") != ENTITY_ID:
		return false
	var next_room := _load_room(address)
	if next_room == null:
		return false
	var next_actor := _new_body(ENTITY_ID)
	var next_surfaces: Array[Dictionary] = [next_room.floor_surface()]
	next_actor.walls = next_room.walls()
	for wall in next_actor.walls:
		next_surfaces.append(_wall_surface(wall))
	next_actor.surfaces = next_surfaces
	if not _restore_body_state(next_actor, body) or not _can_place(next_room, next_actor.position):
		next_actor.free()
		next_room.free()
		return false
	var anchor: Array = next_actor.motion.snapshot()["anchor"]
	next_actor.emergency_anchor = Vector3(float(anchor[0]), float(anchor[1]), float(anchor[2]))
	# A save resumes an occupied room; avatar permissions still apply to new entries.
	actor.free()
	actor = next_actor
	actor.z_index = 1
	_mount_room(next_room, address)
	actor.surfaces = _surfaces
	actor.walls = _walls
	access = next_access
	router.restore_routes(saved_routes)
	_address_input.hide()
	add_child(actor)
	return true
