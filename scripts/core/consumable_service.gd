extends RefCounted
## Edible/drinkable hackable Entities. Recipes are bounded data, never scripts.
## Consumption changes recipients AND decrements servings in ONE world batch;
## the existing CommandProcessor supplies audit provenance and undo/redo.
##
## Note: effects in this slice are immediate parameter changes. Timed status
## effects and capability-granting recipes belong to the later status runner.

const TargetResolver = preload("res://scripts/core/target_resolver.gd")
const MAX_EFFECT_STEPS := 12
const USE_REACH := 3.5

var world
var commands
var effects
var last_error := ""


func _init(world_registry, command_processor, effect_engine) -> void:
	world = world_registry
	commands = command_processor
	effects = effect_engine


func hack_contents(item_id: String, recipe: Array, delivery: String = "CONSUMER",
		radius: float = 2.5, max_targets: int = 3,
		initiator_id: String = "luna") -> bool:
	last_error = ""
	var item: Node = world.get_entity(item_id)
	if not _is_food(item):
		return _fail("Target is not edible")
	var data := {
		"delivery": delivery, "radius": radius,
		"max_targets": max_targets, "effects": recipe
	}
	if not commands.execute_component(item, "SET_COMPONENT", "CONSUMABLE",
			data, initiator_id, "wand:consumable"):
		return _fail("Recipe is invalid")
	return true


func consume(item_id: String, consumer_id: String, target_id: String = "") -> bool:
	last_error = ""
	var item: Node = world.get_entity(item_id)
	var consumer: Node = world.get_entity(consumer_id)
	if not _is_food(item) or not (consumer is Node3D) or consumer.get("record") == null:
		return _fail("Missing item or editable consumer")
	if int(item.call("get_parameter", "portions")) <= 0:
		return _fail("No portions remain")
	var record: Variant = item.get("record")
	var payload: Dictionary = record.get_component("CONSUMABLE")
	if payload.is_empty():
		return _fail("Food has no editable recipe")
	var recipe: Array = payload.get("effects", [])
	if recipe.is_empty():
		return _fail("Food has no effects")
	var pickup: Dictionary = record.get_component("PICKUP")
	var carrier_id: String = str(pickup.get("holder_id", ""))
	if not carrier_id.is_empty():
		if carrier_id != consumer_id:
			return _fail("Item is held by another entity")
	elif not (item is Node3D) or (item as Node3D).global_position.distance_squared_to(
			(consumer as Node3D).global_position) > USE_REACH * USE_REACH:
		return _fail("Food is out of reach")
	var recipients: Array[String] = []
	var delivery: String = str(payload["delivery"])
	if delivery == "CONSUMER":
		recipients.append(consumer_id)
	elif delivery == "TARGET":
		var target: Node = world.get_entity(target_id)
		if not (target is Node3D) or target.get("record") == null:
			return _fail("Selected target is missing")
		var radius: float = float(payload["radius"])
		if (target as Node3D).global_position.distance_squared_to(
				(consumer as Node3D).global_position) > radius * radius:
			return _fail("Selected target is out of range")
		recipients.append(target_id)
	elif delivery == "SPLASH":
		for candidate_id in TargetResolver.around(world, consumer_id, float(payload["radius"])):
			if candidate_id == item_id:
				continue
			var candidate: Node = world.get_entity(candidate_id)
			if candidate == null or not candidate.has_method("get_parameter"):
				continue
			if not bool(candidate.call("get_parameter", "alive")):
				continue
			recipients.append(candidate_id)
			if recipients.size() >= int(payload["max_targets"]):
				break
	else:
		return _fail("Unknown recipe delivery")
	if recipients.is_empty():
		return _fail("No eligible recipients")
	var actions: Array = []
	for recipient_id in recipients:
		for operation in recipe:
			var step: Dictionary = (operation as Dictionary).duplicate(true)
			step["target_id"] = recipient_id
			actions.append(step)
	# The final step is the physical price paid for the effects.
	actions.append({"operation": "ADD", "target_id": item_id,
		"parameter_id": "portions", "value": -1})
	if actions.size() > MAX_EFFECT_STEPS:
		return _fail("Too many recipe effects for one atomic transaction")
	if not effects.apply_batch(actions, consumer_id, consumer_id,
			"consumable:%s" % item_id):
		return _fail("Recipe could not be applied: %s" % effects.last_error)
	return true


func _is_food(item: Node) -> bool:
	if item == null or not item.has_method("get_parameter"):
		return false
	var record: Variant = item.get("record")
	return record != null and str(record.category) in ["food", "drink"]


func _fail(message: String) -> bool:
	last_error = message
	return false
