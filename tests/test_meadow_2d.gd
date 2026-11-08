extends SceneTree
const Save2D = preload("res://scripts/2d/meadow_save_2d.gd")
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var source: PackedScene = load("res://scenes/2d/world_2d.tscn")
	assert(source != null, "2D scene must load")
	var meadow: Node2D = source.instantiate() as Node2D
	assert(meadow != null)
	root.add_child(meadow)
	await process_frame
	var editor: PanelContainer = meadow.get("inspector")
	assert(editor != null)
	var save_button: Button = editor.get("save_button")
	var copy_button: Button = editor.get("copy_button")
	var delete_button: Button = editor.get("delete_button")
	assert(save_button != null and save_button.text == "Сохранить")
	assert(editor.custom_minimum_size.x < editor.custom_minimum_size.y)
	assert(editor.size.x < editor.size.y)
	assert(editor.custom_minimum_size == Vector2(390, 610))
	assert(copy_button.text.is_empty() and delete_button.text.is_empty())
	assert(editor.position.x + editor.size.x <= meadow.get_viewport_rect().size.x)
	assert(editor.position.y + editor.size.y <= meadow.get_viewport_rect().size.y)
	assert(copy_button != null and copy_button.tooltip_text == "Копировать объект")
	assert(delete_button != null and delete_button.tooltip_text == "Удалить объект")
	assert(save_button.pressed.is_connected(Callable(editor, "_request_save")))
	assert(editor.save_requested.is_connected(Callable(meadow, "_save")))
	var world: Variant = meadow.get("world")
	var registry: Variant = meadow.get("registry")
	var processor: Variant = meadow.get("processor")
	var hack: Variant = meadow.get("session")
	var player: CharacterBody2D = meadow.get_node("Entities/Player")
	var tree: Node = world.get_entity("tree_01")
	assert(tree != null and world.count_live() == 6)
	assert(meadow.get_node("Terrain") is TileMapLayer)
	assert(meadow.get_node("Entities/Player/Visual").has_method("set_motion"))
	var luna = meadow.get_node("Entities/Player/Visual")
	luna.call("set_motion", Vector2.RIGHT*200.0, false, 0.1)
	assert(luna.facing == "right")
	assert(luna.right_hand != null and luna.left_hand != null)
	assert(luna.boot_left != null and luna.boot_right != null)
	assert(luna.wand.position.distance_to(luna.right_hand.position-Vector2(0,16)) < 1.1)
	luna.call("set_motion", Vector2.LEFT*200.0, false, 0.1)
	assert(luna.facing == "left")
	assert(luna.wand.position.distance_to(luna.left_hand.position-Vector2(0,16)) < 1.1)
	luna.call("set_motion", Vector2.UP*200.0, true, 0.1)
	assert(luna.facing == "up" and luna.mode == "run")
	luna.call("set_motion", Vector2.DOWN*200.0, false, 0.1)
	assert(luna.facing == "down")
	luna.call("trigger_action", "cast", 0.2)
	assert(luna.mode == "cast")
	assert(world.get_entity("duck_01") != null)
	assert(world.get_entity("slime_01") != null)
	for filename in [
		"res://assets/2d/characters/luna/luna_front.svg",
		"res://assets/2d/characters/luna/luna_back.svg",
		"res://assets/2d/characters/luna/luna_side.svg",
		"res://assets/2d/creatures/sheep.svg",
		"res://assets/2d/creatures/fridge.svg",
		"res://assets/2d/creatures/duck.svg",
		"res://assets/2d/creatures/tree.svg",
		"res://assets/2d/creatures/slime.svg",
		"res://assets/2d/creatures/sheep_front.svg",
		"res://assets/2d/creatures/sheep_back.svg",
		"res://assets/2d/creatures/duck_front.svg",
		"res://assets/2d/creatures/duck_back.svg",
		"res://assets/2d/creatures/fridge_side.svg",
		"res://assets/2d/creatures/fridge_back.svg",
		"res://assets/2d/characters/luna/hand.svg",
		"res://assets/2d/characters/luna/boot.svg",
		"res://assets/2d/props/portal.svg",
		"res://assets/2d/props/waterfall.svg",
		"res://assets/2d/props/lake.svg"
	]:
		assert(ResourceLoader.exists(filename), "Missing game-ready SVG: " + filename)
	for icon_id in ["wand","hourglass","donut","apple","crystal","book","health","mana","stamina","copy","delete","done"]:
		assert(ResourceLoader.exists("res://assets/2d/ui/icons/" + icon_id + ".svg"))
	for tile_id in range(1,13):
		var art := "res://assets/2d/eternia/terrain/grass_%d.png" % tile_id
		assert(ResourceLoader.exists(art), "Expected imported PNG terrain: " + art)
	for prop in ["flower_bush","moss_arch","pink_crystals","oracle_pedestal","walking_fridge","berry_tree"]:
		var asset: String = "res://assets/2d/eternia/props/" + str(prop) + ".webp"
		assert(ResourceLoader.exists(asset), "Expected imported RGBA prop: " + asset)
	assert(not hack.can_edit("alive"))
	hack.touch_rift()
	assert(hack.edit(tree, "alive", true, processor))
	assert(bool(tree.call("get_parameter", "alive")))
	assert(processor.undo())
	assert(not bool(tree.call("get_parameter", "alive")))
	assert(processor.redo())
	assert(bool(tree.call("get_parameter", "alive")))
	assert(not hack.can_edit("ai_enabled"))
	assert(hack.copy_wand() and hack.upgrade_original())
	assert(hack.can_edit("ai_enabled"))
	assert(hack.edit(tree, "ai_enabled", false, processor))
	var path := "user://test_2d_meadow_snapshot.json"
	var saving = Save2D.new(path)
	assert(saving.write(player, world, hack))
	var expected := player.position
	player.position = Vector2(100, 100)
	assert(hack.edit(tree, "alive", false, processor))
	assert(saving.read(player, world, hack, registry))
	assert(player.position == expected)
	assert(bool(tree.call("get_parameter", "alive")))
	assert(not bool(tree.call("get_parameter", "ai_enabled")))
	var invalid := saving.snapshot(player, world, hack)
	invalid["player"] = [1.0, 2.0, 3.0]
	assert(not saving.apply_snapshot(invalid, player, world, hack, registry))
	assert(player.position == expected)
	assert(bool(tree.call("get_parameter", "alive")))
	var lifecycle: Variant = meadow.get("lifecycle")
	assert(lifecycle != null)
	var blueprint: Dictionary = lifecycle.clone_blueprint("duck_01", Vector2(870, 610))
	assert(not blueprint.is_empty())
	var copy: Node = processor.execute_entity_create(lifecycle, blueprint)
	assert(copy != null and world.count_live() == 7)
	assert(processor.undo() and world.count_live() == 6)
	assert(processor.redo() and world.count_live() == 7)
	assert(saving.write(player, world, hack))
	assert(processor.execute_entity_delete(lifecycle, str(blueprint["id"])))
	assert(world.count_live() == 6)
	assert(saving.read(player, world, hack, registry, lifecycle))
	assert(world.count_live() == 7)
	assert(world.get_entity(str(blueprint["id"])) != null)
	meadow.queue_free()
	print("2D meadow gameplay and save: PASS")
	quit()
