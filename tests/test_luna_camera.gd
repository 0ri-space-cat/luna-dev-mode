extends SceneTree
## Whole high-resolution canvases stay visible at all supported SIZE values and world edges.
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
 var scene = load("res://scenes/2d/luna_art_preview.tscn").instantiate()
 root.add_child(scene)
 scene.set_process(false)
 await process_frame
 for multiplier in [0.5,1.0,2.0]:
  scene.size_multiplier = multiplier
  scene._apply_size()
  for position in [Vector2.ZERO, Vector2(1472,0), Vector2(0,1024), Vector2(1472,1024), Vector2(736,512)]:
   scene.luna.position = position
   scene._clamp_position()
   scene.camera.force_update_scroll()
   await process_frame
   var viewport_rect: Rect2 = root.get_visible_rect()
   var world_rect: Rect2 = scene.get_global_transform_with_canvas() * Rect2(Vector2.ZERO,scene.WORLD_SIZE)
   assert(world_rect.grow(1.0).encloses(viewport_rect), "Camera exposes outside world")
   for view in scene.ASSETS:
    scene._show_view(view)
    var sprite: Sprite2D = scene.sprite_for_view(view)
    for clip in {"idle":[0.0],"walk":[0.0,0.125,0.25,0.375],"cast":[0.10,0.21],"blink":[0.10],"hair":[0.15]}:
     var times = {"idle":[0.0],"walk":[0.0,0.125,0.25,0.375],"cast":[0.10,0.21],"blink":[0.10],"hair":[0.15]}[clip]
     for time in times:
      scene.animator.apply(sprite,view,clip,time,scene.BASE_SCALE*multiplier,0.0)
      var bounds: Rect2 = sprite.get_global_transform_with_canvas() * sprite.get_rect()
      assert(viewport_rect.grow(1.0).encloses(bounds), "Cropped Luna at SIZE=" + str(multiplier) + " view=" + view + " clip=" + clip + " rect=" + str(bounds))
 scene.queue_free()
 print("Luna camera: full canvases and ground coverage at 0.5x, 1x, 2x / all world corners PASS")
 quit()
