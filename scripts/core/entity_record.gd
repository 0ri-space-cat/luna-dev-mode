extends RefCounted
## Lightweight, engine-independent gameplay record.
## Only a first slice of the ParameterRegistry planned in docs/05.

var id: String
var category: String
var display_name: String
var parameters: Dictionary


func _init(entity_id: String, entity_category: String, label: String, defaults: Dictionary) -> void:
	id = entity_id
	category = entity_category
	display_name = label
	parameters = defaults.duplicate(true)


func get_parameter(key: String) -> Variant:
	return parameters.get(key)


func set_parameter(key: String, value: Variant) -> bool:
	if not parameters.has(key):
		push_warning("Unknown parameter '%s' on %s" % [key, id])
		return false
	match key:
		"size":
			if typeof(value) != TYPE_FLOAT and typeof(value) != TYPE_INT:
				return false
			value = clampf(float(value), 0.5, 2.0)
		"speed":
			if typeof(value) != TYPE_FLOAT and typeof(value) != TYPE_INT:
				return false
			value = clampf(float(value), 0.0, 5.0)
		"health":
			if typeof(value) != TYPE_FLOAT and typeof(value) != TYPE_INT:
				return false
			value = clampi(int(value), 1, 200)
		"alive":
			if typeof(value) != TYPE_BOOL:
				return false
		"color":
			if typeof(value) != TYPE_COLOR:
				return false
	parameters[key] = value
	return true
