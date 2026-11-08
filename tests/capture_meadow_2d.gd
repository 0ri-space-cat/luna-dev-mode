extends SceneTree
## CI visual artifact. Runs with a display (xvfb) to inspect true Godot output.
func _initialize() -> void:
	call_deferred("_capture")
func _capture() -> void:
	root.size = Vector2i(1280,800)
	var source: PackedScene = load("res://scenes/2d/world_2d.tscn")
	if source == null:
		push_error("Could not load Eternia")
		quit(1)
		return
	var scene: Node2D = source.instantiate() as Node2D
	root.add_child(scene)
	for i in range(15):
		await process_frame
	if not is_instance_valid(scene):
		quit(1)
		return
	var image: Image = root.get_texture().get_image()
	if image == null or image.is_empty():
		push_error("No framebuffer image")
		quit(1)
		return
	var path := "user://eternia_preview.png"
	var error: Error = image.save_png(path)
	if error != OK:
		push_error("Screenshot export failed: %s" % error)
		quit(1)
		return
	print("ETERNIA_SCREENSHOT_OK: " + ProjectSettings.globalize_path(path))
	scene.queue_free()
	quit()
