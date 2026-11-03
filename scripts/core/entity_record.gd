extends RefCounted
## Identity and classification for a single Entity. Base category NEVER changes
## when life, AI, appearance or roles are added. Stored roles are independent
## of the derived CREATURE role produced by IS_ALIVE.
const MAX_TRAITS := 24
const MAX_TRAIT_LENGTH := 32

var id: String
var category: String
var display_name: String
var parameters: Dictionary
var registry
var _roles: Array[String] = []
var _tags: Array[String] = []


func _init(entity_id: String, entity_category: String, label: String, parameter_registry, overrides: Dictionary = {}) -> void:
	id = entity_id
	category = entity_category
	display_name = label
	registry = parameter_registry
	parameters = registry.make_defaults(category, overrides)
	_roles = default_roles(category)
	_tags = default_tags(category)


func get_parameter(key: String) -> Variant:
	return parameters.get(key)


func set_parameter(key: String, value: Variant) -> bool:
	var checked: Dictionary = registry.normalize(category, key, value)
	if not checked["ok"]:
		push_warning("Rejected parameter '%s' on %s: %s" % [key, id, checked["error"]])
		return false
	parameters[key] = checked["value"]
	return true


func get_roles() -> Array[String]:
	var effective: Array[String] = _roles.duplicate()
	if bool(parameters.get("alive", false)) and not effective.has("CREATURE"):
		effective.append("CREATURE")
	effective.sort()
	return effective


func get_stored_roles() -> Array[String]:
	return _roles.duplicate()


func get_tags() -> Array[String]:
	return _tags.duplicate()


func has_role(role: String) -> bool:
	return get_roles().has(role)


func has_tag(tag: String) -> bool:
	return _tags.has(tag)


func set_traits(roles: Variant, tags: Variant) -> bool:
	# An invalid replacement never changes either collection.
	if not validate_trait_list(roles) or not validate_trait_list(tags):
		return false
	var next_roles: Array[String] = []
	var next_tags: Array[String] = []
	for value in roles:
		next_roles.append(str(value))
	for value in tags:
		next_tags.append(str(value))
	next_roles.sort()
	next_tags.sort()
	_roles = next_roles
	_tags = next_tags
	return true


func add_role(role: String) -> bool:
	if not _valid_trait_name(role) or _roles.has(role) or _roles.size() >= MAX_TRAITS:
		return false
	_roles.append(role)
	_roles.sort()
	return true


func remove_role(role: String) -> bool:
	if not _roles.has(role):
		return false
	_roles.erase(role)
	return true


func add_tag(tag: String) -> bool:
	if not _valid_trait_name(tag) or _tags.has(tag) or _tags.size() >= MAX_TRAITS:
		return false
	_tags.append(tag)
	_tags.sort()
	return true


func remove_tag(tag: String) -> bool:
	if not _tags.has(tag):
		return false
	_tags.erase(tag)
	return true


static func default_roles(entity_category: String) -> Array[String]:
	match entity_category:
		"tree": return ["PLANT"]
		"fridge": return ["MACHINE", "OBJECT"]
		"arcane_creature": return ["CREATURE", "MAGICAL"]
		"arcane_object": return ["MAGICAL", "OBJECT"]
		"arcane_energy": return ["ENERGY", "MAGICAL"]
	return []


static func default_tags(entity_category: String) -> Array[String]:
	match entity_category:
		"tree": return ["NATURE"]
		"fridge": return ["TECH"]
		"arcane_creature", "arcane_object", "arcane_energy": return ["ARCANE"]
	return []


static func validate_trait_list(values: Variant) -> bool:
	if typeof(values) != TYPE_ARRAY or values.size() > MAX_TRAITS:
		return false
	var found := {}
	for value in values:
		if typeof(value) != TYPE_STRING or not _valid_trait_name(str(value)) or found.has(value):
			return false
		found[value] = true
	return true


static func _valid_trait_name(value: String) -> bool:
	return not value.is_empty() and value.length() <= MAX_TRAIT_LENGTH \
		and value == value.to_upper() and value.is_valid_identifier()
