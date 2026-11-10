extends SceneTree
func _initialize() -> void: call_deferred("_capture")
func _capture() -> void:
 var scene = load("res://scenes/2d/luna_art_preview.tscn").instantiate()
 root.add_child(scene)
 scene.set_process(false)
 await process_frame
 var path = OS.get_cmdline_user_args()[0]
 var view = path.get_base_dir().get_file()
 scene._show_view(view)
 var sprite = scene.sprite_for_view(view)
 var image = Image.load_from_file(ProjectSettings.globalize_path(path))
 sprite.texture = ImageTexture.create_from_image(image)
 sprite.set_meta("feet_y", image.get_used_rect().end.y)
 scene._update_anchor(sprite)
 await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://docs/screenshots/luna_animation_latest_cel.png")
 quit()
