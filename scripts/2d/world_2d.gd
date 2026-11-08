extends Node2D
## The first standalone playable 2D meadow. Legacy main stays unchanged.
const Actor = preload("res://scripts/2d/entity_actor_2d.gd")
const Inspector = preload("res://scripts/2d/hack_inspector_2d.gd")
const HUD = preload("res://scripts/2d/meadow_hud_2d.gd")
const Session = preload("res://scripts/2d/hack_session_2d.gd")
const Save2D = preload("res://scripts/2d/meadow_save_2d.gd")
const Registry = preload("res://scripts/core/parameter_registry.gd")
const Processor = preload("res://scripts/core/command_processor.gd")
const World = preload("res://scripts/core/world_registry.gd")
const RIFT := Vector2(265, 245)
const LAKE := Vector2(985, 600)
const ORACLE := Vector2(1140, 275)
const WALK_SPEED := 225.0
const RUN_SPEED := 335.0

@onready var player: CharacterBody2D = $Entities/Player
var registry = Registry.new()
var processor = Processor.new()
var world = World.new()
var session = Session.new()
var save_game = Save2D.new()
var selected: Node
var actors: Array = []
var hud: CanvasLayer
var inspector: PanelContainer
var inspector_layer: CanvasLayer
var debug_character := 0
@onready var puppet: Node2D = $Entities/Player/Visual
const THEME_ORDER := ["luna", "yuki", "ori", "mia", "leya", "toffi", "oni"]

func _ready() -> void:
	processor.configure_world(world)
	_spawn("tree_01", "tree", "Клён", Vector2(430, 350), {"color": Color("#a9db5c")})
	_spawn("fridge_01", "fridge", "Холодильник", Vector2(790, 410), {"color": Color("#e3b9f1")})
	_spawn("tree_02", "tree", "Вишня", Vector2(1030, 380), {"color": Color("#f9a6d5")})
	_spawn("sheep_01", "arcane_creature", "Овечка", Vector2(650, 610), {"color": Color("#f5e8ff"), "alive": true})
	_spawn("duck_01", "arcane_creature", "Уточка", Vector2(750, 660), {"color": Color("#ffdb66"), "alive": true})
	_spawn("slime_01", "arcane_creature", "Сонный слайм", Vector2(925, 380), {"color": Color("#83e3f0"), "alive": true})
	hud = HUD.new()
	add_child(hud)
	hud.set_targets(player, actors)
	inspector_layer = CanvasLayer.new()
	inspector_layer.layer = 3
	add_child(inspector_layer)
	inspector = Inspector.new()
	inspector.position = Vector2(826, 145)
	inspector_layer.add_child(inspector)
	inspector.save_requested.connect(_save)
	inspector.set_character_theme("luna")
	_show("Луна проснулась в Этернии. Разлом мерцает слева.")

func _spawn(id: String, category: String, title: String, at: Vector2, overrides: Dictionary) -> void:
	var actor := Actor.new()
	actor.position = at
	$Entities.add_child(actor)
	actor.setup(id, category, title, registry, overrides)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 17.0
	shape.shape = circle
	actor.add_child(shape)
	world.register_entity(id, actor, category.to_upper())
	actor.set_context(player, world)
	actors.append(actor)

func _movement_vector() -> Vector2:
	var vector := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if Input.is_key_pressed(KEY_A):
		vector.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		vector.x += 1.0
	if Input.is_key_pressed(KEY_W):
		vector.y -= 1.0
	if Input.is_key_pressed(KEY_S):
		vector.y += 1.0
	return vector.limit_length(1.0)

func _physics_process(_delta: float) -> void:
	# A fullscreen editor never freezes the host OS; just stop player motion.
	var running := Input.is_key_pressed(KEY_SHIFT)
	player.velocity = Vector2.ZERO if inspector.visible else _movement_vector() * (RUN_SPEED if running else WALK_SPEED)
	player.move_and_slide()
	puppet.set_motion(player.velocity, running, _delta)
	player.position = player.position.clamp(Vector2(45, 95), Vector2(1420, 714))
	if inspector.visible:
		hud.set_prompt("Редактор: Сохранить мир или Закрыть")
	elif player.position.distance_to(RIFT) < 94.0:
		hud.set_prompt("[E] Исследовать мерцающий разлом")
	elif player.position.distance_to(LAKE) < 115.0:
		hud.set_prompt("[E] Озеро отражений: создать копию палочки")
	elif player.position.distance_to(ORACLE) < 100.0:
		hud.set_prompt("[E] Оракул и механический глаз")
	elif not session.duplicate.is_empty() and not session.wand["is_hacked"]:
		hud.set_prompt("[U] Применить копию палочки к оригиналу")
	else:
		hud.set_prompt("ЛКМ: выбрать объект • F5: сохранить • F9: загрузить")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var at := get_global_mouse_position()
		var closest := 57.0
		var picked: Node = null
		for actor in actors:
			var distance: float = actor.global_position.distance_to(at)
			if distance < closest:
				closest = distance
				picked = actor
		if picked != null:
			for actor in actors:
				if is_instance_valid(actor.visual):
					actor.visual.selected = actor == picked
			_open_object(picked)
			puppet.trigger_action("cast",0.36)

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_SPACE:
			puppet.trigger_action("cast",0.55)
			_show("Луна взмахнула палочкой. Звёзды послушно вспыхнули.")
		KEY_Q:
			puppet.trigger_action("surprise",0.55)
			_show("Луна: «Ой! Кажется, я что-то заметила...»")
		KEY_E:
			_interact()
		KEY_U:
			if session.upgrade_original():
				_show("Палочка изменила себя! Доступ: АРХИТЕКТОР.")
				if inspector.visible:
					inspector._refresh()
			else:
				_show("Для самовзлома нужна отдельная копия взломанной палочки.")
		KEY_Z:
			if processor.undo():
				puppet.trigger_action("cast",0.22)
				_show("Последнее изменение отменено.")
				if inspector.visible:
					inspector._refresh()
		KEY_Y:
			if processor.redo():
				puppet.trigger_action("cast",0.22)
				_show("Изменение повторено.")
				if inspector.visible:
					inspector._refresh()
		KEY_F5:
			_save()
		KEY_F9:
			_load()
		KEY_ESCAPE:
			inspector.hide()
		KEY_F6:
			# Temporary visual test: switches themes only, not physical characters.
			debug_character = (debug_character + 1) % THEME_ORDER.size()
			hud.set_character(THEME_ORDER[debug_character])
			inspector.set_character_theme(THEME_ORDER[debug_character])
			_show("Предпросмотр интерфейса: " + THEME_ORDER[debug_character] + ". Управление остаётся у Луны.")

func _interact() -> void:
	puppet.trigger_action("interact",0.40)
	if player.position.distance_to(RIFT) < 94.0:
		session.touch_rift()
		_show("Палочка заискрилась! Теперь можно редактировать простые свойства вещей.")
	elif player.position.distance_to(LAKE) < 115.0:
		if session.copy_wand():
			_show("Отражение превратилось в настоящую копию палочки. Нажми U для самовзлома.")
		else:
			_show("Озеро ничего не копирует. Сперва найди разлом или убери уже созданную копию.")
	elif player.position.distance_to(ORACLE) < 100.0:
		if session.collect_oracle_eye():
			_show("Получен Глаз Оракула! Технические символы стали понятными.")
			if inspector.visible:
				inspector._refresh()
		else:
			_show("Оракул: «Глаз откликнется только на палочку, коснувшуюся разлома».")
	else:
		_show("Рядом ничего не откликается. Посмотри на поляну внимательнее.")

func _open_object(actor: Node) -> void:
	if player.global_position.distance_to(actor.global_position) > 195.0:
		_show("Слишком далеко для взлома. Подойди к объекту поближе.")
		return
	if not bool(session.wand["rift_enabled"]):
		_show("Луна: «Палочка показывает только обычные заклинания. Что за странный разлом?»")
		return
	selected = actor
	inspector.open_actor(actor, processor, registry, session)
	_show("Открыт редактор: " + str(actor.record.display_name))

func _save() -> void:
	if save_game.write(player, world, session):
		_show("Поляна сохранена (F9 — загрузить).")
	else:
		_show("Ошибка сохранения: " + save_game.last_error)

func _load() -> void:
	if not save_game.has_save():
		_show("Сохранение пока не создано.")
		return
	if save_game.read(player, world, session, registry):
		_show("Поляна и состояние палочки загружены.")
		if inspector.visible:
			inspector._refresh()
	else:
		_show("Не удалось загрузить: " + save_game.last_error)

func _show(text: String) -> void:
	if is_instance_valid(hud):
		hud.set_status(text)
		hud.set_quest_state(session)
