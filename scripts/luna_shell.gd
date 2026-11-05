extends Control
## Asset-ready HUD shell. Deliberately labels unbound gameplay data as TBD.
signal panel_requested(panel_id: String)
var locale := "en"
var inventory_service
var world_registry
var asset_registry
var avatar_fallback: Label
var avatar_texture: TextureRect
var hud_status: Label
var inventory_text := ""
var panel: PanelContainer
var panel_title: Label
var panel_body: Label
var buttons: Dictionary = {}
const PANEL_NAMES := ["INVENTORY", "HACK", "MAGIC", "DIALOGUE", "JOURNAL", "MAP", "SETTINGS", "HELP"]

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()

func configure(inventory, world, current_locale: String, assets = null) -> void:
	inventory_service = inventory
	world_registry = world
	locale = current_locale
	asset_registry = assets
	_apply_portrait()
	_refresh_inventory()

func _build() -> void:
	var hud := PanelContainer.new()
	hud.position = Vector2(22, 88)
	hud.custom_minimum_size = Vector2(250, 202)
	_style(hud, Color("28233e"), Color("b78cff"))
	add_child(hud)
	var stack := VBoxContainer.new()
	hud.add_child(stack)
	var row := HBoxContainer.new()
	stack.add_child(row)
	avatar_fallback = Label.new()
	avatar_fallback.text = "✦"
	avatar_fallback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	avatar_fallback.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	avatar_fallback.custom_minimum_size = Vector2(62, 62)
	avatar_fallback.add_theme_font_size_override("font_size", 38)
	avatar_fallback.add_theme_color_override("font_color", Color("ffc8f0"))
	row.add_child(avatar_fallback)
	avatar_texture = TextureRect.new()
	avatar_texture.custom_minimum_size = Vector2(62, 62)
	avatar_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	avatar_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	avatar_texture.visible = false
	row.add_child(avatar_texture)
	var identity := VBoxContainer.new()
	row.add_child(identity)
	identity.add_child(_label("LUNA", 19, Color("f5ddff")))
	identity.add_child(_label("LEVEL — TBD", 12, Color("cbbde1")))
	for stat in ["HEALTH", "MANA", "STAMINA"]:
		var stat_row := HBoxContainer.new()
		stack.add_child(stat_row)
		stat_row.add_child(_label(stat, 12, Color("e9ddff")))
		var bar := ProgressBar.new()
		bar.name = stat + "Slot"
		bar.custom_minimum_size = Vector2(96, 13)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.value = 0
		bar.show_percentage = false
		bar.tooltip_text = "Gameplay value not connected yet"
		stat_row.add_child(bar)
		stat_row.add_child(_label("—", 12, Color("b9abc9")))
	hud_status = _label("PLACEHOLDER • DATA NOT CONNECTED", 10, Color("8cefe0"))
	stack.add_child(hud_status)

	var minimap := PanelContainer.new()
	minimap.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	minimap.position = Vector2(-250, 56)
	minimap.custom_minimum_size = Vector2(226, 142)
	_style(minimap, Color("20243c"), Color("6ce4d3"))
	add_child(minimap)
	var map_box := VBoxContainer.new()
	minimap.add_child(map_box)
	map_box.add_child(_label("WORLD MAP • PLACEHOLDER", 12, Color("bffcf0")))
	var map_view := ColorRect.new()
	map_view.custom_minimum_size = Vector2(196, 92)
	map_view.color = Color("3d694a")
	map_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_box.add_child(map_view)
	var marker := Label.new()
	marker.text = "✦"
	marker.position = Vector2(88, 24)
	marker.add_theme_color_override("font_color", Color("ffb6e2"))
	map_view.add_child(marker)

	var quickbar := HBoxContainer.new()
	quickbar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	quickbar.position = Vector2(-210, -64)
	quickbar.custom_minimum_size = Vector2(420, 48)
	quickbar.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(quickbar)
	for i in range(1, 6):
		var slot := Button.new()
		slot.text = "%d\n—" % i
		slot.custom_minimum_size = Vector2(62, 46)
		slot.tooltip_text = "Quick slot placeholder; assignment is not implemented"
		quickbar.add_child(slot)

	var nav := HBoxContainer.new()
	nav_fix(nav)
	for panel_id in PANEL_NAMES:
		var button := Button.new()
		button.text = panel_id
		button.pressed.connect(_open_panel.bind(panel_id))
		nav.add_child(button)
		buttons[panel_id] = button
	var inventory_layout := VBoxContainer.new()
	panel = PanelContainer.new()
	panel.position = Vector2(286, 108)
	panel.custom_minimum_size = Vector2(360, 240)
	panel.visible = false
	_style(panel, Color("28233e"), Color("aa8ae0"))
	add_child(panel)
	panel.add_child(inventory_layout)
	panel_title = _label("", 18, Color("e4caff"))
	inventory_layout.add_child(panel_title)
	panel_body = _label("", 13, Color("eee5f6"))
	panel_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inventory_layout.add_child(panel_body)
	var close := Button.new()
	close.text = "CLOSE"
	close.pressed.connect(func(): panel.visible = false)
	inventory_layout.add_child(close)
	_refresh_inventory()

func nav_fix(nav: HBoxContainer) -> void:
	nav.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE, Control.PRESET_MODE_MINSIZE)
	nav.position = Vector2(12, -112)
	nav.custom_minimum_size.y = 40
	nav.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(nav)

func _open_panel(panel_id: String) -> void:
	if panel_id == "INVENTORY":
		_refresh_inventory()
		panel_title.text = "BACKPACK • ENTITY ITEMS"
		panel_body.text = inventory_text
	elif panel_id == "HACK":
		panel_title.text = "REALITY EDITOR"
		panel_body.text = "Click a world object to open the existing COPY / DELETE / DONE editor.\nThe editor is not an inventory action."
	elif panel_id == "MAGIC":
		panel.visible = false
		panel_requested.emit(panel_id)
		return
	elif panel_id == "JOURNAL":
		panel.visible = false
		panel_requested.emit(panel_id)
		return
	else:
		panel_title.text = panel_id + " • FOUNDATION"
		panel_body.text = "Visual and interaction slot prepared.\nThis feature is not implemented yet."
	panel.visible = true

func _apply_portrait() -> void:
	if asset_registry == null or not is_instance_valid(avatar_texture):
		return
	var portrait: Resource = asset_registry.load_asset("luna.portrait")
	if portrait is Texture2D:
		avatar_texture.texture = portrait
		avatar_texture.visible = true
		avatar_fallback.visible = false

func _refresh_inventory() -> void:
	if inventory_service == null or world_registry == null:
		inventory_text = "Inventory service unavailable."
		return
	var items: Array[String] = inventory_service.list_items("luna")
	if items.is_empty():
		inventory_text = "No carried entities.\n\nSlot grid: visual placeholder.\nPickup / drop controls are not connected to this panel."
		return
	var lines := PackedStringArray(["Carried entities (%d):" % items.size()])
	for item_id in items:
		var item: Node = world_registry.get_entity(item_id)
		var category := str(item.record.category) if item != null and item.get("record") != null else "ENTITY"
		lines.append("□  %s  •  %s" % [item_id, category.to_upper()])
	lines.append("\nSelection/use/drop UI is not implemented yet.")
	inventory_text = "\n".join(lines)

func _label(value: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label

func _style(control: Control, background: Color, outline: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = outline
	style.set_border_width_all(2)
	style.set_corner_radius_all(9)
	style.set_content_margin_all(10)
	control.add_theme_stylebox_override("panel", style)
