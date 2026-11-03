extends RefCounted
## Directional social links between stable entity IDs.
## Links are world data, not a separate AI implementation per creature.
## NEUTRAL is implicit and removes the stored edge.

signal relationship_changed(change: Dictionary)

const ATTITUDES := ["NEUTRAL", "FRIEND", "HOSTILE", "AFRAID"]
const MAX_AUDIT := 300

var _links: Dictionary = {}
var _audit: Array[Dictionary] = []
var _sequence := 0


func get_attitude(from_id: String, to_id: String) -> String:
	var outward: Dictionary = _links.get(from_id, {})
	return str(outward.get(to_id, "NEUTRAL"))


func is_valid_attitude(attitude: String) -> bool:
	return ATTITUDES.has(attitude)


func set_attitude(from_id: String, to_id: String, attitude: String, initiator_id: String = "system", source_id: String = "system") -> bool:
	if not _valid_link(from_id, to_id, attitude):
		return false
	var before := get_attitude(from_id, to_id)
	if before == attitude:
		return true
	set_attitude_silent(from_id, to_id, attitude)
	announce_change(from_id, to_id, before, attitude, initiator_id, source_id)
	return true


func set_attitude_silent(from_id: String, to_id: String, attitude: String) -> bool:
	## Called by a prevalidated transaction. Emits nothing until commit succeeds.
	if not _valid_link(from_id, to_id, attitude):
		return false
	if attitude == "NEUTRAL":
		var existing: Dictionary = _links.get(from_id, {})
		existing.erase(to_id)
		if existing.is_empty():
			_links.erase(from_id)
		else:
			_links[from_id] = existing
	else:
		var outward: Dictionary = _links.get(from_id, {})
		outward[to_id] = attitude
		_links[from_id] = outward
	return true


func announce_change(from_id: String, to_id: String, before: String, after: String, initiator_id: String, source_id: String) -> void:
	if before == after:
		return
	_sequence += 1
	var change := {
		"sequence": _sequence, "from_id": from_id, "to_id": to_id,
		"before": before, "after": after,
		"initiator_id": initiator_id, "source_id": source_id
	}
	_audit.append(change)
	if _audit.size() > MAX_AUDIT:
		_audit.pop_front()
	relationship_changed.emit(change.duplicate(true))


func _valid_link(from_id: String, to_id: String, attitude: String) -> bool:
	return not from_id.is_empty() and not to_id.is_empty() and from_id != to_id and ATTITUDES.has(attitude)


func export_data() -> Dictionary:
	return _links.duplicate(true)


func validate_data(data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false
	for from_id in data.keys():
		if typeof(from_id) != TYPE_STRING or str(from_id).is_empty():
			return false
		if typeof(data[from_id]) != TYPE_DICTIONARY:
			return false
		for to_id in data[from_id].keys():
			if typeof(to_id) != TYPE_STRING or str(to_id).is_empty() or from_id == to_id:
				return false
			if typeof(data[from_id][to_id]) != TYPE_STRING or not ATTITUDES.has(data[from_id][to_id]):
				return false
	return true


func import_data(data: Dictionary) -> bool:
	if not validate_data(data):
		return false
	var restored := {}
	for from_id in data.keys():
		var outward := {}
		for to_id in data[from_id].keys():
			var attitude: String = data[from_id][to_id]
			if attitude != "NEUTRAL":
				outward[to_id] = attitude
		if not outward.is_empty():
			restored[from_id] = outward
	_links = restored
	clear_audit()
	return true


func clear_audit() -> void:
	_audit.clear()


func get_recent_audit(count: int = 6) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for i in range(_audit.size() - 1, maxi(_audit.size() - count, 0) - 1, -1):
		result.append(_audit[i].duplicate(true))
	return result
