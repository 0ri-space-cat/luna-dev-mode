extends PanelContainer
## Visual component. The host supplies data and handles all edit and save requests.
signal parameter_requested(key: String, value: Variant)
signal save_requested
signal copy_requested
signal delete_requested
signal close_requested

const Retro = preload("res://retro_ui_2d.gd")
const TABS := [
	["general", "Общее"], ["appearance", "Облик"], ["physics", "Физика"],
	["mind", "Разум"], ["behavior", "Поведение"], ["relationships", "Отношения"],
	["abilities", "Способности"]
]

var _theme_id := "luna"
var _active_tab := 0
var _object: Dictionary = {}
var _specs: Array = []
var _body: VBoxContainer
var _toast: PanelContainer
var _timer: Timer

func _ready() -> void:
	var pixel := Theme.new()
	pixel.default_font = Retro.FONT
	pixel.default_font_size = 12
	theme = pixel
	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 6)
	add_child(_body)
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.timeout.connect(func() -> void:
		if is_instance_valid(_toast):
			_toast.hide())
	add_child(_timer)
	_rebuild()

func set_character_theme(id: String) -> void:
	_theme_id = Retro.id_for(id)
	if is_node_ready():
		_rebuild()

func show_object(identity: Dictionary, specs: Array) -> void:
	var previous_id := str(_object.get("id", ""))
	_object = identity.duplicate(true)
	_specs = specs.duplicate(true)
	if previous_id != str(identity.get("id", "")):
		_active_tab = 0
	if is_node_ready():
		_rebuild()

func show_saved() -> void:
	if is_instance_valid(_toast):
		_toast.size = _toast.get_combined_minimum_size()
		var left := global_position.x - _toast.size.x - 8.0
		var at := Vector2(left, global_position.y + 14.0)
		if left < 0.0:
			at = global_position + Vector2(size.x - _toast.size.x - 10.0, 46.0)
		_toast.global_position = at
		_toast.show()
		_timer.start(1.0)

func _part(key: String) -> String:
	return "themes/" + _theme_id + "/" + key

func _ink() -> Color:
	return Color(Retro.INK[_theme_id])

func _dark() -> Color:
	return Color(Retro.DARK_INK[_theme_id])

func _label(value: String, color: Color, size: int = 12) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", size)
	return label

func _panel(parent: Control, part: String, margin: int, padding: int = 4) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", Retro.style(_part(part), margin, padding))
	parent.add_child(panel)
	return panel

func _button(part: String, value: String, icon: String = "", tip: String = "") -> Button:
	var button := Button.new()
	button.text = value
	button.tooltip_text = tip
	button.custom_minimum_size.y = 32
	var common := part.begins_with("common/")
	var tex := part if common else _part(part)
	var hot := tex
	var down := tex
	if common or part == "copy_normal":
		hot = tex.replace("_normal", "_hover")
		down = tex.replace("_normal", "_pressed")
	elif part.begins_with("tab_"):
		hot = _part("tab_hover")
		down = _part("tab_selected")
	elif part == "button_save":
		hot = _part("button_save_hover")
		down = _part("button_save_pressed")
	var states := {"normal": tex, "hover": hot, "pressed": down, "hover_pressed": down}
	for state in states:
		button.add_theme_stylebox_override(state, Retro.style(states[state], 5, 6))
	var focus := StyleBoxFlat.new()
	focus.draw_center = false
	focus.border_color = Color("#fff4b0")
	focus.set_border_width_all(1)
	button.add_theme_stylebox_override("focus", focus)
	var ink := _ink() if part == "toggle_off" or part == "field_normal" else _dark()
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, ink)
	if not icon.is_empty():
		button.icon = Retro.texture("common/" + icon)
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.expand_icon = true
		button.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return button

func _picture(texture: Texture2D, extent: Vector2) -> TextureRect:
	var view := TextureRect.new()
	view.texture = texture
	view.custom_minimum_size = extent
	view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if texture and texture.get_width() > 64:
		view.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return view

func _rebuild() -> void:
	_timer.stop()
	for child in _body.get_children():
		_body.remove_child(child)
		child.queue_free()
	add_theme_stylebox_override("panel", Retro.style(_part("window"), 12, 13))
	var title_bar := HBoxContainer.new()
	_panel(_body, "title_bar", 5).add_child(title_bar)
	var title := _label("LUNA: Dev Mode", _dark(), 16)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var emblem := _picture(Retro.texture("common/map_player"), Vector2(24, 24))
	title_bar.add_child(emblem)
	title_bar.add_child(title)
	for symbol in ["window_minimize", "window_maximize"]:
		var decoration := _panel(title_bar, "tab_normal", 6, 4)
		decoration.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var picture := _picture(Retro.texture("common/" + symbol), Vector2(16, 16))
		decoration.add_child(picture)
	var close := _button("tab_normal", "", "icon_close", "Закрыть")
	close.custom_minimum_size = Vector2(26, 24)
	close.name = "CloseButton"
	close.pressed.connect(_close)
	title_bar.add_child(close)

	var header := HBoxContainer.new()
	_panel(_body, "object_header", 7, 6).add_child(header)
	var picture: Texture2D = _object.get("portrait")
	var avatar := _panel(header, "object_portrait", 6, 2)
	avatar.add_child(_picture(picture, Vector2(66, 66)))
	var name_block := VBoxContainer.new()
	name_block.alignment = BoxContainer.ALIGNMENT_CENTER
	name_block.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(name_block)
	var name_label := _label(str(_object.get("name", "")).to_upper(), _ink(), 20)
	name_label.clip_text = true
	name_block.add_child(name_label)
	var object_id := _label("ID: " + str(_object.get("id", "")), _ink())
	object_id.clip_text = true
	object_id.tooltip_text = object_id.text
	name_block.add_child(object_id)
	var active := bool(_object.get("active", true)) and bool(_object.get("alive", true))
	if active and _object.has("signal_strength"):
		var count := clampi(int(_object["signal_strength"]), 0, 4)
		if count > 0:
			var bars := AtlasTexture.new()
			bars.atlas = Retro.texture("common/signal_4")
			bars.region = Rect2(0, 0, 1 + 3 * (count - 1), 8)
			bars.margin = Rect2(0, 0, 10 - bars.region.size.x, 0)
			header.add_child(_picture(bars, Vector2(20, 16)))
	var indicator := _picture(Retro.texture("common/status_active" if active else "common/status_inactive"), Vector2(14, 14))
	indicator.tooltip_text = "Активен" if active else "Неактивен"
	header.add_child(indicator)

	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 3)
	_body.add_child(tabs)
	for i in range(TABS.size()):
		var tab = TABS[i]
		var button := _button("tab_selected" if i == _active_tab else "tab_normal", "", "tab_" + tab[0], tab[1])
		button.custom_minimum_size.y = 43
		button.add_theme_constant_override("icon_max_width", 28)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_select_tab.bind(i))
		tabs.add_child(button)
	var properties := VBoxContainer.new()
	var section := _panel(_body, "property_panel", 7)
	section.size_flags_vertical = Control.SIZE_EXPAND_FILL
	section.add_child(properties)
	var badge := _panel(properties, "title_bar", 5, 6)
	badge.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	badge.add_child(_label(str(TABS[_active_tab][1]).to_upper(), _dark(), 12))
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size.y = 166
	properties.add_child(scroll)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 1)
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(rows)
	for spec in _specs:
		if str(spec.get("tab", "general")).to_lower() == TABS[_active_tab][0]:
			_add_row(rows, spec)
	if rows.get_child_count() == 0:
		rows.add_child(_label("Нет доступных параметров", _ink()))

	var footer := HBoxContainer.new()
	footer.name = "Actions"
	_body.add_child(footer)
	var copy_skin := "copy_normal" if _theme_id == "luna" else "common/button_copy_normal"
	var copy := _button(copy_skin, "", "icon_copy", "Копировать")
	copy.name = "CopyButton"
	copy.custom_minimum_size = Vector2(44, 40)
	copy.add_theme_constant_override("icon_max_width", 22)
	copy.pressed.connect(func() -> void: copy_requested.emit())
	footer.add_child(copy)
	footer.add_spacer(false)
	var save := _button("button_save", "Сохранить")
	save.name = "SaveButton"
	save.custom_minimum_size = Vector2(190, 40)
	save.add_theme_font_size_override("font_size", 16)
	save.pressed.connect(func() -> void: save_requested.emit())
	footer.add_child(save)
	footer.add_spacer(false)
	var remove := _button("common/button_delete_normal", "", "icon_delete", "Удалить")
	remove.name = "DeleteButton"
	remove.custom_minimum_size = Vector2(44, 40)
	remove.add_theme_constant_override("icon_max_width", 22)
	remove.pressed.connect(func() -> void: delete_requested.emit())
	footer.add_child(remove)
	_toast = _panel(_body, "toast", 6, 8)
	_toast.top_level = true
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var feedback := HBoxContainer.new()
	_toast.add_child(feedback)
	feedback.add_child(_picture(Retro.texture("common/icon_done"), Vector2(12, 12)))
	feedback.add_child(_label("Сохранено", _dark()))
	_toast.hide()

func _select_tab(index: int) -> void:
	_active_tab = index
	_rebuild()

func _add_row(parent: VBoxContainer, spec: Dictionary) -> void:
	var key := str(spec["key"])
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = 27
	row.add_theme_constant_override("separation", 8)
	_panel(parent, "property_row", 2, 2).add_child(row)
	var glyph_key := str(spec.get("glyph", key))
	var icon: Texture2D = spec.get("icon")
	if icon == null and glyph_key in ["health", "alive", "speed", "behavior", "tint"]:
		icon = Retro.texture("common/property_" + glyph_key)
	var glyph := _picture(icon, Vector2(16, 16))
	if not spec.get("icon_color", false):
		glyph.modulate = _ink()
	row.add_child(glyph)
	var label := _label(str(spec.get("label", key.to_upper())), _ink())
	label.clip_text = true
	label.tooltip_text = label.text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var current: Variant = spec.get("value")
	var first_control := row.get_child_count()
	match str(spec.get("kind", "number")):
		"bool":
			var group := ButtonGroup.new()
			for value in [true, false]:
				var button := _button("toggle_off", "TRUE" if value else "FALSE")
				button.custom_minimum_size.y = 26
				for state in ["pressed", "hover_pressed"]:
					button.add_theme_stylebox_override(state, Retro.style(_part("toggle_on"), 5, 6))
				button.add_theme_color_override("font_pressed_color", _dark())
				button.toggle_mode = true
				button.button_group = group
				button.button_pressed = current == value
				button.pressed.connect(_emit_value.bind(key, value))
				row.add_child(button)
		"enum":
			var select := OptionButton.new()
			select.fit_to_longest_item = false
			select.custom_minimum_size.x = 132
			select.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			select.add_theme_color_override("font_color", _ink())
			select.add_theme_stylebox_override("normal", Retro.style(_part("field_normal"), 5))
			var options: Array = spec.get("options", [])
			for value in options:
				select.add_item(str(value))
			select.select(options.find(current))
			select.item_selected.connect(func(index: int) -> void: _emit_value(key, options[index]))
			row.add_child(select)
		"color":
			var picker := ColorPickerButton.new()
			picker.color = current if current is Color else Color.WHITE
			picker.custom_minimum_size = Vector2(25, 22)
			var hue := HSlider.new()
			hue.custom_minimum_size.x = 120
			hue.max_value = 1.0
			hue.step = 0.005
			hue.value = picker.color.h
			hue.add_theme_stylebox_override("slider", Retro.style("common/color_ramp", 0, 4))
			hue.add_theme_stylebox_override("grabber_area", StyleBoxEmpty.new())
			hue.add_theme_stylebox_override("grabber_area_highlight", StyleBoxEmpty.new())
			hue.add_theme_icon_override("grabber", Retro.texture("common/color_thumb"))
			hue.add_theme_icon_override("grabber_highlight", Retro.texture("common/color_thumb"))
			hue.value_changed.connect(func(value: float) -> void:
				var color := Color.from_hsv(value, picker.color.s, picker.color.v, picker.color.a)
				picker.color = color
				_emit_value(key, color))
			picker.color_changed.connect(func(color: Color) -> void:
				hue.set_value_no_signal(color.h)
				_emit_value(key, color))
			row.add_child(hue)
			row.add_child(picker)
		_:
			var field := SpinBox.new()
			field.custom_minimum_size.x = 112
			field.min_value = float(spec.get("min", 0))
			field.max_value = float(spec.get("max", 100))
			field.step = float(spec.get("step", 1))
			field.value = float(current) if current != null else 0.0
			field.get_line_edit().add_theme_color_override("font_color", _ink())
			field.get_line_edit().add_theme_stylebox_override("normal", Retro.style(_part("field_normal"), 5))
			field.value_changed.connect(func(value: float) -> void: _emit_value(key, value))
			row.add_child(field)

	if bool(spec.get("read_only", false)):
		for i in range(first_control, row.get_child_count()):
			var control := row.get_child(i)
			control.mouse_filter = Control.MOUSE_FILTER_IGNORE
			control.focus_mode = Control.FOCUS_NONE
			if control is BaseButton:
				control.disabled = true
			elif control is Slider or control is SpinBox:
				control.editable = false

func _close() -> void:
	hide()
	close_requested.emit()

func _emit_value(key: String, value: Variant) -> void:
	parameter_requested.emit(key, value)
