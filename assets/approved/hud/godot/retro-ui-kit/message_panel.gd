extends PanelContainer

signal accepted
signal rejected

const Retro = preload("res://retro_ui_2d.gd")
var _id := "luna"
var _body: VBoxContainer

func _ready() -> void:
	_body = VBoxContainer.new()
	add_child(_body)
	hide()

func show_message(id: String, title: String, message: String, action: String = "") -> void:
	_id = Retro.id_for(id)
	add_theme_stylebox_override("panel", Retro.style(Retro.part(_id, "mission_panel"), 6, 10))
	for child in _body.get_children():
		_body.remove_child(child)
		child.queue_free()
	var ink := Color(Retro.INK[_id])
	_body.add_child(Retro.label(title, ink, 14))
	if not message.is_empty():
		var details := Retro.label(message, ink, 12)
		details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		details.custom_minimum_size.x = 260
		_body.add_child(details)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_END
	_body.add_child(buttons)
	if not action.is_empty():
		var accept := Retro.button(_id, action, true)
		buttons.add_child(accept)
		accept.pressed.connect(func() -> void:
			hide()
			accepted.emit())
	var cancel := Retro.button(_id, "Закрыть" if action.is_empty() else "Отмена")
	buttons.add_child(cancel)
	cancel.pressed.connect(func() -> void:
		hide()
		rejected.emit())
	show()
