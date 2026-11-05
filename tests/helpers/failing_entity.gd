extends "res://scripts/hackable_entity.gd"
## Test double to simulate a setter failing after the save has been validated.
var rejected_health := -1

func set_parameter(key: String, value: Variant) -> bool:
	if key == "health" and int(value) == rejected_health:
		return false
	return super.set_parameter(key, value)
