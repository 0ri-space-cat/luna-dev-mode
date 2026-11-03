extends SceneTree
## Boots Main as a real scene and exercises gameplay glue, not just services.

const SaveService = preload("res://scripts/core/save_service.gd")
const ProfileService = preload("res://scripts/core/profile_service.gd")
const WorkshopService = preload("res://scripts/core/spell_workshop_service.gd")

const RUN_TEST_PATH := "user://luna_main_integration_run.json"
const PROFILE_TEST_PATH := "user://luna_main_integration_profile.json"
const SPELL_TEST_PATH := "user://luna_main_integration_spells.json"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for path in [RUN_TEST_PATH, PROFILE_TEST_PATH, SPELL_TEST_PATH]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var stage = load("res://scenes/main.tscn").instantiate()
	root.add_child(stage)
	stage.save_service = SaveService.new(RUN_TEST_PATH)
	stage.profile_service = ProfileService.new(PROFILE_TEST_PATH)
	var fridge: Node = stage.world_registry.get_entity("fridge_001")
	assert(fridge != null)
	assert(stage.spell_service.list_spell_ids() == ["FIREBALL", "FROST_SHARD", "ARC_BOLT"])
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


	# Live workshop: use registry choices to assemble, persist and select a spell.
	stage.spell_workshop_service = WorkshopService.new(
		stage.parameter_registry, stage.spell_service, SPELL_TEST_PATH
	)
	stage.spell_workshop_panel.configure(stage.parameter_registry, stage.spell_workshop_service)
	stage._open_workshop()
	assert(stage.spell_workshop_panel.visible)
	assert(paused)
	var panel = stage.spell_workshop_panel
	# The workshop now opens by dissecting the selected fireball.
	assert(panel._choice_value(panel.create_choice) == "ENERGY")
	assert(panel.draft.size() == 1)
	assert(panel.form_choice.get_item_metadata(panel.form_choice.selected) == "ORB")
	assert(panel.essence_choice.get_item_metadata(panel.essence_choice.selected) == "FIRE")
	assert(panel._impact()["mode"] == "BURST")
	assert(is_equal_approx(float(panel._impact()["radius"]), 2.5))
	panel._on_new_recipe()
	assert(panel._impact().is_empty())
	panel._select_choice(panel.create_choice, "NONE")
	panel._on_create_changed(panel.create_choice.selected)
	panel.name_input.text = "Мой оживитель"
	panel.field_choice.select(0)
	panel._on_field_changed(0)
	panel._on_add_block() # IS_ALIVE = TRUE
	var speed_index := -1
	for index in range(panel.specs.size()):
		if panel.specs[index]["id"] == "speed":
			speed_index = index
			break
	assert(speed_index >= 0)
	panel.field_choice.select(speed_index)
	panel._on_field_changed(speed_index)
	panel.operation_choice.select(1) # ADD
	panel._on_operation_changed(1)
	(panel.value_control as SpinBox).value = 0.5
	panel._on_add_block()
	assert(panel.draft.size() == 2)
	panel._on_save()
	assert(not paused)
	assert(not panel.visible)
	assert(stage.selected_spell_id == "CUSTOM_001")
	assert(FileAccess.file_exists(SPELL_TEST_PATH))
	var before_speed: float = float(fridge.get_parameter("speed"))
	assert(stage.spell_service.cast_spell("CUSTOM_001", "luna", "fridge_001"))
	assert(is_equal_approx(float(fridge.get_parameter("speed")), before_speed + 0.5))
	assert(stage.command_processor.undo())
	assert(is_equal_approx(float(fridge.get_parameter("speed")), before_speed))

	# World-level frost status is visible and survives save/load.
	assert(not fridge.elemental_label.visible)
	assert(stage.elemental_status_service.apply_element("fridge_001", "FROST"))
	assert(fridge.elemental_label.visible)
	assert(fridge.elemental_label.text.contains("CHILL"))
	stage._save_checkpoint(false)
	assert(stage.elemental_status_service.import_data({}))
	assert(not fridge.elemental_label.visible)
	stage._load_checkpoint(false)
	assert(stage.elemental_status_service.has_status("fridge_001", "CHILL"))
	assert(fridge.elemental_label.visible)
	assert(fridge.elemental_label.text.contains("CHILL"))
	assert(stage.luna.surface_service == stage.surface_field_service)
	assert(stage.surface_field_service.get_fields().size() == 1)
	assert(stage.surface_field_service.traction(fridge.global_position) < 1.0)
	assert(stage.ice_visuals.size() == 1)
	stage._save_checkpoint(false)
	assert(stage.surface_field_service.import_data({}))
	assert(stage.ice_visuals.is_empty())
	stage._load_checkpoint(false)
	assert(stage.surface_field_service.get_fields().size() == 1)
	assert(stage.ice_visuals.size() == 1)

	stage.free()
	var profile_after_restart = ProfileService.new(PROFILE_TEST_PATH)
	assert(profile_after_restart.load_profile())
	assert(profile_after_restart.has_discovered_category("fridge"))
	assert(profile_after_restart.has_discovered_parameter("fridge", "luna_relation"))
	for path in [RUN_TEST_PATH, PROFILE_TEST_PATH, SPELL_TEST_PATH]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("LUNA 0.13: elemental labels, workshop, saves and full scene passed")
	quit(0)
