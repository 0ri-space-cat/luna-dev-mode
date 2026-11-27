extends CanvasLayer

var game
var status := Label.new()
var hint := Label.new()
var panel := PanelContainer.new()
var content := VBoxContainer.new()
var borders: Array[Button] = []

func setup(owner_game) -> void:
	game = owner_game
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(status)
	status.mouse_filter = Control.MOUSE_FILTER_STOP
	status.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and game.bag.has("Цифровой глаз"): game.hud_page())
	status.position = Vector2(22,18)
	status.add_theme_font_size_override("font_size",21)
	add_child(hint)
	hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	hint.offset_left = 22
	hint.offset_top = -76
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for edge in 4:
		var border := Button.new()
		add_child(border)
		border.flat = true
		border.focus_mode = Control.FOCUS_NONE
		border.mouse_default_cursor_shape = Control.CURSOR_CROSS
		border.set_anchors_and_offsets_preset([Control.PRESET_TOP_WIDE,Control.PRESET_BOTTOM_WIDE,Control.PRESET_LEFT_WIDE,Control.PRESET_RIGHT_WIDE][edge])
		match edge:
			0: border.offset_bottom = 8
			1: border.offset_top = -8
			2: border.offset_right = 8
			3: border.offset_left = -8
		border.pressed.connect(game.touch_frame)
		borders.append(border)
	add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -255
	panel.offset_right = 255
	panel.offset_top = -240
	panel.offset_bottom = 240
	var margin := MarginContainer.new()
	panel.add_child(margin)
	for side in ["left","right","top","bottom"]:
		margin.add_theme_constant_override("margin_"+side,18)
	var scroll := ScrollContainer.new()
	margin.add_child(scroll)
	scroll.add_child(content)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.hide()

func page(title: String) -> void:
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()
	get_tree().paused = true
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -255
	panel.offset_right = 255
	panel.offset_top = -240
	panel.offset_bottom = 240
	panel.show()
	var heading := Label.new()
	heading.text = title
	heading.add_theme_font_size_override("font_size",25)
	content.add_child(heading)

func dialogue_page(title: String, text: String) -> void:
	page(title)
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left = 32
	panel.offset_right = -32
	panel.offset_top = -230
	panel.offset_bottom = -24
	words(text)

func close() -> void:
	panel.hide()
	get_tree().paused = false
	get_viewport().gui_release_focus()

func words(message: String) -> void:
	var label := Label.new()
	label.text = message
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(label)

func button(title: String, action: Callable) -> Button:
	var control := Button.new()
	control.text = title
	control.pressed.connect(action)
	content.add_child(control)
	return control

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		if game.started and panel.visible: close()
		else: game.menu()

func field(parent: Container, spec: Dictionary, current: Variant, commit: Callable) -> void:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var name_label := Label.new()
	name_label.text = str(spec.label)
	name_label.tooltip_text = str(spec.get("hint_en",spec.get("hint","")))
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)
	match str(spec.kind):
		"bool":
			var toggle := CheckButton.new()
			toggle.button_pressed = bool(current)
			row.add_child(toggle)
			toggle.toggled.connect(commit)
		"int","float":
			var number := SpinBox.new()
			number.min_value = spec.get("min",0)
			number.max_value = spec.get("max",100)
			number.step = spec.get("step",1)
			number.value = float(current)
			row.add_child(number)
			number.value_changed.connect(func(v): commit.call(int(v) if spec.kind == "int" else v))
		"enum":
			var choices := OptionButton.new()
			for choice in spec.choices:
				choices.add_item(str(choice.name))
				if choice.value == current: choices.select(choices.item_count-1)
			row.add_child(choices)
			choices.item_selected.connect(func(i): commit.call(spec.choices[i].value))
		"color":
			var picker := ColorPickerButton.new()
			picker.custom_minimum_size.x = 78
			picker.color = current
			row.add_child(picker)
			picker.color_changed.connect(commit)
