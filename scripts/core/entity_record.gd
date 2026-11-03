extends RefCounted
## Runtime parameters for one object. Base category is never modified by revival.
## Validation and defaults come entirely from ParameterRegistry.

var id: String
var category: String
var display_name: String
var parameters: Dictionary
var registry


func _init(entity_id: String, entity_category: String, label: String, parameter_registry, overrides: Dictionary = {}) -> void:
	id = entity_id
	category = entity_category
	display_name = label
	registry = parameter_registry
	parameters = registry.make_defaults(category, overrides)


func get_parameter(key: String) -> Variant:
	return parameters.get(key)


func set_parameter(key: String, value: Variant) -> bool:
	var checked: Dictionary = registry.normalize(category, key, value)
	if not checked["ok"]:
		push_warning("Rejected parameter '%s' on %s: %s" % [key, id, checked["error"]])
		return false
	parameters[key] = checked["value"]
	return true
