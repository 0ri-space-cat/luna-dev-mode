extends Node2D
## Small developer-only test map. Dimensions are fixture tuning.

const ElevationBody = preload("res://scripts/skeleton/elevation_body_2d.gd")
const SaveStore = preload("res://scripts/runtime2d/save_store_2d.gd")
const ENTITY_ID := "DEV_ELEVATION_ACTOR"
const FIXTURE_KEY := "p9_01"
const START := Vector2(176, 264)
const UPPER_HEIGHT := 72.0
const SURFACES: Array[Dictionary] = [
	{"bounds": Rect2(80, 194, 510, 270), "height": 0.0},
	{"bounds": Rect2(126, 226, 224, 142), "height": UPPER_HEIGHT},
	{"bounds": Rect2(686, 210, 300, 254), "height": 0.0},
]
const WALLS: Array[Dictionary] = [
	{"bounds": Rect2(464, 230, 28, 184), "height": 36.0, "layer": 1},
	{"bounds": Rect2(830, 230, 28, 184), "height": 160.0, "layer": 2},
]

var actor: ElevationBody
var keyboard := true
var _surfaces: Array[Dictionary] = []
var _jump_down := false
@onready var height_readout: Label = $Readout


func _ready() -> void:
	_surfaces.assign(SURFACES)
	for wall in WALLS:
		_build_wall(wall)
	actor = _new_actor()
	actor.position = START
	actor.motion.reset_on_surface(START, UPPER_HEIGHT)
	actor.flight_enabled = true
	add_child(actor)


func _physics_process(_delta: float) -> void:
	if keyboard:
		var movement := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		movement.x += float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A))
		movement.y += float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))
		actor.direction = movement
		var jump_down := Input.is_physical_key_pressed(KEY_SPACE)
		if jump_down and not _jump_down:
			actor.jump()
		_jump_down = jump_down
		actor.thrust_requested = Input.is_physical_key_pressed(KEY_F)
		actor.gravity_scale = 0.4 if Input.is_physical_key_pressed(KEY_G) else 1.0
	height_readout.text = "Z %.1f   Vz %.1f   %s   Returns %d" % [
		actor.motion.elevation, actor.motion.vertical_speed,
		"Supported" if actor.motion.grounded else "Airborne", actor.recoveries,
	]


func make_snapshot() -> Dictionary:
	return {
		"format": SaveStore.FORMAT,
		"fixture": FIXTURE_KEY,
		"actor": {
			"id": actor.entity_id,
			"position": [actor.position.x, actor.position.y],
			"flight_enabled": actor.flight_enabled,
			"motion": actor.motion.snapshot(),
		},
	}


func apply_snapshot(data: Dictionary) -> bool:
	if data.get("format") != SaveStore.FORMAT or data.get("fixture") != FIXTURE_KEY:
		return false
	var body: Variant = data.get("actor")
	if not body is Dictionary or body.get("id") != ENTITY_ID:
		return false
	var point: Variant = body.get("position")
	var height_state: Variant = body.get("motion")
	var flight: Variant = body.get("flight_enabled")
	if not point is Array or point.size() != 2 or not height_state is Dictionary or not flight is bool:
		return false
	for coordinate in point:
		if typeof(coordinate) not in [TYPE_FLOAT, TYPE_INT] or not is_finite(float(coordinate)) \
				or absf(float(coordinate)) > 100000.0:
			return false
	var candidate := _new_actor()
	candidate.position = Vector2(float(point[0]), float(point[1]))
	if not candidate.motion.load_snapshot(height_state, candidate.position, _surfaces,
			ElevationBody.RECOVERY_HEIGHT):
		candidate.free()
		return false
	var anchor: Array = candidate.motion.snapshot()["anchor"]
	var anchor_point := Vector2(float(anchor[0]), float(anchor[1]))
	if _intersects_wall(candidate.position, candidate.motion.elevation) \
			or _intersects_wall(anchor_point, float(anchor[2])):
		candidate.free()
		return false
	candidate.flight_enabled = flight
	actor.free()
	actor = candidate
	add_child(actor)
	return true


func _intersects_wall(point: Vector2, elevation: float) -> bool:
	for wall in WALLS:
		if elevation >= float(wall["height"]):
			continue
		var bounds: Rect2 = wall["bounds"]
		var closest := point.clamp(bounds.position, bounds.end)
		if point.distance_to(closest) < ElevationBody.FOOT_RADIUS - 0.01:
			return true
	return false


func _new_actor() -> ElevationBody:
	var body := ElevationBody.new()
	body.entity_id = ENTITY_ID
	body.surfaces = _surfaces
	body.walls = WALLS
	return body


func _build_wall(wall: Dictionary) -> void:
	var bounds: Rect2 = wall["bounds"]
	var solid := StaticBody2D.new()
	solid.position = bounds.get_center()
	solid.collision_layer = wall["layer"]
	solid.collision_mask = 0
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = bounds.size
	collider.shape = shape
	solid.add_child(collider)
	add_child(solid)
	_surfaces.append({
		"bounds": bounds.grow(ElevationBody.FOOT_RADIUS),
		"height": wall["height"],
		"safe": false,
	})


func _draw() -> void:
	for surface in SURFACES:
		_draw_platform(surface["bounds"], surface["height"], Color("3f395c"))
	for wall in WALLS:
		_draw_platform(wall["bounds"], wall["height"], Color("705d83"))


func _draw_platform(bounds: Rect2, height: float, color: Color) -> void:
	var top := Rect2(bounds.position - Vector2(0.0, height), bounds.size)
	draw_rect(bounds, Color("242036"), false, 2.0)
	if height > 0.0:
		draw_rect(Rect2(top.position + Vector2(0, top.size.y), Vector2(top.size.x, height)),
			color.darkened(0.28))
	draw_rect(top, color)
	draw_rect(top, color.lightened(0.22), false, 2.0)
