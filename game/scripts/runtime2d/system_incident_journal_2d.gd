extends RefCounted
## Per-world history. Only the save envelope owns it; local checkpoints never do.

const Access = preload("res://scripts/runtime2d/access_state_2d.gd")
const NONE := ""
const RESET_WAND := "RESET_WAND"
const REMOVE_LUNA := "REMOVE_LUNA"
const WINDOW_SECONDS := 900.0
const FIRST_THRESHOLD := 3
const NEXT_THRESHOLD := 2
const MAX_SERIAL := 2147483647

var serial := 0
var applied := 0
var active_seconds := 0.0
var wand_mode := NONE
var pending: Dictionary = {}
var history: Array[Dictionary] = []


func advance(delta: float) -> void:
	if delta > 0.0 and is_finite(delta):
		active_seconds += delta


func accept(reason: String, overload: bool) -> bool:
	if not pending.is_empty() or serial >= MAX_SERIAL:
		return false
	serial += 1
	var action := NONE
	if overload and applied < 2:
		var count := 1
		for index in range(history.size() - 1, -1, -1):
			var incident := history[index]
			if incident["action"] != NONE or active_seconds - float(incident["time"]) > WINDOW_SECONDS:
				break
			if incident["overload"]:
				count += 1
		var threshold := FIRST_THRESHOLD if applied == 0 else NEXT_THRESHOLD
		if count >= threshold:
			action = RESET_WAND if applied == 0 else REMOVE_LUNA
	pending = {"id": serial, "reason": reason.substr(0, 128), "overload": overload,
		"time": active_seconds, "action": action}
	return true


func acknowledge() -> void:
	if pending.is_empty():
		return
	match pending["action"]:
		RESET_WAND:
			wand_mode = Access.ORDINARY
			applied = 1
		REMOVE_LUNA:
			applied = 2
	history.append(pending)
	pending = {}


func snapshot() -> Dictionary:
	return {"serial": serial, "applied": applied, "active_seconds": active_seconds,
		"wand_mode": wand_mode, "history": history.duplicate(true), "pending": pending.duplicate(true)}


func restore(value: Variant) -> bool:
	if not value is Dictionary or not _whole(value.get("serial"), MAX_SERIAL) \
			or not _whole(value.get("applied"), 2) or not _number(value.get("active_seconds")) \
			or not value.get("history") is Array \
			or not value.get("pending") is Dictionary:
		return false
	var stage := int(value["applied"])
	var mode: Variant = value.get("wand_mode")
	if (stage == 0 and mode != NONE) or (stage > 0 and mode not in [Access.ORDINARY, Access.PLAYFUL, Access.DEVELOPER]):
		return false
	var entries: Array = value["history"]
	var next_pending: Dictionary = value["pending"]
	var latest := int(value["serial"])
	var end_time := float(value["active_seconds"])
	if latest != entries.size() + int(not next_pending.is_empty()):
		return false
	var previous := 0
	var previous_time := 0.0
	var previous_stage := 0
	for entry in entries:
		previous += 1
		if not _valid_incident(entry, previous, previous_time, end_time):
			return false
		previous_time = entry["time"]
		var action_stage := _stage(entry["action"])
		if action_stage > 0:
			if action_stage != previous_stage + 1 or action_stage > stage:
				return false
			previous_stage = action_stage
	if previous_stage != stage:
		return false
	if not next_pending.is_empty() and (not _valid_incident(next_pending, latest, previous_time, end_time) \
			or (_stage(next_pending["action"]) > 0 and _stage(next_pending["action"]) != stage + 1)):
		return false
	serial = latest
	applied = stage
	active_seconds = end_time
	wand_mode = mode
	history.assign(entries.duplicate(true))
	pending = next_pending.duplicate(true)
	return true


func _valid_incident(entry: Variant, id: int, earlier: float, later: float) -> bool:
	return entry is Dictionary and _whole(entry.get("id"), MAX_SERIAL) and int(entry["id"]) == id \
		and entry.get("reason") is String and entry["reason"].length() <= 128 \
		and entry.get("overload") is bool and _number(entry.get("time")) \
		and float(entry["time"]) >= earlier and float(entry["time"]) <= later \
		and entry.get("action") in [NONE, RESET_WAND, REMOVE_LUNA] \
		and (entry["overload"] or entry["action"] == NONE)


func _stage(action: String) -> int:
	return [NONE, RESET_WAND, REMOVE_LUNA].find(action)


func _whole(value: Variant, maximum: int) -> bool:
	return _number(value) and float(value) <= maximum and floorf(float(value)) == float(value)


func _number(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) and float(value) >= 0.0
