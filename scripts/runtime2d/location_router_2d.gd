extends RefCounted
## Data-driven scene addresses. No locations or secrets are encoded in the router.
## Authoring tools register real scene paths, entry IDs and door IDs later.

const WorldRuleEngine = preload("res://scripts/runtime2d/world_rule_engine_2d.gd")

const MAX_LOCATIONS := 128
const MAX_DOORS := 512

var locations: Dictionary = {}
var door_destinations: Dictionary = {}
var last_error := ""


## One author-produced catalog can be loaded after the map is drawn.
## Validation is transactional: a broken entry never partly changes live routes.
func load_catalog_json(path: String) -> bool:
	if not path.begins_with("res://"):
		return _fail("Only bundled level manifests may be loaded")
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return _fail("Location catalog file not found")
	var value: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not (value is Dictionary):
		return _fail("Invalid location catalog JSON")
	return import_catalog(value)


func import_catalog(document: Dictionary) -> bool:
	var entries: Variant = document.get("locations", [])
	var links: Variant = document.get("doors", [])
	if not (entries is Array) or not (links is Array):
		return _fail("Locations and doors must be arrays")
	if entries.is_empty() or entries.size() > MAX_LOCATIONS or links.size() > MAX_DOORS:
		return _fail("Catalog exceeds bounds or has no locations")
	var candidate = get_script().new()
	var authored_ids := {}
	var authored_rule_ids := {}
	for row in entries:
		if not (row is Dictionary) or not (row.get("entries", null) is Dictionary):
			return _fail("Invalid location row")
		var prepared: Dictionary = {}
		for key in row["entries"].keys():
			var pair: Variant = row["entries"][key]
			if not (pair is Array) or pair.size() != 2:
				return _fail("Location entry must have two coordinates")
			if typeof(pair[0]) not in [TYPE_INT, TYPE_FLOAT] or typeof(pair[1]) not in [TYPE_INT, TYPE_FLOAT]:
				return _fail("Location entry must be numeric")
			if not is_finite(float(pair[0])) or not is_finite(float(pair[1])):
				return _fail("Non-finite entry coordinate")
			if absf(float(pair[0])) > 100000.0 or absf(float(pair[1])) > 100000.0:
				return _fail("Entry is outside safe world range")
			prepared[str(key)] = Vector2(float(pair[0]), float(pair[1]))
		var authored: Variant = row.get("entities", [])
		if not (authored is Array) or authored.size() > 48:
			return _fail("Invalid authored entities")
		for item in authored:
			if not (item is Dictionary):
				return _fail("Invalid authored entity row")
			var actor_id := str(item.get("id", ""))
			if actor_id == "luna" or not _valid_id(actor_id) or authored_ids.has(actor_id):
				return _fail("Duplicate or invalid authored entity ID")
			authored_ids[actor_id] = true
		var rules: Variant = row.get("rules", [])
		var rule_checker = WorldRuleEngine.new()
		if not rule_checker.validate_rules(rules):
			return _fail(rule_checker.last_error)
		for rule in rules:
			var rule_id := str(rule["id"])
			if authored_rule_ids.has(rule_id):
				return _fail("Rule IDs must be unique across the catalog")
			authored_rule_ids[rule_id] = true
		if not candidate.register_location(str(row.get("id", "")),
				str(row.get("scene", "")), prepared, int(row.get("required_access", 0)),
				authored, rules):
			return _fail(candidate.last_error)
	for row in links:
		if not (row is Dictionary):
			return _fail("Invalid door row")
		if not candidate.register_door(str(row.get("id", "")), str(row.get("destination", ""))):
			return _fail(candidate.last_error)
	locations = candidate.locations
	door_destinations = candidate.door_destinations
	last_error = ""
	return true


func register_location(address: String, scene_path: String, entry_points: Dictionary,
		required_access: int = 0, authored_entities: Array = [],
		rules: Array = []) -> bool:
	if not _valid_id(address) or locations.has(address) or locations.size() >= MAX_LOCATIONS:
		return _fail("Duplicate or invalid location ID")
	if not scene_path.begins_with("res://") or not ResourceLoader.exists(scene_path):
		return _fail("Scene path does not exist")
	if entry_points.is_empty() or required_access < 0 or required_access > 3 or authored_entities.size() > 48:
		return _fail("Invalid entries or access")
	var rule_checker = WorldRuleEngine.new()
	if not rule_checker.validate_rules(rules):
		return _fail(rule_checker.last_error)
	for key in entry_points:
		if not _valid_id(str(key)) or not (entry_points[key] is Vector2):
			return _fail("Invalid entry point")
	locations[address] = {"scene": scene_path, "entries": entry_points.duplicate(true),
		"access": required_access, "entities": authored_entities.duplicate(true),
		"rules": rules.duplicate(true)}
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
