extends RefCounted
## Data-driven spells, sharing the same EffectEngine as hacking and rules.
## Final spell-card visuals and the player's spell builder are later features.

signal spell_cast(details: Dictionary)
signal projectile_requested(details: Dictionary)
signal manifestation_requested(details: Dictionary)
signal chain_resolved(details: Dictionary)

const ArcaneGrammar = preload("res://scripts/core/arcane_grammar.gd")
const TargetResolver = preload("res://scripts/core/target_resolver.gd")

const MAX_EFFECTS := 12

var world
var effects
var elemental_statuses
var last_error := ""
var _order: Array[String] = []
var _definitions: Dictionary = {}


func _init(world_registry, effect_engine, elemental_service = null) -> void:
	world = world_registry
	effects = effect_engine
	elemental_statuses = elemental_service
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
	var manifest: Variant = spec.get("manifestation", {})
	if typeof(manifest) != TYPE_DICTIONARY or not ArcaneGrammar.valid(manifest):
		return false
	if typeof(actions) != TYPE_ARRAY or actions.size() > MAX_EFFECTS or (actions.is_empty() and manifest.is_empty()):
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
	var impact: Variant = spec.get("impact", {})
	if not is_valid_impact(impact):
		return false
	var stored: Dictionary = spec.duplicate(true)
	stored["manifestation"] = ArcaneGrammar.normalize(manifest)
	stored["impact"] = impact.duplicate(true)
	if str(impact.get("mode", "")) == "CHAIN":
		stored["impact"]["jumps"] = int(impact["jumps"])
	_definitions[id] = stored
	_order.append(id)
	return true


func is_valid_impact(impact: Variant) -> bool:
	if typeof(impact) != TYPE_DICTIONARY:
		return false
	var mode: String = str(impact.get("mode", "DIRECT"))
	if mode == "BURST" or mode == "CHAIN":
		var wanted_fields: int = 3 if mode == "CHAIN" else 2
		if impact.size() != wanted_fields or typeof(impact.get("radius")) not in [TYPE_INT, TYPE_FLOAT]:
			return false
		var radius: float = float(impact["radius"])
		if is_nan(radius) or is_inf(radius) or radius < 0.5 or radius > TargetResolver.MAX_RADIUS:
			return false
		if mode == "CHAIN":
			var jumps: Variant = impact.get("jumps")
			if typeof(jumps) not in [TYPE_INT, TYPE_FLOAT] or is_nan(float(jumps)) or is_inf(float(jumps)):
				return false
			return float(jumps) == float(int(jumps)) and int(jumps) >= 1 and int(jumps) <= 4
		return true
	return mode == "DIRECT" and (impact.is_empty() or impact.size() == 1)


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
	if spec["effects"].is_empty():
		return true
	var impact: Dictionary = spec.get("impact", {})
	var mode: String = str(impact.get("mode", "DIRECT"))
	var affected: Array[String] = [target_id]
	if mode == "BURST":
		affected = TargetResolver.around(world, target_id, float(impact["radius"]))
	elif mode == "CHAIN":
		affected = TargetResolver.chain(world, target_id,
			float(impact["radius"]), int(impact["jumps"]))
	var ok := false
	if mode == "CHAIN":
		var plans: Array[Dictionary] = []
		for hop in range(affected.size()):
			var actions: Array = []
			for original in spec["effects"]:
				var action: Dictionary = original.duplicate(true)
				# Only damaging HEALTH values fade; utility effects retain
				# their normal semantics throughout the chain.
				if str(action.get("operation", "")) == "ADD" \
						and str(action.get("parameter_id", "")) == "health" \
						and float(action.get("value", 0)) < 0:
					var damage: int = maxi(1,
						roundi(absf(float(action["value"])) * pow(0.65, hop)))
					action["value"] = -damage
				actions.append(action)
			plans.append({"target_id": affected[hop], "actions": actions})
		ok = effects.apply_targeted_batches(plans, caster_id, "spell:%s" % spell_id)
	elif mode == "BURST":
		ok = effects.apply_to_targets(spec["effects"], affected, caster_id, "spell:%s" % spell_id)
	else:
		ok = effects.apply_batch(spec["effects"], target_id, caster_id, "spell:%s" % spell_id)
	if not ok:
		return _fail("Попадание не сработало: %s" % effects.last_error)
	# Elemental overlays are attached only after the entire hit was accepted.
	var manifestation: Dictionary = spec.get("manifestation", {})
	if elemental_statuses != null and not manifestation.is_empty():
		for entity_id in affected:
			elemental_statuses.apply_element(entity_id, str(manifestation["element"]))
	if mode == "CHAIN" and affected.size() > 1:
		var links: Array[Dictionary] = []
		for i in range(1, affected.size()):
			links.append({"from_id": affected[i - 1], "to_id": affected[i]})
		chain_resolved.emit({
			"spell_id": spell_id, "origin_id": target_id,
			"targets": affected.duplicate(), "links": links
		})
	return true


func _register_starters() -> void:
	# These read like classic spells until the player looks under their hood.
	register_spell({
		"id": "FIREBALL", "label": "ОГНЕННЫЙ ШАР", "cast_range": 15.0,
		"symbol_id": "FIRE", "stone_color": Color("ff884a"),
		"manifestation": ArcaneGrammar.make("ORB", "FIRE", 12.0, 0.44),
		"impact": {"mode": "BURST", "radius": 2.5},
		"effects": [{"operation": "ADD", "parameter_id": "health", "value": -24}]
	})
	register_spell({
		"id": "FROST_SHARD", "label": "ЛЕДЯНОЙ ОСКОЛОК", "cast_range": 15.0,
		"symbol_id": "SNOW", "stone_color": Color("9edffa"),
		"manifestation": ArcaneGrammar.make("SHARD", "FROST", 14.0, 0.34),
		"effects": [
			{"operation": "ADD", "parameter_id": "health", "value": -10}
		]
	})
	register_spell({
		"id": "ARC_BOLT", "label": "ИСКРОВОЙ РАЗРЯД", "cast_range": 17.0,
		"symbol_id": "LIGHTNING", "stone_color": Color("e6d77a"),
		"manifestation": ArcaneGrammar.make("BOLT", "STORM", 22.0, 0.25),
		"impact": {"mode": "CHAIN", "radius": 4.5, "jumps": 3},
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
