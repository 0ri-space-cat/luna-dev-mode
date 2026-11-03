extends RefCounted
## The single entry point for changes made by Luna's editor.
## Later spells, Yuki and AI rules can pass their own initiator/source IDs.
## Audit entries are in-memory for now; save serialization is a later milestone.

signal parameter_changed(change: Dictionary)
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


func undo() -> bool:
	if _undo_stack.is_empty():
		return false
	var entry: Dictionary = _undo_stack.back()
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
