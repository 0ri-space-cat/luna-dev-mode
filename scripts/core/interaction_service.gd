extends RefCounted
## Validated USE / TALK / OPEN / INSPECT events share one event bus.
## This service never modifies world state directly.
var world
var events
var last_error := ""


func _init(world_registry, event_bus) -> void:
	world = world_registry
	events = event_bus


func request(source_id: String, target_id: String, verb: String = "USE",
		initiator_id: String = "luna",
		command_source_id: String = "interaction:luna") -> bool:
	last_error = ""
	if source_id == target_id:
		return _reject("Cannot interact with self")
	var source: Node = world.get_entity(source_id)
	var target: Node = world.get_entity(target_id)
	if not (source is Node3D) or not (target is Node3D):
		return _reject("Source or target is missing")
	var record: Variant = target.get("record")
	if record == null or not record.has_component("INTERACTION"):
		return _reject("Target is not interactable")
	var config: Dictionary = record.get_component("INTERACTION")
	if not bool(config.get("enabled", false)):
		return _reject("Interaction is disabled")
	if verb != str(config["verb"]):
		return _reject("Unsupported interaction verb")
	var reach: float = float(config["reach"])
	if (source as Node3D).global_position.distance_squared_to(
			(target as Node3D).global_position) > reach * reach:
		return _reject("Target is out of reach")
	if not events.enqueue({
		"type": "entity.interacted",
		"source_id": source_id,
		"target_id": target_id,
		"payload": {
			"verb": verb, "initiator_id": initiator_id,
			"command_source_id": command_source_id
		}
	}):
		return _reject("Event queue is full")
	return true


func _reject(message: String) -> bool:
	last_error = message
	return false
