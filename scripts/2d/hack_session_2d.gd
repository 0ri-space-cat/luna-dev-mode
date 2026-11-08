extends RefCounted
## Game-facing magical entry points. Existing CommandProcessor remains the only mutator.
const Access = preload("res://scripts/2d/hack_access_policy.gd")
var wand: Dictionary = {
	"id": "wand_luna", "origin_id": "luna_wand", "rift_enabled": false,
	"ACCESS_TIER": Access.PLAYFUL, "is_hacked": false
}
var duplicate: Dictionary = {}
var oracle_eye_owned := false
var oracle_eye_equipped := false

func touch_rift() -> void:
	wand["rift_enabled"] = true

func copy_wand() -> bool:
	if not Access.can_perform(wand, "COPY") or not duplicate.is_empty():
		return false
	duplicate = {
		"id": "wand_luna_copy_01", "origin_id": str(wand["origin_id"]),
		"copied_from": str(wand["id"])
	}
	return true

func upgrade_original() -> bool:
	var result: Dictionary = Access.duplicate_unlock(wand, duplicate)
	if not bool(result["ok"]):
		return false
	wand = result["wand"]
	return true

func collect_oracle_eye() -> bool:
	if not bool(wand.get("rift_enabled", false)):
		return false
	oracle_eye_owned = true
	oracle_eye_equipped = true
	return true

func can_action(action: String) -> bool:
	return Access.can_perform(wand, action)

func can_edit(key: String) -> bool:
	return Access.can_read(wand, key)

func edit(target: Node, key: String, value: Variant, processor) -> bool:
	if not can_edit(key) or not is_instance_valid(target):
		return false
	return processor.execute_set(target, key, value, "luna", "wand:luna")

func machine_label(key: String, readable: String) -> String:
	if oracle_eye_owned and oracle_eye_equipped:
		return readable
	# Stable visible cipher per technical key; real parameter identifiers never change.
	var marks := ["✧", "◇", "◈", "⊹", "∴", "⊙"]
	var cipher := ""
	for character in key:
		cipher += marks[abs(character.unicode_at(0)) % marks.size()]
	return cipher

func export_data() -> Dictionary:
	return {
		"wand": wand.duplicate(true),
		"duplicate": duplicate.duplicate(true),
		"oracle_eye_owned": oracle_eye_owned,
		"oracle_eye_equipped": oracle_eye_equipped
	}

func validate_data(data: Variant) -> bool:
	if not (data is Dictionary) or not (data.get("wand") is Dictionary):
		return false
	var w: Dictionary = data["wand"]
	if str(w.get("id", "")) != "wand_luna" or str(w.get("origin_id", "")) != "luna_wand":
		return false
	if typeof(w.get("rift_enabled")) != TYPE_BOOL or typeof(w.get("is_hacked")) != TYPE_BOOL:
		return false
	var tier := str(w.get("ACCESS_TIER", ""))
	if tier not in [Access.PLAYFUL, Access.ARCHITECT]:
		return false
	if tier == Access.ARCHITECT and not Access.has_architect_access(w):
		return false
	var d: Variant = data.get("duplicate", {})
	if not (d is Dictionary):
		return false
	if not d.is_empty():
		if str(d.get("id", "")) != "wand_luna_copy_01" or str(d.get("origin_id", "")) != "luna_wand" or str(d.get("copied_from", "")) != "wand_luna":
			return false
		if not bool(w.get("rift_enabled", false)):
			return false
	if tier == Access.ARCHITECT and d.is_empty():
		return false
	if typeof(data.get("oracle_eye_owned")) != TYPE_BOOL or typeof(data.get("oracle_eye_equipped")) != TYPE_BOOL:
		return false
	if bool(data["oracle_eye_equipped"]) and not bool(data["oracle_eye_owned"]):
		return false
	if bool(data["oracle_eye_owned"]) and not bool(w["rift_enabled"]):
		return false
	return true

func import_data(data: Dictionary) -> bool:
	if not validate_data(data):
		return false
	wand = (data["wand"] as Dictionary).duplicate(true)
	duplicate = (data["duplicate"] as Dictionary).duplicate(true)
	oracle_eye_owned = bool(data["oracle_eye_owned"])
	oracle_eye_equipped = bool(data["oracle_eye_equipped"])
	return true
