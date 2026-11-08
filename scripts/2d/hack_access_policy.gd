extends RefCounted
## Two in-world permissions; Oracle Eye and SCAN_DEPTH are separate axes.
const PLAYFUL := "PLAYFUL"
const ARCHITECT := "ARCHITECT"
const BASE_KEYS := ["alive", "health", "speed", "size", "color", "behavior_mode"]
const DEEP_KEYS := ["ai_enabled", "material", "target_group", "luna_relation", "sense_range", "follow_distance"]
const BASE_ACTIONS := ["INSPECT", "TINT", "RESIZE", "RENAME", "UNDO", "COPY", "DELETE"]
const DEEP_ACTIONS := ["EDIT_ROUTE", "TRANSFER_ABILITY", "EDIT_GRAVITY", "EDIT_TIME", "EDIT_RELATIONS", "EDIT_PORTAL", "EDIT_AVATAR"]

static func can_read(wand: Dictionary, key: String) -> bool:
	if not bool(wand.get("rift_enabled", false)):
		return false
	if BASE_KEYS.has(key):
		return true
	return has_architect_access(wand) and DEEP_KEYS.has(key)

static func can_perform(wand: Dictionary, action: String) -> bool:
	if not bool(wand.get("rift_enabled", false)):
		return false
	return BASE_ACTIONS.has(action) or (has_architect_access(wand) and DEEP_ACTIONS.has(action))

static func has_architect_access(wand: Dictionary) -> bool:
	return bool(wand.get("rift_enabled", false)) and str(wand.get("ACCESS_TIER", PLAYFUL)) == ARCHITECT and bool(wand.get("is_hacked", false))

static func duplicate_unlock(original_wand: Dictionary, duplicate_wand: Dictionary) -> Dictionary:
	if not bool(original_wand.get("rift_enabled", false)):
		return {"ok": false, "reason": "rift_required"}
	if str(original_wand.get("id", "")).is_empty() or str(duplicate_wand.get("id", "")).is_empty():
		return {"ok": false, "reason": "missing_identity"}
	if str(original_wand["id"]) == str(duplicate_wand["id"]):
		return {"ok": false, "reason": "requires_second_wand"}
	if str(duplicate_wand.get("copied_from", "")) != str(original_wand["id"]):
		return {"ok": false, "reason": "copy_not_from_original"}
	if str(original_wand.get("origin_id", "")) != str(duplicate_wand.get("origin_id", "")):
		return {"ok": false, "reason": "different_origin"}
	var upgraded: Dictionary = original_wand.duplicate(true)
	upgraded["ACCESS_TIER"] = ARCHITECT
	upgraded["is_hacked"] = true
	return {"ok": true, "wand": upgraded}
