extends RefCounted
## Effects always route through the same CommandProcessor as the hack editor.
## Nothing here runs arbitrary scripts or mutates Node properties directly.

var world
var commands
var relationships
var last_error := ""


func _init(world_registry, command_processor, relationship_service = null) -> void:
	world = world_registry
	commands = command_processor
	relationships = relationship_service


func apply(effect: Dictionary, target_id: String, initiator_id: String, source_id: String) -> bool:
	last_error = ""
	var target: Node = world.get_entity(target_id)
	if target == null:
		last_error = "Unknown target ID: %s" % target_id
		return false
	if str(effect.get("operation", "")) == "SET_RELATION":
		if relationships == null:
			last_error = "Relationship service is missing"
			return false
		var subject_id: String = str(effect.get("subject_id", ""))
		var attitude: String = str(effect.get("value", ""))
		if world.get_entity(subject_id) == null:
			last_error = "Unknown relationship source"
			return false
		if not relationships.set_attitude(subject_id, target_id, attitude, initiator_id, source_id):
			last_error = "Invalid relationship effect"
			return false
		return true
	if not target.has_method("get_parameter"):
		last_error = "Target has no editable parameters"
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


func apply_batch(actions: Array, target_id: String, initiator_id: String, source_id: String) -> bool:
	## Plan the entire chain against an in-memory shadow state. All or nothing.
	last_error = ""
	var plan: Dictionary = preview_batch(actions, target_id)
	if not bool(plan["ok"]):
		return false
	var prepared: Array[Dictionary] = plan["steps"]
	if not commands.execute_batch(prepared, initiator_id, source_id):
		last_error = "Failed to commit effect transaction"
		return false
	return true


func preview_batch(actions: Array, target_id: String) -> Dictionary:
	last_error = ""
	if actions.is_empty() or actions.size() > 12:
		return _reject_plan("An effect chain needs 1–12 steps")
	var target: Node = world.get_entity(target_id)
	if target == null:
		return _reject_plan("Unknown target: %s" % target_id)
	var virtual_values := {}
	var planned: Array[Dictionary] = []
	for effect in actions:
		if typeof(effect) != TYPE_DICTIONARY:
			return _reject_plan("Effect must be a dictionary")
		var operation: String = str(effect.get("operation", ""))
		if operation == "SET_RELATION":
			if relationships == null:
				return _reject_plan("No social relationship service")
			var from_id: String = str(effect.get("subject_id", ""))
			if world.get_entity(from_id) == null:
				return _reject_plan("Unknown relationship subject")
			if typeof(effect.get("value")) != TYPE_STRING:
				return _reject_plan("Relationship value must be a string")
			var attitude: String = effect["value"]
			if from_id == target_id or not relationships.is_valid_attitude(attitude):
				return _reject_plan("Invalid relationship")
			var relation_key := "R:%s:%s" % [from_id, target_id]
			var old_attitude: String = relationships.get_attitude(from_id, target_id)
			if virtual_values.has(relation_key):
				old_attitude = str(virtual_values[relation_key])
			if attitude != old_attitude:
				planned.append({
					"kind": "relation", "relations": relationships,
					"from_id": from_id, "to_id": target_id,
					"before": old_attitude, "after": attitude
				})
			virtual_values[relation_key] = attitude
			continue

		if not target.has_method("get_parameter"):
			return _reject_plan("Target has no editable parameters")
		var record: Variant = target.get("record")
		if record == null:
			return _reject_plan("Target has no entity record")
		var field: String = str(effect.get("parameter_id", ""))
		var key := "P:%s:%s" % [target_id, field]
		var before: Variant = target.call("get_parameter", field)
		if before == null:
			return _reject_plan("Unknown parameter: %s" % field)
		if virtual_values.has(key):
			before = virtual_values[key]
		var proposed: Variant
		match operation:
			"SET":
				if not effect.has("value"):
					return _reject_plan("SET requires a value")
				proposed = effect["value"]
			"ADD", "MULTIPLY":
				if not _numeric(before) or not _numeric(effect.get("value")):
					return _reject_plan("%s needs numbers" % operation)
				var amount := float(effect["value"])
				var calculated: float = float(before) + amount if operation == "ADD" else float(before) * amount
				if is_nan(calculated) or is_inf(calculated) or absf(calculated) > 100000000.0:
					return _reject_plan("Numeric result is out of bounds")
				proposed = int(roundf(calculated)) if typeof(before) == TYPE_INT else calculated
			"TOGGLE":
				if typeof(before) != TYPE_BOOL:
					return _reject_plan("TOGGLE requires TRUE/FALSE")
				proposed = not bool(before)
			_:
				return _reject_plan("Unsupported effect: %s" % operation)
		var checked: Dictionary = record.registry.normalize(record.category, field, proposed)
		if not bool(checked["ok"]):
			return _reject_plan("Invalid value for %s: %s" % [field, str(checked["error"])])
		var after: Variant = checked["value"]
		if before != after:
			planned.append({
				"kind": "parameter", "target": target, "entity_id": target_id,
				"parameter_id": field, "before": before, "after": after
			})
		virtual_values[key] = after
	return {"ok": true, "steps": planned}


func _numeric(value: Variant) -> bool:
	return typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT


func _reject_plan(reason: String) -> Dictionary:
	last_error = reason
	return {"ok": false, "steps": []}



func apply_to_targets(actions: Array, target_ids: Array[String],
		initiator_id: String, source_id: String) -> bool:
	var plans: Array[Dictionary] = []
	for target_id in target_ids:
		plans.append({"target_id": target_id, "actions": actions})
	return apply_targeted_batches(plans, initiator_id, source_id)


func apply_targeted_batches(plans: Array[Dictionary], initiator_id: String, source_id: String) -> bool:
	## Used by chain lightning: targets can receive DIFFERENT damage, all in
	## one transaction. Never leave a partially applied lightning chain.
	last_error = ""
	if plans.is_empty() or plans.size() > 8:
		last_error = "Invalid number of effect targets"
		return false
	var encountered := {}
	var steps: Array[Dictionary] = []
	for plan in plans:
		var target_id: String = str(plan.get("target_id", ""))
		if target_id.is_empty() or encountered.has(target_id):
			last_error = "Missing or repeated effect target"
			return false
		if typeof(plan.get("actions")) != TYPE_ARRAY:
			last_error = "Malformed effect plan"
			return false
		encountered[target_id] = true
		var preview: Dictionary = preview_batch(plan["actions"], target_id)
		if not bool(preview["ok"]):
			return false
		for step in preview["steps"]:
			steps.append(step)
		if steps.size() > 32:
			last_error = "Too many changes in a single spell"
			return false
	if steps.is_empty():
		return true
	if not commands.execute_batch(steps, initiator_id, source_id):
		last_error = "Multi-target transaction failed to commit"
		return false
	return true
