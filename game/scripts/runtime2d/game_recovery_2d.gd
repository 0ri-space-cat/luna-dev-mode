extends RefCounted
## Bounded recovery guard for controlled in-game overloads.
## Never creates windows, manipulates the OS, crashes Godot or writes bad saves.
## The UI team can later display an in-game "rewind/system reset" affordance.

signal recovery_requested(reason: String)

const MAX_SAFE_ACTORS := 48
const MAX_REASON_LENGTH := 128

var pending := false
var reason := ""
var _safe_snapshot: Dictionary = {}


func capture(world: Dictionary) -> bool:
	# Don't overwrite the last known-good checkpoint during an incident.
	if pending or not _valid_snapshot(world):
		return false
	_safe_snapshot = world.duplicate(true)
	return true


func report(reason_code: String) -> bool:
	if pending:
		return false
	pending = true
	reason = reason_code.substr(0, MAX_REASON_LENGTH) if not reason_code.is_empty() else "UNKNOWN_INTEGRITY_EVENT"
	recovery_requested.emit(reason)
	return true


func snapshot_for_recovery() -> Dictionary:
	if not pending or _safe_snapshot.is_empty():
		return {}
	return _safe_snapshot.duplicate(true)


func acknowledge() -> void:
	# Only call after the world successfully applied the saved snapshot.
	pending = false
	reason = ""


func has_checkpoint() -> bool:
	return not _safe_snapshot.is_empty()


func _valid_snapshot(data: Dictionary) -> bool:
	if typeof(data.get("format", null)) not in [TYPE_INT, TYPE_FLOAT] or float(data["format"]) != 2.0:
		return false
	var entities: Variant = data.get("entities", null)
	if not (entities is Array) or entities.is_empty() or entities.size() > MAX_SAFE_ACTORS:
		return false
	return data.get("routes", null) is Dictionary and data.get("projection", null) is Dictionary
