extends PanelContainer
## The text is a draft until the same type-checked profile accepts it.

const Profile = preload("res://scripts/runtime2d/consumable_profile_2d.gd")

var _profile: Dictionary
var _food := false
var _commit: Callable
var _title: Label
var _tabs: TabContainer
var _fields: VBoxContainer
var _code: TextEdit
var _message: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	offset_left = -220
	offset_right = 220
	offset_top = -195
	offset_bottom = 195
	var frame := StyleBoxFlat.new()
	frame.bg_color = Color("272335")
	frame.border_color = Color("60566f")
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		frame.set_border_width(side, 1)
		frame.set_content_margin(side, 12.0)
	add_theme_stylebox_override("panel", frame)
	var content := VBoxContainer.new()
	add_child(content)
	_title = Label.new()
	content.add_child(_title)
	_tabs = TabContainer.new()
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(_tabs)
	var scroll := ScrollContainer.new()
	scroll.name = "Параметры"
	_tabs.add_child(scroll)
	_fields = VBoxContainer.new()
	_fields.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_fields)
	var code_page := VBoxContainer.new()
	code_page.name = "Код"
	_tabs.add_child(code_page)
	_code = TextEdit.new()
	_code.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_code.custom_minimum_size.y = 190
	code_page.add_child(_code)
	var code_buttons := HBoxContainer.new()
	code_page.add_child(code_buttons)
	_add_button(code_buttons, "Применить", _apply_code)
	_add_button(code_buttons, "Отменить правку", _reset_text)
	_message = Label.new()
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_message)
	_add_button(content, "Закрыть", hide)
	_tabs.tab_changed.connect(_tab_changed)
	hide()


func open_profile(title: String, profile: Dictionary, food: bool, commit: Callable) -> void:
	_title.text = title
	_profile = profile.duplicate(true)
	_food = food
	_commit = commit
	_reset_text()
	_render_fields()
	_tabs.current_tab = 0
	show()


func _add_button(parent: Control, title: String, action: Callable) -> void:
	var button := Button.new()
	button.text = title
	button.pressed.connect(action)
	parent.add_child(button)


func _reset_text() -> void:
	_code.text = Profile.format(_profile)
	_message.text = ""


func _tab_changed(index: int) -> void:
	if index != 0 or _code.text == Profile.format(_profile):
		return
	if not _apply_code():
		_tabs.set_deferred("current_tab", 1)


func _apply_code() -> bool:
	var result := Profile.parse(_code.text, _food)
	if result.has("error"):
		_message.text = result["error"]
		return false
	if not _accept(result["profile"]):
		return false
	_render_fields()
	return true


func _accept(candidate: Dictionary) -> bool:
	if not _commit.is_valid() or not _commit.call(candidate):
		_message.text = "Запись недоступна для этого расходника"
		return false
	_profile = candidate
	_reset_text()
	return true


func _render_fields() -> void:
	for child in _fields.get_children():
		_fields.remove_child(child)
		child.queue_free()
	if _food:
		var edible := CheckButton.new()
		edible.text = "EDIBLE"
		edible.button_pressed = _profile["edible"]
		edible.toggled.connect(_edit_food_field.bind("edible"))
		_fields.add_child(edible)
		var row := _field_row("PORTIONS")
		_add_number(row, _profile["portions"], 0, 16, _edit_food_field.bind("portions"))
	var effects: Array = _profile["effects"]
	if effects.is_empty():
		var empty := Label.new()
		empty.text = "Эффектов нет"
		_fields.add_child(empty)
	for index in effects.size():
		var effect: Dictionary = effects[index]
		var spec: Dictionary = Profile.EFFECTS[effect["id"]]
		var label: String = effect["id"]
		if effect.has("value"):
			label += " · " + spec["argument"]
		var row := _field_row(label)
		if effect.has("value"):
			_add_number(row, effect["value"], 1, spec["max"], _edit_amount.bind(index))
		_add_button(row, "Убрать", _remove_effect.bind(index))


func _field_row(title: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = title
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	_fields.add_child(row)
	return row


func _add_number(row: HBoxContainer, initial: int, low: int, high: int, changed: Callable) -> void:
	var input := SpinBox.new()
	input.min_value = low
	input.max_value = high
	input.step = 1
	input.value = initial
	input.value_changed.connect(changed)
	row.add_child(input)


func _edit_food_field(value: Variant, key: String) -> void:
	var candidate := _profile.duplicate(true)
	candidate[key] = int(value) if key == "portions" else value
	if not _accept(candidate):
		_render_fields()


func _edit_amount(value: float, index: int) -> void:
	var candidate := _profile.duplicate(true)
	candidate["effects"][index]["value"] = int(value)
	if not _accept(candidate):
		_render_fields()


func _remove_effect(index: int) -> void:
	var candidate := _profile.duplicate(true)
	candidate["effects"].remove_at(index)
	if _accept(candidate):
		_render_fields()
