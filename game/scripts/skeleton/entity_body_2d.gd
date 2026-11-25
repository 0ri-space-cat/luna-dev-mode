extends "res://scripts/skeleton/elevation_body_2d.gd"
## An EntityRecord and a real 2D+Z body share one stable world ID.

const EntityRecord = preload("res://scripts/core/entity_record.gd")
const Parameters = preload("res://scripts/skeleton/entity_parameters_2d.gd")

const Brain = preload("res://scripts/runtime2d/behavior_brain_2d.gd")
const SEAT_HEIGHT := 16.0
const SEAT_CAPACITY := 2.0
var brain := Brain.new()
var world_registry
var navigation = null

var record: EntityRecord
var location_id := ""


func get_world_location_id() -> String:
	return location_id


func get_parameter(key: String) -> Variant:
	return record.get_parameter(key)


func can_edit_parameter(key: String) -> bool:
	if key == "alive":
		return record.category in ["fridge", "prop"]
	if key == "asleep":
		return record.category == "yeti"
	if key == "rideable":
		return _seat_capacity > 0.0
	if key == "pickable":
		return record.category != "player"
	return key in Parameters.PHYSICS_FIELDS or key in Parameters.BEHAVIOR_FIELDS or key in ["size", "speed", "color", "ai_enabled", "control_source", "gravity_scale"]


func _ready() -> void:
	super._ready()
	_marker.color = get_parameter("color")


func set_parameter(key: String, value: Variant) -> bool:
	if not can_edit_parameter(key):
		return false
	if key in Parameters.ATTACHMENT_FIELDS:
		if not value is bool:
			return false
		if not value and (has_rider() if key == "rideable" else is_carried()):
			return false
		record.parameters[key] = value
		return true
	if key in Parameters.BEHAVIOR_FIELDS or key == "color":
		var checked: Dictionary = record.registry.normalize(record.category, key, value)
		if not checked["ok"]:
			return false
		record.parameters[key] = checked["value"]
		if key == "color" and _marker != null:
			_marker.color = checked["value"]
		return true
	if key == "gravity_scale":
		var checked: Dictionary = record.registry.normalize(record.category, key, value)
		if not checked["ok"]:
			return false
		gravity_scale = float(checked["value"])
		record.parameters[key] = gravity_scale
		return true
	if key in ["size", "speed"]:
		var checked: Dictionary = record.registry.normalize(record.category, key, value)
		if not checked["ok"]:
			return false
		var number := float(checked["value"])
		if key == "size" and not _try_resize(number):
			return false
		if key == "speed":
			drive_multiplier = number / 2.0
		record.parameters[key] = number
		return true
	if key in ["ai_enabled", "control_source"]:
		var checked: Dictionary = record.registry.normalize(record.category, key, value)
		if not checked["ok"]:
			return false
		record.parameters[key] = checked["value"]
		_stop_active_motion()
		return true
	if key == "alive" and record.category in ["fridge", "prop"] or key == "asleep" and record.category == "yeti":
		if not value is bool:
			return false
		record.parameters[key] = value
		if not _can_act():
			_stop_active_motion()
		return true
	if key not in Parameters.PHYSICS_FIELDS:
		return false
	var checked: Dictionary = record.registry.normalize(record.category, key, value)
	if not checked["ok"]:
		return false
	var mass := float(checked["value"]) if key == "mass" else _mass
	var bounciness := float(checked["value"]) if key == "bounciness" else _bounciness
	return configure_dynamics(mass, bounciness)


func configure_dynamics(mass: float, bounciness: float) -> bool:
	if not record.registry.normalize(record.category, "mass", mass)["ok"]:
		return false
	if not super.configure_dynamics(mass, bounciness):
		return false
	record.parameters["mass"] = mass
	record.parameters["bounciness"] = bounciness
	return true

func life_snapshot() -> Dictionary:
	return {"alive": get_parameter("alive"), "asleep": get_parameter("asleep")}


func restore_life(state: Variant) -> bool:
	if not state is Dictionary or state.size() != 2:
		return false
	var alive: Variant = state.get("alive")
	var asleep: Variant = state.get("asleep")
	if not alive is bool or not asleep is bool:
		return false
	if record.category not in ["fridge", "prop"] and alive != get_parameter("alive"):
		return false
	if record.category != "yeti" and asleep != get_parameter("asleep"):
		return false
	record.parameters["alive"] = alive
	record.parameters["asleep"] = asleep
	return true


func _can_act() -> bool:
	return get_parameter("alive") and not get_parameter("asleep")


func _allows_ride() -> bool:
	return super._allows_ride() and get_parameter("rideable") == true


func _allows_pickup() -> bool:
	return can_edit_parameter("pickable") and get_parameter("pickable") == true


func _release_is_clear(point: Vector2, floor: float, feet: float) -> bool:
	for identity in world_registry.list_ids():
		var other := world_registry.get_entity(identity) as SkeletonElevationBody2D
		if other == null or other == self or other == _carrier:
			continue
		if floor >= other.motion.elevation + other.body_height() or other.motion.elevation >= feet + body_height():
			continue
		if point.distance_to(other.position) < foot_radius() + other.foot_radius():
			return false
	return true


func attachment_snapshot() -> Dictionary:
	return {
		"rideable": get_parameter("rideable"),
		"pickable": get_parameter("pickable"),
		"carrier_id": _carrier.entity_id if is_attached() else "",
		"carried": is_carried(),
	}


func _stop_active_motion() -> void:
	direction = Vector2.ZERO
	thrust_requested = false
	swim_intent = 0.0


func jump() -> void:
	if _can_act():
		super.jump()


func _physics_process(delta: float) -> void:
	if not _can_act():
		_stop_active_motion()
	elif get_parameter("ai_enabled"):
		direction = _wander_on_support(delta)
	elif not accepts_player_input():
		_stop_active_motion()
	super._physics_process(delta)


func _wander_on_support(delta: float) -> Vector2:
	if not motion.grounded or is_attached():
		return Vector2.ZERO
	var heading := brain.direction_for(self, world_registry, delta)
	for attempt in range(4):
		if heading.is_zero_approx():
			return Vector2.ZERO
		var ahead := position + heading * 22.0
		if is_equal_approx(_dry_landing_height(ahead, motion.elevation), motion.elevation) \
				and _clear_step(ahead, motion.elevation):
			return heading
		brain.avoid_obstacle()
		heading = brain.direction_for(self, world_registry, 0.0)
	return Vector2.ZERO


func accepts_player_input() -> bool:
	return _can_act() and not get_parameter("ai_enabled") and get_parameter("control_source") == "PLAYER"


func control_snapshot() -> Dictionary:
	return {"ai_enabled": get_parameter("ai_enabled"), "control_source": get_parameter("control_source")}


func restore_control(state: Variant) -> bool:
	if not state is Dictionary or state.size() != 2:
		return false
	var autonomy: Variant = state.get("ai_enabled")
	var source: Variant = state.get("control_source")
	if not autonomy is bool or not source is String or source not in ["NONE", "PLAYER"]:
		return false
	record.parameters["ai_enabled"] = autonomy
	record.parameters["control_source"] = source
	return true


func _try_resize(value: float) -> bool:
	if is_attached() or has_passenger():
		return false
	var radius := FOOT_RADIUS * value
	if not fits_walls_at(position, motion.elevation, radius):
		return false
	var state := motion.snapshot()
	var anchor: Array = state["anchor"]
	var anchor_point := Vector2(float(anchor[0]), float(anchor[1]))
	if not fits_walls_at(anchor_point, float(anchor[2]), radius):
		return false
	var candidate := ElevationMotion.new()
	candidate.safe_margin = 14.0 * value
	if not candidate.load_snapshot(state, position, surfaces, RECOVERY_HEIGHT):
		return false
	if value > body_size:
		for identity in world_registry.list_ids():
			var other = world_registry.get_entity(identity)
			if other == self:
				continue
			if motion.elevation >= other.motion.elevation + other.body_height() or other.motion.elevation >= motion.elevation + BODY_HEIGHT * value:
				continue
			if position.distance_to(other.position) < radius + other.foot_radius():
				return false
	_apply_body_size(value)
	return true


func movement_snapshot() -> Dictionary:
	return {"size": get_parameter("size"), "speed": get_parameter("speed")}


func restore_movement(state: Variant) -> bool:
	if not state is Dictionary or state.size() != 2:
		return false
	for key in ["size", "speed"]:
		var checked: Dictionary = record.registry.normalize(record.category, key, state.get(key))
		if not checked["ok"] or not is_equal_approx(float(state[key]), float(checked["value"])):
			return false
	var size_value := float(state["size"])
	var speed_value := float(state["speed"])
	_apply_body_size(size_value)
	drive_multiplier = speed_value / 2.0
	record.parameters["size"] = size_value
	record.parameters["speed"] = speed_value
	return true


func editor_snapshot() -> Dictionary:
	var data := {"color": get_parameter("color").to_html()}
	for key in Parameters.BEHAVIOR_FIELDS:
		data[key] = get_parameter(key)
	return data


func restore_editor(state: Variant) -> bool:
	if not state is Dictionary or state.size() != Parameters.BEHAVIOR_FIELDS.size() + 1:
		return false
	var encoded: Variant = state.get("color")
	if not encoded is String or encoded.length() != 8 or not Color.html_is_valid(encoded):
		return false
	for key in Parameters.BEHAVIOR_FIELDS:
		if not set_parameter(key, state.get(key)):
			return false
	return set_parameter("color", Color.html(encoded))
