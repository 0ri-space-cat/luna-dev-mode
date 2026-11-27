extends RefCounted
## Durable narrative knowledge belongs to the Adventure envelope, not a local rollback.
## No Entity, profile, inventory, access or world mutation is performed here.
const MERGE := "MERGE"
const PIXEL := "PIXEL"

var merged := false
var pixel_seen := false


func snapshot() -> Dictionary:
	return {"merged": merged, "pixel_seen": pixel_seen}


func restore(data: Variant) -> bool:
	if not data is Dictionary or not data.get("merged", false) is bool or not data.get("pixel_seen", false) is bool:
		return false
	var next_merged: bool = data.get("merged", false)
	var next_pixel: bool = data.get("pixel_seen", false)
	if next_pixel and not next_merged:
		return false
	merged = next_merged
	pixel_seen = next_pixel
	return true


func advance(event: String) -> bool:
	match event:
		MERGE:
			if merged:
				return false
			merged = true
			return true
		PIXEL:
			if not merged or pixel_seen:
				return false
			pixel_seen = true
			return true
	return false
