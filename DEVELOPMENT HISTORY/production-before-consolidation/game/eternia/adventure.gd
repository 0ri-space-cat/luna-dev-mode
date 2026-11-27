extends "res://scripts/runtime2d/world_controller_2d.gd"
## Geography review. Ordinary exits and the author's room picker are independent.
const Layout = preload("res://eternia/landscape.gd")
const DIRECTIONS := [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]
var rooms := {}
var exits := {}
var status := Label.new()
var panel := PanelContainer.new()
var tabs := TabContainer.new()

func _ready() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(catalog_path))
	for room in data.locations:
		rooms[room.id] = room
	location_entered.connect(build_room)
	super._ready()
	var overlay := CanvasLayer.new()
	add_child(overlay)
	overlay.add_child(status)
	status.position = Vector2(18,14)
	overlay.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 32
	panel.offset_right = -32
	panel.offset_top = 40
	panel.offset_bottom = -28
	panel.add_child(tabs)
	panel.process_mode = Node.PROCESS_MODE_ALWAYS
	var picker := add_tab("География")
	for id in rooms:
		var button := Button.new()
		button.text = rooms[id].title
		button.pressed.connect(review_room.bind(id))
		picker.add_child(button)
	var pool: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://eternia/content_pool.json"))
	for category in pool:
		var list := add_tab(category)
		for item in pool[category]:
			var entry := Label.new()
			entry.text = item.name+"   ·   "+item.note
			entry.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			list.add_child(entry)
	panel.hide()

func add_tab(title: String) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = title
	tabs.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	var close := Button.new()
	close.text = "Вернуться на карту"
	close.pressed.connect(toggle_panel)
	list.add_child(close)
	return list

func build_room(id: String) -> void:
	var room: Dictionary = rooms[id]
	exits.clear()
	for i in room.links.size():
		exits[room.links[i]] = DIRECTIONS[i] * Vector2(490,255)
	_live_level.geometry.build_from_description({"solids":room.solids})
	var layout := Layout.new()
	layout.tint = Color(room.color)
	for dest in exits:
		layout.paths[rooms[dest].title] = exits[dest]
	_live_level.add_child(layout)
	_live_level.move_child(layout,1)
	camera.limit_left = -600
	camera.limit_right = 600
	camera.limit_top = -350
	camera.limit_bottom = 350

func _process(delta: float) -> void:
	super._process(delta)
	player.position = player.position.clamp(Vector2(-570,-320),Vector2(570,320))
	status.text = rooms[current_location_id].title+"    ·    Tab — каталог и география"
	for id in exits:
		if player.position.distance_to(exits[id]) < 70:
			status.text += "    ·    E — "+rooms[id].title

func toggle_panel() -> void:
	panel.visible = not panel.visible
	player.set_physics_process(not panel.visible)

func review_room(id: String) -> void:
	if _enter_location(id): toggle_panel()

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	if event.physical_keycode == KEY_TAB or (event.physical_keycode == KEY_ESCAPE and panel.visible):
		toggle_panel()
	elif event.physical_keycode == KEY_E and not panel.visible:
		for id in exits:
			if player.position.distance_to(exits[id]) < 70:
				var origin := current_location_id
				if _enter_location(id): player.position = exits[origin] * 0.8
				return
