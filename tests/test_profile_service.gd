extends SceneTree
## Persistent discovery profile, independent from a world's run save.

const Profiles = preload("res://scripts/core/profile_service.gd")
const JsonStore = preload("res://scripts/core/json_store.gd")

const TEST_PATH := "user://luna_profile_test_v1.json"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	var profile = Profiles.new(TEST_PATH)
	assert(not profile.has_profile())
	assert(profile.discover_category("tree"))
	assert(not profile.discover_category("tree"))
	assert(profile.discover_parameter("tree", "alive"))
	assert(profile.discover_parameter("tree", "speed"))
	assert(not profile.discover_parameter("tree", "speed"))
	assert(profile.discover_parameter("fridge", "color"))
	assert(profile.has_discovered_category("fridge"))
	assert(profile.has_discovered_parameter("tree", "alive"))
	assert(profile.list_categories() == ["fridge", "tree"])
	assert(profile.list_parameters("tree") == ["alive", "speed"])
	assert(not profile.discover_category(""))
	assert(not profile.discover_parameter("tree", "not-a-valid-identifier"))
	assert(profile.dirty)
	assert(profile.save_profile())
	assert(not profile.dirty)
	assert(profile.has_profile())
	assert(profile.save_profile()) # No rewrite needed when unchanged.

	var saved: Dictionary = JsonStore.read_document(TEST_PATH)
	assert(saved["ok"])
	assert(saved["data"]["version"] == 1)
	assert(saved["data"]["categories"].size() == 2)

	# New run / new in-memory service still knows the same discoveries.
	var next_run = Profiles.new(TEST_PATH)
	assert(next_run.load_profile())
	assert(next_run.has_discovered_category("tree"))
	assert(next_run.has_discovered_parameter("tree", "speed"))
	assert(next_run.has_discovered_parameter("fridge", "color"))
	assert(not next_run.has_discovered_parameter("fridge", "speed"))
	assert(not next_run.dirty)

	# Import must validate everything before replacing existing profile.
	var corrupted: Dictionary = next_run.export_data()
	corrupted["parameters"]["tree"].append("not-a-valid-identifier")
	assert(not next_run.import_data(corrupted))
	assert(next_run.has_discovered_parameter("tree", "speed"))
	var wrong_version: Dictionary = next_run.export_data()
	wrong_version["version"] = 77
	assert(not next_run.import_data(wrong_version))
	assert(next_run.has_discovered_category("tree"))

	# An unreadable file does not erase an already loaded in-memory profile.
	var broken := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	assert(broken != null)
	broken.store_string("{not json")
	broken.close()
	assert(not next_run.load_profile())
	assert(next_run.has_discovered_category("tree"))

	assert(next_run.discover_parameter("tree", "health"))
	assert(next_run.save_profile())
	var third_run = Profiles.new(TEST_PATH)
	assert(third_run.load_profile())
	assert(third_run.has_discovered_parameter("tree", "health"))

	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	print("LUNA 0.7: persistent knowledge profile and atomic JSON tests passed")
	quit(0)
