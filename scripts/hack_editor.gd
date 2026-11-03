extends PanelContainer
## Compact, RPG-like neon entity inspector. All fields are sourced from
## ParameterRegistry, and all edits go through CommandProcessor.
signal closed
signal duplicate_requested(entity: Node3D)
signal delete_requested(entity: Node3D)

const UiLanguage = preload("res://scripts/core/ui_language.gd")
const TAB_IDS := [
	"GENERAL", "APPEARANCE", "PHYSICS", "MIND", "BEHAVIOR",
	"RELATIONSHIPS", "ABILITIES", "REACTIONS", "AURAS", "TAGS"
]
const TAB_RU := [
	"ОБЩЕЕ", "ОБЛИК", "ФИЗИКА", "РАЗУМ", "ПОВЕДЕНИЕ",
	"ОТНОШЕНИЯ", "СПОСОБНОСТИ", "РЕАКЦИИ", "АУРЫ", "ТЕГИ"
]
var target: Node3D
var registry
var commands
var ui_language = UiLanguage.new()
var syncing := false
var _gesture_number := 0
var _active_gestures: Dictionary = {}
var field_controls: Dictionary = {}
var title_label: Label
var type_label: Label
var tab_bar: TabBar
var fields_container: VBoxContainer
var duplicate_button: Button
var delete_button: Button
var close_button: Button
var selected_tab := "GENERAL"


func configure(parameter_registry, command_processor, language_service = null) -> void:
	registry = parameter_registry
	commands = command_processor
	if language_service != null:
		ui_language = language_service
	commands.history_changed.connect(_on_history_changed)


func _ready() -> void:
	anchor_left = 1.0
	anchor_right = 1.0
	anchor_top = 1.0
	anchor_bottom = 1.0
	offset_left = -505.0
	offset_right = -20.0
	offset_top = -505.0
	offset_bottom = -20.0
	mouse_filter = Control.MOUSE_FILTER_STOP

	var styling := StyleBoxFlat.new()
	styling.bg_color = Color("221038")
	styling.border_color = Color("f45cef")
	styling.set_border_width_all(3)
	styling.set_corner_radius_all(12)
	styling.set_content_margin_all(13)
	styling.shadow_color = Color("b93bff6a")
	styling.shadow_size = 8
	add_theme_stylebox_override("panel", styling)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 8)
	add_child(layout)
	title_label = _label(layout, "> ENTITY  ID: ---", 19)
	type_label = _label(layout, "TYPE: UNKNOWN", 12)
	type_label.add_theme_color_override("font_color", Color("a5eff5"))

	tab_bar = TabBar.new()
	tab_bar.clip_tabs = true
	tab_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(tab_bar)
	for id in TAB_IDS:
		tab_bar.add_tab(id)
	tab_bar.tab_changed.connect(_on_tab_changed)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(scroll)
	fields_container = VBoxContainer.new()
	fields_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fields_container.add_theme_constant_override("separation", 11)
	scroll.add_child(fields_container)

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)
	layout.add_child(footer)
	duplicate_button = Button.new()
	duplicate_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	duplicate_button.pressed.connect(_on_duplicate_pressed)
	footer.add_child(duplicate_button)
	delete_button = Button.new()
	delete_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	delete_button.pressed.connect(_on_delete_pressed)
	footer.add_child(delete_button)
	close_button = Button.new()
	close_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	close_button.pressed.connect(func() -> void: closed.emit())
	footer.add_child(close_button)
	refresh_language()
	visible = false


func show_for(entity: Node3D) -> void:
	target = entity
	_active_gestures.clear()
	selected_tab = "GENERAL"
	if is_instance_valid(tab_bar):
		tab_bar.current_tab = 0
	_update_identity()
	_build_fields()
	_sync_fields_from_target()
	visible = true


func refresh_language() -> void:
	if not is_instance_valid(tab_bar):
		return
	for index in range(TAB_IDS.size()):
		tab_bar.set_tab_title(index, ui_language.text(TAB_IDS[index], TAB_RU[index]))
	if is_instance_valid(duplicate_button):
		duplicate_button.text = "COPY"
		duplicate_button.tooltip_text = ui_language.text(
			"Create an independent copy with the same parameters.",
			"Создать независимую копию с теми же параметрами."
		)
	if is_instance_valid(close_button):
		close_button.text = "DONE"
	if is_instance_valid(delete_button):
		delete_button.text = "DELETE"
		delete_button.tooltip_text = ui_language.text(
			"Remove this entity from the world. You can undo it.",
			"Удалить объект из мира. Действие можно отменить."
		)
	_update_identity()
	_build_fields()
	_sync_fields_from_target()


func _update_identity() -> void:
	if not is_instance_valid(target) or not is_instance_valid(title_label):
		return
	title_label.text = "> %s   ID: %s" % [ui_language.translated(str(target.record.display_name)).to_upper(), str(target.record.id).to_upper()]
	type_label.text = "TYPE: %s" % str(target.record.category).to_upper()


func _on_tab_changed(index: int) -> void:
	if index < 0 or index >= TAB_IDS.size():
		return
	selected_tab = TAB_IDS[index]
	_active_gestures.clear()
	_build_fields()
	_sync_fields_from_target()


func _build_fields() -> void:
	if not is_instance_valid(fields_container):
		return
	for child in fields_container.get_children():
		fields_container.remove_child(child)
		child.queue_free()
	field_controls.clear()
	if registry == null or not is_instance_valid(target):
		return
	var total := 0
	for spec in registry.get_specs_for(str(target.record.category)):
		if str(spec.get("tab", "GENERAL")) != selected_tab:
			continue
		_add_field(spec)
		total += 1
	if total == 0:
		var placeholder := _label(fields_container, ui_language.text(
			"NO PARAMETERS IN THIS TAB YET", "ЗДЕСЬ ПОКА НЕТ ПАРАМЕТРОВ"
		), 12)
		placeholder.add_theme_color_override("font_color", Color("b7a1d5"))


func _add_field(spec: Dictionary) -> void:
	var parameter_id: String = str(spec["id"])
	var kind: String = str(spec["kind"])
	var hint: String = ui_language.hint(spec)
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 4)
	fields_container.add_child(container)
	container.tooltip_text = hint

	var line := HBoxContainer.new()
	container.add_child(line)
	line.tooltip_text = hint
	var icon_label := _label(line, str(spec.get("icon", "✧")), 18)
	icon_label.custom_minimum_size.x = 27
	icon_label.tooltip_text = hint
	icon_label.add_theme_color_override("font_color", Color("65eeff"))
	var field_label := _label(line, str(spec["label"]), 14)
	field_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field_label.tooltip_text = hint

	match kind:
		"bool":
			var toggle := CheckButton.new()
			toggle.text = "FALSE"
			toggle.custom_minimum_size.x = 90
			toggle.tooltip_text = hint
			line.add_child(toggle)
			toggle.toggled.connect(_on_bool_changed.bind(parameter_id))
			field_controls[parameter_id] = {"kind": kind, "input": toggle}
		"int", "float":
			var slider := HSlider.new()
			slider.min_value = float(spec["min"])
			slider.max_value = float(spec["max"])
			slider.step = float(spec["step"])
			slider.custom_minimum_size.x = 88
			slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			slider.tooltip_text = hint
			line.add_child(slider)
			var number := _label(line, "0", 13)
			number.custom_minimum_size.x = 40
			number.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			number.tooltip_text = hint
			slider.value_changed.connect(_on_range_changed.bind(parameter_id))
			slider.drag_started.connect(_on_drag_started.bind(parameter_id))
			slider.drag_ended.connect(_on_drag_ended.bind(parameter_id))
			field_controls[parameter_id] = {"kind": kind, "input": slider, "display": number}
		"color", "enum":
			var picker := OptionButton.new()
			picker.custom_minimum_size.x = 165
			picker.tooltip_text = hint
			for option in spec.get("choices", []):
				if kind == "color":
					picker.add_item("%s #%s" % [
						option["name"], str(option["value"].to_html(false)).to_upper()
					])
				else:
					picker.add_item(str(option["name"]))
			line.add_child(picker)
			picker.item_selected.connect(_on_choice_selected.bind(parameter_id, spec.get("choices", [])))
			field_controls[parameter_id] = {"kind": kind, "input": picker, "choices": spec.get("choices", [])}


func _sync_fields_from_target() -> void:
	if not is_instance_valid(target):
		return
	syncing = true
	for parameter_id in field_controls.keys():
		var field: Dictionary = field_controls[parameter_id]
		var value: Variant = target.get_parameter(parameter_id)
		match str(field["kind"]):
			"bool":
				var toggle: CheckButton = field["input"]
				toggle.set_pressed_no_signal(bool(value))
				toggle.text = "TRUE" if bool(value) else "FALSE"
			"int", "float":
				var slider: HSlider = field["input"]
				slider.set_value_no_signal(float(value))
				var value_label: Label = field["display"]
				value_label.text = str(int(value)) if field["kind"] == "int" else "%.1f" % float(value)
			"color", "enum":
				var picker: OptionButton = field["input"]
				var choices: Array = field["choices"]
				for index in range(choices.size()):
					if choices[index]["value"] == value:
						picker.select(index)
						break
	syncing = false


func _on_duplicate_pressed() -> void:
	if is_instance_valid(target):
		duplicate_requested.emit(target)


func _on_delete_pressed() -> void:
	if is_instance_valid(target):
		delete_requested.emit(target)


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		closed.emit()


func _label(parent: Node, content: String, font_size: int) -> Label:
	var result := Label.new()
	result.text = content
	result.add_theme_color_override("font_color", Color("f2d9ff"))
	result.add_theme_font_size_override("font_size", font_size)
	parent.add_child(result)
	return result


func _on_drag_started(parameter_id: String) -> void:
	_gesture_number += 1
	_active_gestures[parameter_id] = "%s:%s:%d" % [target.record.id, parameter_id, _gesture_number]


func _on_drag_ended(_changed: bool, parameter_id: String) -> void:
	_active_gestures.erase(parameter_id)


func _on_bool_changed(enabled: bool, parameter_id: String) -> void:
	if not syncing:
		_apply_change(parameter_id, enabled)


func _on_range_changed(value: float, parameter_id: String) -> void:
	if syncing:
		return
	var field: Dictionary = field_controls[parameter_id]
	var requested: Variant = int(value) if field["kind"] == "int" else value
	_apply_change(parameter_id, requested, str(_active_gestures.get(parameter_id, "")))


func _on_choice_selected(index: int, parameter_id: String, choices: Array) -> void:
	if syncing or index < 0 or index >= choices.size():
		return
	_apply_change(parameter_id, choices[index]["value"])


func _apply_change(parameter_id: String, value: Variant, merge_key: String = "") -> void:
	if commands == null or not is_instance_valid(target):
		return
	if not commands.execute_set(target, parameter_id, value, "luna", "wand:luna", merge_key):
		_sync_fields_from_target()


func _on_history_changed() -> void:
	if visible:
		_sync_fields_from_target()
