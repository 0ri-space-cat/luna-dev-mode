extends PanelContainer
## Graybox inspector: technical parameter names, Russian optional hints.
## The editor is in an always-processing CanvasLayer while the game world is paused.
## FIELD_SPECS are temporary metadata until the planned ParameterRegistry is introduced.

signal closed

const PALETTE = [
	{"name": "LAVENDER", "color": Color("b790dd")},
	{"name": "MINT", "color": Color("8ed7bd")},
	{"name": "PINK", "color": Color("f49fc9")},
	{"name": "BLUE", "color": Color("87bfe8")},
	{"name": "PEACH", "color": Color("efb68e")},
	{"name": "VIOLET", "color": Color("684a96")}
]

# UI-facing names are intentionally independent of the EntityRecord storage keys.
const FIELD_SPECS = [
	{"id": "alive", "label": "IS_ALIVE", "kind": "bool",
	 "hint": "Объект живой и может действовать самостоятельно."},
	{"id": "health", "label": "HEALTH", "kind": "range",
	 "min": 1.0, "max": 200.0, "step": 1.0,
	 "hint": "Запас здоровья объекта."},
	{"id": "speed", "label": "MOVE_SPEED", "kind": "range",
	 "min": 0.0, "max": 5.0, "step": 0.1,
	 "hint": "Скорость самостоятельного передвижения."},
	{"id": "size", "label": "SCALE", "kind": "range",
	 "min": 0.5, "max": 2.0, "step": 0.1,
	 "hint": "Размер объекта относительно исходного."},
	{"id": "color", "label": "BASE_COLOR", "kind": "color",
	 "hint": "Основной цвет объекта."}
]

var target: Node3D
var syncing := false
var show_hints := false
var title_label: Label
var type_label: Label
var hints_toggle: CheckButton
var field_controls: Dictionary = {}
var hint_labels: Array[Label] = []


func _ready() -> void:
	anchor_left = 1.0
	anchor_right = 1.0
	anchor_top = 0.0
	anchor_bottom = 0.0
	offset_left = -414.0
	offset_right = -22.0
	offset_top = 22.0
	offset_bottom = 680.0
	mouse_filter = Control.MOUSE_FILTER_STOP

	var styling := StyleBoxFlat.new()
	styling.bg_color = Color("25213b")
	styling.border_color = Color("7be4e6")
	styling.set_border_width_all(2)
	styling.set_corner_radius_all(10)
	styling.set_content_margin_all(16)
	add_theme_stylebox_override("panel", styling)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	add_child(column)

	title_label = _label(column, "ENTITY", 21)
	type_label = _label(column, "TYPE: UNKNOWN", 13)

	var top_line := HBoxContainer.new()
	column.add_child(top_line)
	var metadata_label := _label(top_line, "PARAMETERS", 14)
	metadata_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	hints_toggle = CheckButton.new()
	hints_toggle.text = "SHOW_HINTS: FALSE"
	hints_toggle.button_pressed = false
	hints_toggle.toggled.connect(_on_hints_toggled)
	top_line.add_child(hints_toggle)
	column.add_child(HSeparator.new())

	for spec in FIELD_SPECS:
		_add_field(column, spec)

	column.add_child(HSeparator.new())
	var close_button := Button.new()
	close_button.text = "ЗАКРЫТЬ  [ESC]"
	close_button.pressed.connect(func() -> void: closed.emit())
	column.add_child(close_button)
	visible = false


func _add_field(parent: VBoxContainer, spec: Dictionary) -> void:
	var parameter_id: String = str(spec["id"])
	var kind: String = str(spec["kind"])
	var group := VBoxContainer.new()
	group.add_theme_constant_override("separation", 2)
	parent.add_child(group)

	var row := HBoxContainer.new()
	group.add_child(row)
	var name_label := _label(row, str(spec["label"]) + ":", 15)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	match kind:
		"bool":
			var toggle := CheckButton.new()
			toggle.text = "FALSE"
			toggle.custom_minimum_size.x = 94
			row.add_child(toggle)
			toggle.toggled.connect(_on_bool_changed.bind(parameter_id, toggle))
			field_controls[parameter_id] = {"kind": kind, "input": toggle}

		"range":
			var slider := HSlider.new()
			slider.min_value = float(spec["min"])
			slider.max_value = float(spec["max"])
			slider.step = float(spec["step"])
			slider.custom_minimum_size.x = 95
			slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(slider)

			var number := _label(row, "0", 14)
			number.custom_minimum_size.x = 44
			number.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			slider.value_changed.connect(_on_range_changed.bind(parameter_id, number))
			field_controls[parameter_id] = {
				"kind": kind,
				"input": slider,
				"display": number
			}

		"color":
			var picker := OptionButton.new()
			picker.custom_minimum_size.x = 140
			for option in PALETTE:
				picker.add_item("%s  #%s" % [
					option["name"], str(option["color"].to_html(false)).to_upper()
				])
			row.add_child(picker)
			picker.item_selected.connect(_on_color_selected.bind(parameter_id))
			field_controls[parameter_id] = {"kind": kind, "input": picker}

	var hint := _label(group, str(spec["hint"]), 12)
	hint.add_theme_color_override("font_color", Color("b6b4cf"))
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.visible = show_hints
	hint_labels.append(hint)


func show_for(entity: Node3D) -> void:
	target = entity
	syncing = true
	title_label.text = "ENTITY: %s" % str(entity.record.id).to_upper()
	type_label.text = "TYPE: %s" % str(entity.record.category).to_upper()
	for spec in FIELD_SPECS:
		var parameter_id: String = str(spec["id"])
		var value: Variant = target.get_parameter(parameter_id)
		var control: Dictionary = field_controls[parameter_id]
		match str(control["kind"]):
			"bool":
				var toggle: CheckButton = control["input"]
				toggle.set_pressed_no_signal(bool(value))
				toggle.text = "TRUE" if bool(value) else "FALSE"
			"range":
				var slider: HSlider = control["input"]
				slider.set_value_no_signal(float(value))
				_set_range_display(parameter_id, float(value), control["display"])
			"color":
				var picker: OptionButton = control["input"]
				for i in range(PALETTE.size()):
					if PALETTE[i]["color"] == value:
						picker.select(i)
						break
	syncing = false
	visible = true


func _unhandled_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		closed.emit()


func _label(parent: Node, content: String, font_size: int) -> Label:
	var result := Label.new()
	result.text = content
	result.add_theme_color_override("font_color", Color("e9e2fc"))
	result.add_theme_font_size_override("font_size", font_size)
	parent.add_child(result)
	return result


func _set_range_display(parameter_id: String, value: float, output: Label) -> void:
	if parameter_id == "health":
		output.text = str(int(value))
	else:
		output.text = "%.1f" % value


func _on_hints_toggled(enabled: bool) -> void:
	show_hints = enabled
	hints_toggle.text = "SHOW_HINTS: TRUE" if enabled else "SHOW_HINTS: FALSE"
	for hint in hint_labels:
		hint.visible = enabled


func _on_bool_changed(enabled: bool, parameter_id: String, toggle: CheckButton) -> void:
	if syncing or target == null:
		return
	if target.set_parameter(parameter_id, enabled):
		toggle.text = "TRUE" if enabled else "FALSE"


func _on_range_changed(value: float, parameter_id: String, output: Label) -> void:
	if syncing or target == null:
		return
	if target.set_parameter(parameter_id, value):
		_set_range_display(parameter_id, float(target.get_parameter(parameter_id)), output)


func _on_color_selected(index: int, parameter_id: String) -> void:
	if syncing or target == null:
		return
	if index >= 0 and index < PALETTE.size():
		target.set_parameter(parameter_id, PALETTE[index]["color"])
