extends SceneTree
## 0.18 integration: locale, hover hints, tabs, independent copies and persistence.

const SaveService = preload("res://scripts/core/save_service.gd")
const TEST_PATH := "user://luna_018_editor_test.json"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	var stage = load("res://scenes/main.tscn").instantiate()
	root.add_child(stage)
	stage.save_service = SaveService.new(TEST_PATH)
	stage._on_language_selected(0)
	assert(stage.ui_language.locale == "en")
	assert(stage.editor.tab_bar.get_tab_count() == 10)
	assert(stage.editor.tab_bar.get_tab_title(0) == "GENERAL")

	var fridge: Node3D = stage.world_registry.get_entity("fridge_001") as Node3D
	assert(fridge != null)
	assert(stage.command_processor.execute_set(fridge, "health", 88, "luna", "wand:luna"))
	stage._open_editor(fridge)
	assert(stage.editor.field_controls.has("alive"))
	var bool_control: Control = stage.editor.field_controls["alive"]["input"]
	assert(bool_control.tooltip_text.contains("Bring this object"))
	stage.editor._on_tab_changed(4)
	assert(stage.editor.field_controls.has("behavior_mode"))
	assert(not stage.editor.field_controls.has("alive"))

	stage._on_language_selected(1)
	assert(stage.ui_language.locale == "ru")
	assert(stage.editor.tab_bar.get_tab_title(0) == "ОБЩЕЕ")
	stage.editor._on_tab_changed(0)
	assert(stage.editor.field_controls.has("alive"))
	var ru_toggle: Control = stage.editor.field_controls["alive"]["input"]
	assert(ru_toggle.tooltip_text.contains("Оживляет"))
	# Buttons and metadata do not rename technical parameters.
	assert(stage.parameter_registry.get_spec("fridge", "alive")["label"] == "IS_ALIVE")

	stage.editor._on_duplicate_pressed()
	assert(stage.editor.target != fridge)
	var copied: Node3D = stage.editor.target
	var copied_id: String = str(copied.record.id)
	assert(copied_id.begins_with("fridge_copy_"))
	assert(copied.get_parameter("health") == 88)
	assert(str(copied.record.category) == "fridge")
	assert(copied.has_meta("copy_origin"))
	assert(copied.get_meta("copy_origin") == "fridge_001")
	assert(stage.command_processor.execute_set(fridge, "health", 77, "luna", "wand:luna"))
	assert(copied.get_parameter("health") == 88)
	stage._close_editor()

	stage._save_checkpoint(false)
	assert(FileAccess.file_exists(TEST_PATH))
	stage.world_registry.unregister_entity(copied_id)
	copied.free()
	assert(stage.world_registry.get_entity(copied_id) == null)
	stage._load_checkpoint(false)
	var restored: Node3D = stage.world_registry.get_entity(copied_id) as Node3D
	assert(restored != null)
	assert(restored.get_parameter("health") == 88)
	assert(restored.get_meta("copy_origin") == "fridge_001")
	assert(fridge.get_parameter("health") == 77)
	stage._on_language_selected(0)

	stage.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	print("LUNA 0.18: localized inspector, hover tips, tabs, COPY and restore passed")
	quit(0)
