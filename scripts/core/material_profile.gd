extends RefCounted
## Material qualities shared by fire spread, electricity and future physics.
## Editable MATERIAL is independent of an entity's category or current shape.

const DEFINITIONS = [
	{"id": "WOOD", "name": "Дерево", "flammable": true, "conductive": false},
	{"id": "FABRIC", "name": "Ткань", "flammable": true, "conductive": false},
	{"id": "METAL", "name": "Металл", "flammable": false, "conductive": true},
	{"id": "STONE", "name": "Камень", "flammable": false, "conductive": false},
	{"id": "ICE", "name": "Лёд", "flammable": false, "conductive": false},
	{"id": "ARCANE", "name": "Магическая материя", "flammable": false, "conductive": true}
]


static func choices() -> Array:
	var result := []
	for definition in DEFINITIONS:
		result.append({"name": definition["id"], "value": definition["id"]})
	return result


static func is_flammable(material_id: String) -> bool:
	return bool(_definition(material_id).get("flammable", false))


static func is_conductive(material_id: String) -> bool:
	return bool(_definition(material_id).get("conductive", false))


static func initial(category: String, manifestation: Dictionary = {}) -> String:
	match category:
		"tree":
			return "WOOD"
		"fridge":
			return "METAL"
		"arcane_object":
			return "ICE" if str(manifestation.get("element", "")) == "FROST" else "STONE"
		"arcane_creature", "arcane_energy":
			return "ARCANE"
	return "STONE"


static func _definition(material_id: String) -> Dictionary:
	for definition in DEFINITIONS:
		if definition["id"] == material_id:
			return definition
	return {}
