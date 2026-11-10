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
# This server-side/level-authoring table is not derived from editable Entity roles.
var _trusted_actor_tiers: Dictionary = {}
var last_error := ""


func _init(world_registry, command_processor) -> void:
	world = world_registry
	commands = command_processor


func register_intrinsic_authority(actor_id: String, tier: int) -> bool:
	# Call only from trusted bootstrap/level authoring, never from wand/UI commands.
	if actor_id.is_empty() or not actor_id.is_valid_identifier() or tier < 0 or tier > 3:
		return _fail("Invalid authority registration")
	_trusted_actor_tiers[actor_id] = tier
	return true


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
	var source := "door:redirect@" + tool_id
	if not commands.execute_component(door, "SET_COMPONENT", "DOOR_LINK", component,
			actor_id, source):
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


func can_redirect(actor_id: String, door_id: String,
		address_id: String, tool_id: String) -> bool:
	var actor: Node = world.get_entity(actor_id)
	var door: Node = world.get_entity(door_id)
	if not (actor is Node3D) or not (door is Node3D):
		return false
	var record: Variant = door.get("record")
	if record == null or str(record.category) != "door" or not record.has_component("DOOR_LINK"):
		return false
	if not _destinations.has(address_id):
		return false
	if (actor as Node3D).global_position.distance_squared_to(
			(door as Node3D).global_position) > EDIT_REACH * EDIT_REACH:
		return false
	return _effective_access(actor_id, tool_id) >= int(_destinations[address_id]["required_access"])


func authorize_component_edit(actor_id: String, target_id: String,
		component_id: String, before: Dictionary, after: Dictionary,
		source_id: String) -> bool:
	# Data authoring can set a door directly. User-originated command changes
	# must go through the same address verifier, even via generic editor APIs.
	if component_id != "DOOR_LINK":
		return true
	if before.get("DOOR_LINK", {}) == after.get("DOOR_LINK", {}):
		return true
	if not source_id.begins_with("door:redirect@"):
		return false
	var destination: String = str(after.get("DOOR_LINK", {}).get("destination", ""))
	return can_redirect(actor_id, target_id, destination,
		source_id.trim_prefix("door:redirect@"))


func authorize_tool_edit(actor_id: String, target_id: String,
		new_access: Variant, source_id: String) -> bool:
	# A wand cannot raise its own access. The lake-secret route specifically
	# uses a physical copy to edit its original, with traceable copy_origin.
	if typeof(new_access) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(new_access)):
		return false
	if int(_trusted_actor_tiers.get(actor_id, -1)) >= 2:
		return true
	if not source_id.begins_with("wand:"):
		return false
	var source_id_of_wand: String = source_id.trim_prefix("wand:")
	if source_id_of_wand.is_empty() or source_id_of_wand == target_id:
		return false
	var source_tool: Node = world.get_entity(source_id_of_wand)
	var target_tool: Node = world.get_entity(target_id)
	if source_tool == null or target_tool == null:
		return false
	var source_record: Variant = source_tool.get("record")
	var target_record: Variant = target_tool.get("record")
	if source_record == null or target_record == null:
		return false
	if str(source_record.category) != "wand" or str(target_record.category) != "wand":
		return false
	if str(source_record.get_component("PICKUP").get("holder_id", "")) != actor_id:
		return false
	return source_tool.has_meta("copy_origin") and str(source_tool.get_meta("copy_origin")) == target_id


func _effective_access(actor_id: String, tool_id: String) -> int:
	var actor: Node = world.get_entity(actor_id)
	if actor == null:
		return -1
	var intrinsic: int = int(_trusted_actor_tiers.get(actor_id, -1))
	var tool: Node = world.get_entity(tool_id)
	if tool == null or tool.get("record") == null:
		return intrinsic
	var wand: Variant = tool.get("record")
	if str(wand.category) != "wand":
		return intrinsic
	# A tool cannot be invoked remotely or borrowed from another owner's bag.
	var pickup: Dictionary = wand.get_component("PICKUP")
	if str(pickup.get("holder_id", "")) != actor_id:
		return intrinsic
	return maxi(intrinsic, int(tool.call("get_parameter", "access_level")))


func _reject(message: String) -> Dictionary:
	last_error = message
	return {"ok": false, "error": message}


func _fail(message: String) -> bool:
	last_error = message
	return false
