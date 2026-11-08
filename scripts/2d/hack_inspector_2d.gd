extends PanelContainer
## Fictional visual editor; actual keys and actions are validated by HackSession2D.
signal save_requested
const Profiles = preload("res://scripts/2d/character_ui_profile.gd")
var target: Node
var processor
var registry
var hack_session
var rows: VBoxContainer
var heading: Label
var access_caption: Label
var status_caption: Label
var tab_buttons: HBoxContainer
var active_tab := "GENERAL"
const GROUPS := {"GENERAL": "Общее", "APPEARANCE": "Облик", "BEHAVIOR": "Поведение", "OTHER": "Свойства"}

func _ready() -> void:
	custom_minimum_size = Vector2(410, 430)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#292044")
	style.border_color = Color("#d46eff")
	style.set_border_width_all(3)
	style.set_corner_radius_all(15)
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
		button.pressed.connect(_switch_tab.bind(str(group)))
		tab_buttons.add_child(button)
	var scroller := ScrollContainer.new()
	scroller.custom_minimum_size = Vector2(384, 278)
	scroller.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(scroller)
	rows = VBoxContainer.new()
	rows.custom_minimum_size.x = 370
	rows.add_theme_constant_override("separation", 8)
	scroller.add_child(rows)
	status_caption = Label.new()
	status_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_caption.add_theme_color_override("font_color", Color("#ffd98d"))
	outer.add_child(status_caption)
	var footer := HBoxContainer.new()
	outer.add_child(footer)
	var save_button := Button.new()
	save_button.text = "Сохранить мир"
	save_button.pressed.connect(func() -> void: save_requested.emit())
	footer.add_child(save_button)
	var close_button := Button.new()
	close_button.text = "✓ Закрыть"
	close_button.pressed.connect(hide)
	footer.add_child(close_button)
	hide()

func open_actor(actor: Node, commands, parameters, session) -> void:
	target = actor
	processor = commands
	registry = parameters
	hack_session = session
	active_tab = "GENERAL"
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
	status_caption.text = "Технические символы читает Глаз Оракула." if not hack_session.oracle_eye_equipped else "Выбирай свойства. Изменения происходят сразу."
	for child in rows.get_children():
		rows.remove_child(child)
		child.queue_free()
	var count := 0
	for spec in registry.get_specs_for(target.record.category):
		var key := str(spec["id"])
		if _group_for(spec) != active_tab or not hack_session.can_edit(key):
			continue
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
	caption.custom_minimum_size.x = 148
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
			picker.color_changed.connect(_on_value.bind(key))
			line.add_child(picker)
		"enum":
			var options: Array = spec["choices"]
			var select := OptionButton.new()
			select.custom_minimum_size.x = 148
			for i in range(options.size()):
				select.add_item(str(options[i]["name"]))
				if str(options[i]["value"]) == str(target.get_parameter(key)):
					select.select(i)
			select.item_selected.connect(_on_choice.bind(key, options))
			line.add_child(select)
		_:
			var slider := HSlider.new()
			slider.custom_minimum_size.x = 138
			slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			slider.min_value = float(spec["min"])
			slider.max_value = float(spec["max"])
			slider.step = float(spec["step"])
			slider.value = float(target.get_parameter(key))
			slider.value_changed.connect(_on_slider.bind(key, str(spec["kind"])))
			line.add_child(slider)

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
