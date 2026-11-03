extends PanelContainer
## Minimal working spell editor. The parameter choices come from registry data.
## We keep the UI deliberately plain until the stone-card presentation is ready.

signal closed
signal spell_created(spell_id: String)

const ArcaneGrammar = preload("res://scripts/core/arcane_grammar.gd")

var workshop
var registry
var draft: Array[Dictionary] = []
var specs: Array[Dictionary] = []

var source_choice: OptionButton
var source_ids: Array[String] = []
var create_choice: OptionButton
var manifestation_settings: VBoxContainer
var form_choice: OptionButton
var essence_choice: OptionButton
var behavior_choice: OptionButton
var release_choice: OptionButton
var impact_choice: OptionButton
var impact_radius_row: HBoxContainer
var impact_radius_control: SpinBox
var speed_control: SpinBox
var size_control: SpinBox

var name_input: LineEdit
var range_input: SpinBox
var field_choice: OptionButton
var operation_choice: OptionButton
var value_host: HBoxContainer
var value_control: Control
var hint_label: Label
var block_list: VBoxContainer
var status_label: Label


func configure(parameter_registry, workshop_service) -> void:
	registry = parameter_registry
	workshop = workshop_service
	specs = workshop.available_fields()
	if is_node_ready():
		_rebuild_fields()


func _ready() -> void:
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 0.5
	anchor_bottom = 0.5
	offset_left = -290.0
	offset_right = 290.0
	offset_top = -380.0
	offset_bottom = 380.0
	mouse_filter = Control.MOUSE_FILTER_STOP

	var style := StyleBoxFlat.new()
	style.bg_color = Color("292339")
	style.border_color = Color("8ed7bd")
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(16)
	add_theme_stylebox_override("panel", style)
	var panel_scroll := ScrollContainer.new()
	panel_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(panel_scroll)
	var layout := VBoxContainer.new()
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("separation", 5)
	panel_scroll.add_child(layout)

	var title := _label(layout, "SPELL_WORKSHOP", 21)
	title.add_theme_color_override("font_color", Color("a4f8e2"))
	_label(layout, "Собери цепочку. А последствия посмотрим.", 13)

	var source_row := HBoxContainer.new()
	layout.add_child(source_row)
	_label(source_row, "РАЗОБРАТЬ:", 13)
	source_choice = OptionButton.new()
	source_choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	source_choice.item_selected.connect(_on_source_selected)
	source_row.add_child(source_choice)
	var new_button := Button.new()
	new_button.text = "С НУЛЯ"
	new_button.pressed.connect(_on_new_recipe)
	source_row.add_child(new_button)

	var headline := HBoxContainer.new()
	layout.add_child(headline)
	_label(headline, "NAME:", 14)
	name_input = LineEdit.new()
	name_input.placeholder_text = "Название заклинания"
	name_input.text = "МОЙ ХАОС"
	name_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	headline.add_child(name_input)
	var range_row := HBoxContainer.new()
	layout.add_child(range_row)
	_label(range_row, "CAST_RANGE:", 14)
	range_input = SpinBox.new()
	range_input.min_value = 0.5
	range_input.max_value = 50.0
	range_input.step = 0.5
	range_input.value = 11.0
	range_row.add_child(range_input)

	layout.add_child(HSeparator.new())
	var create_choices: Array = [{"id": "NONE", "name": "Без создания"}]
	create_choices.append_array(ArcaneGrammar.CREATIONS)
	create_choice = _choice_row(layout, "CREATE · Создать", create_choices)
	create_choice.item_selected.connect(_on_create_changed)

	manifestation_settings = VBoxContainer.new()
	manifestation_settings.add_theme_constant_override("separation", 4)
	layout.add_child(manifestation_settings)
	form_choice = _choice_row(manifestation_settings, "SHAPE · Форма", ArcaneGrammar.SHAPES)
	essence_choice = _choice_row(manifestation_settings, "ELEMENT · Стихия", ArcaneGrammar.ELEMENTS)
	behavior_choice = _choice_row(manifestation_settings, "BEHAVIOR · Поведение", ArcaneGrammar.BEHAVIORS)
	release_choice = _choice_row(manifestation_settings, "RELEASE · Выпустить", ArcaneGrammar.RELEASES)
	var motion_row := HBoxContainer.new()
	manifestation_settings.add_child(motion_row)
	_label(motion_row, "Скорость полёта", 12)
	speed_control = SpinBox.new()
	speed_control.min_value = 3.0
	speed_control.max_value = 30.0
	speed_control.step = 1.0
	speed_control.value = ArcaneGrammar.DEFAULT_SPEED
	motion_row.add_child(speed_control)
	_label(motion_row, "Размер", 12)
	size_control = SpinBox.new()
	size_control.min_value = 0.15
	size_control.max_value = 0.9
	size_control.step = 0.05
	size_control.value = ArcaneGrammar.DEFAULT_SIZE
	motion_row.add_child(size_control)
	manifestation_settings.visible = false

	layout.add_child(HSeparator.new())
	impact_choice = _choice_row(
		layout, "ON_HIT · Попадание", [
			{"id": "DIRECT", "name": "Одна цель"},
			{"id": "BURST", "name": "Взрыв вокруг цели"}
		]
	)
	impact_choice.item_selected.connect(_on_impact_changed)
	impact_radius_row = HBoxContainer.new()
	layout.add_child(impact_radius_row)
	_label(impact_radius_row, "Радиус взрыва", 12)
	impact_radius_control = SpinBox.new()
	impact_radius_control.min_value = 0.5
	impact_radius_control.max_value = 6.0
	impact_radius_control.step = 0.5
	impact_radius_control.value = 2.5
	impact_radius_row.add_child(impact_radius_control)
	impact_radius_row.visible = false
	var field_row := HBoxContainer.new()
	layout.add_child(field_row)
	_label(field_row, "ПРИ ПОПАДАНИИ:", 13)
	field_choice = OptionButton.new()
	field_choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field_choice.item_selected.connect(_on_field_changed)
	field_row.add_child(field_choice)

	var operation_row := HBoxContainer.new()
	layout.add_child(operation_row)
	_label(operation_row, "ДЕЙСТВИЕ:", 13)
	operation_choice = OptionButton.new()
	operation_choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	operation_choice.item_selected.connect(_on_operation_changed)
	operation_row.add_child(operation_choice)

	value_host = HBoxContainer.new()
	value_host.add_theme_constant_override("separation", 8)
	layout.add_child(value_host)
	hint_label = _label(layout, "", 12)
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label.add_theme_color_override("font_color", Color("bdb6dc"))
	var add_button := Button.new()
	add_button.text = "+ ДОБАВИТЬ БЛОК"
	add_button.pressed.connect(_on_add_block)
	layout.add_child(add_button)

	layout.add_child(HSeparator.new())
	_label(layout, "ON_HIT · Цепочка эффектов [до 12]", 13)
	var scroller := ScrollContainer.new()
	scroller.custom_minimum_size.y = 105
	scroller.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(scroller)
	block_list = VBoxContainer.new()
	block_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	block_list.add_theme_constant_override("separation", 5)
	scroller.add_child(block_list)

	status_label = _label(layout, "", 12)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var buttons := HBoxContainer.new()
	layout.add_child(buttons)
	var save_button := Button.new()
	save_button.text = "СОХРАНИТЬ ЗАКЛИНАНИЕ"
	save_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save_button.pressed.connect(_on_save)
	buttons.add_child(save_button)
	var close_button := Button.new()
	close_button.text = "ЗАКРЫТЬ [B]"
	close_button.pressed.connect(func() -> void: closed.emit())
	buttons.add_child(close_button)

	visible = false
	if workshop != null:
		_rebuild_fields()
	_refresh_blocks()


func show_workshop(selected_spell_id: String = "") -> void:
	_reload_sources()
	if not selected_spell_id.is_empty():
		load_spell(selected_spell_id)
	status_label.text = "Разбери заклинание. Перепиши как хочешь."
	visible = true


func load_spell(spell_id: String) -> bool:
	if workshop == null:
		return false
	var definition: Dictionary = workshop.spells.get_spell(spell_id)
	if definition.is_empty():
		return false
	var title: String = str(definition["label"])
	name_input.text = ("МОЙ " + title).substr(0, 40)
	range_input.value = float(definition["cast_range"])
	draft.clear()
	for action in definition["effects"]:
		draft.append(action.duplicate(true))
	var manifest: Dictionary = ArcaneGrammar.normalize(definition.get("manifestation", {}))
	_select_choice(create_choice, "NONE" if manifest.is_empty() else str(manifest["create"]))
	_on_create_changed(create_choice.selected)
	if not manifest.is_empty():
		_select_choice(form_choice, str(manifest["shape"]))
		_select_choice(essence_choice, str(manifest["element"]))
		_select_choice(behavior_choice, str(manifest["behavior"]))
		_select_choice(release_choice, str(manifest["release"]))
		speed_control.value = float(manifest["speed"])
		size_control.value = float(manifest["size"])
	var impact: Dictionary = definition.get("impact", {})
	_select_choice(impact_choice, str(impact.get("mode", "DIRECT")))
	_on_impact_changed(impact_choice.selected)
	if impact.has("radius"):
		impact_radius_control.value = float(impact["radius"])
	var location: int = source_ids.find(spell_id)
	if location >= 0:
		source_choice.select(location)
	_refresh_blocks()
	return true


func _reload_sources() -> void:
	source_ids.clear()
	source_choice.clear()
	for spell_id in workshop.spells.list_spell_ids():
		var item: Dictionary = workshop.spells.get_spell(spell_id)
		source_ids.append(spell_id)
		source_choice.add_item(str(item.get("label", spell_id)))


func _on_source_selected(index: int) -> void:
	if index >= 0 and index < source_ids.size():
		load_spell(source_ids[index])


func _on_new_recipe() -> void:
	draft.clear()
	name_input.text = "МОЁ ЗАКЛИНАНИЕ"
	range_input.value = 11.0
	_select_choice(create_choice, "ENERGY")
	_on_create_changed(create_choice.selected)
	_select_choice(form_choice, "ORB")
	_select_choice(essence_choice, "FIRE")
	_select_choice(behavior_choice, "SEEK")
	_select_choice(release_choice, "PROJECTILE")
	speed_control.value = ArcaneGrammar.DEFAULT_SPEED
	size_control.value = ArcaneGrammar.DEFAULT_SIZE
	status_label.text = ""
	_select_choice(impact_choice, "DIRECT")
	_on_impact_changed(impact_choice.selected)
	_refresh_blocks()


func _on_create_changed(_index: int) -> void:
	manifestation_settings.visible = _choice_value(create_choice) != "NONE"


func _choice_value(choice: OptionButton) -> String:
	if choice == null or choice.selected < 0:
		return ""
	return str(choice.get_item_metadata(choice.selected))


func _manifestation() -> Dictionary:
	var create: String = _choice_value(create_choice)
	if create == "NONE":
		return {}
	return ArcaneGrammar.make_recipe(
		create, _choice_value(form_choice), _choice_value(essence_choice),
		_choice_value(behavior_choice), _choice_value(release_choice),
		speed_control.value, size_control.value
	)


func _on_impact_changed(_index: int) -> void:
	impact_radius_row.visible = _choice_value(impact_choice) == "BURST"


func _impact() -> Dictionary:
	if _choice_value(impact_choice) == "BURST":
		return {"mode": "BURST", "radius": impact_radius_control.value}
	return {}


func _choice_row(parent: Node, label: String, choices: Array) -> OptionButton:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var name := _label(row, label, 12)
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var options := OptionButton.new()
	options.custom_minimum_size.x = 145
	for item in choices:
		options.add_item(str(item["name"]))
		options.set_item_metadata(options.item_count - 1, item["id"])
	row.add_child(options)
	return options


func _select_choice(choice: OptionButton, id: String) -> void:
	for index in range(choice.item_count):
		if str(choice.get_item_metadata(index)) == id:
			choice.select(index)
			return


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if event.keycode == KEY_ESCAPE or event.keycode == KEY_B:
		get_viewport().set_input_as_handled()
		closed.emit()


func _rebuild_fields() -> void:
	field_choice.clear()
	for spec in specs:
		field_choice.add_item(str(spec.get("display_name", spec["label"])))
	if not specs.is_empty():
		field_choice.select(0)
		_on_field_changed(0)


func _on_field_changed(_index: int) -> void:
	var spec: Dictionary = _current_spec()
	operation_choice.clear()
	if spec.is_empty():
		return
	match str(spec["kind"]):
		"bool":
			_add_operation("Задать", "SET")
			_add_operation("Переключить", "TOGGLE")
		"int", "float":
			_add_operation("Задать", "SET")
			_add_operation("Прибавить", "ADD")
			_add_operation("Умножить", "MULTIPLY")
		_:
			_add_operation("Задать", "SET")
	operation_choice.select(0)
	hint_label.text = str(spec["hint"])
	_refresh_value_input()


func _add_operation(label: String, operation_id: String) -> void:
	operation_choice.add_item(label)
	operation_choice.set_item_metadata(operation_choice.item_count - 1, operation_id)


func _selected_operation() -> String:
	if operation_choice.selected < 0:
		return ""
	return str(operation_choice.get_item_metadata(operation_choice.selected))


func _on_operation_changed(_index: int) -> void:
	_refresh_value_input()


func _current_spec() -> Dictionary:
	var i := field_choice.selected
	if i < 0 or i >= specs.size():
		return {}
	return specs[i]


func _refresh_value_input() -> void:
	for child in value_host.get_children():
		value_host.remove_child(child)
		child.queue_free()
	value_control = null
	var spec := _current_spec()
	if spec.is_empty():
		return
	var operation := _selected_operation()
	_label(value_host, "VALUE:", 14)
	if operation == "TOGGLE":
		_label(value_host, "INVERT", 14)
		return
	var kind: String = spec["kind"]
	if kind == "bool" or kind == "enum" or kind == "color":
		var choices := OptionButton.new()
		choices.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if kind == "bool":
			choices.add_item("TRUE")
			choices.add_item("FALSE")
		else:
			for item in spec.get("choices", []):
				choices.add_item(str(item["name"]))
		value_host.add_child(choices)
		value_control = choices
	else:
		var number := SpinBox.new()
		if operation == "SET":
			number.min_value = float(spec["min"])
			number.max_value = float(spec["max"])
			number.step = float(spec["step"])
			number.value = float(spec["default"])
		elif operation == "ADD":
			number.min_value = -20.0
			number.max_value = 20.0
			number.step = 0.1
			number.value = 1.0
		else:
			number.min_value = 0.0
			number.max_value = 5.0
			number.step = 0.1
			number.value = 1.5
		number.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		value_host.add_child(number)
		value_control = number


func _on_add_block() -> void:
	if draft.size() >= 12:
		status_label.text = "Двенадцать блоков. Дальше уже издевательство."
		return
	var spec := _current_spec()
	if spec.is_empty():
		return
	var operation := _selected_operation()
	var block: Dictionary = {
		"operation": operation,
		"parameter_id": str(spec["id"])
	}
	if operation != "TOGGLE":
		if value_control is SpinBox:
			block["value"] = int((value_control as SpinBox).value) if spec["kind"] == "int" and operation == "SET" else (value_control as SpinBox).value
		elif value_control is OptionButton:
			var selected: int = (value_control as OptionButton).selected
			if str(spec["kind"]) == "bool":
				block["value"] = selected == 0
			else:
				var choices: Array = spec.get("choices", [])
				if selected < 0 or selected >= choices.size():
					return
				block["value"] = choices[selected]["value"]
		else:
			return
	draft.append(block)
	status_label.text = ""
	_refresh_blocks()


func _refresh_blocks() -> void:
	for node in block_list.get_children():
		block_list.remove_child(node)
		node.queue_free()
	if draft.is_empty():
		_label(block_list, "Пока пусто. Добавь пару пакостей.", 13)
		return
	for i in range(draft.size()):
		var row := HBoxContainer.new()
		block_list.add_child(row)
		var block: Dictionary = draft[i]
		var spec_name := str(block["parameter_id"]).to_upper()
		for spec in specs:
			if spec["id"] == block["parameter_id"]:
				spec_name = str(spec.get("display_name", spec["label"]))
				break
		var readable_op := {"SET": "ЗАДАТЬ", "ADD": "ИЗМЕНИТЬ НА", "MULTIPLY": "УМНОЖИТЬ", "TOGGLE": "ПЕРЕКЛЮЧИТЬ"}
		var description := "%02d  %s  ·  %s" % [i + 1, spec_name, str(readable_op.get(block["operation"], block["operation"]))]
		if block.has("value"):
			description += "  %s" % _format_value(block["value"])
		var label := _label(row, description, 12)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for button_name in ["↑", "↓", "×"]:
			var button := Button.new()
			button.text = button_name
			row.add_child(button)
			match button_name:
				"↑":
					button.disabled = i == 0
					button.pressed.connect(_on_move_block.bind(i, -1))
				"↓":
					button.disabled = i == draft.size() - 1
					button.pressed.connect(_on_move_block.bind(i, 1))
				"×":
					button.pressed.connect(_on_remove_block.bind(i))


func _on_move_block(index: int, amount: int) -> void:
	var other := index + amount
	if other < 0 or other >= draft.size():
		return
	var item: Dictionary = draft[index]
	draft[index] = draft[other]
	draft[other] = item
	_refresh_blocks()


func _on_remove_block(index: int) -> void:
	if index >= 0 and index < draft.size():
		draft.remove_at(index)
		_refresh_blocks()


func _on_save() -> void:
	if workshop == null:
		return
	var spell_id: String = workshop.create_recipe(
		name_input.text, range_input.value, draft, _manifestation(), _impact()
	)
	if spell_id.is_empty():
		status_label.text = workshop.last_error
		return
	draft.clear()
	_refresh_blocks()
	status_label.text = "Готово: %s. Теперь попробуй на холодильнике." % spell_id
	spell_created.emit(spell_id)


func _format_value(value: Variant) -> String:
	if typeof(value) == TYPE_COLOR:
		return "#" + (value as Color).to_html(false).to_upper()
	if typeof(value) == TYPE_BOOL:
		return "TRUE" if bool(value) else "FALSE"
	return str(value)


func _label(parent: Node, text: String, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color("ece5f9"))
	parent.add_child(label)
	return label
