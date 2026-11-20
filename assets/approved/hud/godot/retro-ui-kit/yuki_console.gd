extends PanelContainer
## The host owns the graph and decides if a program can be run.
signal run_requested(source: String)
signal card_requested(id: String)
signal world_requested
signal close_requested

const Retro = preload("res://retro_ui_2d.gd")
const MODES := ["Схема", "Мир", "Код"]
var _data: Dictionary = {}
var _mode := 0
var _layout: VBoxContainer
var _code: CodeEdit
var _source := ""
var _status := ""

func _ready() -> void:
	_layout = VBoxContainer.new()
	_layout.add_theme_constant_override("separation", 7)
	add_child(_layout)
	_rebuild()

func set_program(value: Dictionary) -> void:
	_data = value.duplicate(true)
	_source = str(_data.get("code", ""))
	_status = str(_data.get("status", ""))
	if is_node_ready():
		_rebuild()

func _rebuild() -> void:
	for child in _layout.get_children():
		_layout.remove_child(child)
		child.queue_free()
	_code = null
	add_theme_stylebox_override("panel", Retro.style(Retro.part("yuki", "console_panel"), 8, 12))
	var ink := Color(Retro.INK.yuki)
	var band := PanelContainer.new()
	band.add_theme_stylebox_override("panel", Retro.style(Retro.part("yuki", "title_bar"), 5, 7))
	_layout.add_child(band)
	var heading := HBoxContainer.new()
	band.add_child(heading)
	var title := Retro.label("КОНСОЛЬ ЮКИ", ink, 16)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(title)
	var close := Retro.button("yuki", "X")
	close.pressed.connect(func() -> void:
		hide()
		close_requested.emit())
	heading.add_child(close)
	var modes := HBoxContainer.new()
	_layout.add_child(modes)
	for i in range(MODES.size()):
		var button := Retro.button("yuki", MODES[i], i == _mode)
		button.pressed.connect(_set_mode.bind(i))
		modes.add_child(button)

	var workspace := VBoxContainer.new()
	workspace.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_layout.add_child(workspace)
	if _mode == 0:
		var scroll := ScrollContainer.new()
		scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		workspace.add_child(scroll)
		var cards := HBoxContainer.new()
		cards.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		scroll.add_child(cards)
		for entry in _data.get("cards", []):
			if cards.get_child_count() > 0:
				cards.add_child(Retro.label(">", ink))
			var card := Retro.button("yuki", str(entry.get("type", "")) + "\n" + str(entry.get("title", "")))
			card.custom_minimum_size = Vector2(156, 74)
			card.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			card.pressed.connect(card_requested.emit.bind(str(entry.get("id", ""))))
			cards.add_child(card)
	elif _mode == 1:
		workspace.add_child(Retro.label(str(_data.get("target_caption", "Укажите объект в мире")), ink))
		var choose := Retro.button("yuki", "Выбрать цель")
		choose.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		choose.pressed.connect(world_requested.emit)
		workspace.add_child(choose)
	else:
		_code = CodeEdit.new()
		_code.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_code.custom_minimum_size.y = 120
		_code.gutters_draw_line_numbers = true
		_code.add_theme_font_override("font", Retro.FONT)
		_code.add_theme_font_size_override("font_size", 12)
		_code.add_theme_color_override("font_color", ink)
		_code.add_theme_stylebox_override("normal", Retro.style(Retro.part("yuki", "field_normal"), 5, 8))
		_code.text = _source
		workspace.add_child(_code)
	var footer := HBoxContainer.new()
	_layout.add_child(footer)
	var status := Retro.label(_status, ink, 10)
	status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	footer.add_child(status)
	var run := Retro.button("yuki", "Запустить", true)
	run.pressed.connect(func() -> void:
		_remember_code()
		run_requested.emit(_source))
	footer.add_child(run)

func _remember_code() -> void:
	if is_instance_valid(_code):
		_source = _code.text

func _set_mode(index: int) -> void:
	_remember_code()
	_mode = index
	_rebuild()
