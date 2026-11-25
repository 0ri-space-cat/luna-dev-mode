extends Node2D
## Technical forest clearing and the Ancient Console's single command field.

signal command_submitted(command: String, argument: String)

const LOCATION_ID := "ET_FOREST_SERVICE"
const TRAIL := Rect2(2148, 36, 166, 96)
const CLEARING := Rect2(2272, -64, 315, 244)
const DECKS := [TRAIL, CLEARING]
const CONSOLE_BODY := Rect2(2400, 25, 59, 38)
const RETURN_POINT := Vector2(2429, 111)
const REACH := 54.0

var field: LineEdit
var _feedback: Label


func attach_interface(interface: CanvasLayer) -> void:
	field = LineEdit.new()
	field.name = "AncientCommand"
	field.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	field.offset_left = -222
	field.offset_right = 222
	field.offset_top = -20
	field.offset_bottom = 20
	field.max_length = 128
	field.text_submitted.connect(_submit)
	field.gui_input.connect(_handle_key)
	field.hide()
	interface.add_child(field)

	_feedback = Label.new()
	_feedback.name = "AncientCommandFeedback"
	_feedback.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_feedback.offset_left = -222
	_feedback.offset_right = 222
	_feedback.offset_top = 27
	_feedback.offset_bottom = 55
	_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_feedback.hide()
	interface.add_child(_feedback)


func can_interact(feet: Vector2, height: float) -> bool:
	return CLEARING.has_point(feet) and is_zero_approx(height) \
		and feet.distance_squared_to(RETURN_POINT) <= REACH * REACH


func is_open() -> bool:
	return field.visible


func open() -> void:
	field.clear()
	_feedback.hide()
	field.show()
	field.grab_focus()


func close() -> void:
	field.release_focus()
	field.hide()
	_feedback.hide()


func reject() -> void:
	_feedback.text = "Команда не принята"
	_feedback.show()
	field.grab_focus()


func _handle_key(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()


func _submit(source: String) -> void:
	if not is_open():
		return
	var tokens := source.replace("\t", " ").strip_edges().split(" ", false)
	if tokens.size() != 2:
		reject()
		return
	command_submitted.emit(tokens[0], tokens[1])


func _draw() -> void:
	draw_line(Vector2(2150, 84), Vector2(2339, 84), Color("728477"), 20.0, true)
	draw_line(Vector2(2339, 84), RETURN_POINT, Color("728477"), 20.0, true)
	var dais := CONSOLE_BODY.grow(10)
	draw_rect(dais, Color("69736f"))
	draw_rect(CONSOLE_BODY, Color("444052"))
	draw_rect(CONSOLE_BODY.grow(-5), Color("aabeae"), false, 2.0)
	draw_rect(Rect2(CONSOLE_BODY.position + Vector2(10, 6), Vector2(39, 11)), Color("c9ddd3"))
