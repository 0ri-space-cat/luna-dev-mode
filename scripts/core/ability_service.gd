extends RefCounted
## Reusable capability definitions; any Entity can receive the same ability.
## Abilities route their effects through the existing atomic EffectEngine.
const MAX_DEFINITIONS := 64
const MAX_ACTIONS := 12
const OPERATIONS := ["SET", "ADD", "MULTIPLY", "TOGGLE", "SET_RELATION", "COPY_ENTITY", "DELETE_ENTITY"]

var world
var effects
var commands
var definitions: Dictionary = {}
var _last_used: Dictionary = {}
var last_error := ""


func _init(world_registry, effect_engine, command_processor) -> void:
	world = world_registry
	effects = effect_engine
	commands = command_processor


func register_ability(data: Dictionary) -> bool:
	last_error = ""
	for key in data.keys():
		if str(key) not in ["id", "effects", "range", "cooldown_ms"]:
			return _fail("Unknown ability field")
	var ability_id: Variant = data.get("id")
	var actions: Variant = data.get("effects")
	if typeof(ability_id) != TYPE_STRING or not str(ability_id).is_valid_identifier() or str(ability_id).length() > 64:
		return _fail("Invalid ability ID")
	if definitions.has(ability_id) or definitions.size() >= MAX_DEFINITIONS:
		return _fail("Ability already registered or capacity reached")
	if typeof(actions) != TYPE_ARRAY or actions.is_empty() or actions.size() > MAX_ACTIONS:
		return _fail("Invalid effects array")
	for action in actions:
		if typeof(action) != TYPE_DICTIONARY or str(action.get("operation", "")) not in OPERATIONS or action.has("target_id"):
			return _fail("Invalid ability effect")
	var radius: Variant = data.get("range", 4.0)
	var cooldown: Variant = data.get("cooldown_ms", 0)
	if typeof(radius) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(radius)) or float(radius) < 0.5 or float(radius) > 20.0:
		return _fail("Invalid activation range")
	if typeof(cooldown) != TYPE_INT or cooldown < 0 or cooldown > 120000:
		return _fail("Invalid cooldown")
	definitions[str(ability_id)] = {
		"effects": actions.duplicate(true),
		"range": float(radius),
		"cooldown_ms": int(cooldown)
	}
	return true


func grant(entity_id: String, ability_id: String,
		initiator_id: String = "luna", source_id: String = "wand:luna") -> bool:
	last_error = ""
	var actor: Node = world.get_entity(entity_id)
	if actor == null or not definitions.has(ability_id):
		return _fail("Unknown entity or ability")
	var record: Variant = actor.get("record")
	if record == null:
		return _fail("Entity has no ability storage")
	var current: Dictionary = record.get_component("ABILITY_SET")
	var ids: Array = current.get("ids", []).duplicate()
	if ids.has(ability_id) or ids.size() >= 16:
		return _fail("Already granted or ability limit reached")
	ids.append(ability_id)
	ids.sort()
	if not commands.execute_component(actor, "SET_COMPONENT", "ABILITY_SET",
			{"ids": ids}, initiator_id, source_id):
		return _fail("Unable to grant ability")
	return true


func revoke(entity_id: String, ability_id: String,
		initiator_id: String = "luna", source_id: String = "wand:luna") -> bool:
	last_error = ""
	var actor: Node = world.get_entity(entity_id)
	if actor == null:
		return _fail("Unknown entity")
	var record: Variant = actor.get("record")
	if record == null or not record.has_component("ABILITY_SET"):
		return _fail("Entity has no abilities")
	var ids: Array = record.get_component("ABILITY_SET").get("ids", []).duplicate()
	if not ids.has(ability_id):
		return _fail("Ability not granted")
	ids.erase(ability_id)
	var operation := "REMOVE_COMPONENT" if ids.is_empty() else "SET_COMPONENT"
	if not commands.execute_component(actor, operation, "ABILITY_SET",
			{"ids": ids}, initiator_id, source_id):
		return _fail("Unable to revoke ability")
	return true


func activate(entity_id: String, ability_id: String, target_id: String) -> bool:
	last_error = ""
	var actor: Node = world.get_entity(entity_id)
	var target: Node = world.get_entity(target_id)
	if not (actor is Node3D) or not (target is Node3D):
		return _fail("Ability source or target is absent")
	var record: Variant = actor.get("record")
	if record == null or not record.has_component("ABILITY_SET"):
		return _fail("Entity has no ability component")
	if not record.get_component("ABILITY_SET").get("ids", []).has(ability_id):
		return _fail("Ability not granted")
	if not definitions.has(ability_id):
		return _fail("Ability definition is unavailable")
	var spec: Dictionary = definitions[ability_id]
	var reach: float = float(spec["range"])
	if (actor as Node3D).global_position.distance_squared_to((target as Node3D).global_position) > reach * reach:
		return _fail("Ability target out of range")
	var cooldown_key := "%s:%s" % [entity_id, ability_id]
	var now: int = Time.get_ticks_msec()
	if _last_used.has(cooldown_key) and now - int(_last_used[cooldown_key]) < int(spec["cooldown_ms"]):
		return _fail("Ability on cooldown")
	if not effects.apply_batch(spec["effects"], target_id, entity_id, "ability:%s" % ability_id):
		return _fail(effects.last_error)
	_last_used[cooldown_key] = now
	return true


func reset_cooldowns() -> void:
	_last_used.clear()


func _fail(reason: String) -> bool:
	last_error = reason
	return false
