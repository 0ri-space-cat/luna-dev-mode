extends RefCounted
## Data-driven spells, sharing the same EffectEngine as hacking and rules.
## Final spell-card visuals and the player's spell builder are later features.

signal spell_cast(details: Dictionary)
signal projectile_requested(details: Dictionary)
signal manifestation_requested(details: Dictionary)

const ArcaneGrammar = preload("res://scripts/core/arcane_grammar.gd")

const MAX_EFFECTS := 12

var world
var effects
var last_error := ""
var _order: Array[String] = []
var _definitions: Dictionary = {}


func _init(world_registry, effect_engine) -> void:
	world = world_registry
	effects = effect_engine
	_register_starters()


func register_spell(spec: Dictionary) -> bool:
	for required in ["id", "label", "cast_range", "effects"]:
		if not spec.has(required):
			return false
	var id: String = str(spec["id"])
	if id.is_empty() or id.length() > 64 or not id.is_valid_identifier() or _definitions.has(id):
		return false
	var cast_range: Variant = spec["cast_range"]
	if typeof(cast_range) != TYPE_INT and typeof(cast_range) != TYPE_FLOAT:
		return false
	if float(cast_range) < 0.5 or float(cast_range) > 50.0:
		return false
	var actions: Variant = spec["effects"]
	if typeof(actions) != TYPE_ARRAY or actions.is_empty() or actions.size() > MAX_EFFECTS:
		return false
	for action in actions:
		if typeof(action) != TYPE_DICTIONARY:
			return false
		var operation: String = str(action.get("operation", ""))
		if not ["SET", "ADD", "MULTIPLY", "TOGGLE", "SET_RELATION"].has(operation):
			return false
		if operation == "SET_RELATION":
			if not action.has("subject_id") or not action.has("value"):
				return false
		elif not action.has("parameter_id"):
			return false
		if operation != "TOGGLE" and not action.has("value"):
			return false
	var manifest: Variant = spec.get("manifestation", {})
	if typeof(manifest) != TYPE_DICTIONARY or not ArcaneGrammar.valid(manifest):
		return false
	var stored: Dictionary = spec.duplicate(true)
	stored["manifestation"] = ArcaneGrammar.normalize(manifest)
	_definitions[id] = stored
	_order.append(id)
	return true

func unregister_custom_spell(spell_id: String) -> bool:
	if not spell_id.begins_with("CUSTOM_") or not _definitions.has(spell_id):
		return false
	_definitions.erase(spell_id)
	_order.erase(spell_id)
	return true


func contains_spell(spell_id: String) -> bool:
	return _definitions.has(spell_id)


func list_spell_ids() -> Array[String]:
	return _order.duplicate()


func get_spell(spell_id: String) -> Dictionary:
	return (_definitions.get(spell_id, {}) as Dictionary).duplicate(true)


func cast_spell(spell_id: String, caster_id: String, target_id: String) -> bool:
	last_error = ""
	var spec: Dictionary = _definitions.get(spell_id, {})
	if spec.is_empty():
		return _fail("Неизвестное заклинание.")
	var caster: Node = world.get_entity(caster_id)
	var target: Node = world.get_entity(target_id)
	if caster == null or target == null or not (caster is Node3D) or not (target is Node3D):
		return _fail("Цель куда-то делась.")
	var dist: float = (caster as Node3D).global_position.distance_to((target as Node3D).global_position)
	if dist > float(spec["cast_range"]):
		return _fail("Не достаю! Подойди поближе.")
	var manifest: Dictionary = spec.get("manifestation", {})
	if not manifest.is_empty():
		var details := {
			"spell_id": spell_id,
			"caster_id": caster_id,
			"target_id": target_id,
			"manifestation": manifest.duplicate(true)
		}
		if str(manifest["release"]) == "PLACE":
			# Placed spells resolve on contact immediately, then create the form.
			if not resolve_impact(spell_id, caster_id, target_id):
				return false
			manifestation_requested.emit(details)
		else:
			projectile_requested.emit(details)
	else:
		if not resolve_impact(spell_id, caster_id, target_id):
			return false
	spell_cast.emit({
		"spell_id": spell_id,
		"caster_id": caster_id,
		"target_id": target_id,
		"effect_count": spec["effects"].size()
	})
	return true


func resolve_impact(spell_id: String, caster_id: String, target_id: String) -> bool:
	last_error = ""
	var spec: Dictionary = _definitions.get(spell_id, {})
	if spec.is_empty() or world.get_entity(target_id) == null:
		return _fail("Снаряд потерял свою цель.")
	if not effects.apply_batch(spec["effects"], target_id, caster_id, "spell:%s" % spell_id):
		return _fail("Попадание не сработало: %s" % effects.last_error)
	return true


func _register_starters() -> void:
	# These read like classic spells until the player looks under their hood.
	register_spell({
		"id": "FIREBALL", "label": "ОГНЕННЫЙ ШАР", "cast_range": 15.0,
		"symbol_id": "FIRE", "stone_color": Color("ff884a"),
		"manifestation": ArcaneGrammar.make("ORB", "FIRE", 12.0, 0.44),
		"effects": [{"operation": "ADD", "parameter_id": "health", "value": -24}]
	})
	register_spell({
		"id": "FROST_SHARD", "label": "ЛЕДЯНОЙ ОСКОЛОК", "cast_range": 15.0,
		"symbol_id": "SNOW", "stone_color": Color("9edffa"),
		"manifestation": ArcaneGrammar.make("SHARD", "FROST", 14.0, 0.34),
		"effects": [
			{"operation": "ADD", "parameter_id": "health", "value": -10},
			{"operation": "MULTIPLY", "parameter_id": "speed", "value": 0.65}
		]
	})
	register_spell({
		"id": "ARC_BOLT", "label": "ИСКРОВОЙ РАЗРЯД", "cast_range": 17.0,
		"symbol_id": "LIGHTNING", "stone_color": Color("e6d77a"),
		"manifestation": ArcaneGrammar.make("BOLT", "STORM", 22.0, 0.25),
		"effects": [{"operation": "ADD", "parameter_id": "health", "value": -16}]
	})

	# Legacy utility spells remain loadable for older saved custom systems,
	# but are removed from the initial quickbar: 1–3 are actual magic.
	register_spell({
		"id": "AWAKEN", "label": "AWAKEN", "cast_range": 11.0,
		"stone_color": Color("8ed7bd"), "symbol_id": "SPARK",
		"effects": [{"operation": "SET", "parameter_id": "alive", "value": true}]
	})
	register_spell({
		"id": "PINKIFY", "label": "PINKIFY", "cast_range": 11.0,
		"stone_color": Color("f49fc9"), "symbol_id": "STAR",
		"effects": [{"operation": "SET", "parameter_id": "color", "value": Color("f49fc9")}]
	})
	register_spell({
		"id": "QUICKEN", "label": "QUICKEN", "cast_range": 11.0,
		"stone_color": Color("87bfe8"), "symbol_id": "WIND",
		"effects": [{"operation": "ADD", "parameter_id": "speed", "value": 1.2}]
	})
	for utility_id in ["AWAKEN", "PINKIFY", "QUICKEN"]:
		_order.erase(utility_id)


func _fail(message: String) -> bool:
	last_error = message
	return false
