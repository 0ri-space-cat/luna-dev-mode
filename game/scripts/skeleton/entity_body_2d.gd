extends "res://scripts/skeleton/elevation_body_2d.gd"
## An EntityRecord and a real 2D+Z body share one stable world ID.

const EntityRecord = preload("res://scripts/core/entity_record.gd")
const Parameters = preload("res://scripts/skeleton/entity_parameters_2d.gd")

const Brain = preload("res://scripts/runtime2d/behavior_brain_2d.gd")
var brain := Brain.new()
var world_registry

var record: EntityRecord
var location_id := ""


func get_world_location_id() -> String:
	return location_id


func get_parameter(key: String) -> Variant:
	return record.get_parameter(key)


func set_parameter(key: String, value: Variant) -> bool:
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
	elif record.category != "player" and get_parameter("ai_enabled"):
		direction = _wander_on_support(delta)
	super._physics_process(delta)


func _wander_on_support(delta: float) -> Vector2:
	if not motion.grounded or is_riding():
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
