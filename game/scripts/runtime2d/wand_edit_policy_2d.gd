extends RefCounted
## Game-world side of the future TAB hacking interaction.
## The future UI must call authorize() before invoking trusted game commands.
## SELF-HACK, GAME_FRAME and HUD require their own approved physical flows.

const REACH_PX := 112.0 # Technical prototype tuning, not canonical.
var last_error := ""


func authorize(player: Node2D, target: Node2D, current_location_id: String,
		wand_projection, tool_access, parameter_registry, parameter_id: String) -> bool:
	last_error = ""
	if not is_instance_valid(player) or not is_instance_valid(target):
		return _fail("MISSING_ENTITY")
	if not player.has_method("get_world_location_id") or not target.has_method("get_world_location_id"):
		return _fail("NOT_A_GAMEPLAY_ENTITY")
	if not wand_projection.carried:
		return _fail("WAND_NOT_CARRIED")
	if str(player.get_world_location_id()) != current_location_id or str(target.get_world_location_id()) != current_location_id:
		return _fail("OTHER_LOCATION")
	if player.global_position.distance_squared_to(target.global_position) > REACH_PX * REACH_PX:
		return _fail("OUT_OF_REACH")
	if player == target:
		return _fail("REQUIRES_SELF_HACK_FLOW")
	var record: Variant = target.get("record")
	if record == null:
		return _fail("NOT_HACKABLE")
	if str(record.category) in ["system", "hud", "game_frame"]:
		return _fail("SYSTEM_TARGET_REQUIRES_SEPARATE_FLOW")
	if str(parameter_id) in ["access_level", "material"]:
		# Independent character/tool access and removal of material as a wand
		# control are the latest author decisions; data still exists in core.
		return _fail("PROTECTED_PARAMETER")
	if tool_access.wand_mode not in ["PLAYFUL", "DEVELOPER"]:
		return _fail("INVALID_WAND_ACCESS")
	var spec: Dictionary = parameter_registry.get_spec(str(record.category), parameter_id)
	if spec.is_empty():
		return _fail("UNKNOWN_PARAMETER")
	return true


func _fail(reason: String) -> bool:
	last_error = reason
	return false
