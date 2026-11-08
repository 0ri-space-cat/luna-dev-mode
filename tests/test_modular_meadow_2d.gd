extends SceneTree
## Repeatable meadow + authored decor and cursor-aim regression.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: PackedScene = load("res://scenes/2d/world_2d.tscn")
	assert(scene != null)
	var meadow := scene.instantiate() as Node2D
	root.add_child(meadow)
	await process_frame
	var ground := meadow.get_node("GroundSurface") as Sprite2D
	assert(ground != null and ground.texture != null)
	assert(ground.region_enabled and not ground.centered)
	assert(ground.region_rect.size == Vector2(1472, 1024))
	assert(ground.texture_repeat == CanvasItem.TEXTURE_REPEAT_ENABLED)
	assert(ground.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST)
	assert(ground.get("source_path") != "")
	assert(not meadow.get_node("Terrain").visible)
	var scatter := meadow.get_node("GroundDecorScatter")
	assert(scatter != null and scatter.spawned.size() >= 12)
	for sprite in scatter.spawned:
		assert(sprite.texture != null)
		assert(scatter._is_safe(sprite.get_meta("ground_point")))
	var luna := meadow.get_node("Entities/Player/Visual")
	luna.call("set_motion", Vector2.RIGHT * 200.0, false, 0.1, Vector2.UP * 200.0)
	assert(luna.facing == "up")
	luna.call("set_motion", Vector2.ZERO, false, 0.1, Vector2.LEFT * 200.0)
	assert(luna.facing == "left")
	luna.call("set_motion", Vector2.RIGHT * 200.0, false, 0.1, Vector2.DOWN * 200.0)
	assert(luna.facing == "down")
	luna.call("set_motion", Vector2.RIGHT * 200.0, false, 0.1)
	assert(luna.facing == "right")
	meadow.queue_free()
	print("Modular meadow ground / decor / independent aim: PASS")
	quit()
