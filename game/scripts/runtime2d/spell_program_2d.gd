extends RefCounted
## Safe, bounded programmable parameter effects for the author's wand.
## A spell is a small immutable list of typed operations, not executable GDScript.
## It uses the SAME reach, access and protected-target rules as TAB hacking.
## Actual spell names, visuals, resource costs and projectile rules are still
## authored separately. This adapter touches no screen-space UI or real OS.
const MAX_STEPS := 8
const MAX_ABS_OPERAND := 10000.0
const OPERATIONS := ["SET", "ADD", "MULTIPLY", "TOGGLE"]

var last_error := ""


func apply_to(controller: Node, target_id: String, program: Variant) -> bool:
	last_error = ""
	if not (program is Array) or program.is_empty() or program.size() > MAX_STEPS:
		return _fail("PROGRAM_LENGTH")
	if not is_instance_valid(controller.player):
		return _fail("MISSING_CASTER")
	var target: Node2D = controller.world_registry.get_entity(target_id) as Node2D
	if not is_instance_valid(target):
		return _fail("MISSING_TARGET")
	var record: Variant = target.get("record")
	if record == null:
		return _fail("NOT_EDITABLE_ENTITY")
	var virtual := {}
	var prepared: Array[Dictionary] = []
	var any_change := false
	for step in program:
		if not (step is Dictionary):
			return _fail("INVALID_STEP")
		var op: String = str(step.get("operation", ""))
		var field: String = str(step.get("parameter_id", ""))
		if op not in OPERATIONS or field.is_empty() or not field.is_valid_identifier() \
				or field.length() > 64:
			return _fail("UNKNOWN_OPERATION")
		if step.size() != (2 if op == "TOGGLE" else 3) \
				or (op != "TOGGLE" and not step.has("value")):
			return _fail("INVALID_STEP_SHAPE")
		for key in step:
			if str(key) not in ["operation", "parameter_id", "value"]:
				return _fail("UNKNOWN_STEP_FIELD")
		if not controller.wand_edit_policy.authorize(
				controller.player, target, controller.current_location_id,
				controller.projection, controller.access, controller.parameter_registry, field):
			return _fail(controller.wand_edit_policy.last_error)
		var old: Variant = virtual.get(field, target.get_parameter(field))
		if old == null:
			return _fail("UNKNOWN_PARAMETER")
		var requested: Variant = old
		match op:
			"SET":
				requested = step["value"]
			"TOGGLE":
				if typeof(old) != TYPE_BOOL:
					return _fail("TOGGLE_REQUIRES_BOOLEAN")
				requested = not bool(old)
			"ADD", "MULTIPLY":
				var operand: Variant = step["value"]
				if typeof(old) not in [TYPE_INT, TYPE_FLOAT] \
						or typeof(operand) not in [TYPE_INT, TYPE_FLOAT] \
						or not is_finite(float(operand)) \
						or absf(float(operand)) > MAX_ABS_OPERAND:
					return _fail("INVALID_NUMERIC_OPERATION")
				requested = float(old) + float(operand) if op == "ADD" \
					else float(old) * float(operand)
				if not is_finite(float(requested)):
					return _fail("NONFINITE_RESULT")
		if not _safe_operand(requested):
			return _fail("UNSAFE_VALUE")
		var checked: Dictionary = controller.parameter_registry.normalize(
			str(record.category), field, requested)
		if not bool(checked.get("ok", false)):
			return _fail("VALUE_REJECTED")
		var after: Variant = checked["value"]
		if after != old:
			any_change = true
		prepared.append({
			"kind": "parameter", "target": target,
			"entity_id": str(record.id), "parameter_id": field,
			"before": old, "after": after
		})
		virtual[field] = after
	if not any_change:
		return _fail("NOTHING_TO_CHANGE")
	# All steps have passed the public wand policy and registry validation.
	# The existing core applies the whole sequence atomically, emits events
	# only after success, and stores a SINGLE Undo/Redo transaction.
	if not controller.command_processor.execute_batch(
			prepared, "luna", "wand:spell_program"):
		return _fail("ATOMIC_TRANSACTION_REJECTED")
	return true


func _safe_operand(value: Variant) -> bool:
	match typeof(value):
		TYPE_BOOL:
			return true
		TYPE_INT, TYPE_FLOAT:
			return is_finite(float(value)) and absf(float(value)) <= MAX_ABS_OPERAND
		TYPE_STRING:
			return str(value).length() <= 96
		TYPE_COLOR:
			var tint: Color = value
			for channel in [tint.r, tint.g, tint.b, tint.a]:
				if not is_finite(float(channel)) or absf(float(channel)) > 16.0:
					return false
			return true
	return false


func _fail(reason: String) -> bool:
	last_error = reason
	return false
