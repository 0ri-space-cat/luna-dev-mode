extends RefCounted
## Lightweight WHEN -> IF -> DO -> TARGET rules.
## All actions are typed EffectEngine operations; no arbitrary GDScript is run.

const ALLOWED_TARGETS = ["EVENT_SOURCE", "EVENT_TARGET", "RULE_OWNER"]

var effects
var _rules: Dictionary = {}
var _last_fired: Dictionary = {}


func _init(effect_engine) -> void:
	effects = effect_engine


func register_rule(definition: Dictionary) -> bool:
	for field in ["id", "owner_id", "event_type", "target", "effects"]:
		if not definition.has(field):
			return false
	var rule_id: String = str(definition["id"])
	if rule_id.is_empty() or _rules.has(rule_id) or str(definition["event_type"]).is_empty():
		return false
	if not ALLOWED_TARGETS.has(str(definition["target"])):
		return false
	var actions: Variant = definition["effects"]
	if typeof(actions) != TYPE_ARRAY or actions.is_empty():
		return false
	for action in actions:
		if typeof(action) != TYPE_DICTIONARY or not action.has("operation"):
			return false
		if str(action["operation"]) == "SET_RELATION":
			if not action.has("subject_id") or not action.has("value"):
				return false
		elif not action.has("parameter_id"):
			return false
	var conditions: Variant = definition.get("conditions", [])
	if typeof(conditions) != TYPE_ARRAY:
		return false
	for condition in conditions:
		if typeof(condition) != TYPE_DICTIONARY or not condition.has("field") or not condition.has("equals"):
			return false
	_rules[rule_id] = definition.duplicate(true)
	return true


func remove_rule(rule_id: String) -> void:
	_rules.erase(rule_id)
	_last_fired.erase(rule_id)


func count_rules() -> int:
	return _rules.size()


func process_event(event: Dictionary) -> int:
	var changes := 0
	for rule_id in _rules.keys():
		var rule: Dictionary = _rules[rule_id]
		if str(event.get("type", "")) != str(rule["event_type"]):
			continue
		var owner_id: String = str(rule["owner_id"])
		if not owner_id.is_empty() and owner_id != str(event.get("source_id", "")):
			continue
		if not _matches_conditions(rule, event):
			continue
		var cooldown_ms: int = int(rule.get("cooldown_ms", 0))
		var now_ms: int = Time.get_ticks_msec()
		if cooldown_ms > 0 and _last_fired.has(rule_id) and now_ms - int(_last_fired[rule_id]) < cooldown_ms:
			continue
		var target_id := _resolve_target(str(rule["target"]), owner_id, event)
		if target_id.is_empty():
			continue
		var successful := false
		for action in rule["effects"]:
			if effects.apply(action, target_id, "entity:%s" % owner_id, "rule:%s" % rule_id):
				changes += 1
				successful = true
		if successful:
			_last_fired[rule_id] = now_ms
	return changes


func _matches_conditions(rule: Dictionary, event: Dictionary) -> bool:
	var payload: Dictionary = event.get("payload", {})
	for condition in rule.get("conditions", []):
		if not payload.has(str(condition["field"])) or payload[str(condition["field"])] != condition["equals"]:
			return false
	return true


func _resolve_target(target_kind: String, owner_id: String, event: Dictionary) -> String:
	match target_kind:
		"EVENT_SOURCE":
			return str(event.get("source_id", ""))
		"EVENT_TARGET":
			return str(event.get("target_id", ""))
		"RULE_OWNER":
			return owner_id
	return ""
