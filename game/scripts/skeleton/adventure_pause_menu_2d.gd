extends CanvasLayer
## The ordinary game menu. The recoverable in-world pauses remain separate.

var _root: Control
var _status: Label
var _continue: Button
var _frame: CheckButton
var _save: Callable
var _load: Callable
var _set_mode: Callable


func setup(save: Callable, load_game: Callable, set_mode: Callable) -> void:
	_save = save
	_load = load_game
	_set_mode = set_mode
	layer = 8
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED

	_root = Control.new()
	add_child(_root)
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = Color(0.08, 0.06, 0.13, 0.65)
	_root.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	_root.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var margin := MarginContainer.new()
	for edge in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 24)
	panel.add_child(margin)
	var stack := VBoxContainer.new()
	stack.custom_minimum_size.x = 250
	stack.add_theme_constant_override("separation", 10)
	margin.add_child(stack)

	_continue = _button(stack, "Продолжить", close)
	_button(stack, "Сохранить", _save_pressed)
	_button(stack, "Загрузить", _load_pressed)
	_frame = CheckButton.new()
	_frame.text = "Игровая рамка"
	_frame.toggled.connect(_frame_pressed)
	stack.add_child(_frame)
	_status = Label.new()
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(_status)
	_root.hide()


func open(mode: String, can_toggle_mode: bool) -> void:
	_frame.set_pressed_no_signal(mode == "WINDOWED")
	_frame.disabled = not can_toggle_mode
	_status.text = ""
	get_tree().paused = true
	_root.show()
	_continue.grab_focus()


func close() -> void:
	_root.hide()
	get_tree().paused = false


func _input(event: InputEvent) -> void:
	if not _root.visible or not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func _button(parent: Control, label: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = label
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _save_pressed() -> void:
	_status.text = "Сохранено" if _save.call() else "Сохранение недоступно"


func _load_pressed() -> void:
	get_tree().paused = false
	if _load.call():
		_root.hide()
	else:
		get_tree().paused = true
		_status.text = "Загрузка недоступна"


func _frame_pressed(enabled: bool) -> void:
	if not _set_mode.call("WINDOWED" if enabled else "FULLSCREEN"):
		_frame.set_pressed_no_signal(not enabled)
