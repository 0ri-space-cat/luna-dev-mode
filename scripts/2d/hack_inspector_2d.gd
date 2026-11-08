extends PanelContainer
## Fictional visual editor; actual keys and actions are validated by HackSession2D.
signal save_requested
signal copy_requested(actor: Node)
signal delete_requested(actor: Node)
const Profiles = preload("res://scripts/2d/character_ui_profile.gd")
const PANEL_WIDTH := 390.0
const PANEL_HEIGHT := 610.0
var copy_button: Button
var delete_button: Button
var save_button: Button
var confirmation: ConfirmationDialog
var target: Node
var processor
var registry
var hack_session
var rows: VBoxContainer
var heading: Label
var access_caption: Label
var status_caption: Label
var tab_buttons: HBoxContainer
var active_tab := "ALL"
const GROUPS := {"ALL": "Всё", "GENERAL": "Общее", "APPEARANCE": "Облик", "BEHAVIOR": "Поведение", "OTHER": "Свойства"}

func _ready() -> void:
	custom_minimum_size = Vector2(PANEL_WIDTH, PANEL_HEIGHT)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#292044")
	style.border_color = Color("#d46eff")
	style.set_border_width_all(3)
	style.set_corner_radius_all(0) # Crisp inspector frame, not a rounded level-editor card.
	style.shadow_color = Color("#bd64ed",0.35)
	style.shadow_size = 10
	style.set_content_margin_all(14)
	add_theme_stylebox_override("panel", style)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 9)
	add_child(outer)
	heading = Label.new()
	heading.add_theme_color_override("font_color", Color("#fff2ff"))
	heading.add_theme_font_size_override("font_size", 21)
	outer.add_child(heading)
	access_caption = Label.new()
	access_caption.add_theme_color_override("font_color", Color("#76e9ef"))
	outer.add_child(access_caption)
	tab_buttons = HBoxContainer.new()
	outer.add_child(tab_buttons)
	for group in GROUPS.keys():
		var button := Button.new()
		button.text = str(GROUPS[group])
		button.add_theme_font_size_override("font_size",12)
		_style_button(button)
		button.pressed.connect(_switch_tab.bind(str(group)))
		tab_buttons.add_child(button)
	var scroller := ScrollContainer.new()
	scroller.custom_minimum_size = Vector2(326, 350)
	scroller.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(scroller)
	rows = VBoxContainer.new()
	rows.custom_minimum_size.x = 312 # Parameter rows remain a single vertical list.
	rows.add_theme_constant_override("separation", 8)
	scroller.add_child(rows)
	status_caption = Label.new()
	status_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_caption.add_theme_color_override("font_color", Color("#ffd98d"))
	outer.add_child(status_caption)
	var footer := HBoxContainer.new()
	outer.add_child(footer)
	copy_button = Button.new()
	copy_button.text = ""
	copy_button.tooltip_text = "Копировать объект"
	copy_button.custom_minimum_size.x = 42
	copy_button.icon = load("res://assets/2d/ui/icons/copy.svg")
	copy_button.pressed.connect(func() -> void:
		if is_instance_valid(target):
			copy_requested.emit(target))
	footer.add_child(copy_button)
	_style_button(copy_button)
	delete_button = Button.new()
	delete_button.text = ""
	delete_button.tooltip_text = "Удалить объект"
	delete_button.custom_minimum_size.x = 42
	delete_button.icon = load("res://assets/2d/ui/icons/delete.svg")
	delete_button.pressed.connect(func() -> void: confirmation.popup_centered())
	footer.add_child(delete_button)
	_style_button(delete_button)
	confirmation = ConfirmationDialog.new()
	confirmation.title = "Удалить сущность?"
	confirmation.dialog_text = "Удалить выбранный объект? Действие можно отменить клавишей Z."
	confirmation.confirmed.connect(func() -> void:
		if is_instance_valid(target):
			delete_requested.emit(target))
	add_child(confirmation)
	save_button = Button.new()
	save_button.text = "Сохранить"
	save_button.tooltip_text = "Сохранить мир сейчас"
	save_button.icon = load("res://assets/ui/hack/icons/save.svg")
	save_button.pressed.connect(_request_save)
	footer.add_child(save_button)
	_style_button(save_button)
	save_button.expand_icon = false
	var close_button := Button.new()
	close_button.text = "Закрыть"
	close_button.icon = load("res://assets/2d/ui/icons/done.svg")
	close_button.pressed.connect(hide)
	footer.add_child(close_button)
	_style_button(close_button)
	hide()

func _request_save() -> void:
	save_requested.emit()

func open_actor(actor: Node, commands, parameters, session) -> void:
	target = actor
	processor = commands
	registry = parameters
	hack_session = session
	active_tab = "ALL"
	_refresh()
	show()

func _switch_tab(tab: String) -> void:
	active_tab = tab
	_refresh()

func _group_for(spec: Dictionary) -> String:
	var tab := str(spec.get("tab", "GENERAL"))
	if tab == "GENERAL":
		return "GENERAL"
	if tab == "APPEARANCE":
		return "APPEARANCE"
	if tab == "BEHAVIOR":
		return "BEHAVIOR"
	return "OTHER"

func _refresh() -> void:
	if not is_instance_valid(target) or registry == null or hack_session == null:
		return
	heading.text = "%s  •  %s" % [target.record.display_name, target.record.id]
	access_caption.text = "Доступ: " + ("АРХИТЕКТОР" if hack_session.wand["ACCESS_TIER"] == "ARCHITECT" else "ШАЛОСТИ")
	copy_button.disabled = not hack_session.can_action("COPY")
	delete_button.disabled = not hack_session.can_action("DELETE")
	status_caption.text = "Глубокие руны переводит Глаз Оракула." if not hack_session.oracle_eye_equipped else "Изменения применяются сразу."
	for child in rows.get_children():
		rows.remove_child(child)
		child.queue_free()
	var count := 0
	for group in ["GENERAL", "APPEARANCE", "BEHAVIOR", "OTHER"]:
		if active_tab != "ALL" and active_tab != group:
			continue
		var heading_added := false
		for spec in registry.get_specs_for(target.record.category):
			var key := str(spec["id"])
			if _group_for(spec) != group or not hack_session.can_edit(key):
				continue
			if active_tab == "ALL" and not heading_added:
				var category := Label.new()
				category.text = str(GROUPS.get(group, "Свойства")).to_upper()
				category.add_theme_font_size_override("font_size", 12)
				category.add_theme_color_override("font_color", Color("#85e0ef"))
				rows.add_child(category)
				heading_added = true
			count += 1
			_add_parameter(spec)
	if count == 0:
		var note := Label.new()
		note.text = "Пока здесь пусто. Возможно, палочке нужно больше возможностей."
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		rows.add_child(note)

func _add_parameter(spec: Dictionary) -> void:
	var key := str(spec["id"])
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 7)
	rows.add_child(line)
	var caption := Label.new()
	caption.text = hack_session.machine_label(key, str(spec["label"]))
	caption.tooltip_text = str(spec.get("hint", ""))
	caption.custom_minimum_size.x = 120
	caption.clip_text = true
	caption.add_theme_color_override("font_color", Color("#eee0ff"))
	line.add_child(caption)
	match str(spec["kind"]):
		"bool":
			var toggle := CheckButton.new()
			toggle.button_pressed = bool(target.get_parameter(key))
			toggle.toggled.connect(_on_value.bind(key))
			line.add_child(toggle)
		"color":
			var picker := ColorPickerButton.new()
			picker.color = target.get_parameter(key)
			picker.custom_minimum_size = Vector2(110,28)
			picker.color_changed.connect(_on_value.bind(key))
			line.add_child(picker)
		"enum":
			var options: Array = spec["choices"]
			var select := OptionButton.new()
			select.custom_minimum_size.x = 136
			for i in range(options.size()):
				select.add_item(str(options[i]["name"]))
				if str(options[i]["value"]) == str(target.get_parameter(key)):
					select.select(i)
			select.item_selected.connect(_on_choice.bind(key, options))
			line.add_child(select)
		_:
			var slider := HSlider.new()
			slider.custom_minimum_size.x = 108
			slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			slider.min_value = float(spec["min"])
			slider.max_value = float(spec["max"])
			slider.step = float(spec["step"])
			slider.value = float(target.get_parameter(key))
			var value_text := Label.new()
			value_text.custom_minimum_size.x = 39
			value_text.text = ("%.1f" % float(slider.value)) if str(spec["kind"]) != "int" else str(int(slider.value))
			slider.value_changed.connect(func(v: float) -> void:
				value_text.text = ("%.1f" % v) if str(spec["kind"]) != "int" else str(int(v))
				_on_slider(v, key, str(spec["kind"])))
			line.add_child(slider)
			line.add_child(value_text)

func _on_slider(value: float, key: String, kind: String) -> void:
	_on_value(int(value) if kind == "int" else value, key)

func _on_choice(index: int, key: String, options: Array) -> void:
	if index >= 0 and index < options.size():
		_on_value(options[index]["value"], key)

func _on_value(value: Variant, key: String) -> void:
	if not is_instance_valid(target) or not hack_session.edit(target, key, value, processor):
		status_caption.text = "Это свойство пока недоступно."

func set_character_theme(character_id: String) -> void:
	var profile: Dictionary = Profiles.get_profile(character_id)
	var style: StyleBoxFlat = get_theme_stylebox("panel") as StyleBoxFlat
	if style != null:
		style.border_color = profile["accent"]
		style.bg_color = Color("#26203c").lerp(profile["accent"], 0.10)
		queue_redraw()

func _style_button(button: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#382854")
	normal.border_color = Color("#ac76df")
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(6)
	normal.set_content_margin_all(6)
	var hovered := normal.duplicate() as StyleBoxFlat
	hovered.bg_color = Color("#69448d")
	hovered.border_color = Color("#e9b2fb")
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("#8650aa")
	button.custom_minimum_size.y = 38
	button.expand_icon = true
	button.add_theme_stylebox_override("normal",normal)
	button.add_theme_stylebox_override("hover",hovered)
	button.add_theme_stylebox_override("pressed",pressed)
	button.add_theme_color_override("font_color",Color("#f7eaff"))
	button.add_theme_color_override("font_hover_color",Color("#fff5ff"))
