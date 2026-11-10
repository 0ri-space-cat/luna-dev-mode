extends RefCounted
## Registry-only address navigation. No scene loading, teleportation or art
## dependency: the eventual 2D WorldManager consumes successful resolve() data.
## Familiar doors may be redirected at USER tier; forbidden SYSTEM addresses
## need actual administrator credentials, not a chapter-completion flag.
##
## Tiers: USER=0, OPERATOR=1, ADMIN=2, DEVELOPER=3.

const EDIT_REACH := 4.5
const MAX_DESTINATIONS := 128

var world
var commands
var _destinations: Dictionary = {}
var last_error := ""


func _init(world_registry, command_processor) -> void:
	world = world_registry
	commands = command_processor


func register_location(address_id: String, required_access: int = 0,
		region_id: String = "", entry_id: String = "") -> bool:
	last_error = ""
	if address_id.is_empty() or not address_id.is_valid_identifier() or address_id.length() > 96:
		return _fail("Invalid location ID")
	if required_access < 0 or required_access > 3:
		return _fail("Location requires an unknown access tier")
	if not region_id.is_empty() and (region_id.length() > 96 or not region_id.is_valid_identifier()):
		return _fail("Invalid region ID")
	if not entry_id.is_empty() and (entry_id.length() > 96 or not entry_id.is_valid_identifier()):
		return _fail("Invalid entry ID")
	if _destinations.has(address_id) or _destinations.size() >= MAX_DESTINATIONS:
		return _fail("Location already exists or catalog is full")
	_destinations[address_id] = {
		"required_access": required_access,
		"region_id": region_id,
		"entry_id": entry_id
	}
	return true


func describe(address_id: String) -> Dictionary:
	return (_destinations.get(address_id, {}) as Dictionary).duplicate(true)


func redirect(door_id: String, address_id: String, actor_id: String,
		tool_id: String = "") -> bool:
	last_error = ""
	var door: Node = world.get_entity(door_id)
	var actor: Node = world.get_entity(actor_id)
	if not (door is Node3D) or not (actor is Node3D) or door.get("record") == null:
		return _fail("Missing door or actor")
	var record: Variant = door.get("record")
	if str(record.category) != "door" or not record.has_component("DOOR_LINK"):
		return _fail("Target has no door address component")
	if (door as Node3D).global_position.distance_squared_to(
			(actor as Node3D).global_position) > EDIT_REACH * EDIT_REACH:
		return _fail("Door is out of reach")
	if not _destinations.has(address_id):
		return _fail("UNKNOWN_LOCATION")
	var tier: int = _effective_access(actor_id, tool_id)
	if tier < 0:
		return _fail("NO_HACKING_TOOL")
	var required: int = int(_destinations[address_id]["required_access"])
	if tier < required:
		return _fail("LOCATION_FORBIDDEN: access %d required" % required)
	var component: Dictionary = record.get_component("DOOR_LINK")
	component["destination"] = address_id
	if not commands.execute_component(door, "SET_COMPONENT", "DOOR_LINK", component,
			actor_id, "door:redirect"):
		return _fail("Could not apply the address change")
	return true


func resolve(door_id: String, actor_id: String) -> Dictionary:
	## Opening a door is different from gaining permission to EDIT its address.
	## A low-tier visitor may pass through a real preconfigured secret door.
	last_error = ""
	var door: Node = world.get_entity(door_id)
	var actor: Node = world.get_entity(actor_id)
	if not (door is Node3D) or not (actor is Node3D) or door.get("record") == null:
		return _reject("Missing door or actor")
	var record: Variant = door.get("record")
	if str(record.category) != "door" or not record.has_component("DOOR_LINK"):
		return _reject("Target is not a doorway")
	if (door as Node3D).global_position.distance_squared_to(
			(actor as Node3D).global_position) > EDIT_REACH * EDIT_REACH:
		return _reject("Door is out of reach")
	var link: Dictionary = record.get_component("DOOR_LINK")
	if not bool(link.get("enabled", false)):
		return _reject("Door is locked")
	var destination: String = str(link.get("destination", ""))
	if not _destinations.has(destination):
		return _reject("UNKNOWN_LOCATION")
	var details: Dictionary = describe(destination)
	details["ok"] = true
	details["address_id"] = destination
	details["door_id"] = door_id
	return details


func _effective_access(actor_id: String, tool_id: String) -> int:
	var actor: Node = world.get_entity(actor_id)
	if actor == null or actor.get("record") == null:
		return -1
	var record: Variant = actor.get("record")
	if record.has_role("DEVELOPER"):
		return 3
	if record.has_role("ADMIN"):
		return 2
	var tool: Node = world.get_entity(tool_id)
	if tool == null or tool.get("record") == null:
		return -1
	var wand: Variant = tool.get("record")
	if str(wand.category) != "wand":
		return -1
	# A tool cannot be invoked remotely or borrowed from another owner's bag.
	var pickup: Dictionary = wand.get_component("PICKUP")
	if str(pickup.get("holder_id", "")) != actor_id:
		return -1
	return int(tool.call("get_parameter", "access_level"))


func _reject(message: String) -> Dictionary:
	last_error = message
	return {"ok": false, "error": message}


func _fail(message: String) -> bool:
	last_error = message
	return false
