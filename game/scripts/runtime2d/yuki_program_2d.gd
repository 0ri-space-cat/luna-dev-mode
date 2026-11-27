extends RefCounted
## Data-only, bounded scheduler. Every installed rule has independent state.
const MAX_RULES := 12
const ACTIONS := ["SPAWN_CAT", "SET_SPEED", "SET_ALIVE", "SET_AI"]
var ownership := 0 # 0 Yuki, 1 loan, 2 gift
var running := true
var rules: Array[Dictionary] = []
var next_id := 1
var spawn_serial := 0
var observed := false


func parse(source: String) -> Dictionary:
	var words := source.strip_edges().to_upper().split(" ", false)
	if words.size() < 4 or words[0] != "EVERY" or not words[1].is_valid_int():
		return {}
	var interval := int(words[1])
	if interval < 1 or interval > 1440:
		return {}
	if words.size() == 4 and words[2] == "SPAWN" and words[3] == "CAT":
		return {"period": interval, "action": "SPAWN_CAT", "value": 0.0}
	if words.size() != 6 or words[2] != "SET" or words[3] != "SELF":
		return {}
	if words[4] == "SPEED" and words[5].is_valid_float():
		var speed := float(words[5])
		if is_finite(speed) and speed >= 0.0 and speed <= 5.0:
			return {"period": interval, "action": "SET_SPEED", "value": speed}
	if words[4] in ["IS_ALIVE", "AUTONOMY"] and words[5] in ["ON", "OFF"]:
		return {"period": interval, "action": "SET_ALIVE" if words[4] == "IS_ALIVE" else "SET_AI", "value": words[5] == "ON"}
	return {}


func describe(rule: Dictionary) -> String:
	var prefix := "EVERY %d " % int(rule["period"])
	match rule["action"]:
		"SPAWN_CAT": return prefix + "SPAWN CAT"
		"SET_SPEED": return prefix + "SET SELF SPEED " + str(rule["value"])
		"SET_ALIVE": return prefix + "SET SELF IS_ALIVE " + ("ON" if rule["value"] else "OFF")
		"SET_AI": return prefix + "SET SELF AUTONOMY " + ("ON" if rule["value"] else "OFF")
	return ""


func install(host: String, source: String) -> bool:
	if ownership == 0 or rules.size() >= MAX_RULES or next_id >= 1000000:
		return false
	var rule := parse(source)
	if rule.is_empty() or (host.is_empty() and rule["action"] != "SPAWN_CAT"):
		return false
	rule.merge({"id": next_id, "host": host, "elapsed": 0.0, "enabled": true})
	rules.append(rule)
	next_id += 1
	return true


func set_enabled(id: int, enabled: bool) -> bool:
	for rule in rules:
		if int(rule["id"]) == id:
			rule["enabled"] = enabled
			return true
	return false


func remove(id: int) -> bool:
	for index in rules.size():
		if int(rules[index]["id"]) == id:
			rules.remove_at(index)
			return true
	return false


func has_active_cat_rule() -> bool:
	if not running:
		return false
	for rule in rules:
		if rule["enabled"] and rule["action"] == "SPAWN_CAT":
			return true
	return false


func advance(minutes: float, execute: Callable) -> void:
	if not running or not is_finite(minutes) or minutes <= 0.0 or not execute.is_valid():
		return
	# At most one dispatch per rule per update, no recursive event execution.
	for rule in rules:
		if not rule["enabled"]:
			continue
		var period := float(rule["period"])
		rule["elapsed"] = minf(period, float(rule["elapsed"]) + minutes)
		if rule["elapsed"] >= period:
			rule["elapsed"] = 0.0
			execute.call(rule)


func snapshot() -> Dictionary:
	return {"ownership": ownership, "running": running, "rules": rules.duplicate(true), "next_id": next_id, "spawn_serial": spawn_serial, "observed": observed}


static func _whole(value: Variant, low: int, high: int) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) and float(value) == floorf(float(value)) and float(value) >= low and float(value) <= high


func restore(data: Variant) -> bool:
	if not data is Dictionary or data.size() != 6:
		return false
	if not _whole(data.get("ownership"), 0, 2) or not data.get("running") is bool or not data.get("observed") is bool:
		return false
	if not _whole(data.get("next_id"), 1, 1000000) or not _whole(data.get("spawn_serial"), 0, 999999):
		return false
	var input: Variant = data.get("rules")
	if not input is Array or input.size() > MAX_RULES:
		return false
	var validated: Array[Dictionary] = []
	var ids := {}
	for rule in input:
		if not rule is Dictionary or rule.size() != 7:
			return false
		if not _whole(rule.get("id"), 1, int(data["next_id"]) - 1) or ids.has(int(rule["id"])):
			return false
		var host: Variant = rule.get("host")
		var action: Variant = rule.get("action")
		if not host is String or host.length() > 96 or (not host.is_empty() and not host.is_valid_identifier()):
			return false
		if action not in ACTIONS or (host.is_empty() and action != "SPAWN_CAT"):
			return false
		if not _whole(rule.get("period"), 1, 1440) or not rule.get("enabled") is bool:
			return false
		var elapsed: Variant = rule.get("elapsed")
		if typeof(elapsed) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(elapsed)) or float(elapsed) < 0.0 or float(elapsed) > float(rule["period"]):
			return false
		var value: Variant = rule.get("value")
		if action in ["SET_ALIVE", "SET_AI"]:
			if not value is bool:
				return false
		elif typeof(value) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(value)) or float(value) < 0.0 or float(value) > 5.0:
			return false
		ids[int(rule["id"])] = true
		validated.append(rule.duplicate(true))
	ownership = int(data["ownership"])
	running = data["running"]
	next_id = int(data["next_id"])
	spawn_serial = int(data["spawn_serial"])
	observed = data["observed"]
	rules = validated
	return true
