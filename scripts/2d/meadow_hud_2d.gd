extends CanvasLayer
## Reference-inspired neon-purple HUD. UI graphics are independent of gameplay art.
const Profiles = preload("res://scripts/2d/character_ui_profile.gd")
const Minimap = preload("res://scripts/2d/meadow_minimap_2d.gd")
const ItemIcon = preload("res://scripts/2d/ui_icon_2d.gd")
const ITEMS := ["wand","hourglass","donut","apple","crystal","book"]
var character_id := "luna"
var portrait: TextureRect
var backpack_texture: TextureRect
var header: Label
var status: Label
var prompt: Label
var minmap: Control
var access_label: Label
var quest_labels: Array[Label] = []
var accent := Color("#db78f3")
var panels: Array[Panel] = []
var quick_slots: Array[Panel] = []
var root_ui: Control

func _ready() -> void:
	layer = 2
	root_ui = Control.new()
	root_ui.name = "MeadowOverlay"
	root_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root_ui)
	_build_vitals()
	_build_quest_log()
	_build_minimap()
	_build_inventory()
	_build_hotbar()
	_build_action_hint()
	_build_status()
	set_character("luna")
	set_status("WASD: ходить • Shift: бежать • E: общение • ЛКМ: взлом")

func _skin(fill: Color, edge: Color, radius: int = 12, border_size: int = 2) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.set_border_width_all(border_size)
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(7)
	return style

func _frame(parent: Node, at: Vector2, size: Vector2, color: Color) -> Panel:
	var frame := Panel.new()
	frame.position = at
	frame.custom_minimum_size = size
	frame.size = size
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_theme_stylebox_override("panel", _skin(Color("#271d44",0.93), color))
	parent.add_child(frame)
	panels.append(frame)
	return frame

func _label(parent: Node, text: String, at: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.position = at
	label.text = text
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func _build_vitals() -> void:
	var frame := _frame(root_ui, Vector2(10, 10), Vector2(390, 140), Color("#bf73ec"))
	portrait = TextureRect.new()
	portrait.position = Vector2(12,17)
	portrait.size = Vector2(90,95)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(portrait)
	var border := TextureRect.new()
	var frame_svg := "res://assets/ui/common/frames/portrait.svg"
	if ResourceLoader.exists(frame_svg):
		border.texture = load(frame_svg)
	border.position = Vector2(7,11)
	border.size = Vector2(101,108)
	border.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(border)
	header = _label(frame,"ЛУНА • ПАЛОЧКА",Vector2(131,8),15,Color("#fff5fc"))
	var entries := [
		{"name":"HEALTH", "value":"120 / 120", "color":Color("#f56ca3")},
		{"name":"MANA", "value":"80 / 80", "color":Color("#57d4fa")},
		{"name":"STAMINA", "value":"100 / 100", "color":Color("#f7d05d")}
	]
	for i in range(entries.size()):
		var bar := ProgressBar.new()
		bar.position = Vector2(159, 38 + i * 31)
		bar.size = Vector2(217,24)
		bar.value = 100
		bar.show_percentage = false
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar.add_theme_stylebox_override("background",_skin(Color("#4c326f"),Color("#6f5194"),7,1))
		bar.add_theme_stylebox_override("fill",_skin(entries[i]["color"],Color("#fff3fa"),7,1))
		frame.add_child(bar)
		_label(frame,str(entries[i]["name"]) + "  " + str(entries[i]["value"]), Vector2(138,40+i*31), 13,Color("#291d45"))

func _build_quest_log() -> void:
	var log := _frame(root_ui,Vector2(12,158),Vector2(256,142),Color("#af65eb"))
	_label(log,"✦  ПЕРВЫЕ ОТКРЫТИЯ",Vector2(14,10),14,Color("#ffe8ac"))
	for i in range(4):
		var label := _label(log,"",Vector2(14,37+i*23),12,Color("#efe0ff"))
		quest_labels.append(label)

func _build_minimap() -> void:
	minmap = Minimap.new()
	minmap.position = Vector2(1138,18)
	minmap.custom_minimum_size = Vector2(128,128)
	minmap.size = Vector2(128,128)
	minmap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_ui.add_child(minmap)
	_label(root_ui,"N",Vector2(1196,6),14,Color("#f8eeff"))

func _build_inventory() -> void:
	var bag := TextureRect.new()
	bag.position = Vector2(9,528)
	bag.size = Vector2(212,267)
	bag.name = "BagTexture"
	bag.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bag.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	bag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backpack_texture = bag
	root_ui.add_child(bag)
	# Overlay slots remain user-interface children, not baked into bag textures.
	for index in range(6):
		var col := index % 3
		var row := int(index / 3)
		var art := ItemIcon.new(ITEMS[index])
		art.position = Vector2(62+col*44,636+row*43)
		art.size = Vector2(37,37)
		root_ui.add_child(art)

func _build_hotbar() -> void:
	for i in range(5):
		var color := Color("#ffb5fa") if i == 0 else Color("#b57bea")
		var tile := _frame(root_ui, Vector2(480 + i * 66, 732),Vector2(58,58),color)
		quick_slots.append(tile)
		_label(tile,str(i+1),Vector2(21,-16),14,Color("#f5e2ff"))
		var art := ItemIcon.new(ITEMS[i])
		art.position = Vector2(7,7)
		art.size = Vector2(44,44)
		tile.add_child(art)

func _build_action_hint() -> void:
	var hints := _frame(root_ui,Vector2(897,700),Vector2(369,92),Color("#c279eb"))
	access_label = _label(hints,"ПАЛОЧКА  ·  ОБЫЧНАЯ",Vector2(14,12),15,Color("#80e8fa"))
	_label(hints,"Space: магия    Q: реакция",Vector2(14,38),13,Color("#e9d5fd"))
	_label(hints,"Z/Y: отмена/повтор   F5/F9: сейвы",Vector2(14,59),12,Color("#e9d5fd"))

func _build_status() -> void:
	var frame := _frame(root_ui,Vector2(278,663),Vector2(591,55),Color("#8859c5"))
	status = _label(frame,"",Vector2(11,8),13,Color("#fff0fa"))
	status.custom_minimum_size.x = 565
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var prompt_frame := _frame(root_ui,Vector2(415,10),Vector2(680,38),Color("#5d9ec8"))
	prompt = _label(prompt_frame,"",Vector2(10,8),13,Color("#e7faff"))

func set_character(id: String) -> void:
	character_id = id
	var profile: Dictionary = Profiles.get_profile(id)
	accent = profile["accent"]
	header.text = str(profile["title"]).to_upper()+"  ·  "+str(profile["tool"]).to_upper()
	var portrait_path := "res://assets/characters/%s/ui/portrait.png" % id
	if ResourceLoader.exists(portrait_path):
		portrait.texture = load(portrait_path)
	var backpack_path := "res://assets/characters/%s/ui/backpack.png" % id
	if ResourceLoader.exists(backpack_path):
		backpack_texture.texture = load(backpack_path)
	for panel in panels:
		var skin: StyleBoxFlat = panel.get_theme_stylebox("panel") as StyleBoxFlat
		if skin != null:
			skin.border_color = accent.lightened(0.1)

func set_status(message: String) -> void:
	if is_instance_valid(status):
		status.text = message

func set_prompt(message: String) -> void:
	if is_instance_valid(prompt):
		prompt.text = message

func set_targets(player: Node2D, actors: Array) -> void:
	minmap.set_targets(player, actors)

func set_quest_state(session) -> void:
	if quest_labels.size() != 4:
		return
	var checked := [
		bool(session.wand.get("rift_enabled", false)),
		not session.duplicate.is_empty(),
		bool(session.wand.get("is_hacked", false)),
		bool(session.oracle_eye_owned)
	]
	var titles := ["Найти странный разлом","Получить копию палочки","Повысить доступ палочки","Найти Глаз Оракула"]
	for i in range(4):
		quest_labels[i].text = ("●  " if checked[i] else "○  ") + titles[i]
		quest_labels[i].add_theme_color_override("font_color",Color("#a1f4cf") if checked[i] else Color("#f6e6ff"))
	access_label.text = "ДОСТУП: " + ("АРХИТЕКТОР" if bool(session.wand["is_hacked"]) else ("ШАЛОСТИ" if checked[0] else "ОБЫЧНАЯ"))
