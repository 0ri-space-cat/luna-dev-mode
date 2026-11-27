extends RefCounted
## Three editors share this small rule format and the world's typed fields.

const Fields = preload("res://eternia/console.gd")
const LIMIT := 12
const PROTECTED := ["luna", "giant", "leya", "ori", "toffi", "mia", "oni"]
const GROUPS := ["creature", "object", "emot"]

var rules: Array = []
var clocks := {}
var inside := {}
var pending := {}
var running := true

func parse(game, text: String) -> Dictionary:
	var words := text.strip_edges().split(" ", false)
	if words.size() < 7 or words.size() > 18 or words[3] != "SET":
		return {}
	var rule := {"trigger":words[0], "source":words[1], "distance":0.0,
		"room":game.current_location_id, "target":words[4], "field":words[5], "value":words[6]}
	if not words[2].is_valid_float() or not is_finite(words[2].to_float()):
		return {}
	rule.distance = words[2].to_float()
	if rule.trigger == "NEAR":
		if not game.world_registry.get_entity(rule.source) or rule.distance < 16 or rule.distance > 180:
			return {}
	elif rule.trigger == "ON_PAD":
		if not game._live_level.geometry.find_zone(rule.source) or words[2] != "0":
			return {}
	elif rule.trigger == "EVERY":
		if rule.source not in ["HERE","WORLD"] or rule.distance < 1 or rule.distance > 60:
			return {}
	else:
		return {}
	var category := category_for(game,rule.target)
	if category.is_empty() or rule.target in PROTECTED:
		return {}
	if typed_field(game,category,rule.field,rule.value).is_empty():
		return {}
	var cursor := 7
	if words.size() > cursor and words[cursor] == "IF":
		if words.size() < cursor + 4: return {}
		var guard = game.world_registry.get_entity(words[cursor+1])
		if not guard or typed_field(game,guard.record.category,words[cursor+2],words[cursor+3]).is_empty():
			return {}
		rule.guard = {"actor":words[cursor+1],"field":words[cursor+2],"value":words[cursor+3]}
		cursor += 4
	if words.size() > cursor and words[cursor] == "ELSE":
		if not rule.has("guard") or words.size() < cursor + 2:
			return {}
		if typed_field(game,category,rule.field,words[cursor+1]).is_empty():
			return {}
		rule.alternate = words[cursor+1]
		cursor += 2
	if words.size() > cursor and words[cursor] == "WAIT":
		if words.size() < cursor + 2 or not words[cursor+1].is_valid_float():
			return {}
		var delay := words[cursor+1].to_float()
		if not is_finite(delay) or delay <= 0 or delay > 30:
			return {}
		rule.delay = delay
		cursor += 2
	if cursor != words.size(): return {}
	return rule

func category_for(game, target: String) -> String:
	if target.begins_with("@"):
		var category := target.substr(1)
		return category if category in GROUPS else ""
	var actor = game.world_registry.get_entity(target)
	return actor.record.category if actor else ""

func typed_field(game, category: String, name: String, value: String) -> Dictionary:
	var spec := Fields.find_field(game.parameter_registry,category,name)
	if spec.is_empty():
		return {}
	var parsed: Variant = Fields.parse_value(spec.kind,value)
	if parsed == null:
		return {}
	var normalized: Dictionary = game.parameter_registry.normalize(category,spec.id,parsed)
	return normalized.merged({"id":spec.id}) if normalized.ok else {}

func valid_snapshot(data: Variant) -> bool:
	if not data is Array or data.size() > LIMIT:
		return false
	for rule in data:
		if not rule is Dictionary:
			return false
		for key in ["trigger","source","room","target","field","value"]:
			if not rule.get(key) is String or rule[key].is_empty() or rule[key].length() > 96:
				return false
		if rule.trigger not in ["NEAR","EVERY","ON_PAD"]:
			return false
		if typeof(rule.get("distance")) not in [TYPE_FLOAT,TYPE_INT] or not is_finite(float(rule.distance)):
			return false
		match rule.trigger:
			"EVERY":
				if rule.distance < 1 or rule.distance > 60 or rule.source not in ["HERE","WORLD"]:
					return false
			"NEAR":
				if rule.distance < 16 or rule.distance > 180:
					return false
		if rule.has("guard"):
			if not rule.guard is Dictionary:
				return false
			for key in ["actor","field","value"]:
				if not rule.guard.get(key) is String or rule.guard[key].length() > 96:
					return false
		if rule.has("alternate") and (not rule.alternate is String or rule.alternate.length() > 96):
			return false
		if rule.has("delay"):
			if typeof(rule.delay) not in [TYPE_FLOAT,TYPE_INT] or not is_finite(float(rule.delay)) or rule.delay <= 0 or rule.delay > 30:
				return false
	return true

func add(rule: Dictionary) -> bool:
	if rule.is_empty() or rules.size() >= LIMIT:
		return false
	rules.append(rule)
	return true

func remove(index: int) -> void:
	rules.remove_at(index)
	reset_transients()

func reset_transients() -> void:
	clocks.clear()
	inside.clear()
	pending.clear()

func describe(rule: Dictionary) -> String:
	var code := "%s %s %s SET %s %s %s" % [rule.trigger,rule.source,rule.distance,rule.target,rule.field,rule.value]
	if rule.has("guard"):
		code += " IF %s %s %s" % [rule.guard.actor,rule.guard.field,rule.guard.value]
	if rule.has("alternate"): code += " ELSE "+rule.alternate
	if rule.has("delay"): code += " WAIT "+str(rule.delay)
	return code

func advance(game, delta: float) -> void:
	if not running:
		return
	for i in rules.size():
		var rule: Dictionary = rules[i]
		if rule.source != "WORLD" and game.current_location_id != rule.room:
			pending.erase(i)
		if pending.has(i):
			var job: Dictionary = pending[i]
			job.left -= delta
			if job.left <= 0:
				apply_rule(game,rule,job.value)
				pending.erase(i)
			continue
		if not should_fire(game,rule,i,delta): continue
		var value: String = rule.value
		if rule.has("guard") and not guard_succeeds(game,rule.guard):
			if not rule.has("alternate"): continue
			value = rule.alternate
		if rule.has("delay"):
			pending[i] = {"left":rule.delay,"value":value}
		else:
			apply_rule(game,rule,value)

func guard_succeeds(game, guard_spec: Dictionary) -> bool:
	var guard = game.world_registry.get_entity(guard_spec.actor)
	if not guard: return false
	var condition := typed_field(game,guard.record.category,guard_spec.field,guard_spec.value)
	return not condition.is_empty() and guard.get_parameter(condition.id) == condition.value

func apply_rule(game, rule: Dictionary, value: String) -> void:
	for id in game.world_registry.list_ids():
		if id in PROTECTED: continue
		var actor = game.world_registry.get_entity(id)
		if rule.source != "WORLD" and actor.location_id != game.current_location_id: continue
		if id != rule.target and "@"+actor.record.category != rule.target: continue
		var field := typed_field(game,actor.record.category,rule.field,value)
		if not field.is_empty() and actor.get_parameter(field.id) != field.value:
			game.edit_remote(id,field.id,field.value)

func should_fire(game, rule: Dictionary, index: int, delta: float) -> bool:
	if rule.source != "WORLD" and game.current_location_id != rule.room:
		inside.erase(index)
		return false
	if rule.trigger == "EVERY":
		var elapsed: float = clocks.get(index,0.0) + delta
		clocks[index] = fmod(elapsed,rule.distance)
		return elapsed >= rule.distance
	var near := false
	if rule.trigger == "ON_PAD":
		var zone: Area2D = game._live_level.geometry.find_zone(rule.source)
		near = zone != null and not zone.get_overlapping_bodies().is_empty()
	else:
		var source = game.world_registry.get_entity(rule.source)
		near = source != null and source.location_id == rule.room and game.player.position.distance_to(source.position) < rule.distance
	var had_contact: bool = inside.get(index,false)
	inside[index] = near
	return near and not had_contact
