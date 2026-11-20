extends RefCounted
## Separate authority domains. Editing the wand does not grant avatar entry.
const PLAYFUL := "PLAYFUL"
const DEVELOPER := "DEVELOPER"

var wand_mode := PLAYFUL
var avatar_access_level := 0


func set_wand_mode(value: String) -> bool:
	if value != PLAYFUL and value != DEVELOPER:
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
	var mode: String = str(data.get("wand_mode", ""))
	var tier: int = int(data.get("avatar_access_level", -1))
	if (mode != PLAYFUL and mode != DEVELOPER) or tier < 0 or tier > 3:
		return false
	wand_mode = mode
	avatar_access_level = tier
	return true
