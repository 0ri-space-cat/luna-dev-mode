extends PanelContainer
## Three views over the same validated scheduler; never executes arbitrary code.
var world
var _targets: OptionButton
var _code: LineEdit
var _programs: VBoxContainer
var _message: Label
var _switch: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	offset_left = -290
	offset_right = 290
	offset_top = -220
	offset_bottom = 220
	var root := VBoxContainer.new()
	add_child(root)
	var title := Label.new()
	title.text = "Ноутбук Юки  /  Библиотека"
	root.add_child(title)
	_targets = OptionButton.new()
	root.add_child(_targets)
	var tabs := TabContainer.new()
	root.add_child(tabs)
	var cards := VBoxContainer.new()
	cards.name = "Карточки"
	tabs.add_child(cards)
	for pair in [["CAT_DENSITY", "EVERY 1 SPAWN CAT"], ["Скорость", "EVERY 5 SET SELF SPEED 0.6"], ["Остановить автономию", "EVERY 5 SET SELF AUTONOMY OFF"], ["Оживить предмет", "EVERY 5 SET SELF IS_ALIVE ON"]]:
		var button := Button.new()
		button.text = pair[0]
		button.pressed.connect(_install.bind(pair[1]))
		cards.add_child(button)
	var map := VBoxContainer.new()
	map.name = "Мир"
	tabs.add_child(map)
	var hint := Label.new()
	hint.text = "Выбери физического носителя рядом с Луной.\nГлобальное правило не привязано к телу."
	map.add_child(hint)
	var refresh := Button.new()
	refresh.text = "Обновить ближайшие тела"
	refresh.pressed.connect(_refresh_targets)
	map.add_child(refresh)
	var code := VBoxContainer.new()
	code.name = "Код"
	tabs.add_child(code)
	_code = LineEdit.new()
	_code.placeholder_text = "EVERY 1 SPAWN CAT"
	code.add_child(_code)
	var add := Button.new()
	add.text = "Установить независимую копию"
	add.pressed.connect(func(): _install(_code.text))
	code.add_child(add)
	_switch = Button.new()
	_switch.pressed.connect(_toggle_running)
	root.add_child(_switch)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 110
	root.add_child(scroll)
	_programs = VBoxContainer.new()
	_programs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_programs)
	_message = Label.new()
	root.add_child(_message)
	var give_back := Button.new()
	give_back.text = "Вернуть Юки (рядом с ней)"
	give_back.pressed.connect(_return_loan)
	root.add_child(give_back)
	var close := Button.new()
	close.text = "Закрыть"
	close.pressed.connect(hide)
	root.add_child(close)
	hide()


func open_for(owner_world: Node) -> void:
	world = owner_world
	_refresh_targets()
	_refresh_rules()
	_message.text = ""
	show()


func _refresh_targets() -> void:
	_targets.clear()
	_targets.add_item("Весь мир")
	_targets.set_item_metadata(0, "")
	for target in world.yuki_nearby_hosts():
		_targets.add_item(target["label"])
		_targets.set_item_metadata(_targets.item_count - 1, target["id"])


func _install(source: String) -> void:
	var host := str(_targets.get_item_metadata(_targets.selected))
	_message.text = "Программа установлена" if world.install_yuki_rule(host, source) else "Операция отклонена"
	_refresh_rules()


func _toggle_running() -> void:
	world.set_yuki_running(not world.yuki.running)
	_refresh_rules()


func _return_loan() -> void:
	if world.return_yuki_loan():
		hide()
	else:
		_message.text = "Подойди к Юки с одолженным ноутбуком"


func _refresh_rules() -> void:
	_switch.text = "Остановить все программы" if world.yuki.running else "Возобновить программы"
	for child in _programs.get_children():
		_programs.remove_child(child)
		child.queue_free()
	for rule in world.yuki.rules:
		var row := HBoxContainer.new()
		_programs.add_child(row)
		var label := Label.new()
		label.text = ("%s  ·  %s" % [rule["host"] if not rule["host"].is_empty() else "Мир", world.yuki.describe(rule)])
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		var toggle := Button.new()
		toggle.text = "Стоп" if rule["enabled"] else "Пуск"
		toggle.pressed.connect(_toggle_rule.bind(int(rule["id"]), not rule["enabled"]))
		row.add_child(toggle)
		var remove := Button.new()
		remove.text = "×"
		remove.pressed.connect(_remove_rule.bind(int(rule["id"])))
		row.add_child(remove)


func _toggle_rule(id: int, enabled: bool) -> void:
	world.yuki.set_enabled(id, enabled)
	_refresh_rules()


func _remove_rule(id: int) -> void:
	world.yuki.remove(id)
	_refresh_rules()
