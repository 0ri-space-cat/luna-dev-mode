extends RefCounted
## Stable physical wand instances with one shared capability domain.

const Field = preload("res://scripts/runtime2d/projection_field_2d.gd")
const ORIGINAL := "LUNA_WAND"
const DUPLICATE := "LUNA_WAND_DUPLICATE"
const REACH := 54.0

var original := Field.new()
var duplicate: Field
var held := ORIGINAL
var retained := ORIGINAL


func active() -> Field:
	return original if retained == ORIGINAL else duplicate


func other() -> Field:
	return duplicate if retained == ORIGINAL else original


func duplicate_in_water(shore: Vector2, location: String) -> bool:
	if duplicate != null or held.is_empty() or not active().carried:
		return false
	duplicate = Field.new()
	duplicate.radius = active().radius
	return duplicate.drop_at(shore, location)


func can_hack_other(point: Vector2, location: String) -> bool:
	var target := other()
	return not held.is_empty() and active().carried and _near(target, point, location)


func exchange(point: Vector2, location: String) -> bool:
	var target := other()
	if _near(target, point, location):
		if not held.is_empty() and not active().drop_at(point, location):
			return false
		if not target.pick_up_from(point, REACH, location):
			return false
		held = DUPLICATE if retained == ORIGINAL else ORIGINAL
		retained = held
		return true
	if held.is_empty() and _near(active(), point, location):
		held = retained
		return active().pick_up_from(point, REACH, location)
	return false


func snapshot() -> Dictionary:
	return {"held": held, "retained": retained,
		"duplicate": {} if duplicate == null else duplicate.snapshot()}


func restore(base: Field, data: Variant) -> bool:
	if not data is Dictionary or data.get("held") not in ["", ORIGINAL, DUPLICATE] \
			or data.get("retained") not in [ORIGINAL, DUPLICATE] or not data.get("duplicate") is Dictionary:
		return false
	var clone: Field
	if not data["duplicate"].is_empty():
		clone = Field.new()
		if not clone.restore(data["duplicate"]):
			return false
	var next_held: String = data["held"]
	var selected: String = data["retained"]
	if (clone == null and selected == DUPLICATE) or (not next_held.is_empty() and selected != next_held) \
			or base.carried != (next_held == ORIGINAL) \
			or (next_held == DUPLICATE) != (clone != null and clone.carried):
		return false
	original = base
	duplicate = clone
	held = next_held
	retained = selected
	return true


func _near(field: Field, point: Vector2, location: String) -> bool:
	return field != null and not field.carried and field.ground_location_id == location \
		and field.ground_position.distance_squared_to(point) <= REACH * REACH
