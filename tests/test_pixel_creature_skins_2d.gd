extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var src: PackedScene = load("res://scenes/2d/world_2d.tscn")
	var meadow := src.instantiate() as Node2D
	root.add_child(meadow)
	await process_frame
	var world: Variant = meadow.get("world")
	var fridge: Node2D = world.get_entity("fridge_01")
	var tree: Node2D = world.get_entity("tree_01")
	var duck: Node2D = world.get_entity("duck_01")
	var sheep: Node2D = world.get_entity("sheep_01")
	assert(fridge.visual.legs != null and tree.visual.legs != null)
	assert(duck.visual.legs.kind == "" and sheep.visual.legs.kind == "")
	assert(not duck.visual.legs.visible and not sheep.visual.legs.visible)
	var paint := Image.create(64, 80, false, Image.FORMAT_RGBA8)
	paint.fill(Color("#d6a3ef"))
	var tex := ImageTexture.create_from_image(paint)
	assert(fridge.visual.install_pixel_skin(tex))
	assert(tree.visual.install_pixel_skin(tex))
	assert(duck.visual.install_pixel_skin(tex))
	assert(fridge.visual.uses_pixel_skin and tree.visual.uses_pixel_skin)
	assert(fridge.visual.sprite.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST)
	assert(fridge.visual.sprite.scale == Vector2.ONE)
	assert(duck.visual.uses_pixel_skin)
	assert(not duck.visual.legs.visible)
	assert(fridge.set_parameter("alive", true))
	await physics_frame
	await process_frame
	assert(fridge.visual.legs.visible)
	assert(not duck.visual.legs.visible)
	meadow.queue_free()
	print("Pixel creature source override / universal legs scope: PASS")
	quit()
