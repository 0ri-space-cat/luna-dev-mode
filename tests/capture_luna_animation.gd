extends SceneTree
## Render animation frames through the real scene/controller for visual QA.
func _initialize() -> void: call_deferred("_capture")
func _capture() -> void:
 var args := OS.get_cmdline_user_args()
 var view := args[0] if args.size() > 0 else "front_right"
 var clip := args[1] if args.size() > 1 else "walk"
 var out := "res://docs/screenshots/animation_frames/" + view + "_" + clip
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
 var scene = load("res://scenes/2d/luna_art_preview.tscn").instantiate()
 root.add_child(scene)
 scene.set_process(false)
 scene._show_view(view)
 await process_frame
 var sprite: Sprite2D = scene.sprite_for_view(view)
 for i in range(32):
  var phase := float(i) / 16.0
  var bounce := absf(sin(phase * TAU * 2.0)) * 1.5 if clip == "walk" else 0.0
  scene.animator.apply(sprite, view, clip, phase, scene.BASE_SCALE, bounce)
  await process_frame
  await RenderingServer.frame_post_draw
  var feet = scene.luna.get_global_transform_with_canvas().origin
  var crop := Rect2i(int(feet.x)-240, int(feet.y)-340, 480, 400)
  assert(root.get_texture().get_image().get_region(crop).save_png(out + "/%02d.png" % i) == OK)
 print("Captured actual Godot animation frames: ", out)
 quit()
