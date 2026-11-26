extends PanelContainer
const Catalog = preload("res://scripts/runtime2d/ori_catalog_2d.gd")
var world
var _forms: OptionButton
var _relations: OptionButton
var _ability: OptionButton
var _size: HSlider
var _message: Label
var _bank: Label
var _targets: OptionButton


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	offset_left = -220
	offset_right = 220
	offset_top = -175
	offset_bottom = 175
	var layout := VBoxContainer.new()
	add_child(layout)
	var title := Label.new()
	title.text = "Каталог Ори · Создание"
	layout.add_child(title)
	_forms = OptionButton.new()
	layout.add_child(_forms)
	_relations = OptionButton.new()
	for relation in Catalog.RELATIONS:
		_relations.add_item(relation)
	layout.add_child(_relations)
	_size = HSlider.new()
	_size.min_value = 0.5
	_size.max_value = 2.0
	_size.step = 0.1
	_size.value = 1.0
	layout.add_child(_size)
	_ability = OptionButton.new()
	_ability.add_item("Без особого модуля")
	_ability.add_item("GLOW")
	_ability.add_item("FLY")
	layout.add_child(_ability)
	_bank = Label.new()
	layout.add_child(_bank)
	var create := Button.new()
	create.text = "Создать настоящее существо"
	create.pressed.connect(_create)
	layout.add_child(create)
	_targets = OptionButton.new()
	layout.add_child(_targets)
	var change := Button.new()
	change.text = "Изменить форму выбранной особи"
	change.pressed.connect(_change_form)
	layout.add_child(change)
	var install := Button.new()
	install.text = "Установить выбранный модуль особи"
	install.pressed.connect(_install_existing)
	layout.add_child(install)
	var repeat := Button.new()
	repeat.text = "Повторить последний шаблон"
	repeat.pressed.connect(_repeat)
	layout.add_child(repeat)
	_message = Label.new()
	layout.add_child(_message)
	var give_back := Button.new()
	give_back.text = "Вернуть Ори (рядом с ним)"
	give_back.pressed.connect(_return_loan)
	layout.add_child(give_back)
	var close := Button.new()
	close.text = "Закрыть"
	close.pressed.connect(hide)
	layout.add_child(close)
	hide()


func open_for(owner_world: Node) -> void:
	world = owner_world
	_forms.clear()
	for form in world.ori.known:
		_forms.add_item(Catalog.FORMS[form])
		_forms.set_item_metadata(_forms.item_count - 1, form)
	if not world.ori.template.is_empty():
		var saved: Dictionary = world.ori.template
		for index in _forms.item_count:
			if _forms.get_item_metadata(index) == saved["form"]:
				_forms.select(index)
		_relations.select(Catalog.RELATIONS.find(saved["relation"]))
		_ability.select(Catalog.MODULES.find(saved["ability"]))
		_size.value = float(saved["size"])
	_message.text = ""
	_refresh_targets()
	_refresh_bank()
	show()


func _refresh_targets() -> void:
	_targets.clear()
	for item in world.catalog_editable_targets():
		_targets.add_item(item["label"])
		_targets.set_item_metadata(_targets.item_count - 1, item["id"])


func _change_form() -> void:
	if _targets.selected < 0 or _forms.selected < 0:
		return
	_message.text = "Форма изменена, личность сохранена" if world.catalog_change_form(str(_targets.get_item_metadata(_targets.selected)), str(_forms.get_item_metadata(_forms.selected))) else "Нельзя изменить сейчас"
	_refresh_targets()


func _install_existing() -> void:
	if _targets.selected < 0:
		return
	_message.text = "Модуль установлен" if world.catalog_install_existing(str(_targets.get_item_metadata(_targets.selected)), Catalog.MODULES[_ability.selected]) else "Нет доступного экземпляра или форма несовместима"
	_refresh_bank()


func _refresh_bank() -> void:
	_bank.text = "Банк: GLOW %d  /  FLY %d. WALK свободен." % [world.ability_bank.amount(world.ENTITY_ID, "GLOW"), world.ability_bank.amount(world.ENTITY_ID, "FLY")]


func _create() -> void:
	if _forms.selected < 0:
		_message.text = "Сначала познакомься с существом"
		return
	var data := {"form": _forms.get_item_metadata(_forms.selected), "relation": Catalog.RELATIONS[_relations.selected], "size": _size.value, "ability": Catalog.MODULES[_ability.selected]}
	_message.text = "Создано" if not world.catalog_create(data).is_empty() else "Нет свободной опоры или достигнут предел"
	_refresh_targets()
	_refresh_bank()


func _repeat() -> void:
	_message.text = "Создано" if not world.catalog_repeat().is_empty() else "Нет сохранённого шаблона или свободного места"
	_refresh_bank()


func _return_loan() -> void:
	if world.return_ori_loan():
		hide()
	else:
		_message.text = "Подойди к Ори с одолженным Каталогом"
