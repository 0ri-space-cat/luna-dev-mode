extends PanelContainer
## Shared mixer model; effects are dispatched by the world, not by the UI.
signal try_effect(effect_id: String)
signal fill_effect(effect_id: String)
signal borrow_requested
const Recipes = preload("res://scripts/runtime2d/alchemy_recipes_2d.gd")
const IMPLEMENTED := ["ALC-R08", "ALC-R09", "ALC-R20", "ALC-R21", "ALC-R30"]
var selected: Array[String] = []
var _buttons: Dictionary = {}
var _result: Label
var _try: Button
var _effect := ""
var _fill: Button
var _borrow: Button
var _portable := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	offset_left = -220
	offset_right = 220
	offset_top = -180
	offset_bottom = 180
	var content := VBoxContainer.new()
	add_child(content)
	var title := Label.new()
	title.text = "Алхимическая установка"
	content.add_child(title)
	var grid := GridContainer.new()
	grid.columns = 3
	content.add_child(grid)
	for element in Recipes.ELEMENTS:
		var button := Button.new()
		button.text = element
		button.toggle_mode = true
		button.toggled.connect(_select.bind(element))
		grid.add_child(button)
		_buttons[element] = button
	var mix := Button.new()
	mix.text = "Смешать"
	mix.pressed.connect(_mix)
	content.add_child(mix)
	_result = Label.new()
	_result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_result)
	_try = Button.new()
	_try.text = "Испытать на себе"
	_try.disabled = true
	_try.pressed.connect(func(): try_effect.emit(_effect))
	content.add_child(_try)
	_fill = Button.new()
	_fill.text = "Заполнить склянку"
	_fill.disabled = true
	_fill.pressed.connect(func(): fill_effect.emit(_effect))
	content.add_child(_fill)
	_borrow = Button.new()
	_borrow.text = "Одолжить склянку Мии"
	_borrow.pressed.connect(func(): borrow_requested.emit())
	content.add_child(_borrow)
	configure_access(false, false, false)
	var close := Button.new()
	close.text = "Закрыть"
	close.pressed.connect(hide)
	content.add_child(close)
	hide()


func configure_access(portable: bool, has_flask: bool, can_borrow: bool) -> void:
	_portable = portable
	_try.visible = not portable
	_fill.visible = has_flask
	_borrow.visible = can_borrow


func _select(enabled: bool, element: String) -> void:
	if enabled:
		if selected.size() >= 3:
			_buttons[element].set_pressed_no_signal(false)
			return
		selected.append(element)
	else:
		selected.erase(element)
	_effect = ""
	_result.text = ""
	_try.disabled = true
	_fill.disabled = true


func _mix() -> void:
	_effect = Recipes.resolve(selected)
	_result.text = Recipes.NAMES.get(_effect, "Нет известной реакции") if not selected.is_empty() else "Выбери 1–3 элемента"
	_try.disabled = _effect not in IMPLEMENTED
	_fill.disabled = _effect not in IMPLEMENTED
