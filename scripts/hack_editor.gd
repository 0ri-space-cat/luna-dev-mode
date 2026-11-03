extends PanelContainer
## Compact Hack 'n' Slash-inspired inspector, driven entirely by ParameterRegistry.
## Controls edit values via CommandProcessor rather than setting them directly.

signal closed

var target: Node3D
var registry
var commands
var syncing := false
var show_hints := false
var _gesture_number := 0
var _active_gestures: Dictionary = {}
var field_controls: Dictionary = {}
var hint_labels: Array[Label] = []

var title_label: Label
var type_label: Label
var hints_toggle: CheckButton
var fields_container: VBoxContainer
var undo_button: Button
var redo_button: Button
var history_label: Label


func configure(parameter_registry, command_processor) -> void:
	registry = parameter_registry
	commands = command_processor
	commands.history_changed.connect(_on_history_changed)
	_refresh_history()


func _ready() -> void:
	anchor_left = 1.0
	anchor_right = 1.0
	anchor_top = 0.0
	anchor_bottom = 0.0
	offset_left = -430.0
	offset_right = -22.0
	offset_top = 20.0
	offset_bottom = 755.0
	mouse_filter = Control.MOUSE_FILTER_STOP

	var styling := StyleBoxFlat.new()
	styling.bg_color = Color("25213b")
	styling.border_color = Color("7be4e6")
	styling.set_border_width_all(2)
	styling.set_corner_radius_all(10)
	styling.set_content_margin_all(15)
	add_theme_stylebox_override("panel", styling)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 8)
	add_child(layout)
	title_label = _label(layout, "ENTITY", 20)
	type_label = _label(layout, "TYPE: UNKNOWN", 13)

	var options_line := HBoxContainer.new()
	layout.add_child(options_line)
	var name_label := _label(options_line, "PARAMETERS", 14)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hints_toggle = CheckButton.new()
	hints_toggle.text = "SHOW_HINTS: FALSE"
	hints_toggle.toggled.connect(_on_hints_toggled)
	options_line.add_child(hints_toggle)
	layout.add_child(HSeparator.new())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(scroll)
	fields_container = VBoxContainer.new()
	fields_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fields_container.add_theme_constant_override("separation", 12)
	scroll.add_child(fields_container)

	layout.add_child(HSeparator.new())
	var history_title := _label(layout, "CHANGE_HISTORY", 13)
	history_title.add_theme_color_override("font_color", Color("87dadb"))
	history_label = _label(layout, "EMPTY", 12)
	history_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	history_label.custom_minimum_size.y = 65

	var buttons := HBoxContainer.new()
	layout.add_child(buttons)
	undo_button = Button.new()
	undo_button.text = "UNDO"
	undo_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	undo_button.pressed.connect(_on_undo_pressed)
	buttons.add_child(undo_button)
	redo_button = Button.new()
	redo_button.text = "REDO"
	redo_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	redo_button.pressed.connect(_on_redo_pressed)
	buttons.add_child(redo_button)

	var close_button := Button.new()
	close_button.text = "ЗАКРЫТЬ   [ESC]"
	close_button.pressed.connect(func() -> void: closed.emit())
	layout.add_child(close_button)

	visible = false
	_refresh_history()


func show_for(entity: Node3D) -> void:
	target = entity
	title_label.text = "ENTITY: %s" % str(entity.record.id).to_upper()
	type_label.text = "TYPE: %s" % str(entity.record.category).to_upper()
	_active_gestures.clear()
	_build_fields()
	_sync_fields_from_target()
	_refresh_history()
	visible = true


func _build_fields() -> void:
	for child in fields_container.get_children():
		fields_container.remove_child(child)
		child.queue_free()
	field_controls.clear()
	hint_labels.clear()
	if registry == null or target == null:
		return
	for spec in registry.get_specs_for(str(target.record.category)):
		_add_field(spec)


func _add_field(spec: Dictionary) -> void:
	var parameter_id: String = str(spec["id"])
	var kind: String = str(spec["kind"])
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 3)
	fields_container.add_child(container)

	var line := HBoxContainer.new()
	container.add_child(line)
	var field_label := _label(line, str(spec["label"]) + ":", 15)
	field_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	match kind:
		"bool":
			var toggle := CheckButton.new()
			toggle.text = "FALSE"
			toggle.custom_minimum_size.x = 98
			line.add_child(toggle)
			toggle.toggled.connect(_on_bool_changed.bind(parameter_id))
			field_controls[parameter_id] = {"kind": kind, "input": toggle}
		"int", "float":
			var slider := HSlider.new()
			slider.min_value = float(spec["min"])
			slider.max_value = float(spec["max"])
			slider.step = float(spec["step"])
			slider.custom_minimum_size.x = 102
			slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			line.add_child(slider)
			var number := _label(line, "0", 14)
			number.custom_minimum_size.x = 46
			number.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			slider.value_changed.connect(_on_range_changed.bind(parameter_id))
			slider.drag_started.connect(_on_drag_started.bind(parameter_id))
			slider.drag_ended.connect(_on_drag_ended.bind(parameter_id))
			field_controls[parameter_id] = {
				"kind": kind, "input": slider, "display": number
			}
		"color", "enum":
			var picker := OptionButton.new()
			picker.custom_minimum_size.x = 144
			for option in spec.get("choices", []):
				if kind == "color":
					picker.add_item("%s #%s" % [
						option["name"], str(option["value"].to_html(false)).to_upper()
					])
				else:
					picker.add_item(str(option["name"]))
			line.add_child(picker)
			picker.item_selected.connect(_on_choice_selected.bind(parameter_id, spec.get("choices", [])))
			field_controls[parameter_id] = {
				"kind": kind, "input": picker, "choices": spec.get("choices", [])
			}

	var hint := _label(container, str(spec["hint"]), 12)
	hint.add_theme_color_override("font_color", Color("b8b6d7"))
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.visible = show_hints
	hint_labels.append(hint)


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


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		closed.emit()
	elif (event.meta_pressed or event.ctrl_pressed) and event.keycode == KEY_Z:
		get_viewport().set_input_as_handled()
		if event.shift_pressed:
			_on_redo_pressed()
		else:
			_on_undo_pressed()
	elif (event.meta_pressed or event.ctrl_pressed) and event.keycode == KEY_Y:
		get_viewport().set_input_as_handled()
		_on_redo_pressed()


func _label(parent: Node, content: String, font_size: int) -> Label:
	var result := Label.new()
	result.text = content
	result.add_theme_color_override("font_color", Color("e9e2fc"))
	result.add_theme_font_size_override("font_size", font_size)
	parent.add_child(result)
	return result


func _on_hints_toggled(enabled: bool) -> void:
	show_hints = enabled
	hints_toggle.text = "SHOW_HINTS: TRUE" if enabled else "SHOW_HINTS: FALSE"
	for hint in hint_labels:
		hint.visible = enabled


func _on_drag_started(parameter_id: String) -> void:
	_gesture_number += 1
	_active_gestures[parameter_id] = "%s:%s:%d" % [target.record.id, parameter_id, _gesture_number]


func _on_drag_ended(_changed: bool, parameter_id: String) -> void:
	_active_gestures.erase(parameter_id)


func _on_bool_changed(enabled: bool, parameter_id: String) -> void:
	if syncing:
		return
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


func _on_undo_pressed() -> void:
	if commands != null:
		commands.undo()


func _on_redo_pressed() -> void:
	if commands != null:
		commands.redo()


func _on_history_changed() -> void:
	if visible:
		_sync_fields_from_target()
	_refresh_history()


func _refresh_history() -> void:
	if commands == null or history_label == null:
		return
	undo_button.disabled = not commands.can_undo()
	redo_button.disabled = not commands.can_redo()
	var lines := PackedStringArray()
	for entry in commands.get_recent_audit(3):
		lines.append("%s %s.%s = %s  (%s)" % [
			entry["action"],
			entry["entity_id"],
			entry["parameter_id"],
			_display_value(entry["after"]),
			entry["initiator_id"]
		])
	history_label.text = "\n".join(lines) if lines.size() > 0 else "EMPTY"


func _display_value(value: Variant) -> String:
	match typeof(value):
		TYPE_BOOL:
			return "TRUE" if bool(value) else "FALSE"
		TYPE_COLOR:
			return "#%s" % (value as Color).to_html(false).to_upper()
		TYPE_FLOAT:
			return "%.1f" % float(value)
	return str(value)
