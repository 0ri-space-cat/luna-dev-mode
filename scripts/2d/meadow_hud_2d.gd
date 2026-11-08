extends CanvasLayer
## Lightweight 2D gameplay HUD; existing prepared art is used when present.
const Profiles = preload("res://scripts/2d/character_ui_profile.gd")
const Minimap = preload("res://scripts/2d/meadow_minimap_2d.gd")
var character_id := "luna"
var portrait: TextureRect
var backpack_texture: TextureRect
var header: Label
var status: Label
var prompt: Label
var minmap: Control
var avatar_color := Color("#d85aff")

func _ready() -> void:
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	portrait = TextureRect.new()
	portrait.position = Vector2(12, 12)
	portrait.custom_minimum_size = Vector2(104, 104)
	portrait.size = Vector2(104, 104)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(portrait)
	header = Label.new()
	header.position = Vector2(125, 14)
	header.add_theme_font_size_override("font_size", 18)
	overlay.add_child(header)
	var bars := ["HEALTH    120 / 120", "MANA        80 / 80", "STAMINA  100 / 100"]
	var colors := [Color("#fd6fae"), Color("#56dce8"), Color("#ffca53")]
	for i in range(bars.size()):
		var bar := ProgressBar.new()
		bar.position = Vector2(125, 42 + 29 * i)
		bar.size = Vector2(255, 19)
		bar.value = 100
		bar.show_percentage = false
		var fill := StyleBoxFlat.new()
		fill.bg_color = colors[i]
		fill.set_corner_radius_all(5)
		bar.add_theme_stylebox_override("fill", fill)
		overlay.add_child(bar)
		var caption := Label.new()
		caption.text = bars[i]
		caption.position = Vector2(5, -1)
		caption.add_theme_color_override("font_color", Color("#271a45"))
		bar.add_child(caption)
	minmap = Minimap.new()
	minmap.position = Vector2(1130, 10)
	minmap.custom_minimum_size = Vector2(128, 128)
	minmap.size = Vector2(128, 128)
	minmap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(minmap)
	var bag := TextureRect.new()
	bag.position = Vector2(18, 520)
	bag.size = Vector2(190, 260)
	bag.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bag.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	bag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bag.name = "BagTexture"
	backpack_texture = bag
	overlay.add_child(bag)
	status = Label.new()
	status.position = Vector2(235, 735)
	status.add_theme_font_size_override("font_size", 16)
	status.add_theme_color_override("font_color", Color("#fcf0fe"))
	overlay.add_child(status)
	prompt = Label.new()
	prompt.position = Vector2(395, 20)
	prompt.add_theme_font_size_override("font_size", 16)
	prompt.add_theme_color_override("font_color", Color("#fff8d4"))
	overlay.add_child(prompt)
	set_character("luna")
	set_status("WASD / стрелки — ходить • ЛКМ — выбрать • E — взаимодействовать")

func set_character(id: String) -> void:
	character_id = id
	var profile: Dictionary = Profiles.get_profile(id)
	avatar_color = profile["accent"]
	header.text = str(profile["title"]) + " • " + str(profile["tool"])
	var p := "res://assets/characters/%s/ui/portrait.png" % id
	if ResourceLoader.exists(p):
		portrait.texture = load(p)
	var bag_path := "res://assets/characters/%s/ui/backpack.png" % id
	if ResourceLoader.exists(bag_path):
		backpack_texture.texture = load(bag_path)

func set_status(message: String) -> void:
	if is_instance_valid(status):
		status.text = message

func set_prompt(message: String) -> void:
	if is_instance_valid(prompt):
		prompt.text = message

func set_targets(player: Node2D, actors: Array) -> void:
	minmap.set_targets(player, actors)
