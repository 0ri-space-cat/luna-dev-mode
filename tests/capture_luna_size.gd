extends SceneTree
func _initialize() -> void: call_deferred("_capture")
func _capture() -> void:
 var scene = load("res://scenes/2d/luna_art_preview.tscn").instantiate()
 root.add_child(scene)
 scene.set_process(false)
 scene._show_view("front_right")
 for entry in [[0.5,"05x"],[1.0,"1x"],[2.0,"2x"]]:
  scene.size_multiplier = entry[0]
  scene._apply_size()
  scene.animator.apply(scene.front_right,"front_right","idle",0.0,scene.BASE_SCALE*entry[0],0.0)
  scene.camera.force_update_scroll()
  await process_frame
  await RenderingServer.frame_post_draw
  assert(root.get_texture().get_image().save_png("res://docs/screenshots/luna_size_%s.png" % entry[1]) == OK)
 print("Captured actual Godot SIZE screenshots: 0.5x, 1x, 2x")
 quit()
