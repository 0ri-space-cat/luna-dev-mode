extends Control
## Fixture for UI review. All bundled labels, map and values here are example data.
const Retro = preload("res://retro_ui_2d.gd")
const Message = preload("res://message_panel.tscn")
const IDS := ["luna", "yuki", "ori", "leya", "toffi", "miya", "oni"]
const NAMES := ["Луна", "Юки", "Ори", "Лея", "Тоффи", "Мия", "Они"]

@onready var inspector = $HackWindow
@onready var hud = $HUD
@onready var console = $Console
@onready var toolbar: HBoxContainer = $Toolbar
@onready var profiles: OptionButton = $Toolbar/Profiles

var identity: Dictionary
var _state: Dictionary
var _id := "luna"
var _message: PanelContainer
var specs := [
	{"key": "health", "label": "HEALTH", "value": 100, "max": 120},
	{"key": "alive", "label": "IS_ALIVE", "value": true, "kind": "bool"},
	{"key": "speed", "label": "MOVE_SPEED", "value": 2.0, "max": 8.0, "step": 0.1},
	{"key": "behavior", "label": "BEHAVIOR_MODE", "value": "WANDER", "kind": "enum",
		"options": ["WANDER", "FOLLOW", "IDLE"]},
	{"key": "tint", "label": "COLOR_TINT", "value": Color("#e24ac8"), "kind": "color"},
	{"key": "size", "label": "SIZE", "tab": "appearance", "value": 1.0, "min": 0.25, "max": 3.0, "step": 0.25}
]

func _ready() -> void:
	for title in NAMES:
		profiles.add_item(title)
	profiles.item_selected.connect(_set_theme)
	var inspect := Retro.button("luna", "Взлом")
	inspect.pressed.connect(func() -> void:
		console.hide()
		inspector.show())
	toolbar.add_child(inspect)
	var yuki := Retro.button("yuki", "Консоль")
	yuki.pressed.connect(func() -> void:
		inspector.hide()
		console.show())
	toolbar.add_child(yuki)
	var notice := Retro.button("luna", "Плашка")
	notice.pressed.connect(func() -> void:
		_message.show_message(_id, "ЗАДАНИЕ", "Найдена новая точка на карте."))
	toolbar.add_child(notice)
	_message = Message.instantiate()
	add_child(_message)
	_message.position = Vector2(448, 370)
	identity = {"name": "Клён", "id": "tree_001",
		"portrait": Retro.texture("common/maple-sample"), "alive": true, "signal_strength": 4}
	inspector.parameter_requested.connect(_change)
	inspector.save_requested.connect(inspector.show_saved)
	inspector.copy_requested.connect(func() -> void:
		identity["id"] = "tree_copy"
		inspector.show_object(identity, specs))
	inspector.delete_requested.connect(func() -> void:
		_message.show_message(_id, "УДАЛЕНИЕ", "Удалить выбранный объект?", "Удалить"))
	_message.accepted.connect(inspector.hide)
	inspector.show_object(identity, specs)
	console.set_program({
		"cards": [
			{"id": "event", "type": "Событие", "title": "Сигнал"},
			{"id": "condition", "type": "Условие", "title": "Рядом"},
			{"id": "action", "type": "Действие", "title": "Свет"}],
		"code": "WHEN signal\nIF target.near\nSET target.light = true",
		"target_caption": "Цель: tree_001",
		"status": "Готово к запуску"})
	console.card_requested.connect(func(id: String) -> void:
		_message.show_message("yuki", "СХЕМА", "Карточка: " + id))
	console.world_requested.connect(func() -> void:
		_message.show_message("yuki", "ЦЕЛЬ", "Выбор цели передаётся игровой сцене."))
	console.run_requested.connect(func(_source: String) -> void:
		_message.show_message("yuki", "КОНСОЛЬ", "Запрос запуска передан."))
	_state = _example_hud()
	hud.set_state(_state)
	hud.slot_requested.connect(func(index: int) -> void:
		_state["selected_inventory"] = index
		hud.call_deferred("set_state", _state))
	hud.shortcut_requested.connect(func(index: int) -> void:
		_state["selected_shortcut"] = index
		_state["tool"] = _state["shortcuts"][index]
		hud.call_deferred("set_state", _state))
	hud.tool_cycle_requested.connect(func(direction: int) -> void:
		var next := posmod(int(_state["selected_shortcut"]) + direction, _state["shortcuts"].size())
		hud.shortcut_requested.emit(next))
	inspector.visibility_changed.connect(func() -> void: hud.set_inspector_open(inspector.visible))
	hud.set_inspector_open(inspector.visible)
	resized.connect(_position)
	_position()

func _position() -> void:
	inspector.position = Vector2(size.x - inspector.size.x - 18, 177)
	inspector.size.y = maxf(inspector.get_combined_minimum_size().y, size.y - inspector.position.y - 18.0)
	console.position = Vector2((size.x - console.size.x) / 2.0 + 120, 202)

func _set_theme(index: int) -> void:
	_id = IDS[index]
	profiles.select(index)
	hud.set_character_theme(_id)
	inspector.set_character_theme(_id)

func _change(key: String, value: Variant) -> void:
	for spec in specs:
		if spec["key"] == key:
			spec["value"] = value
	if key == "alive":
		identity["alive"] = value
		inspector.call_deferred("show_object", identity, specs)

func _item(key: String, title: String, count: int = 1) -> Dictionary:
	return {"icon": Retro.texture("items/" + key), "title": title, "count": count}

func _example_hud() -> Dictionary:
	var tools := [_item("wand", "Палочка Луны"), _item("hourglass", "Песочные часы"),
		_item("scroll", "Свиток"), _item("yuki-console", "Консоль Юки"),
		_item("miya-potion", "Зелье Мии")]
	return {
		"vitals": {"health": Vector2(107, 120), "mana": Vector2(64, 80), "stamina": Vector2(87, 100)},
		"map_texture": _sample_map(),
		"markers": [{"kind": "player", "uv": Vector2(.48, .54)}, {"kind": "passage", "uv": Vector2(.67, .36)},
			{"kind": "bridge", "uv": Vector2(.39, .32)}, {"kind": "quest", "uv": Vector2(.26, .51)},
			{"kind": "pin", "uv": Vector2(.65, .68)}],
		"phase": "night", "time": "21:40", "inventory": tools, "shortcuts": tools,
		"selected_inventory": 0, "selected_shortcut": 0, "tool": tools[0],
		"quests": [{"title": "Осмотреть поляну", "done": true}, {"title": "Найти старый мост"}, {"title": "Проверить проход"}],
		"location": "ETERNIA / CLEARING",
		"hint": "TAB  Взлом   |   1–5  Инструменты"
	}

func _sample_map() -> Texture2D:
	var image := Image.create(80, 80, false, Image.FORMAT_RGBA8)
	image.fill(Color("#65886a"))
	for y in range(80):
		for x in range(80):
			var band := x + roundi(sin(float(y) / 12) * 7.0)
			if band in range(26, 32):
				image.set_pixel(x, y, Color("#6cb8cb"))
			elif absi(y - 34 - floori(x / 5.0)) < 2:
				image.set_pixel(x, y, Color("#b7a581"))
			elif (x * 7 + y * 13) % 23 < 3:
				image.set_pixel(x, y, Color("#729c71"))
	return ImageTexture.create_from_image(image)

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo or console.visible:
		return
	if event.keycode >= KEY_1 and event.keycode <= KEY_5:
		hud.shortcut_requested.emit(event.keycode - KEY_1)
		get_viewport().set_input_as_handled()
