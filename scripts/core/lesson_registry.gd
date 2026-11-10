extends RefCounted
## Describes world laws and optional character hints, never story lock flags.
## Facts must be supplied by trusted physical systems, not by the player's journal.
const MAX_LESSONS := 64
const MAX_CLUES := 8
const MAX_CONDITIONS := 8
var _definitions: Dictionary = {}
var _observed: Dictionary = {}
var last_error := ""


func register_lesson(data: Dictionary) -> bool:
	last_error = ""
	var allowed := ["id", "zone_id", "law", "evidence", "physical_conditions",
		"character_hints", "alternate_methods", "valid_outcomes",
		"failure_feedback", "recovery_anchor"]
	for key in data.keys():
		if str(key) not in allowed:
			return _fail("Unknown lesson field; quest completion is never a physical prerequisite")
	for required in ["id", "zone_id", "law", "evidence", "physical_conditions"]:
		if not data.has(required):
			return _fail("Missing lesson field")
	for required in ["id", "zone_id", "law"]:
		if not _is_id(data[required]):
			return _fail("Invalid lesson identifier")
	var id: String = str(data["id"])
	if _definitions.has(id) or _definitions.size() >= MAX_LESSONS:
		return _fail("Duplicate lesson or registry full")
	for field in ["evidence", "physical_conditions", "character_hints",
			"alternate_methods", "valid_outcomes"]:
		var entries: Variant = data.get(field, [])
		if typeof(entries) != TYPE_ARRAY or entries.size() > (MAX_CONDITIONS if field == "physical_conditions" else MAX_CLUES):
			return _fail("Invalid %s list" % field)
		var seen: Dictionary = {}
		for value in entries:
			if not _is_id(value) or seen.has(str(value)):
				return _fail("Invalid or duplicate entry")
			seen[str(value)] = true
	for field in ["failure_feedback", "recovery_anchor"]:
		if data.has(field) and (typeof(data[field]) != TYPE_STRING or str(data[field]).length() > 120):
			return _fail("Invalid message or recovery anchor")
	_definitions[id] = data.duplicate(true)
	return true


func describe(lesson_id: String) -> Dictionary:
	return (_definitions.get(lesson_id, {}) as Dictionary).duplicate(true)


func list_ids() -> Array[String]:
	var ids: Array[String] = []
	for id in _definitions.keys():
		ids.append(str(id))
	ids.sort()
	return ids


func can_resolve(lesson_id: String, trusted_world_facts: Dictionary) -> bool:
	# No dependence on which character is controlled, journal entries,
	# experience, completed quests or order of discovery.
	var lesson: Dictionary = describe(lesson_id)
	if lesson.is_empty():
		return false
	for key in lesson["physical_conditions"]:
		if trusted_world_facts.get(str(key), false) != true:
			return false
	return true


func observe(lesson_id: String, clue_id: String) -> bool:
	# Journal records understanding only. Recording evidence unlocks no physics.
	var lesson: Dictionary = describe(lesson_id)
	if lesson.is_empty() or clue_id not in lesson["evidence"]:
		return false
	var seen: Dictionary = _observed.get(lesson_id, {}).duplicate(true)
	seen[clue_id] = true
	_observed[lesson_id] = seen
	return true


func observations(lesson_id: String) -> Array[String]:
	var result: Array[String] = []
	for clue in (_observed.get(lesson_id, {}) as Dictionary).keys():
		result.append(str(clue))
	result.sort()
	return result


func _is_id(value: Variant) -> bool:
	return typeof(value) == TYPE_STRING and not str(value).is_empty() \
		and str(value).length() <= 96 and str(value).is_valid_identifier()


func _fail(message: String) -> bool:
	last_error = message
	return false
