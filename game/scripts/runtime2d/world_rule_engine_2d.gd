extends RefCounted
## Data-driven world event rules. No author secrets, scripts, dynamic eval,
## OS actions, scene identifiers or story content are hardcoded in this engine.
## Author rules can react to physical zones and invoke a small trusted action set.
##
## Every rule performs a SINGLE bounded action, and EventBus handles chained
## notifications with its own depth/queue/dispatch budget.

signal rule_fired(rule_id: String, location_id: String)
signal rule_rejected(rule_id: String, reason: String)

const WorldClock2D = preload("res://scripts/runtime2d/world_clock_2d.gd")

const MAX_RULES_PER_LOCATION := 48
const MAX_FIRED_FLAGS := 256
const MAX_ACTIONS_PER_EVENT := 8
const MAX_CONDITIONS_PER_RULE := 4
const TRIGGERS := ["ZONE_ENTERED", "ZONE_EXITED"]
const ACTIONS := ["SET_PARAMETER", "REDIRECT_DOOR", "ANNOUNCE"]
const PROTECTED_FIELDS := ["access_level", "material"]

var last_error := ""
var _rooms: Dictionary = {}
var _fired: Dictionary = {}


func validate_rules(rules: Variant) -> bool:
	last_error = ""
	if not (rules is Array) or rules.size() > MAX_RULES_PER_LOCATION:
		return _fail("Rules must be an array within budget")
	var seen := {}
	for entry in rules:
		if not (entry is Dictionary):
			return _fail("Invalid world rule entry")
		for key in entry:
			if str(key) not in ["id", "event", "zone_id", "actor_id", "once", "action", "conditions"]:
				return _fail("Unknown world rule field")
		var rule_id := str(entry.get("id", ""))
		var zone_id := str(entry.get("zone_id", ""))
		var event_id := str(entry.get("event", ""))
		if not _valid_id(rule_id) or not _valid_id(zone_id) or seen.has(rule_id):
			return _fail("Invalid or duplicate rule/zone ID")
		seen[rule_id] = true
		if event_id not in TRIGGERS:
			return _fail("Unsupported world rule trigger")
		if entry.has("actor_id") and not _valid_id(str(entry["actor_id"])):
			return _fail("Invalid trigger actor ID")
		if typeof(entry.get("once", false)) != TYPE_BOOL:
			return _fail("One-shot flag must be boolean")
		var conditions: Variant = entry.get("conditions", [])
		if not (conditions is Array) or conditions.size() > MAX_CONDITIONS_PER_RULE:
			return _fail("World rule condition budget exceeded")
		for condition in conditions:
			if not (condition is Dictionary):
				return _fail("World rule condition must be an object")
			if not _validate_condition(condition):
				return false
		var action: Variant = entry.get("action", null)
		if not (action is Dictionary):
			return _fail("Missing rule action")
		if not _validate_action(action):
			return false
	return true


func configure_location(location_id: String, definitions: Variant) -> bool:
	if not _valid_id(location_id) or not validate_rules(definitions):
		return false
	# Global IDs keep one-shot flags unambiguous across overlapping map rooms.
	var own_ids := {}
	for entry in definitions:
		own_ids[str(entry["id"])] = true
	for other_location in _rooms:
		if str(other_location) == location_id:
			continue
		for other in _rooms[other_location]:
			if own_ids.has(str(other["id"])):
				return _fail("Rule ID is already owned by another location")
	_rooms[location_id] = (definitions as Array).duplicate(true)
	return true


func process_event(event: Dictionary, controller: Node) -> int:
	var kind: String = str(event.get("type", ""))
	if kind not in TRIGGERS:
		return 0
	var room_id: String = str(event.get("location_id", ""))
	if room_id != str(controller.current_location_id):
		# Events queued before a door transition never affect a new room.
		return 0
	var count := 0
	for rule in _rooms.get(room_id, []):
		if str(rule["event"]) != kind or str(rule["zone_id"]) != str(event.get("zone_id", "")):
			continue
		if rule.has("actor_id") and str(rule["actor_id"]) != str(event.get("entity_id", "")):
			continue
		var id: String = str(rule["id"])
		if bool(rule.get("once", false)) and _fired.has(id):
			continue
		if not _conditions_met(rule, controller, room_id):
			continue
		if count >= MAX_ACTIONS_PER_EVENT:
			rule_rejected.emit(id, "RULE_EVENT_BUDGET")
			break
		if bool(rule.get("once", false)) and _fired.size() >= MAX_FIRED_FLAGS:
			rule_rejected.emit(id, "RULE_FLAG_BUDGET")
			continue
		count += 1
		if _apply_action(rule["action"], id, room_id, controller):
			if bool(rule.get("once", false)):
				_fired[id] = true
			rule_fired.emit(id, room_id)
		else:
			rule_rejected.emit(id, last_error)
	return count


func snapshot_flags() -> Array[String]:
	var ids: Array[String] = []
	for key in _fired:
		ids.append(str(key))
	ids.sort()
	return ids


func validate_flags(data: Variant) -> bool:
	if not (data is Array) or data.size() > MAX_FIRED_FLAGS:
		return false
	var seen := {}
	for value in data:
		if typeof(value) != TYPE_STRING or not _valid_id(str(value)) or seen.has(value):
			return false
		seen[value] = true
	return true


func restore_flags(data: Variant) -> bool:
	if not validate_flags(data):
		return false
	var fresh := {}
	for id in data:
		fresh[str(id)] = true
	_fired = fresh
	return true


func has_fired(rule_id: String) -> bool:
	return _fired.has(rule_id)


## Authorable conditions are deliberately simple and side-effect-free.
## An unknown condition rejects the entire catalog entry before it is mounted.
func _validate_condition(condition: Dictionary) -> bool:
	var kind: String = str(condition.get("type", ""))
	var allowed := ["type"]
	match kind:
		"ZONE_OCCUPIED":
			allowed.append("zone_id")
			allowed.append("actor_id")
			if not _valid_id(str(condition.get("zone_id", ""))):
				return _fail("Invalid occupancy zone")
			if condition.has("actor_id") and not _valid_id(str(condition["actor_id"])):
				return _fail("Invalid occupancy actor")
		"PARAMETER_EQUALS":
			allowed.append_array(["entity_id", "parameter_id", "value"])
			if not _valid_id(str(condition.get("entity_id", ""))) \
					or not _valid_id(str(condition.get("parameter_id", ""))) \
					or not condition.has("value"):
				return _fail("Invalid parameter condition")
			var expected: Variant = condition["value"]
			if typeof(expected) not in [TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING]:
				return _fail("Unsupported condition value")
			if typeof(expected) == TYPE_FLOAT and not is_finite(float(expected)):
				return _fail("Non-finite condition value")
			if typeof(expected) == TYPE_STRING and str(expected).length() > 96:
				return _fail("Condition text exceeds budget")
		"TIME_WINDOW":
			allowed.append_array(["start_minute", "end_minute"])
			if not WorldClock2D.is_valid_window(condition.get("start_minute"), condition.get("end_minute")):
				return _fail("Invalid daily time window")
		_:
			return _fail("Unknown world rule condition")
	for key in condition:
		if str(key) not in allowed:
			return _fail("Unknown condition field")
	return true


func _conditions_met(rule: Dictionary, controller: Node, room_id: String) -> bool:
	for condition in rule.get("conditions", []):
		match str(condition["type"]):
			"PARAMETER_EQUALS":
				var actor = controller.world_registry.get_entity(str(condition["entity_id"]))
				if actor == null or str(actor.location_id) != room_id:
					return false
				var current: Variant = actor.get_parameter(str(condition["parameter_id"]))
				var expected: Variant = condition["value"]
				if current == null:
					return false
				if typeof(current) in [TYPE_INT, TYPE_FLOAT] \
						and typeof(expected) in [TYPE_INT, TYPE_FLOAT]:
					if not is_equal_approx(float(current), float(expected)):
						return false
				elif current != expected:
					return false
			"ZONE_OCCUPIED":
				if not is_instance_valid(controller._live_level):
					return false
				var zone: Area2D = controller._live_level.geometry.find_zone(
					str(condition["zone_id"]))
				if zone == null:
					return false
				var occupied := false
				for body in zone.get_overlapping_bodies():
					if not body.has_method("get_world_location_id") \
							or str(body.get_world_location_id()) != room_id:
						continue
					if condition.has("actor_id"):
						var record: Variant = body.get("record")
						if record == null or str(record.id) != str(condition["actor_id"]):
							continue
					occupied = true
					break
				if not occupied:
					return false
			"TIME_WINDOW":
				if not controller.world_clock.is_in_window(int(condition["start_minute"]), int(condition["end_minute"])):
					return false
	return true


func _validate_action(action: Dictionary) -> bool:
	var kind: String = str(action.get("type", ""))
	if kind not in ACTIONS:
		return _fail("Unknown world rule action")
	var allowed: Array = ["type"]
	match kind:
		"SET_PARAMETER":
			allowed.append_array(["entity_id", "parameter_id", "value"])
			if not _valid_id(str(action.get("entity_id", ""))) or not _valid_id(str(action.get("parameter_id", ""))):
				return _fail("Invalid rule parameter target")
			if str(action["parameter_id"]) in PROTECTED_FIELDS or not action.has("value"):
				return _fail("Protected or absent rule value")
			var value: Variant = action["value"]
			if typeof(value) not in [TYPE_STRING, TYPE_BOOL, TYPE_INT, TYPE_FLOAT]:
				return _fail("Unsupported rule value type")
			if typeof(value) == TYPE_FLOAT and not is_finite(float(value)):
				return _fail("Non-finite rule value")
		"REDIRECT_DOOR":
			allowed.append_array(["door_id", "destination"])
			if not _valid_id(str(action.get("door_id", ""))) or not _valid_id(str(action.get("destination", ""))):
				return _fail("Invalid rule door address")
		"ANNOUNCE":
			allowed.append("event_id")
			if not _valid_id(str(action.get("event_id", ""))):
				return _fail("Invalid author event ID")
	for key in action:
		if str(key) not in allowed:
			return _fail("Unknown world rule action field")
	return true


func _apply_action(action: Dictionary, rule_id: String, room_id: String,
		controller: Node) -> bool:
	match str(action["type"]):
		"SET_PARAMETER":
			var entity = controller.world_registry.get_entity(str(action["entity_id"]))
			if entity == null or str(entity.location_id) != room_id:
				return _fail("Rule target is not present in its room")
			if not controller.command_processor.execute_set(entity,
					str(action["parameter_id"]), action["value"], "world", "world_rule:" + rule_id):
				return _fail("Rule parameter change was rejected")
			return true
		"REDIRECT_DOOR":
			if not controller.router.redirect_door(str(action["door_id"]),
					str(action["destination"]), "DEVELOPER"):
				return _fail("Rule door destination was rejected")
			return true
		"ANNOUNCE":
			return controller.queue_world_event({"type": "AUTHOR_RULE_EVENT",
				"rule_id": rule_id, "event_id": str(action["event_id"]),
				"location_id": room_id})
	return _fail("Unsupported world rule action")


func _valid_id(value: String) -> bool:
	return not value.is_empty() and value.length() <= 96 and value.is_valid_identifier()


func _fail(message: String) -> bool:
	last_error = message
	return false
