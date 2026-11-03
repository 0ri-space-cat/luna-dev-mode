extends RefCounted
## Effects always route through the same CommandProcessor as the hack editor.
## Nothing here runs arbitrary scripts or mutates Node properties directly.

var world
var commands
var last_error := ""


func _init(world_registry, command_processor) -> void:
	world = world_registry
	commands = command_processor


func apply(effect: Dictionary, target_id: String, initiator_id: String, source_id: String) -> bool:
	last_error = ""
	var target: Node = world.get_entity(target_id)
	if target == null or not target.has_method("get_parameter"):
		last_error = "Unknown target ID: %s" % target_id
		return false
	var key: String = str(effect.get("parameter_id", ""))
	if key.is_empty():
		last_error = "Missing parameter_id"
		return false
	var before: Variant = target.call("get_parameter", key)
	if before == null:
		last_error = "Target does not expose parameter %s" % key
		return false
	var operation: String = str(effect.get("operation", "SET"))
	var proposed: Variant
	match operation:
		"SET":
			if not effect.has("value"):
				last_error = "SET requires value"
				return false
			proposed = effect["value"]
		"ADD", "MULTIPLY":
			if not (typeof(before) == TYPE_INT or typeof(before) == TYPE_FLOAT):
				last_error = "%s requires numeric parameter" % operation
				return false
			if not effect.has("value") or not (typeof(effect["value"]) == TYPE_INT or typeof(effect["value"]) == TYPE_FLOAT):
				last_error = "%s requires numeric value" % operation
				return false
			var amount: float = float(effect["value"])
			var calculated: float = float(before) + amount if operation == "ADD" else float(before) * amount
			proposed = int(roundf(calculated)) if typeof(before) == TYPE_INT else calculated
		"TOGGLE":
			if typeof(before) != TYPE_BOOL:
				last_error = "TOGGLE requires boolean parameter"
				return false
			proposed = not bool(before)
		_:
			last_error = "Unsupported effect operation: %s" % operation
			return false
	if not commands.execute_set(target, key, proposed, initiator_id, source_id):
		last_error = "Target rejected effect for %s" % key
		return false
	return true
