extends "res://scripts/skeleton/entity_body_2d.gd"
## Natural individuals keep their Entity and modules through a death cycle.

signal respawned(identity: String)

const RESPAWN_SECONDS := 180.0
const BLINK_SECONDS := 1.0
const BLINK_COUNT := 5

var birth_point := Vector2.ZERO
var birth_height := 0.0
var aquatic_bounds := Rect2()
var death_remaining := 0.0
var _swim_direction := 1.0


func can_edit_parameter(key: String) -> bool:
	if key == "alive":
		return true
	return super.can_edit_parameter(key)


func set_parameter(key: String, value: Variant) -> bool:
	if key != "alive":
		return super.set_parameter(key, value)
	if not value is bool:
		return false
	if value == get_parameter("alive"):
		return true
	if value:
		return _revive()
	if is_attached():
		_detach_from_carrier()
	if has_passenger():
		var passenger := _rider
		if not passenger._try_release():
			passenger._detach_from_carrier()
			passenger._recover_after_carrier_loss()
	record.parameters["alive"] = false
	death_remaining = RESPAWN_SECONDS
	_stop_active_motion()
	return true


func _revive() -> bool:
	if not fits_walls_at(birth_point, birth_height, foot_radius()) \
			or not motion.start_on_safe_support(birth_point, birth_height, surfaces):
		return false
	record.parameters["alive"] = true
	death_remaining = 0.0
	position = birth_point
	velocity = Vector2.ZERO
	_impulse_velocity = Vector2.ZERO
	show()
	if _marker != null:
		_marker.rotation = 0.0
		_sync_projection()
	return true


func life_snapshot() -> Dictionary:
	var data := super.life_snapshot()
	data["respawn_remaining"] = death_remaining
	return data


func restore_life(state: Variant) -> bool:
	if not state is Dictionary or not state.get("alive") is bool or state.get("asleep") != false:
		return false
	var delay: Variant = state.get("respawn_remaining", 0.0)
	if typeof(delay) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(delay)) \
			or float(delay) < 0.0 or float(delay) > RESPAWN_SECONDS or (state["alive"] and float(delay) != 0.0):
		return false
	if not _restore_health(state):
		return false
	record.parameters["alive"] = state["alive"]
	death_remaining = float(delay)
	return true


func has_vital_swim() -> bool:
	return swim_in(record.get_components())


static func swim_in(components: Dictionary) -> bool:
	var abilities: Dictionary = components.get("ABILITY_SET", {})
	if "SWIM" in abilities.get("ids", []):
		return true
	for instance in abilities.get("instances", {}).values():
		if instance["ability_id"] == "SWIM" and instance["enabled"]:
			return true
	return false


func is_vitally_deprived() -> bool:
	if not aquatic_bounds.has_area() or not get_parameter("alive") or has_vital_swim():
		return false
	var water := _current_water()
	return water != null and water.submerged_fraction(position, motion.elevation, body_height()) >= 0.65


func _physics_process(delta: float) -> void:
	if aquatic_bounds.has_area():
		configure_water(0.0, has_vital_swim())
	if not get_parameter("alive"):
		death_remaining = maxf(0.0, death_remaining - delta)
		_update_death_visual()
		if death_remaining == 0.0 and _revive():
			respawned.emit(entity_id)
			return
		elif not visible:
			return
	super._physics_process(delta)


func _ready() -> void:
	super._ready()
	_update_death_visual()


func _update_death_visual() -> void:
	if get_parameter("alive"):
		return
	_marker.rotation = PI / 2.5
	var elapsed := RESPAWN_SECONDS - death_remaining
	visible = elapsed < BLINK_SECONDS and floori(elapsed / BLINK_SECONDS * BLINK_COUNT * 2.0) % 2 == 0


func _wander_on_support(delta: float) -> Vector2:
	if not aquatic_bounds.has_area():
		return super._wander_on_support(delta)
	var limits := aquatic_bounds.grow(-20.0)
	if profile_interest.is_finite() and has_vital_swim():
		# Swim toward the stimulus only inside the actual water bounds.
		var target := profile_interest.clamp(limits.position, limits.end)
		if target.distance_to(position) <= profile_interest_gap:
			return Vector2.ZERO
		return (target - position).normalized()
	if position.x <= limits.position.x:
		_swim_direction = 1.0
	elif position.x >= limits.end.x:
		_swim_direction = -1.0
	return Vector2(_swim_direction, 0.0) if has_vital_swim() else Vector2.ZERO
