extends SceneTree
## Boots Main as a real scene and exercises gameplay glue, not just services.

const SaveService = preload("res://scripts/core/save_service.gd")
const ProfileService = preload("res://scripts/core/profile_service.gd")

const RUN_TEST_PATH := "user://luna_main_integration_run.json"
const PROFILE_TEST_PATH := "user://luna_main_integration_profile.json"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for path in [RUN_TEST_PATH, PROFILE_TEST_PATH]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var stage = load("res://scenes/main.tscn").instantiate()
	root.add_child(stage)
	stage.save_service = SaveService.new(RUN_TEST_PATH)
	stage.profile_service = ProfileService.new(PROFILE_TEST_PATH)
	var fridge: Node = stage.world_registry.get_entity("fridge_001")
	assert(fridge != null)
	assert(stage.spell_service.list_spell_ids() == ["AWAKEN", "PINKIFY", "QUICKEN"])
	assert(not stage.profile_service.has_discovered_category("fridge"))

	# Inspecting a real scene object adds permanent knowledge, not a world edit.
	stage._open_editor(fridge)
	assert(stage.profile_service.has_discovered_category("fridge"))
	stage._close_editor()
	assert(not paused)

	# Player edits add individual parameter discoveries.
	assert(stage.command_processor.execute_set(fridge, "luna_relation", "FRIEND", "luna", "wand:luna"))
	assert(stage.relationship_service.get_attitude("fridge_001", "luna") == "FRIEND")
	assert(stage.profile_service.has_discovered_parameter("fridge", "luna_relation"))
	stage._toggle_journal()
	assert(stage.journal_panel.visible)
	assert(stage.journal_label.text.contains("FRIDGE"))
	stage._toggle_journal()
	assert(not stage.journal_panel.visible)

	# Regression: F6/autosave code must include relationships, not just parameters.
	stage._save_checkpoint(false)
	assert(FileAccess.file_exists(RUN_TEST_PATH))
	assert(stage.relationship_service.set_attitude("fridge_001", "luna", "HOSTILE"))
	assert(stage.command_processor.execute_set(fridge, "luna_relation", "HOSTILE", "luna", "wand:luna"))
	assert(stage.relationship_service.get_attitude("fridge_001", "luna") == "HOSTILE")
	stage._load_checkpoint(false)
	assert(fridge.get_parameter("luna_relation") == "FRIEND")
	assert(stage.relationship_service.get_attitude("fridge_001", "luna") == "FRIEND")

	# The starter wand uses the same effect pipeline as the inspector.
	assert(stage.spell_service.cast_spell("AWAKEN", "luna", "fridge_001"))
	assert(fridge.get_parameter("alive") == true)
	assert(stage.command_processor.get_recent_audit(1)[0]["source_id"] == "spell:AWAKEN")

	stage.free()
	var profile_after_restart = ProfileService.new(PROFILE_TEST_PATH)
	assert(profile_after_restart.load_profile())
	assert(profile_after_restart.has_discovered_category("fridge"))
	assert(profile_after_restart.has_discovered_parameter("fridge", "luna_relation"))
	for path in [RUN_TEST_PATH, PROFILE_TEST_PATH]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("LUNA 0.8: live scene glue, saves, journal and spells passed")
	quit(0)
