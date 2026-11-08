extends SceneTree
const Access = preload("res://scripts/2d/hack_access_policy.gd")
const Profiles = preload("res://scripts/2d/character_ui_profile.gd")
func _initialize() -> void:
	var original := {"id": "wand_luna", "origin_id": "artifact_wand_luna", "ACCESS_TIER": "PLAYFUL", "is_hacked": false}
	var duplicate := {"id": "wand_luna_copy_1", "origin_id": "artifact_wand_luna"}
	assert(Access.can_perform(original, "TINT"))
	assert(not Access.can_perform(original, "EDIT_TIME"))
	assert(not Access.duplicate_unlock(original, original)["ok"])
	assert(not Access.duplicate_unlock(original, {"id": "other", "origin_id": "other"})["ok"])
	var result := Access.duplicate_unlock(original, duplicate)
	assert(result["ok"])
	assert(Access.can_perform(result["wand"], "EDIT_TIME"))
	assert(not Access.can_perform(original, "EDIT_TIME"))
	assert(Profiles.get_profile("luna")["title"] != Profiles.get_profile("yuki")["title"])
	print("2D foundation access policy: PASS")
	quit()
