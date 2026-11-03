extends RefCounted
## Data-driven WHEN -> IF -> DO -> TARGET rules. No executable scripts in data.
## Rule definitions and run-local firing limits survive world checkpoints;
## monotonic cooldown clocks and event-chain counters never cross a restart.

const SERIAL_VERSION := 1
const MAX_RULES := 64
const MAX_ACTIONS := 12
const MAX_CONDITION_DEPTH := 5
const MAX_CONDITION_BRANCHES := 8
const MAX_FIRES_PER_ROOT := 8
const MAX_TRACKED_ROOTS := 128
const ALLOWED_TARGETS := ["EVENT_SOURCE", "EVENT_TARGET", "RULE_OWNER"]
const ALLOWED_OPERATIONS := ["SET", "ADD", "MULTIPLY", "TOGGLE", "SET_RELATION", "COPY_ENTITY", "DELETE_ENTITY"]
const ALLOWED_COMPARISONS := ["EQ", "NE", "GT", "GTE", "LT", "LTE"]
const ALLOWED_RELATIONS := ["NEUTRAL", "FRIEND", "HOSTILE", "AFRAID"]

var effects
var _rules: Dictionary = {}
var _last_fired: Dictionary = {}
var _fire_counts: Dictionary = {}
var _root_counts: Dictionary = {}
var _recent_roots: Array[int] = []
var last_error := ""


func _init(effect_engine) -> void:
	effects = effect_engine


func register_rule(definition: Dictionary) -> bool:
	last_error = ""
	if _rules.size() >= MAX_RULES:
		return _fail("Rule capacity reached")
	var normalized := _normalize_rule(definition)
	if normalized.is_empty():
		return _fail("Invalid rule definition")
	var rule_id: String = str(normalized["id"])
	if _rules.has(rule_id):
		return _fail("Duplicate rule ID")
	_rules[rule_id] = normalized
	return true


func replace_rule(definition: Dictionary) -> bool:
	# Explicit updates preserve ID but reset runtime limits to prevent ambiguity.
	last_error = ""
	var normalized := _normalize_rule(definition)
	if normalized.is_empty():
		return _fail("Invalid rule definition")
	var rule_id: String = str(normalized["id"])
	if not _rules.has(rule_id):
		return _fail("Rule does not exist")
	_rules[rule_id] = normalized
	_last_fired.erase(rule_id)
	_fire_counts.erase(rule_id)
	_root_counts.clear()
	_recent_roots.clear()
	return true


func remove_rule(rule_id: String) -> void:
	_rules.erase(rule_id)
	_last_fired.erase(rule_id)
	_fire_counts.erase(rule_id)
	_root_counts.clear()
	_recent_roots.clear()


func count_rules() -> int:
	return _rules.size()


func get_rule(rule_id: String) -> Dictionary:
	return (_rules.get(rule_id, {}) as Dictionary).duplicate(true)


func list_rule_ids() -> Array[String]:
	var ids: Array[String] = []
	for key in _rules.keys():
		ids.append(str(key))
	ids.sort()
	return ids


func fired_count(rule_id: String) -> int:
	return int(_fire_counts.get(rule_id, 0))


func process_event(event: Dictionary) -> int:
	var changes := 0
	var ordered: Array[String] = list_rule_ids()
	ordered.sort_custom(func(a: String, b: String) -> bool:
		var pa: int = int(_rules[a].get("priority", 0))
		var pb: int = int(_rules[b].get("priority", 0))
		return pa > pb if pa != pb else a < b
	)
	for rule_id in ordered:
		var rule: Dictionary = _rules.get(rule_id, {})
		if rule.is_empty() or not bool(rule.get("enabled", true)):
			continue
		if str(event.get("type", "")) != str(rule["event_type"]):
			continue
		var owner_id: String = str(rule["owner_id"])
		if not owner_id.is_empty():
			if owner_id != str(event.get("source_id", "")):
				continue
			if effects.world.get_entity(owner_id) == null:
				continue
		if not _matches_condition(rule.get("where", {}), event):
			continue
		var lifetime_limit: int = int(rule.get("repeat_limit", 0))
		if lifetime_limit > 0 and fired_count(rule_id) >= lifetime_limit:
			continue
		var cooldown_ms: int = int(rule.get("cooldown_ms", 0))
		var now_ms: int = Time.get_ticks_msec()
		if cooldown_ms > 0 and _last_fired.has(rule_id) and now_ms - int(_last_fired[rule_id]) < cooldown_ms:
			continue
		var root_id: int = int(event.get("root_id", 0))
		var root_key := "%d:%s" % [root_id, rule_id]
		if root_id > 0 and int(_root_counts.get(root_key, 0)) >= MAX_FIRES_PER_ROOT:
			continue
		var target_id: String = _resolve_target(str(rule["target"]), owner_id, event)
		if target_id.is_empty():
			continue
		var initiator_id := "entity:%s" % owner_id if not owner_id.is_empty() else str(rule.get("author_id", "system"))
		if effects.apply_batch(rule["effects"], target_id, initiator_id, "rule:%s" % rule_id):
			changes += (rule["effects"] as Array).size()
			_last_fired[rule_id] = now_ms
			_fire_counts[rule_id] = fired_count(rule_id) + 1
			if root_id > 0:
				_track_root(root_id, root_key)
	return changes


func export_data() -> Dictionary:
	var definitions: Array[Dictionary] = []
	var counts := {}
	for rule_id in list_rule_ids():
		var packed: Dictionary = get_rule(rule_id)
		for action in packed["effects"]:
			if action.has("value") and typeof(action["value"]) == TYPE_COLOR:
				action["value"] = {"type": "color", "value": (action["value"] as Color).to_html(true)}
		definitions.append(packed)
		if fired_count(rule_id) > 0:
			counts[rule_id] = fired_count(rule_id)
	return {"version": SERIAL_VERSION, "rules": definitions, "fired": counts}


func validate_data(data: Variant) -> bool:
	return not _decode_data(data).is_empty()


func import_data(data: Dictionary) -> bool:
	last_error = ""
	if data.is_empty():
		# Older saves have no rules section; preserve the scene's defaults.
		return true
	var decoded: Dictionary = _decode_data(data)
	if decoded.is_empty():
		return _fail("Invalid persisted rule data")
	_rules = decoded["rules"]
	_fire_counts = decoded["fired"]
	_last_fired.clear()
	_root_counts.clear()
	_recent_roots.clear()
	return true


func _decode_data(data: Variant) -> Dictionary:
	if typeof(data) != TYPE_DICTIONARY:
		return {}
	if data.is_empty():
		return {"rules": _rules.duplicate(true), "fired": _fire_counts.duplicate(true)}
	if data.size() != 3 or typeof(data.get("version")) not in [TYPE_INT, TYPE_FLOAT] or int(data["version"]) != SERIAL_VERSION:
		return {}
	var entries: Variant = data.get("rules")
	var raw_counts: Variant = data.get("fired")
	if typeof(entries) != TYPE_ARRAY or typeof(raw_counts) != TYPE_DICTIONARY or entries.size() > MAX_RULES:
		return {}
	var parsed := {}
	for entry in entries:
		if typeof(entry) != TYPE_DICTIONARY:
			return {}
		var unpacked: Dictionary = entry.duplicate(true)
		if not unpacked.has("effects") or typeof(unpacked["effects"]) != TYPE_ARRAY:
			return {}
		for action in unpacked["effects"]:
			if typeof(action) != TYPE_DICTIONARY:
				return {}
			if action.has("value") and typeof(action["value"]) == TYPE_DICTIONARY:
				var color_data: Dictionary = action["value"]
				if color_data.size() != 2 or str(color_data.get("type", "")) != "color" or typeof(color_data.get("value")) != TYPE_STRING:
					return {}
				if not Color.html_is_valid(str(color_data["value"])):
					return {}
				action["value"] = Color.html(str(color_data["value"]))
		var rule: Dictionary = _normalize_rule(unpacked)
		if rule.is_empty() or parsed.has(str(rule["id"])):
			return {}
		parsed[str(rule["id"])] = rule
	var counts := {}
	for rule_id in raw_counts.keys():
		if typeof(rule_id) != TYPE_STRING or not parsed.has(rule_id):
			return {}
		var amount: Variant = raw_counts[rule_id]
		if not _valid_integer_range(amount, 0, 100000):
			return {}
		counts[rule_id] = int(amount)
	return {"rules": parsed, "fired": counts}


func _normalize_rule(input: Dictionary) -> Dictionary:
	for required in ["id", "owner_id", "event_type", "target", "effects"]:
		if not input.has(required):
			return {}
	if typeof(input["id"]) != TYPE_STRING or typeof(input["owner_id"]) != TYPE_STRING or typeof(input["event_type"]) != TYPE_STRING or typeof(input["target"]) != TYPE_STRING:
		return {}
	var rule_id: String = input["id"]
	var owner_id: String = input["owner_id"]
	var event_type: String = input["event_type"]
	if rule_id.is_empty() or rule_id.length() > 96 or owner_id.length() > 96 or event_type.is_empty() or event_type.length() > 96:
		return {}
	if not ALLOWED_TARGETS.has(str(input["target"])) or (owner_id.is_empty() and input["target"] == "RULE_OWNER"):
		return {}
	var actions: Variant = input["effects"]
	if typeof(actions) != TYPE_ARRAY or actions.is_empty() or actions.size() > MAX_ACTIONS:
		return {}
	for action in actions:
		if typeof(action) != TYPE_DICTIONARY or not _valid_action(action):
			return {}
	var where: Dictionary = {}
	if input.has("where"):
		if typeof(input["where"]) != TYPE_DICTIONARY:
			return {}
		if not input["where"].is_empty() and not _valid_condition(input["where"], 0):
			return {}
		where = input["where"].duplicate(true)
	elif input.has("conditions"):
		if typeof(input["conditions"]) != TYPE_ARRAY or input["conditions"].size() > MAX_CONDITION_BRANCHES:
			return {}
		var leaves: Array[Dictionary] = []
		for item in input["conditions"]:
			if typeof(item) != TYPE_DICTIONARY or not item.has("field") or not item.has("equals"):
				return {}
			var field: String = "payload.%s" % str(item["field"])
			var leaf := {"field": field, "op": "EQ", "value": item["equals"]}
			if not _valid_condition(leaf, 1):
				return {}
			leaves.append(leaf)
		if not leaves.is_empty():
			where = {"all": leaves}
	var priority: Variant = input.get("priority", 0)
	var cooldown: Variant = input.get("cooldown_ms", 0)
	var repeats: Variant = input.get("repeat_limit", 0)
	var enabled: Variant = input.get("enabled", true)
	if not _valid_integer_range(priority, -100, 100):
		return {}
	if not _valid_integer_range(cooldown, 0, 120000):
		return {}
	if not _valid_integer_range(repeats, 0, 100000):
		return {}
	if typeof(enabled) != TYPE_BOOL:
		return {}
	var author: Variant = input.get("author_id", "system")
	if typeof(author) != TYPE_STRING or author.is_empty() or author.length() > 96:
		return {}
	return {
		"id": rule_id, "owner_id": owner_id, "event_type": event_type,
		"target": str(input["target"]), "effects": actions.duplicate(true),
		"where": where, "priority": int(priority), "cooldown_ms": int(cooldown),
		"repeat_limit": int(repeats), "enabled": enabled, "author_id": author
	}


func _valid_integer_range(value: Variant, smallest: int, largest: int) -> bool:
	if typeof(value) not in [TYPE_INT, TYPE_FLOAT]:
		return false
	var amount: float = float(value)
	return not is_nan(amount) and not is_inf(amount) and amount >= float(smallest) \
		and amount <= float(largest) and is_equal_approx(amount, float(int(amount)))


func _valid_action(action: Dictionary) -> bool:
	var operation: String = str(action.get("operation", ""))
	if not ALLOWED_OPERATIONS.has(operation):
		return false
	if operation in ["DELETE_ENTITY", "COPY_ENTITY"]:
		# These are data-only; no embedded scripts, arbitrary manifests or
		# arbitrary direct OS actions can be persisted in a rule.
		for key in action.keys():
			if str(key) not in (["operation", "target_id"] if operation == "DELETE_ENTITY" else ["operation", "target_id", "new_id", "offset"]):
				return false
		if action.has("target_id") and (typeof(action["target_id"]) != TYPE_STRING or not str(action["target_id"]).is_valid_identifier()):
			return false
		if operation == "COPY_ENTITY":
			if action.has("new_id") and (typeof(action["new_id"]) != TYPE_STRING or not str(action["new_id"]).is_valid_identifier() or str(action["new_id"]).length() > 96):
				return false
			if action.has("offset"):
				var raw_offset: Variant = action["offset"]
				if typeof(raw_offset) != TYPE_ARRAY or raw_offset.size() != 3:
					return false
				for amount in raw_offset:
					if typeof(amount) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(amount)) or absf(float(amount)) > 12.0:
						return false
		return true
	if operation == "SET_RELATION":
		return typeof(action.get("subject_id")) == TYPE_STRING and not str(action["subject_id"]).is_empty() \
			and typeof(action.get("value")) == TYPE_STRING and ALLOWED_RELATIONS.has(str(action["value"]))
	if typeof(action.get("parameter_id")) != TYPE_STRING or not str(action["parameter_id"]).is_valid_identifier():
		return false
	if operation == "TOGGLE":
		return not action.has("value")
	if not action.has("value"):
		return false
	if operation in ["ADD", "MULTIPLY"]:
		return typeof(action["value"]) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(action["value"]))
	return typeof(action["value"]) in [TYPE_INT, TYPE_FLOAT, TYPE_BOOL, TYPE_STRING, TYPE_COLOR]


func _valid_condition(node: Dictionary, depth: int) -> bool:
	if depth > MAX_CONDITION_DEPTH:
		return false
	for combination in ["all", "any", "not"]:
		if node.has(combination):
			if node.size() != 1:
				return false
			if combination == "not":
				return typeof(node["not"]) == TYPE_DICTIONARY and _valid_condition(node["not"], depth + 1)
			var children: Variant = node[combination]
			if typeof(children) != TYPE_ARRAY or children.is_empty() or children.size() > MAX_CONDITION_BRANCHES:
				return false
			for child in children:
				if typeof(child) != TYPE_DICTIONARY or not _valid_condition(child, depth + 1):
					return false
			return true
	if node.size() != 3 or typeof(node.get("field")) != TYPE_STRING or typeof(node.get("op")) != TYPE_STRING:
		return false
	var field: String = node["field"]
	var valid_path := field.begins_with("payload.") or field in ["event.type", "event.source_id", "event.target_id"]
	if not valid_path or field.length() > 100 or not ALLOWED_COMPARISONS.has(str(node["op"])):
		return false
	if field.begins_with("payload.") and not field.substr(8).is_valid_identifier():
		return false
	var value: Variant = node.get("value")
	return typeof(value) in [TYPE_INT, TYPE_FLOAT, TYPE_BOOL, TYPE_STRING] \
		and (typeof(value) not in [TYPE_INT, TYPE_FLOAT] or is_finite(float(value)))


func _matches_condition(where: Dictionary, event: Dictionary) -> bool:
	if where.is_empty():
		return true
	if where.has("all"):
		for child in where["all"]:
			if not _matches_condition(child, event):
				return false
		return true
	if where.has("any"):
		for child in where["any"]:
			if _matches_condition(child, event):
				return true
		return false
	if where.has("not"):
		return not _matches_condition(where["not"], event)
	var field: String = str(where["field"])
	var found: Variant = null
	var available := false
	if field.begins_with("payload."):
		var payload: Dictionary = event.get("payload", {})
		var field_name: String = field.substr(8)
		if payload.has(field_name):
			found = payload[field_name]
			available = true
	else:
		var field_name: String = field.substr(6)
		if event.has(field_name):
			found = event[field_name]
			available = true
	if not available:
		return false
	var reference: Variant = where["value"]
	match str(where["op"]):
		"EQ": return found == reference
		"NE": return found != reference
		"GT", "GTE", "LT", "LTE":
			if typeof(found) not in [TYPE_INT, TYPE_FLOAT] or typeof(reference) not in [TYPE_INT, TYPE_FLOAT]:
				return false
			match str(where["op"]):
				"GT": return float(found) > float(reference)
				"GTE": return float(found) >= float(reference)
				"LT": return float(found) < float(reference)
				"LTE": return float(found) <= float(reference)
	return false


func _track_root(root_id: int, root_key: String) -> void:
	if not _recent_roots.has(root_id):
		_recent_roots.append(root_id)
		if _recent_roots.size() > MAX_TRACKED_ROOTS:
			var removed: int = _recent_roots.pop_front()
			var prefix := "%d:" % removed
			for key in _root_counts.keys():
				if str(key).begins_with(prefix):
					_root_counts.erase(key)
	_root_counts[root_key] = int(_root_counts.get(root_key, 0)) + 1


func _resolve_target(target_kind: String, owner_id: String, event: Dictionary) -> String:
	match target_kind:
		"EVENT_SOURCE": return str(event.get("source_id", ""))
		"EVENT_TARGET": return str(event.get("target_id", ""))
		"RULE_OWNER": return owner_id
	return ""


func _fail(message: String) -> bool:
	last_error = message
	return false
