extends RefCounted
## Per-world history. Only the save envelope owns it; local checkpoints never do.

const Access = preload("res://scripts/runtime2d/access_state_2d.gd")
const NONE := ""
const RESET_WAND := "RESET_WAND"
const REMOVE_LUNA := "REMOVE_LUNA"
const PARLEY := "PARLEY"
const STARE := "STARE"
const STASIS := "STASIS"
const ACTIONS := [NONE, RESET_WAND, REMOVE_LUNA, PARLEY, STARE, STASIS]
const ANGER := "ANGER"
const MERCY := "MERCY"
const ENCOUNTER_SECONDS := 18.0
const STASIS_SECONDS := 8.0
const RESTRICTION_SECONDS := 360.0
const EXTRA_FROST_COOLDOWN := 4.0
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
var attitude := ANGER
var encounter := NONE
var encounter_until := 0.0
var stasis_deadline := 0.0
var restriction_until := 0.0
var frost_ready_at := 0.0


func advance(delta: float) -> void:
	if delta > 0.0 and is_finite(delta):
		active_seconds += delta


func accept(reason: String, overload: bool) -> bool:
	if not pending.is_empty() or serial >= MAX_SERIAL:
		return false
	serial += 1
	var action := NONE
	if overload and attitude != MERCY:
		var count := 1
		for index in range(history.size() - 1, -1, -1):
			var incident := history[index]
			if incident["action"] != NONE or active_seconds - float(incident["time"]) > WINDOW_SECONDS:
				break
			if incident["overload"]:
				count += 1
		var threshold := NEXT_THRESHOLD
		if applied == 0:
			threshold = FIRST_THRESHOLD
		elif applied in [_stage(PARLEY), _stage(STARE)]:
			threshold = 1
		if count >= threshold:
			action = ACTIONS[mini(applied + 1, ACTIONS.size() - 1)]
	pending = {"id": serial, "reason": reason.substr(0, 128), "overload": overload,
		"time": active_seconds, "action": action}
	return true


func acknowledge(wall_time: float = 0.0) -> void:
	if pending.is_empty():
		return
	match pending["action"]:
		RESET_WAND:
			wand_mode = Access.ORDINARY
			applied = 1
		REMOVE_LUNA:
			applied = 2
		PARLEY, STARE, STASIS:
			encounter = pending["action"]
			applied = _stage(encounter)
			encounter_until = active_seconds + ENCOUNTER_SECONDS
			if encounter == STASIS:
				stasis_deadline = wall_time + STASIS_SECONDS
				if restriction_remaining() <= 0.0:
					restriction_until = active_seconds + RESTRICTION_SECONDS
					frost_ready_at = 0.0
	history.append(pending)
	pending = {}


func encounter_is_active() -> bool:
	return attitude != MERCY and not encounter.is_empty() and encounter_until > active_seconds


func restriction_remaining() -> float:
	return maxf(0.0, restriction_until - active_seconds)


func allow_frost() -> bool:
	return restriction_remaining() <= 0.0 or active_seconds >= frost_ready_at


func record_frost_cast(base_seconds: float) -> bool:
	if restriction_remaining() <= 0.0:
		return false
	frost_ready_at = minf(restriction_until, active_seconds + base_seconds + EXTRA_FROST_COOLDOWN)
	return true


func surrender() -> bool:
	if not pending.is_empty() or not encounter_is_active():
		return false
	attitude = MERCY
	encounter = NONE
	encounter_until = 0.0
	stasis_deadline = 0.0
	restriction_until = 0.0
	frost_ready_at = 0.0
	return true


func snapshot() -> Dictionary:
	return {"serial": serial, "applied": applied, "active_seconds": active_seconds,
		"wand_mode": wand_mode, "history": history.duplicate(true), "pending": pending.duplicate(true),
		"administrator": {"attitude": attitude, "encounter": encounter, "encounter_until": encounter_until,
			"stasis_deadline": stasis_deadline, "restriction_until": restriction_until, "frost_ready_at": frost_ready_at}}


func restore(value: Variant) -> bool:
	if not value is Dictionary or not _whole(value.get("serial"), MAX_SERIAL) \
			or not _whole(value.get("applied"), ACTIONS.size() - 1) or not _number(value.get("active_seconds")) \
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
			if action_stage != mini(previous_stage + 1, ACTIONS.size() - 1) or action_stage > stage:
				return false
			previous_stage = action_stage
	if previous_stage != stage:
		return false
	if not next_pending.is_empty() and (not _valid_incident(next_pending, latest, previous_time, end_time) \
			or (_stage(next_pending["action"]) > 0 and _stage(next_pending["action"]) != mini(stage + 1, ACTIONS.size() - 1))):
		return false
	if not _restore_administrator(value.get("administrator", {}), stage, end_time, next_pending):
		return false
	serial = latest
	applied = stage
	active_seconds = end_time
	wand_mode = mode
	history.assign(entries.duplicate(true))
	pending = next_pending.duplicate(true)
	return true


func _restore_administrator(data: Variant, stage: int, time: float, next_pending: Dictionary) -> bool:
	if not data is Dictionary:
		return false
	var disposition: Variant = data.get("attitude", ANGER)
	var encounter_kind: Variant = data.get("encounter", NONE)
	var encounter_time: Variant = data.get("encounter_until", 0.0)
	var deadline: Variant = data.get("stasis_deadline", 0.0)
	var limit: Variant = data.get("restriction_until", 0.0)
	var cast_time: Variant = data.get("frost_ready_at", 0.0)
	if disposition not in [ANGER, MERCY] or encounter_kind not in [NONE, PARLEY, STARE, STASIS] \
			or not _number(encounter_time) or not _number(deadline) or not _number(limit) or not _number(cast_time):
		return false
	if (not encounter_kind.is_empty() and _stage(encounter_kind) != stage) \
			or (encounter_kind.is_empty() and encounter_time != 0.0) \
			or float(encounter_time) > time + ENCOUNTER_SECONDS + 0.01 \
			or (float(deadline) > 0.0 and encounter_kind != STASIS) \
			or (float(limit) > 0.0 and stage < _stage(STASIS)) \
			or float(limit) > time + RESTRICTION_SECONDS + 0.01 or float(cast_time) > float(limit):
		return false
	if disposition == MERCY and (stage < _stage(PARLEY) or not encounter_kind.is_empty() \
			or float(limit) != 0.0 or next_pending.get("action", NONE) != NONE):
		return false
	attitude = disposition
	encounter = encounter_kind
	encounter_until = encounter_time
	stasis_deadline = deadline
	restriction_until = limit
	frost_ready_at = cast_time
	return true


func _valid_incident(entry: Variant, id: int, earlier: float, later: float) -> bool:
	return entry is Dictionary and _whole(entry.get("id"), MAX_SERIAL) and int(entry["id"]) == id \
		and entry.get("reason") is String and entry["reason"].length() <= 128 \
		and entry.get("overload") is bool and _number(entry.get("time")) \
		and float(entry["time"]) >= earlier and float(entry["time"]) <= later \
		and entry.get("action") in ACTIONS \
		and (entry["overload"] or entry["action"] == NONE)


func _stage(action: String) -> int:
	return ACTIONS.find(action)


func _whole(value: Variant, maximum: int) -> bool:
	return _number(value) and float(value) <= maximum and floorf(float(value)) == float(value)


func _number(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) and float(value) >= 0.0
