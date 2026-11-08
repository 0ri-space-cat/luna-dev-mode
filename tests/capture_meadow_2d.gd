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

	# Separate screenshot of the actual parameter editor, no mockup or baked art.
	var hack: Variant = scene.get("session")
	hack.touch_rift()
	var environment: Variant = scene.get("world")
	var actor: Node = environment.get_entity("tree_01")
	var editor: Control = scene.get("inspector")
	editor.call("open_actor", actor, scene.get("processor"), scene.get("registry"), hack)
	for i in range(5):
		await process_frame
	var editor_image: Image = root.get_texture().get_image()
	var editor_path := "user://eternia_editor_preview.png"
	if editor_image != null and not editor_image.is_empty():
		var saved: Error = editor_image.save_png(editor_path)
		if saved == OK:
			print("ETERNIA_EDITOR_SCREENSHOT_OK: " + ProjectSettings.globalize_path(editor_path))

	scene.queue_free()
	quit()
