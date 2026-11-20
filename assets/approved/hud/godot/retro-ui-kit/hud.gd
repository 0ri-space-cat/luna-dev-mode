extends Control
## On-screen presentation; item IDs, vitals and discovered map markers are host data.
signal slot_requested(index: int)
signal shortcut_requested(index: int)
signal tool_cycle_requested(direction: int)

const Retro = preload("res://retro_ui_2d.gd")
const Map = preload("res://minimap.gd")
const RESOURCES := [["health", "Здоровье"], ["mana", "Мана"], ["stamina", "Выносливость"]]
const BAG_LAYOUT := {
	"luna": [Vector2(72, 121), 35, 33, "#2a0a40"],
	"yuki": [Vector2(77, 133), 34, 32, "#68153e"],
	"ori": [Vector2(73, 122), 36, 34, "#14184e"],
	"leya": [Vector2(79, 141), 32, 30, "#23452a"],
	"toffi": [Vector2(81, 140), 32, 30, "#652b24"],
	"miya": [Vector2(76, 136), 35, 32, "#202f64"],
	"oni": [Vector2(73, 120), 36, 34, "#10294d"]
}

var _id := "luna"
var _state: Dictionary = {}
var _contents: Control
var _map: Control
var _areas: Dictionary = {}
var _quest_collapsed := false
var _inspector_open := false
var _tool_label: Panel
var _tool_timer: Timer

func _ready() -> void:
	resized.connect(_position)
	_tool_timer = Timer.new()
	_tool_timer.one_shot = true
	_tool_timer.timeout.connect(func() -> void:
		if is_instance_valid(_tool_label):
			_tool_label.hide())
	add_child(_tool_timer)
	_refresh()

func set_character_theme(id: String) -> void:
	_id = Retro.id_for(id)
	if is_node_ready():
		_refresh()

func set_inspector_open(open: bool) -> void:
	_inspector_open = open
	_position()

func set_state(state: Dictionary) -> void:
	var old_tool: Dictionary = _state.get("tool", {})
	var new_tool: Dictionary = state.get("tool", {})
	_state = state.duplicate(true)
	if is_node_ready():
		if not old_tool.is_empty() and old_tool != new_tool:
			_tool_timer.start(1.4)
		_refresh()

func _ink() -> Color:
	return Color(Retro.INK[_id])

func _dark() -> Color:
	return Color(Retro.DARK_INK[_id])

func _skin(key: String, slice: int, padding: int = 4) -> StyleBoxTexture:
	return Retro.style(Retro.part(_id, key), slice, padding)

func _panel(key: String, extent: Vector2, slice: int = 6) -> Panel:
	var panel := Panel.new()
	panel.size = extent
	panel.add_theme_stylebox_override("panel", _skin(key, slice))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_contents.add_child(panel)
	return panel

func _chrome(key: String, extent: Vector2) -> Panel:
	var outer := _panel("window", extent, 12)
	var inset := Panel.new()
	inset.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inset.add_theme_stylebox_override("panel", _skin(key, 6))
	outer.add_child(inset)
	inset.position = Vector2(7, 7)
	inset.size = extent - Vector2(14, 14)
	return outer

func _label(parent: Control, value: String, at: Vector2, color: Color, font_size: int = 12) -> Label:
	var label := Retro.label(value, color, font_size)
	parent.add_child(label)
	label.position = at
	return label

func _image(parent: Control, picture: Texture2D, at: Vector2, extent: Vector2) -> TextureRect:
	var image := Retro.image(picture, extent)
	if picture and picture.get_width() > 64:
		image.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	parent.add_child(image)
	image.position = at
	image.size = extent
	return image

func _refresh() -> void:
	if is_instance_valid(_contents):
		remove_child(_contents)
		_contents.queue_free()
	_areas.clear()
	_tool_label = null
	_contents = Control.new()
	_contents.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_contents)
	_contents.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_vitals()
	_build_map()
	_build_inventory()
	_build_quest()
	_build_tools()
	_position()

func _build_vitals() -> void:
	var panel := _chrome("object_header", Vector2(394, 142))
	_areas.vitals = panel
	_image(panel, Retro.texture("characters/" + _id + "/portrait"), Vector2(15, 21), Vector2(98, 98)).texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_image(panel, Retro.texture(Retro.part(_id, "portrait_ring")), Vector2(8, 14), Vector2(112, 112))
	var vitals: Dictionary = _state.get("vitals", {})
	for index in range(RESOURCES.size()):
		var key: String = RESOURCES[index][0]
		var y := float(9 + 43 * index)
		_image(panel, Retro.texture("common/hud_" + key), Vector2(128, y + 3), Vector2(24, 24))
		_label(panel, RESOURCES[index][1], Vector2(157, y), _ink(), 12)
		var pair: Vector2 = vitals.get(key, Vector2.ZERO)
		var amount := _label(panel, "%d/%d" % [pair.x, pair.y], Vector2(303, y), _ink(), 12)
		amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		amount.size.x = 80
		var bar := TextureProgressBar.new()
		bar.texture_under = Retro.texture("common/bar_empty")
		bar.texture_progress = Retro.texture("common/bar_" + key)
		bar.max_value = maxf(1.0, pair.y)
		bar.value = clampf(pair.x, 0.0, bar.max_value)
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(bar)
		bar.position = Vector2(156, y + 19)
		bar.scale = Vector2(2.15, 1.55)

func _build_map() -> void:
	_map = Map.new()
	_contents.add_child(_map)
	_map.size = Vector2(160, 160)
	_map.set_data(_id, _state.get("map_texture"), _state.get("markers", []))
	_areas.map = _map
	var north := _label(_contents, "N", Vector2.ZERO, Color("#fff3ff"), 12)
	_areas.north = north
	var controls := VBoxContainer.new()
	_contents.add_child(controls)
	_areas.zoom = controls
	for direction in [1.0, -1.0]:
		var zoom := Retro.button(_id, "+" if direction > 0 else "-")
		zoom.custom_minimum_size = Vector2(26, 24)
		zoom.pressed.connect(_map.change_zoom.bind(direction * 0.25))
		controls.add_child(zoom)
	var clock := _panel("clock_panel", Vector2(123, 38), 6)
	_areas.clock = clock
	var phase := str(_state.get("phase", "day"))
	if phase not in ["dawn", "day", "dusk", "night"]:
		phase = "day"
	_image(clock, Retro.texture("common/time_" + phase), Vector2(8, 5), Vector2(27, 27))
	_label(clock, str(_state.get("time", "")), Vector2(42, 12), _dark(), 12)

func _slot(parent: Control, at: Vector2, entry: Dictionary, selected: bool, action: Callable, extent: int = 42) -> void:
	var slot := Retro.button(_id, "", selected)
	slot.add_theme_stylebox_override("normal", _skin("slot_selected" if selected else "slot_normal", 5))
	slot.add_theme_stylebox_override("hover", _skin("slot_hover", 5))
	slot.add_theme_stylebox_override("pressed", _skin("slot_selected", 5))
	slot.add_theme_stylebox_override("disabled", _skin("slot_disabled", 5))
	slot.custom_minimum_size = Vector2.ONE * extent
	slot.disabled = bool(entry.get("disabled", false))
	slot.tooltip_text = str(entry.get("title", ""))
	parent.add_child(slot)
	slot.position = at
	slot.pressed.connect(action)
	var icon: Texture2D = entry.get("icon")
	if icon != null:
		_image(slot, icon, Vector2.ONE * 3, Vector2.ONE * (extent - 6)).texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var count := int(entry.get("count", 0))
	if count > 1:
		var badge := Panel.new()
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.add_theme_stylebox_override("panel", _skin("hud_panel", 6))
		slot.add_child(badge)
		badge.position = Vector2(extent - 22, extent - 15)
		badge.size = Vector2(21, 14)
		_label(badge, str(count), Vector2(3, 3), _ink(), 8)

func _build_inventory() -> void:
	var layout: Array = BAG_LAYOUT[_id]
	var origin: Vector2 = layout[0]
	var stride: int = layout[1]
	var extent: int = layout[2]
	var insert := ColorRect.new()
	insert.color = Color(layout[3])
	insert.size = Vector2.ONE * (stride * 2 + extent + 8)
	insert.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_contents.add_child(insert)
	_areas.inventory_insert = insert
	var backpack := _image(_contents, Retro.texture("characters/" + _id + "/backpack"), Vector2.ZERO, Vector2(252, 273))
	_areas.backpack = backpack
	var slots: Array = _state.get("inventory", [])
	for index in range(9):
		var entry: Dictionary = slots[index] if index < slots.size() else {}
		var at := origin + Vector2(index % 3, floori(index / 3.0)) * stride
		_slot(backpack, at, entry, index == int(_state.get("selected_inventory", -1)), slot_requested.emit.bind(index), extent)
	var bar := _panel("hud_panel", Vector2(255, 63))
	_areas.hotbar = bar
	var shortcuts: Array = _state.get("shortcuts", [])
	for index in range(5):
		var entry: Dictionary = shortcuts[index] if index < shortcuts.size() else {}
		var x := float(8 + index * 49)
		var keycap := Panel.new()
		keycap.add_theme_stylebox_override("panel", _skin("hotkey_backing", 4))
		keycap.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar.add_child(keycap)
		keycap.position = Vector2(x + 10, -11)
		keycap.size = Vector2(26, 21)
		_label(keycap, str(index + 1), Vector2(8, 5), _dark(), 10)
		_slot(bar, Vector2(x, 12), entry, index == int(_state.get("selected_shortcut", -1)), shortcut_requested.emit.bind(index), 43)

func _build_quest() -> void:
	var quests: Array = _state.get("quests", [])
	if quests.is_empty():
		return
	var panel := _chrome("mission_panel", Vector2(312, 42.0 if _quest_collapsed else 50.0 + 28.0 * mini(4, quests.size())))
	_areas.quest = panel
	var title := Panel.new()
	title.add_theme_stylebox_override("panel", _skin("title_bar", 5))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(title)
	title.position = Vector2(9, 8)
	title.size = Vector2(294, 27)
	_label(title, "ЗАДАНИЯ", Vector2(8, 8), _dark())
	var collapse := Retro.button(_id, "+" if _quest_collapsed else "-")
	panel.add_child(collapse)
	collapse.position = Vector2(274, 9)
	collapse.size = Vector2(25, 24)
	collapse.pressed.connect(func() -> void:
		_quest_collapsed = not _quest_collapsed
		_refresh())
	if _quest_collapsed:
		return
	for index in range(mini(4, quests.size())):
		var row: Dictionary = quests[index]
		var done := bool(row.get("done", false))
		var icon := _image(panel, Retro.texture("common/quest_done" if done else "common/quest_empty"), Vector2(15, 46 + 28 * index), Vector2(15, 15))
		icon.modulate = _ink()
		var caption := _label(panel, str(row.get("title", "")), Vector2(38, 47 + 28 * index), _ink(), 10)
		caption.size.x = 264
		caption.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		caption.tooltip_text = caption.text

func _build_tools() -> void:
	var tool: Dictionary = _state.get("tool", {})
	if not tool.is_empty():
		var tool_panel := _chrome("slot_normal", Vector2(80, 80))
		_areas.tool = tool_panel
		tool_panel.mouse_filter = Control.MOUSE_FILTER_STOP
		_image(tool_panel, tool.get("icon"), Vector2(11, 11), Vector2(58, 58)).texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		tool_panel.gui_input.connect(_on_tool_input.bind(tool_panel))
		if not _tool_timer.is_stopped():
			var name := str(tool.get("title", ""))
			var width := clampf(22.0 + name.length() * 10.0, 106, 250)
			_tool_label = _panel("hint_panel", Vector2(width, 30), 5)
			var caption := _label(_tool_label, name, Vector2(6, 9), _ink(), 10)
			caption.size.x = width - 12
			caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			caption.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	for kind in ["hint", "location"]:
		var value := str(_state.get(kind, ""))
		if value.is_empty():
			continue
		var w := clampf(24.0 + value.length() * 10.0, 160, 500)
		var plate := _panel("hint_panel", Vector2(w, 36), 5)
		_areas[kind] = plate
		var caption := _label(plate, value, Vector2(11, 12), _ink(), 10)
		caption.size.x = w - 20
		caption.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

func _on_tool_input(event: InputEvent, panel: Control) -> void:
	if not event is InputEventMouseButton or not event.pressed:
		return
	if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		tool_cycle_requested.emit(-1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1)
		panel.accept_event()

func _position() -> void:
	if _areas.is_empty():
		return
	_areas.vitals.position = Vector2(18, 16)
	_areas.map.position = Vector2(size.x - 198, 16)
	_areas.north.position = _areas.map.position + Vector2(74, -3)
	_areas.zoom.position = _areas.map.position + Vector2(158, 59)
	_areas.clock.position = _areas.map.position - Vector2(127, -10)
	_areas.backpack.position = Vector2(15, size.y - 284)
	_areas.inventory_insert.position = _areas.backpack.position + BAG_LAYOUT[_id][0] - Vector2.ONE * 4
	_areas.hotbar.position = Vector2(275, size.y - 74)
	if _areas.has("quest"):
		_areas.quest.position = Vector2(18, 169)
	if _areas.has("tool"):
		var tool_x := size.x - 565 if _inspector_open else size.x - 98
		_areas.tool.position = Vector2(tool_x, size.y - 98)
		if is_instance_valid(_tool_label):
			_tool_label.position = Vector2(clampf(tool_x + 40 - _tool_label.size.x / 2.0, 0, size.x - _tool_label.size.x), size.y - 134)
	if _areas.has("hint"):
		_areas.hint.position = Vector2((size.x - _areas.hint.size.x) / 2.0 - 74, size.y - 170)
	if _areas.has("location"):
		_areas.location.position = Vector2(275, size.y - 123)
