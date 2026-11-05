extends RefCounted
const TargetResolver = preload("res://scripts/core/target_resolver.gd")
## Effects always route through the same CommandProcessor as the hack editor.
## Nothing here runs arbitrary scripts or mutates Node properties directly.

var world
var commands
var relationships
var lifecycle = null
var last_error := ""

const LIFECYCLE_OPS := ["COPY_ENTITY", "DELETE_ENTITY", "CREATE_ENTITY"]
const MAX_WORLD_STEPS := 12


func configure_lifecycle(entity_lifecycle) -> void:
	lifecycle = entity_lifecycle


func _init(world_registry, command_processor, relationship_service = null) -> void:
	world = world_registry
	commands = command_processor
	relationships = relationship_service


func apply(effect: Dictionary, target_id: String, initiator_id: String, source_id: String) -> bool:
	last_error = ""
	if str(effect.get("operation", "")) in LIFECYCLE_OPS:
		return apply_batch([effect], target_id, initiator_id, source_id)
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
	if plan.has("lifecycle"):
		var mutation: Dictionary = plan["lifecycle"]
		if not commands.execute_world_batch(prepared, lifecycle, str(mutation["operation"]),
				mutation["blueprint"], initiator_id, source_id):
			last_error = "Failed to commit world transaction"
			return false
	elif not commands.execute_batch(prepared, initiator_id, source_id):
		last_error = "Failed to commit effect transaction"
		return false
	return true


func preview_batch(actions: Array, target_id: String) -> Dictionary:
	last_error = ""
	if actions.is_empty() or actions.size() > MAX_WORLD_STEPS:
		return _reject_plan("An effect chain needs 1–12 steps")
	var target: Node = world.get_entity(target_id)
	if target == null:
		return _reject_plan("Unknown target: %s" % target_id)
	var virtual_values := {}
	var planned: Array[Dictionary] = []
	var world_mutation: Dictionary = {}
	for index in range(actions.size()):
		var effect: Variant = actions[index]
		if typeof(effect) != TYPE_DICTIONARY:
			return _reject_plan("Effect must be a dictionary")
		var operation: String = str(effect.get("operation", ""))
		var recipient_id: String = str(effect.get("target_id", target_id))
		if recipient_id.is_empty() or world.get_entity(recipient_id) == null:
			return _reject_plan("Unknown effect recipient")
		if operation in LIFECYCLE_OPS:
			# Lifecycle actions are terminal in this version. Creating then
			# modifying the new node will require a virtual-entity planner.
			if index != actions.size() - 1:
				return _reject_plan("A lifecycle action must be last")
			world_mutation = _preview_lifecycle(effect, recipient_id)
			if world_mutation.is_empty():
				return _reject_plan(last_error)
			continue
		var recipient: Node = world.get_entity(recipient_id)
		if operation == "SET_RELATION":
			if relationships == null:
				return _reject_plan("No social relationship service")
			var from_id: String = str(effect.get("subject_id", ""))
			if world.get_entity(from_id) == null:
				return _reject_plan("Unknown relationship subject")
			if typeof(effect.get("value")) != TYPE_STRING:
				return _reject_plan("Relationship value must be a string")
			var attitude: String = effect["value"]
			if from_id == recipient_id or not relationships.is_valid_attitude(attitude):
				return _reject_plan("Invalid relationship")
			var relation_key := "R:%s:%s" % [from_id, recipient_id]
			var old_attitude: String = relationships.get_attitude(from_id, recipient_id)
			if virtual_values.has(relation_key):
				old_attitude = str(virtual_values[relation_key])
			if attitude != old_attitude:
				planned.append({
					"kind": "relation", "relations": relationships,
					"from_id": from_id, "to_id": recipient_id,
					"before": old_attitude, "after": attitude
				})
			virtual_values[relation_key] = attitude
			continue

		if not recipient.has_method("get_parameter"):
			return _reject_plan("Target has no editable parameters")
		var record: Variant = recipient.get("record")
		if record == null:
			return _reject_plan("Target has no entity record")
		var field: String = str(effect.get("parameter_id", ""))
		var key := "P:%s:%s" % [recipient_id, field]
		var before: Variant = recipient.call("get_parameter", field)
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
				"kind": "parameter", "target": recipient, "entity_id": recipient_id,
				"parameter_id": field, "before": before, "after": after
			})
		virtual_values[key] = after
	if not world_mutation.is_empty():
		var boundary_id: String = str(world_mutation["blueprint"]["id"])
		for step in planned:
			if str(step["kind"]) == "parameter" and str(step["entity_id"]) == boundary_id:
				return _reject_plan("Cannot edit and create/delete the same entity in one chain")
			if str(step["kind"]) == "relation" and (str(step["from_id"]) == boundary_id or str(step["to_id"]) == boundary_id):
				return _reject_plan("Cannot edit a deleted entity's relations in the same chain")
		return {"ok": true, "steps": planned, "lifecycle": world_mutation}
	return {"ok": true, "steps": planned}


func _preview_lifecycle(effect: Dictionary, source_id: String) -> Dictionary:
	if lifecycle == null:
		last_error = "Entity lifecycle service is missing"
		return {}
	var operation: String = str(effect.get("operation", ""))
	if operation == "DELETE_ENTITY":
		if not _allowed_keys(effect, ["operation", "target_id"]):
			last_error = "Invalid DELETE_ENTITY fields"
			return {}
		var deleted: Dictionary = lifecycle.capture(source_id)
		if deleted.is_empty() or not lifecycle.validate_blueprint(deleted):
			last_error = "Cannot delete this entity"
			return {}
		return {"operation": "DELETE", "blueprint": deleted}
	if operation == "CREATE_ENTITY":
		if not _allowed_keys(effect, ["operation", "blueprint", "target_id"]) or typeof(effect.get("blueprint")) != TYPE_DICTIONARY:
			last_error = "CREATE_ENTITY requires a typed blueprint"
			return {}
		var blueprint: Dictionary = effect["blueprint"].duplicate(true)
		if not lifecycle.validate_blueprint(blueprint) or world.get_entity(str(blueprint.get("id", ""))) != null:
			last_error = "Invalid or occupied creation blueprint"
			return {}
		return {"operation": "CREATE", "blueprint": blueprint}
	if operation != "COPY_ENTITY" or not _allowed_keys(effect, ["operation", "target_id", "new_id", "offset"]):
		last_error = "Unsupported lifecycle operation"
		return {}
	var original: Dictionary = lifecycle.capture(source_id)
	if original.is_empty():
		last_error = "Cannot copy this entity"
		return {}
	var category: String = str(original["category"])
	var count := 0
	for entity_id in world.list_ids():
		var actor: Node = world.get_entity(entity_id)
		if category.begins_with("arcane_"):
			if entity_id.begins_with("arcane_"):
				count += 1
		elif actor != null and actor.has_meta("copy_origin"):
			count += 1
	if count >= (40 if category.begins_with("arcane_") else 24):
		last_error = "World has reached its copy limit"
		return {}
	var offset: Vector3 = Vector3(1.7, 0.0, 0.8)
	if effect.has("offset"):
		var raw_offset: Variant = effect["offset"]
		if typeof(raw_offset) != TYPE_ARRAY or raw_offset.size() != 3:
			last_error = "COPY offset must be three numeric values"
			return {}
		for coordinate in raw_offset:
			if typeof(coordinate) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(coordinate)) or absf(float(coordinate)) > 12.0:
				last_error = "COPY offset is out of bounds"
				return {}
		offset = Vector3(float(raw_offset[0]), float(raw_offset[1]), float(raw_offset[2]))
	var copy: Dictionary = original.duplicate(true)
	copy["position"] = original["position"] + offset
	if effect.has("new_id"):
		if typeof(effect["new_id"]) != TYPE_STRING:
			last_error = "COPY ID must be a string"
			return {}
		copy["id"] = str(effect["new_id"])
	else:
		var prefix := "arcane_" if category.begins_with("arcane_") else category + "_copy_"
		var serial := 1
		for current_id in world.list_ids() + world.deleted_ids():
			if str(current_id).begins_with(prefix) and str(current_id).substr(prefix.length()).is_valid_int():
				serial = maxi(serial, int(str(current_id).substr(prefix.length())) + 1)
		copy["id"] = "%s%04d" % [prefix, serial]
	if category in ["tree", "fridge"]:
		copy["copy_origin"] = source_id
	var copied_components: Dictionary = copy.get("components", {})
	if copied_components.has("PICKUP"):
		var pickup: Dictionary = copied_components["PICKUP"]
		pickup["holder_id"] = ""
		var landing: Vector3 = copy["position"]
		pickup["world_position"] = [landing.x, landing.y, landing.z]
		copied_components["PICKUP"] = pickup
		copy["components"] = copied_components
	if not lifecycle.validate_blueprint(copy) or world.get_entity(str(copy["id"])) != null or world.was_deleted(str(copy["id"])):
		last_error = "Invalid or reserved copy ID"
		return {}
	return {"operation": "CREATE", "blueprint": copy}


func _allowed_keys(data: Dictionary, allowed: Array) -> bool:
	for key in data.keys():
		if str(key) not in allowed:
			return false
	return true


func _numeric(value: Variant) -> bool:
	return typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT


func _reject_plan(reason: String) -> Dictionary:
	last_error = reason
	return {"ok": false, "steps": []}



## A selector is resolved at cast/rule execution time. Never cache Nodes or
## a list of targets in serialized spell/rule definitions.
func apply_to_selector(actions: Array, origin_id: String, selector: Dictionary,
		initiator_id: String, source_id: String) -> bool:
	last_error = ""
	if not TargetResolver.validate_selector(selector):
		last_error = "Invalid target selector"
		return false
	for action in actions:
		if typeof(action) != TYPE_DICTIONARY or action.has("target_id"):
			last_error = "Selector actions may not override their selected target"
			return false
	var targets: Array[String] = TargetResolver.select_by_properties(
		world, origin_id, selector, relationships
	)
	if targets.is_empty():
		last_error = "No matching targets"
		return false
	if targets.size() == 1:
		return apply_batch(actions, targets[0], initiator_id, source_id)
	return apply_to_targets(actions, targets, initiator_id, source_id)


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
	# No partial deletion across an area or chain. A future multi-entity
	# planner will lift this restriction with a real two-phase commit.
	for plan in plans:
		for action in plan.get("actions", []):
			if typeof(action) == TYPE_DICTIONARY and str(action.get("operation", "")) in LIFECYCLE_OPS:
				if plans.size() == 1:
					return apply_batch(plan["actions"], str(plan.get("target_id", "")), initiator_id, source_id)
				last_error = "Area lifecycle operations need a multi-entity transaction"
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
