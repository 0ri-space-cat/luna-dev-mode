extends PanelContainer
## Technical profile preview. No character assets, changes to the live Entity
## or privilege escalation during preview. Host revalidates every confirmation.
const Profiles = preload("res://scripts/skeleton/hero_profile_2d.gd")
var preview_id := ""
var _active_id := ""
var _available: Array[String] = []
var _commit: Callable
var _description: Label
var _apply: Button
var _choices: Dictionary = {}


func configure(available_ids: Array[String], active_id: String, commit: Callable) -> void:
	_available.assign(available_ids)
	_active_id = active_id
	_commit = commit
	_choices.clear()
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var box := VBoxContainer.new()
	add_child(box)
	var heading := Label.new()
	heading.text = "Профиль"
	box.add_child(heading)
	for id in _available:
		var button := Button.new()
		button.text = Profiles.NAMES[id]
		button.toggle_mode = true
		button.pressed.connect(preview_profile.bind(id))
		_choices[id] = button
		box.add_child(button)
	_description = Label.new()
	_description.custom_minimum_size.x = 260.0
	_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_description)
	_apply = Button.new()
	_apply.text = "Применить"
	_apply.pressed.connect(confirm_preview)
	box.add_child(_apply)
	var close := Button.new()
	close.text = "Закрыть"
	close.pressed.connect(hide)
	box.add_child(close)
	preview_profile(active_id)
	show()


func preview_profile(id: String) -> bool:
	if id not in _available or not is_instance_valid(_description):
		return false
	preview_id = id
	_description.text = Profiles.NAMES[id] + "\n" + Profiles.DESCRIPTIONS[id]
	for choice in _choices:
		(_choices[choice] as Button).set_pressed_no_signal(choice == id)
	_apply.disabled = id == _active_id
	return true


func confirm_preview() -> bool:
	if not visible or preview_id == _active_id or preview_id not in _available or not _commit.is_valid():
		return false
	if not _commit.call(preview_id):
		return false
	hide()
	return true
