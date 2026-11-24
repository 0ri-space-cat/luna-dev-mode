extends "res://scripts/skeleton/elevation_body_2d.gd"
## An EntityRecord and a real 2D+Z body share one stable world ID.

const EntityRecord = preload("res://scripts/core/entity_record.gd")
const Parameters = preload("res://scripts/skeleton/entity_parameters_2d.gd")

var record: EntityRecord
var location_id := ""


func get_world_location_id() -> String:
	return location_id


func get_parameter(key: String) -> Variant:
	return record.get_parameter(key)


func set_parameter(key: String, value: Variant) -> bool:
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
