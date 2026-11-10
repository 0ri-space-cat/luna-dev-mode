extends SceneTree
const Registry = preload("res://scripts/core/lesson_registry.gd")


func _initialize() -> void:
	var lessons = Registry.new()
	var file := FileAccess.open("res://data/v3/lesson_blueprints.json", FileAccess.READ)
	assert(file != null)
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	assert(typeof(parsed) == TYPE_DICTIONARY)
	var catalog = Registry.new()
	for definition in parsed["lessons"]:
		assert(catalog.register_lesson(definition))
	assert(catalog.list_ids().size() == 21)
	assert(catalog.describe("U_17_CAMERA_BRIDGE")["character_hints"].has("TOFFI_GAZE"))
	assert(catalog.can_resolve("U_17_CAMERA_BRIDGE", {
		"CAMERA_FIXED": true, "PLAYER_OUTSIDE_CAMERA_VIEW": true,
		"completed_quests": [], "current_character": "luna"
	}))
	assert(lessons.register_lesson({
		"id": "U_04_BRIDGE", "zone_id": "ET_GORGE",
		"law": "COLLISION_NOT_VISIBILITY",
		"evidence": ["APPLE_BOUNCES", "RAIN_HITS", "BIRD_LANDS"],
		"physical_conditions": ["PLAYER_ON_BRIDGE"],
		"character_hints": ["YUKI_ROUTE_MAP"]
	}))
	assert(lessons.register_lesson({
		"id": "U_17_CAMERA_BRIDGE", "zone_id": "ET_EDGE_SHORE",
		"law": "CAMERA_OBSERVATION",
		"evidence": ["FOOTSTEPS", "EYES_DONT_HELP", "MIRROR_DETACH"],
		"physical_conditions": ["CAMERA_FIXED", "PLAYER_OUTSIDE_FRAME"],
		"character_hints": ["TOFFI_GAZE", "YUKI_ROUTE_MAP", "ORI_UI"]
	}))
	assert(not lessons.register_lesson({
		"id": "BLOCKING_QUEST", "zone_id": "ET_EDGE_SHORE",
		"law": "CAMERA_OBSERVATION",
		"evidence": [], "physical_conditions": ["CAMERA_FIXED"],
		"required_completed_quest": "YUKI_ALL"
	}))
	assert(not lessons.can_resolve("U_17_CAMERA_BRIDGE", {
		"CAMERA_FIXED": true, "PLAYER_OUTSIDE_FRAME": false
	}))
	assert(lessons.can_resolve("U_17_CAMERA_BRIDGE", {
		"CAMERA_FIXED": true, "PLAYER_OUTSIDE_FRAME": true
	}))
	# The world keeps its laws irrespective of the journal or active hero.
	assert(lessons.observe("U_17_CAMERA_BRIDGE", "FOOTSTEPS"))
	assert(lessons.observations("U_17_CAMERA_BRIDGE") == ["FOOTSTEPS"])
	assert(lessons.can_resolve("U_17_CAMERA_BRIDGE", {
		"CAMERA_FIXED": true, "PLAYER_OUTSIDE_FRAME": true,
		"current_character": "luna", "completed_quests": []
	}))
	assert(lessons.describe("U_17_CAMERA_BRIDGE")["character_hints"].size() == 3)
	print("LUNA V3: zone laws, optional character lessons and knowledge-first physics passed")
	quit(0)
