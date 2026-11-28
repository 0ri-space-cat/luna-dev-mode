extends "res://scripts/skeleton/elevation_body_2d.gd"
## A thrown dose owns its launch profile and follows the common 2D+Z physics.

const Profile = preload("res://scripts/runtime2d/consumable_profile_2d.gd")
const LIFETIME := 3.0
const SPEED := 310.0
const RISE := 105.0
const REBOUND := 0.66

var effects: Array:
	set(value):
		effects = value
		carries_electricity = effects.any(func(effect): return effect["id"] == "ELECTRO")
var carries_electricity := false
var hit_body: Callable
var hit_water: Callable
var landed: Callable
var _elapsed := 0.0
var bounced := false


func _ready() -> void:
	super._ready()
	_apply_body_size(0.22)
	_marker.color = Color("9fefe0")
	planar_impact.connect(_wall_contact)


func launch(point: Vector2, height: float, direction: Vector2, anchor: Array) -> void:
	motion.reset_on_surface(Vector2(anchor[0], anchor[1]), anchor[2])
	position = point
	motion.elevation = height
	motion.grounded = false
	configure_dynamics(1.0, REBOUND)
	apply_impulse(direction * SPEED, RISE)
	_sync_projection()


func _surface_bounciness() -> float:
	return 0.0 if bounced else super._surface_bounciness()


func _wall_contact(_collider: Object, _speed: float) -> void:
	if bounced:
		configure_dynamics(1.0, 0.0)
		return
	bounced = true


func _physics_process(delta: float) -> void:
	if is_queued_for_deletion():
		return
	_elapsed += delta
	if _elapsed >= LIFETIME:
		queue_free()
		return
	var from := Vector3(position.x, position.y, motion.elevation)
	var down := motion.vertical_speed < 0.0
	var prior_recoveries := recoveries
	super._physics_process(delta)
	if recoveries != prior_recoveries:
		queue_free()
		return
	var hit_surface := down and motion.vertical_speed > 0.0
	if hit_surface:
		bounced = true
	if bounced:
		configure_dynamics(1.0, 0.0)
	var finish := Vector3(position.x, position.y, motion.elevation)
	var target: Node = hit_body.call(from, finish, bounced, carries_electricity)
	if target != null:
		queue_free()
		landed.call(effects, target, position)
	elif carries_electricity and hit_water.is_valid() and hit_water.call(effects, from, finish):
		queue_free()
	elif motion.grounded:
		queue_free()
		landed.call(effects, null, position)
	elif hit_surface and landed.call(effects, null, position):
		queue_free()


func snapshot() -> Dictionary:
	return {"effects": effects.duplicate(true), "position": [position.x, position.y],
		"motion": motion.snapshot(), "impulse": [_impulse_velocity.x, _impulse_velocity.y],
		"elapsed": _elapsed, "bounced": bounced}


static func valid_snapshot(data: Variant) -> bool:
	if not data is Dictionary or data.size() != 6 or not Profile.valid_effects(data.get("effects"), false) \
			or not _valid_pair(data.get("position"), 100000.0) or not _valid_pair(data.get("impulse"), SPEED + 1.0) \
			or not data.get("motion") is Dictionary or not data.get("bounced") is bool:
		return false
	var movement: Dictionary = data["motion"]
	var anchor: Variant = movement.get("anchor")
	return _number_in(data.get("elapsed"), 0.0, LIFETIME) and movement.size() == 4 \
		and _number_in(movement.get("elevation"), RECOVERY_HEIGHT, 100000.0) \
		and _number_in(movement.get("vertical_speed"), -100000.0, 100000.0) and movement.get("grounded") is bool \
		and anchor is Array and anchor.size() == 3 and anchor.all(func(value): return _number_in(value, -100000.0, 100000.0))


static func _valid_pair(data: Variant, limit: float) -> bool:
	return data is Array and data.size() == 2 and _number_in(data[0], -limit, limit) and _number_in(data[1], -limit, limit)


static func _number_in(data: Variant, low: float, high: float) -> bool:
	return typeof(data) in [TYPE_FLOAT, TYPE_INT] and is_finite(float(data)) and float(data) >= low and float(data) <= high


func restore(data: Dictionary) -> bool:
	position = Vector2(data["position"][0], data["position"][1])
	if not motion.load_snapshot(data["motion"], position, surfaces, RECOVERY_HEIGHT):
		return false
	effects = data["effects"].duplicate(true)
	bounced = data["bounced"]
	_elapsed = float(data["elapsed"])
	_impulse_velocity = Vector2(data["impulse"][0], data["impulse"][1])
	configure_dynamics(1.0, 0.0 if bounced else REBOUND)
	_sync_projection()
	return true
