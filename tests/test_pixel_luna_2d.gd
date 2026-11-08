extends SceneTree
## Two-frame front/side/back sprite pipeline, using synthetic pixels only for QA.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var src: PackedScene = load("res://scenes/2d/world_2d.tscn")
	var meadow := src.instantiate() as Node2D
	root.add_child(meadow)
	await process_frame
	var luna: Node2D = meadow.get_node("Entities/Player/Visual")
	var invalid := Image.create(120, 576, false, Image.FORMAT_RGBA8)
	assert(not luna.install_pixel_sprite(ImageTexture.create_from_image(invalid)))
	assert(luna.animated == null)
	var img := Image.create(96, 576, false, Image.FORMAT_RGBA8)
	img.fill(Color("#d6a3e9"))
	assert(luna.install_pixel_sprite(ImageTexture.create_from_image(img)))
	assert(luna.animated != null)
	assert(luna.animated.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST)
	assert(luna.animated.scale == Vector2(2,2))
	assert(luna.animated.sprite_frames.get_frame_count("walk_down") == 2)
	assert(luna.animated.sprite_frames.get_frame_count("cast_right") == 2)
	assert(not luna.body.visible and not luna.boot_left.visible and not luna.left_arm.visible)
	luna.set_motion(Vector2.RIGHT * 100.0, false, .1, Vector2.UP * 200.0)
	assert(luna.animated.animation == "walk_up")
	luna.set_motion(Vector2.ZERO, false, .1, Vector2.LEFT * 200.0)
	assert(luna.animated.animation == "idle_right" and luna.animated.flip_h)
	luna.set_motion(Vector2.ZERO, false, .1, Vector2.RIGHT * 200.0)
	assert(luna.animated.animation == "idle_right" and not luna.animated.flip_h)
	luna.trigger_action("cast", .3)
	luna.set_motion(Vector2.ZERO, false, .1, Vector2.DOWN * 200.0)
	assert(luna.animated.animation == "cast_down")
	meadow.queue_free()
	print("Pixel Luna three-view sheet and mouse-facing: PASS")
	quit()
