extends "res://scripts/skeleton/entity_body_2d.gd"
## Transient physical projection of the campaign's durable attitude.

const ID := "ET_SYSTEM_ADMINISTRATOR"
const CATEGORY := "administrator"
const ANGER := "ANGER"
const MERCY := "MERCY"

var mercy_requested: Callable


func can_edit_parameter(key: String) -> bool:
	return key == "luna_relation" and mercy_requested.is_valid()


func set_parameter(key: String, value: Variant) -> bool:
	if key != "luna_relation" or value != MERCY or not mercy_requested.is_valid() \
			or get_parameter(key) != ANGER or not mercy_requested.call(self):
		return false
	return super.set_parameter(key, value)
