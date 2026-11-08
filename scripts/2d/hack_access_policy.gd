extends RefCounted
## Fictional magic permissions. Two access tiers; scan depth is independent.
const PLAYFUL := "PLAYFUL"
const ARCHITECT := "ARCHITECT"
const BASE_KEYS := ["IS_ALIVE", "HEALTH", "MOVE_SPEED", "BASE_COLOR", "SCALE", "BEHAVIOR_MODE"]
const DEEP_KEYS := ["AI_ENABLED", "AGGRESSION", "TARGET_LOCATION", "GRAVITY_VECTOR", "TIME_SCALE", "ABILITY_SET", "RELATIONSHIPS", "ENTITY_FORM", "PLAYER_CHARACTER"]
const BASE_ACTIONS := ["INSPECT", "TINT", "RESIZE", "NUDGE", "RENAME", "COPY", "DELETE", "UNDO"]
const DEEP_ACTIONS := ["EDIT_ROUTE", "TRANSFER_ABILITY", "EDIT_GRAVITY", "EDIT_TIME", "EDIT_RELATIONS", "EDIT_PORTAL", "EDIT_AVATAR"]
static func has_architect_access(wand: Dictionary) -> bool:
	return str(wand.get("ACCESS_TIER", PLAYFUL)) == ARCHITECT and bool(wand.get("is_hacked", false))
static func can_read(wand: Dictionary, key: String) -> bool:
	return BASE_KEYS.has(key) or (has_architect_access(wand) and DEEP_KEYS.has(key))
static func can_perform(wand: Dictionary, action: String) -> bool:
	return BASE_ACTIONS.has(action) or (has_architect_access(wand) and DEEP_ACTIONS.has(action))
static func duplicate_unlock(original_wand: Dictionary, duplicate_wand: Dictionary) -> Dictionary:
	# Only a real second wand with the same artifact origin can modify the original.
	if str(original_wand.get("id", "")).is_empty() or str(duplicate_wand.get("id", "")).is_empty():
		return {"ok": false, "reason": "missing_identity"}
	if original_wand["id"] == duplicate_wand["id"]:
		return {"ok": false, "reason": "requires_second_wand"}
	if original_wand.get("origin_id") != duplicate_wand.get("origin_id"):
		return {"ok": false, "reason": "different_origin"}
	var upgraded := original_wand.duplicate(true)
	upgraded["ACCESS_TIER"] = ARCHITECT
	upgraded["is_hacked"] = true
	return {"ok": true, "wand": upgraded}
