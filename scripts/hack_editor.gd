extends PanelContainer
## Small, automatically populated GUI for the first five supported parameters.
## It lives in an always-processing CanvasLayer so the world can be paused.

signal closed

const PALETTE = [
	{"label": "Сиреневый", "value": Color("b790dd")},
	{"label": "Мятный", "value": Color("8ed7bd")},
	{"label": "Розовый", "value": Color("f49fc9")},
	{"label": "Голубой", "value": Color("87bfe8")},
	{"label": "Персиковый", "value": Color("efb68e")},
	{"label": "Тёмно-фиолетовый", "value": Color("684a96")}
]

var target
var syncing := false
var title_label: Label
var status_label: Label
var color_options: OptionButton
var size_slider: HSlider
var size_value: Label
var speed_slider: HSlider
var speed_value: Label
var health_slider: HSlider
var health_value: Label
var alive_toggle: CheckButton


func _ready() -> void:
	anchor_left = 1.0
	anchor_right = 1.0
	anchor_top = 0.0
	anchor_bottom = 0.0
	offset_left = -370.0
	offset_right = -22.0
	offset_top = 24.0
	offset_bottom = 558.0
	mouse_filter = Control.MOUSE_FILTER_STOP
	var styling := StyleBoxFlat.new()
	styling.bg_color = Color("25213b")
	styling.border_color = Color("7be4e6")
	styling.set_border_width_all(2)
	styling.set_corner_radius_all(14)
	styling.set_content_margin_all(18)
	add_theme_stylebox_override("panel", styling)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	add_child(column)

	title_label = _label(column, "ПАРАМЕТРЫ", 22)
	_label(column, "Взлом • Луна Селестис", 13)
	column.add_child(HSeparator.new())
	_label(column, "Цвет объекта", 16)
	color_options = OptionButton.new()
	for item in PALETTE:
		color_options.add_item(item["label"])
	column.add_child(color_options)
	color_options.item_selected.connect(_on_color_selected)

	var size_group := _make_slider(column, "Размер", 0.5, 2.0, 0.1)
	size_slider = size_group[0]
	size_value = size_group[1]
	size_slider.value_changed.connect(_on_size_changed)

	var health_group := _make_slider(column, "Здоровье", 1.0, 200.0, 1.0)
	health_slider = health_group[0]
	health_value = health_group[1]
	health_slider.value_changed.connect(_on_health_changed)

	alive_toggle = CheckButton.new()
	alive_toggle.text = "Оживить предмет"
	column.add_child(alive_toggle)
	alive_toggle.toggled.connect(_on_alive_toggled)

	var speed_group := _make_slider(column, "Скорость движения", 0.0, 5.0, 0.1)
	speed_slider = speed_group[0]
	speed_value = speed_group[1]
	speed_slider.value_changed.connect(_on_speed_changed)

	column.add_child(HSeparator.new())
	status_label = _label(column, "", 13)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var close_button := Button.new()
	close_button.text = "Применить и закрыть    [Esc]"
	column.add_child(close_button)
	close_button.pressed.connect(func() -> void: closed.emit())
	visible = false


func show_for(entity: Node3D) -> void:
	target = entity
	syncing = true
	title_label.text = str(target.record.display_name).to_upper()
	var tint: Color = target.get_parameter("color")
	for i in range(PALETTE.size()):
		if PALETTE[i]["value"] == tint:
			color_options.select(i)
			break
	size_slider.value = float(target.get_parameter("size"))
	health_slider.value = float(target.get_parameter("health"))
	alive_toggle.button_pressed = bool(target.get_parameter("alive"))
	speed_slider.value = float(target.get_parameter("speed"))
	syncing = false
	_refresh_values()
	visible = true


func _unhandled_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		closed.emit()


func _label(parent: VBoxContainer, content: String, font_size: int) -> Label:
	var result := Label.new()
	result.text = content
	result.add_theme_color_override("font_color", Color("e9e2fc"))
	result.add_theme_font_size_override("font_size", font_size)
	parent.add_child(result)
	return result


func _make_slider(parent: VBoxContainer, heading: String, minimum: float, maximum: float, increment: float) -> Array:
	var line := HBoxContainer.new()
	parent.add_child(line)
	var text_label := _label(line, heading, 15)
	text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var number := _label(line, "", 15)
	var slider := HSlider.new()
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = increment
	parent.add_child(slider)
	return [slider, number]


func _refresh_values() -> void:
	if target == null:
		return
	size_value.text = "%.1f×" % float(target.get_parameter("size"))
	health_value.text = str(target.get_parameter("health"))
	speed_value.text = "%.1f" % float(target.get_parameter("speed"))
	status_label.text = "Категория: %s | ID: %s\n%s" % [
		target.record.category,
		target.record.id,
		"Живёт своей жизнью!" if bool(target.get_parameter("alive")) else "Пока обычный предмет"
	]


func _on_color_selected(index: int) -> void:
	if syncing or target == null:
		return
	target.set_parameter("color", PALETTE[index]["value"])


func _on_size_changed(value: float) -> void:
	if syncing or target == null:
		return
	target.set_parameter("size", value)
	_refresh_values()


func _on_health_changed(value: float) -> void:
	if syncing or target == null:
		return
	target.set_parameter("health", int(value))
	_refresh_values()


func _on_alive_toggled(enabled: bool) -> void:
	if syncing or target == null:
		return
	target.set_parameter("alive", enabled)
	_refresh_values()


func _on_speed_changed(value: float) -> void:
	if syncing or target == null:
		return
	target.set_parameter("speed", value)
	_refresh_values()
