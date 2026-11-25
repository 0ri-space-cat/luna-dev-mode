extends RefCounted
## Separate authority domains. Editing the wand does not grant avatar entry.
const ORDINARY := "ORDINARY"
const PLAYFUL := "PLAYFUL"
const DEVELOPER := "DEVELOPER"

var wand_mode := PLAYFUL
var avatar_access_level := 0


func set_wand_mode(value: String) -> bool:
	if value not in [ORDINARY, PLAYFUL, DEVELOPER]:
		return false
	wand_mode = value
	return true


func set_avatar_access_level(value: int) -> bool:
	if value < 0 or value > 3:
		return false
	avatar_access_level = value
	return true


func snapshot() -> Dictionary:
	return {"wand_mode": wand_mode, "avatar_access_level": avatar_access_level}


func restore(data: Dictionary) -> bool:
	var mode: Variant = data.get("wand_mode")
	var tier: Variant = data.get("avatar_access_level")
	if mode not in [ORDINARY, PLAYFUL, DEVELOPER]:
		return false
	if typeof(tier) not in [TYPE_INT, TYPE_FLOAT] or float(tier) not in [0.0, 1.0, 2.0, 3.0]:
		return false
	wand_mode = mode
	avatar_access_level = int(tier)
	return true
