extends PanelContainer
## Temporary skeleton editor: one companion; no separate bank or editable loyalty.
const Parameters = preload("res://scripts/skeleton/entity_parameters_2d.gd")
var world
var _form: OptionButton
var _color: OptionButton
var _size: HSlider
var _module: OptionButton
var _message: Label
var _bank: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	offset_left = -190
	offset_right = 190
	offset_top = -155
	offset_bottom = 155
	var layout := VBoxContainer.new()
	add_child(layout)
	var title := Label.new()
	title.text = "Тамагочи · спутник Луны"
	layout.add_child(title)
	_form = OptionButton.new()
	_form.add_item("Котик")
	_form.add_item("Лисичка")
	layout.add_child(_form)
	_color = OptionButton.new()
	for choice in Parameters.PALETTE:
		_color.add_item(choice["name"])
	layout.add_child(_color)
	_size = HSlider.new()
	_size.min_value = 0.5
	_size.max_value = 2.0
	_size.step = 0.1
	_size.value = 0.8
	layout.add_child(_size)
	var apply := Button.new()
	apply.text = "Создать / изменить спутника"
	apply.pressed.connect(_apply)
	layout.add_child(apply)
	var toggle := Button.new()
	toggle.text = "Позвать / отозвать"
	toggle.pressed.connect(_toggle)
	layout.add_child(toggle)
	_module = OptionButton.new()
	_module.add_item("GLOW")
	_module.add_item("FLY")
	layout.add_child(_module)
	_bank = Label.new()
	layout.add_child(_bank)
	var install := Button.new()
	install.text = "Установить экземпляр из банка"
	install.pressed.connect(_install)
	layout.add_child(install)
	_message = Label.new()
	layout.add_child(_message)
	var close := Button.new()
	close.text = "Закрыть"
	close.pressed.connect(hide)
	layout.add_child(close)
	hide()


func open_for(owner_world: Node) -> void:
	world = owner_world
	var setup: Dictionary = world.pet_configuration()
	_form.select(1 if setup["form"] == "fox" else 0)
	for index in Parameters.PALETTE.size():
		if Parameters.PALETTE[index]["value"] == setup["color"]:
			_color.select(index)
	_size.value = float(setup["size"])
	_message.text = ""
	_refresh()
	show()


func _refresh() -> void:
	_bank.text = "Общий банк: GLOW %d / FLY %d" % [world.ability_bank.amount(world.ENTITY_ID, "GLOW"), world.ability_bank.amount(world.ENTITY_ID, "FLY")]


func _apply() -> void:
	var form := "fox" if _form.selected == 1 else "cat"
	_message.text = "Спутник готов" if world.tamagotchi_configure(form, Parameters.PALETTE[_color.selected]["value"], _size.value) else "Подойди к спутнику или найди свободную опору"
	_refresh()


func _toggle() -> void:
	_message.text = "Готово" if world.toggle_tamagotchi() else "Сейчас нельзя безопасно позвать или отозвать спутника"
	_refresh()


func _install() -> void:
	_message.text = "Модуль установлен" if world.tamagotchi_install(_module.get_item_text(_module.selected)) else "Нет доступного экземпляра или спутника рядом"
	_refresh()
