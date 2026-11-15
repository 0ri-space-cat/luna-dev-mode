extends RefCounted
## Data-driven scene addresses. No locations or secrets are encoded in the router.
## Authoring tools register real scene paths, entry IDs and door IDs later.

const MAX_LOCATIONS := 128
const MAX_DOORS := 512

var locations: Dictionary = {}
var door_destinations: Dictionary = {}
var last_error := ""


func register_location(address: String, scene_path: String, entry_points: Dictionary, required_access: int = 0) -> bool:
	if not _valid_id(address) or locations.has(address) or locations.size() >= MAX_LOCATIONS:
		return _fail("Duplicate or invalid location ID")
	if not scene_path.begins_with("res://") or not ResourceLoader.exists(scene_path):
		return _fail("Scene path does not exist")
	if entry_points.is_empty() or required_access < 0 or required_access > 3:
		return _fail("Invalid entries or access")
	for key in entry_points:
		if not _valid_id(str(key)) or not (entry_points[key] is Vector2):
			return _fail("Invalid entry point")
	locations[address] = {"scene": scene_path, "entries": entry_points.duplicate(true), "access": required_access}
	last_error = ""
	return true


func register_door(door_id: String, destination: String) -> bool:
	if not _valid_id(door_id) or door_destinations.has(door_id) or door_destinations.size() >= MAX_DOORS:
		return _fail("Duplicate or invalid door ID")
	if not locations.has(destination):
		return _fail("UNKNOWN_LOCATION")
	door_destinations[door_id] = destination
	last_error = ""
	return true


func redirect_door(door_id: String, destination: String, wand_mode: String = "PLAYFUL") -> bool:
	if not door_destinations.has(door_id) or not locations.has(destination):
		return _fail("UNKNOWN_LOCATION_OR_DOOR")
	if wand_mode != "PLAYFUL" and wand_mode != "DEVELOPER":
		return _fail("INVALID_TOOL_MODE")
	if int(locations[destination]["access"]) > 0 and wand_mode != "DEVELOPER":
		return _fail("INSUFFICIENT_TOOL_ACCESS")
	door_destinations[door_id] = destination
	last_error = ""
	return true


func resolve_door(door_id: String, avatar_access: int = 0, entry_id: String = "entry") -> Dictionary:
	if not door_destinations.has(door_id):
		return {"ok": false, "error": "UNKNOWN_DOOR"}
	return resolve_address(str(door_destinations[door_id]), avatar_access, entry_id)


func resolve_address(address: String, avatar_access: int = 0, entry_id: String = "entry") -> Dictionary:
	if not locations.has(address):
		return {"ok": false, "error": "UNKNOWN_LOCATION"}
	var data: Dictionary = locations[address]
	if avatar_access < int(data["access"]):
		return {"ok": false, "error": "INSUFFICIENT_AVATAR_ACCESS"}
	var entries: Dictionary = data["entries"]
	if not entries.has(entry_id):
		return {"ok": false, "error": "UNKNOWN_ENTRY"}
	return {"ok": true, "address": address, "scene": data["scene"], "position": entries[entry_id]}


func snapshot_routes() -> Dictionary:
	return door_destinations.duplicate(true)


func validate_routes(routes: Variant) -> bool:
	if not (routes is Dictionary) or routes.size() != door_destinations.size():
		return false
	for id in door_destinations:
		if not routes.has(id) or not locations.has(str(routes[id])):
			return false
	return true


func restore_routes(routes: Dictionary) -> bool:
	if not validate_routes(routes):
		return false
	door_destinations = routes.duplicate(true)
	return true


func _valid_id(value: String) -> bool:
	return not value.is_empty() and value.length() <= 96 and value.is_valid_identifier()


func _fail(reason: String) -> bool:
	last_error = reason
	return false
