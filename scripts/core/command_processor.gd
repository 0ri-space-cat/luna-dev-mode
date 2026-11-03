extends RefCounted
## The single entry point for changes made by Luna's editor.
## Later spells, Yuki and AI rules can pass their own initiator/source IDs.
## Audit entries are in-memory for now; save serialization is a later milestone.

signal parameter_changed(change: Dictionary)
signal trait_changed(change: Dictionary)
signal entity_changed(change: Dictionary)
signal history_changed

const MAX_UNDO := 120
const MAX_AUDIT := 300

var _sequence := 0
var _undo_stack: Array[Dictionary] = []
var _redo_stack: Array[Dictionary] = []
var _audit: Array[Dictionary] = []


func execute_set(target: Node, parameter_id: String, requested_value: Variant, initiator_id: String = "luna", source_id: String = "wand:luna", merge_key: String = "") -> bool:
	if not is_instance_valid(target) or not target.has_method("get_parameter") or not target.has_method("set_parameter"):
		return false
	var record: Variant = target.get("record")
	if record == null:
		return false
	var entity_id: String = str(record.id)
	var previous: Variant = target.call("get_parameter", parameter_id)
	if not bool(target.call("set_parameter", parameter_id, requested_value)):
		return false
	var actual: Variant = target.call("get_parameter", parameter_id)
	if previous == actual:
		return true

	_sequence += 1
	var entry: Dictionary = {
		"sequence": _sequence,
		"target_ref": weakref(target),
		"entity_id": entity_id,
		"parameter_id": parameter_id,
		"before": previous,
		"after": actual,
		"initiator_id": initiator_id,
		"source_id": source_id,
		"merge_key": merge_key
	}
	# Continuous slider motion is one undoable action, while every change
	# still creates its own audit event with initiator/source.
	var merged := false
	if not merge_key.is_empty() and not _undo_stack.is_empty():
		var last: Dictionary = _undo_stack.back()
		if last["merge_key"] == merge_key and last["entity_id"] == entity_id and last["parameter_id"] == parameter_id:
			last["after"] = actual
			merged = true
	if not merged:
		_undo_stack.append(entry)
	if _undo_stack.size() > MAX_UNDO:
		_undo_stack.pop_front()
	_redo_stack.clear()
	_append_audit("SET", entry, previous, actual)
	parameter_changed.emit(_latest_audit())
	history_changed.emit()
	return true


## Role and tag mutations are real commands with provenance and Undo/Redo.
## They change neither the origin category nor the derived CREATURE role.
func execute_trait(target: Node, operation: String, trait_name: String,
		initiator_id: String = "luna", source_id: String = "wand:luna") -> bool:
	if not is_instance_valid(target) or operation not in ["ADD_ROLE", "REMOVE_ROLE", "ADD_TAG", "REMOVE_TAG"]:
		return false
	var record: Variant = target.get("record")
	if record == null:
		return false
	var before := {"roles": record.get_stored_roles(), "tags": record.get_tags()}
	var accepted := false
	match operation:
		"ADD_ROLE": accepted = record.add_role(trait_name)
		"REMOVE_ROLE": accepted = record.remove_role(trait_name)
		"ADD_TAG": accepted = record.add_tag(trait_name)
		"REMOVE_TAG": accepted = record.remove_tag(trait_name)
	if not accepted:
		return false
	var after := {"roles": record.get_stored_roles(), "tags": record.get_tags()}
	_sequence += 1
	var entry := {
		"kind": "traits", "sequence": _sequence,
		"target_ref": weakref(target), "entity_id": str(record.id),
		"parameter_id": "ROLES_TAGS", "before": before, "after": after,
		"initiator_id": initiator_id, "source_id": source_id,
		"merge_key": "", "trait_operation": operation, "trait": trait_name
	}
	_undo_stack.append(entry)
	if _undo_stack.size() > MAX_UNDO:
		_undo_stack.pop_front()
	_redo_stack.clear()
	_append_audit("TRAIT_SET", entry, before, after)
	trait_changed.emit(_latest_audit())
	history_changed.emit()
	return true


func _replay_trait_change(entry: Dictionary, forward: bool) -> bool:
	var target: Object = (entry["target_ref"] as WeakRef).get_ref()
	if not is_instance_valid(target):
		return false
	var record: Variant = target.get("record")
	if record == null:
		return false
	var expected: Dictionary = entry["before"] if forward else entry["after"]
	if record.get_stored_roles() != expected["roles"] or record.get_tags() != expected["tags"]:
		return false
	var new_traits: Dictionary = entry["after"] if forward else entry["before"]
	if not record.set_traits(new_traits["roles"], new_traits["tags"]):
		return false
	_append_audit("REDO_TRAITS" if forward else "UNDO_TRAITS", entry, expected, new_traits)
	trait_changed.emit(_latest_audit())
	return true


## Single creation/removal command shared by the wand, magic and future
## systems. Blueprints contain only data and retain the same ID through redo.
func execute_entity_create(lifecycle, blueprint: Dictionary,
		initiator_id: String = "luna", source_id: String = "wand:luna") -> Node:
	if lifecycle == null:
		return null
	var actor: Node = lifecycle.restore_entity(blueprint)
	if actor == null:
		return null
	_record_entity_action(lifecycle, blueprint, "CREATE", initiator_id, source_id)
	return actor


func execute_entity_delete(lifecycle, entity_id: String,
		initiator_id: String = "luna", source_id: String = "wand:luna") -> bool:
	if lifecycle == null or entity_id == "luna":
		return false
	var blueprint: Dictionary = lifecycle.delete_entity(entity_id)
	if blueprint.is_empty():
		return false
	_record_entity_action(lifecycle, blueprint, "DELETE", initiator_id, source_id)
	return true


func _record_entity_action(lifecycle, blueprint: Dictionary, action: String,
		initiator_id: String, source_id: String) -> void:
	_sequence += 1
	var entry := {
		"kind": "entity", "lifecycle": lifecycle,
		"action": action, "blueprint": blueprint.duplicate(true),
		"sequence": _sequence, "entity_id": str(blueprint["id"]),
		"parameter_id": "ENTITY_LIFECYCLE", "initiator_id": initiator_id,
		"source_id": source_id, "merge_key": ""
	}
	_undo_stack.append(entry)
	if _undo_stack.size() > MAX_UNDO:
		_undo_stack.pop_front()
	_redo_stack.clear()
	_announce_entity(entry, action)
	history_changed.emit()


func _replay_entity(entry: Dictionary, forward: bool) -> bool:
	var lifecycle: Variant = entry["lifecycle"]
	var blueprint: Dictionary = entry["blueprint"]
	var should_exist: bool = (str(entry["action"]) == "CREATE") == forward
	if should_exist:
		if lifecycle.restore_entity(blueprint) == null:
			return false
	else:
		var removed: Dictionary = lifecycle.delete_entity(str(blueprint["id"]))
		if removed.is_empty():
			return false
		# A removed creation may have transient state/relations not captured
		# at creation; restoring it on redo should not inherit those edits.
		if str(entry["action"]) == "DELETE" and forward:
			entry["blueprint"] = removed
	_announce_entity(entry, ("REDO_" if forward else "UNDO_") + str(entry["action"]))
	return true


func _announce_entity(entry: Dictionary, action: String) -> void:
	_append_audit("ENTITY_" + action, entry, {}, entry["blueprint"])
	entity_changed.emit({
		"action": action, "entity_id": str(entry["entity_id"]),
		"category": str(entry["blueprint"]["category"]),
		"present": action in ["CREATE", "UNDO_DELETE", "REDO_CREATE"],
		"initiator_id": str(entry["initiator_id"]),
		"source_id": str(entry["source_id"])
	})


func undo() -> bool:
	if _undo_stack.is_empty():
		return false
	var entry: Dictionary = _undo_stack.back()
	if str(entry.get("kind", "")) == "entity":
		if not _replay_entity(entry, false):
			return false
		_undo_stack.pop_back()
		_redo_stack.append(entry)
		history_changed.emit()
		return true
	if str(entry.get("kind", "")) == "traits":
		if not _replay_trait_change(entry, false):
			return false
		_undo_stack.pop_back()
		_redo_stack.append(entry)
		history_changed.emit()
		return true
	if entry.has("steps"):
		if not _replay_batch(entry, false):
			return false
		_undo_stack.pop_back()
		_redo_stack.append(entry)
		history_changed.emit()
		return true
	var target: Object = (entry["target_ref"] as WeakRef).get_ref()
	if not is_instance_valid(target) or not bool(target.call("set_parameter", entry["parameter_id"], entry["before"])):
		return false
	_undo_stack.pop_back()
	_redo_stack.append(entry)
	_append_audit("UNDO", entry, entry["after"], entry["before"])
	parameter_changed.emit(_latest_audit())
	history_changed.emit()
	return true


func redo() -> bool:
	if _redo_stack.is_empty():
		return false
	var entry: Dictionary = _redo_stack.back()
	if str(entry.get("kind", "")) == "entity":
		if not _replay_entity(entry, true):
			return false
		_redo_stack.pop_back()
		_undo_stack.append(entry)
		history_changed.emit()
		return true
	if str(entry.get("kind", "")) == "traits":
		if not _replay_trait_change(entry, true):
			return false
		_redo_stack.pop_back()
		_undo_stack.append(entry)
		history_changed.emit()
		return true
	if entry.has("steps"):
		if not _replay_batch(entry, true):
			return false
		_redo_stack.pop_back()
		_undo_stack.append(entry)
		history_changed.emit()
		return true
	var target: Object = (entry["target_ref"] as WeakRef).get_ref()
	if not is_instance_valid(target) or not bool(target.call("set_parameter", entry["parameter_id"], entry["after"])):
		return false
	_redo_stack.pop_back()
	_undo_stack.append(entry)
	_append_audit("REDO", entry, entry["before"], entry["after"])
	parameter_changed.emit(_latest_audit())
	history_changed.emit()
	return true


func can_undo() -> bool:
	return not _undo_stack.is_empty()


func can_redo() -> bool:
	return not _redo_stack.is_empty()


func get_recent_audit(count: int = 4) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for i in range(_audit.size() - 1, maxi(_audit.size() - count, 0) - 1, -1):
		result.append(_audit[i].duplicate(true))
	return result


func get_audit_log() -> Array[Dictionary]:
	return _audit.duplicate(true)


func _append_audit(action: String, entry: Dictionary, previous: Variant, actual: Variant) -> void:
	_audit.append({
		"sequence": entry["sequence"],
		"action": action,
		"entity_id": entry["entity_id"],
		"parameter_id": entry["parameter_id"],
		"before": previous,
		"after": actual,
		"initiator_id": entry["initiator_id"],
		"source_id": entry["source_id"],
		"tick_ms": Time.get_ticks_msec()
	})
	if _audit.size() > MAX_AUDIT:
		_audit.pop_front()


func _latest_audit() -> Dictionary:
	return _audit.back().duplicate(true)


func clear_history() -> void:
	_undo_stack.clear()
	_redo_stack.clear()
	_audit.clear()
	history_changed.emit()


func execute_batch(prepared_steps: Array[Dictionary], initiator_id: String, source_id: String) -> bool:
	## One undoable transaction: validate the full sequence, then apply silently.
	## No event is emitted until all changes have committed.
	if prepared_steps.is_empty():
		return true
	if prepared_steps.size() > 32 or not _validate_batch(prepared_steps):
		return false
	if not _apply_steps(prepared_steps, true):
		return false
	var stored: Array[Dictionary] = []
	for step in prepared_steps:
		var archive: Dictionary = step.duplicate()
		if str(step["kind"]) == "parameter":
			archive["target_ref"] = weakref(step["target"])
			archive.erase("target")
		stored.append(archive)
	_undo_stack.append({
		"steps": stored, "initiator_id": initiator_id, "source_id": source_id
	})
	if _undo_stack.size() > MAX_UNDO:
		_undo_stack.pop_front()
	_redo_stack.clear()
	_announce_steps(stored, "SET", initiator_id, source_id, true)
	history_changed.emit()
	return true


func _replay_batch(entry: Dictionary, redo_change: bool) -> bool:
	var ordered: Array[Dictionary] = []
	for step in entry["steps"]:
		ordered.append(step)
	if not redo_change:
		ordered.reverse()
	if not _validate_batch(ordered, redo_change):
		return false
	if not _apply_steps(ordered, redo_change):
		return false
	_announce_steps(ordered, "REDO" if redo_change else "UNDO",
		str(entry["initiator_id"]), str(entry["source_id"]), redo_change)
	return true


func _validate_batch(steps: Array[Dictionary], forward: bool = true) -> bool:
	var virtual_values := {}
	for step in steps:
		if not step.has("kind") or not step.has("before") or not step.has("after"):
			return false
		var current: Variant
		var key := ""
		if step["kind"] == "parameter":
			var target: Object = _target_for_step(step)
			if not is_instance_valid(target) or not target.has_method("get_parameter") or not target.has_method("set_parameter"):
				return false
			var record: Variant = target.get("record")
			if record == null:
				return false
			var parameter_id: String = str(step.get("parameter_id", ""))
			var checked: Dictionary = record.registry.normalize(record.category, parameter_id,
				step["after"] if forward else step["before"])
			if not bool(checked["ok"]) or checked["value"] != (step["after"] if forward else step["before"]):
				return false
			key = "P:%s:%s" % [record.id, parameter_id]
			current = target.call("get_parameter", parameter_id)
		elif step["kind"] == "relation":
			var relations: Variant = step.get("relations")
			var from_id: String = str(step.get("from_id", ""))
			var to_id: String = str(step.get("to_id", ""))
			if relations == null or from_id.is_empty() or to_id.is_empty() or from_id == to_id:
				return false
			if not relations.is_valid_attitude(str(step["before"])) or not relations.is_valid_attitude(str(step["after"])):
				return false
			key = "R:%s:%s" % [from_id, to_id]
			current = relations.get_attitude(from_id, to_id)
		else:
			return false
		var expected: Variant = step["before"] if forward else step["after"]
		if virtual_values.has(key):
			current = virtual_values[key]
		if current != expected:
			return false
		virtual_values[key] = step["after"] if forward else step["before"]
	return true


func _apply_steps(steps: Array[Dictionary], forward: bool) -> bool:
	var done: Array[Dictionary] = []
	for step in steps:
		if not _apply_step(step, forward):
			done.reverse()
			for completed in done:
				_apply_step(completed, not forward)
			return false
		done.append(step)
	return true


func _apply_step(step: Dictionary, forward: bool) -> bool:
	var value: Variant = step["after"] if forward else step["before"]
	if str(step["kind"]) == "parameter":
		var target: Object = _target_for_step(step)
		return is_instance_valid(target) and bool(target.call("set_parameter", step["parameter_id"], value))
	var relations: Variant = step["relations"]
	return relations.set_attitude_silent(str(step["from_id"]), str(step["to_id"]), str(value))


func _target_for_step(step: Dictionary) -> Object:
	if step.has("target"):
		return step["target"]
	if step.has("target_ref"):
		return (step["target_ref"] as WeakRef).get_ref()
	return null


func _announce_steps(steps: Array[Dictionary], action: String,
		initiator_id: String, source_id: String, forward: bool) -> void:
	for step in steps:
		var before: Variant = step["before"] if forward else step["after"]
		var after: Variant = step["after"] if forward else step["before"]
		if step["kind"] == "relation":
			var relations: Variant = step["relations"]
			relations.announce_change(str(step["from_id"]), str(step["to_id"]),
				str(before), str(after), initiator_id, source_id)
			continue
		_sequence += 1
		var audit_step := {
			"sequence": _sequence,
			"entity_id": str(step["entity_id"]),
			"parameter_id": str(step["parameter_id"]),
			"initiator_id": initiator_id,
			"source_id": source_id
		}
		_append_audit(action, audit_step, before, after)
		parameter_changed.emit(_latest_audit())
