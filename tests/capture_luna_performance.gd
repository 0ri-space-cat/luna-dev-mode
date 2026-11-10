extends SceneTree
## Render a deterministic playable-controller demonstration, not an illustration mockup.
var releases := 0
func _on_release(_direction: Vector2) -> void: releases += 1
func _initialize() -> void: call_deferred("_capture")
func _capture() -> void:
 var out := "res://docs/screenshots/luna_performance_frames"
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
 var scene = load("res://scenes/2d/luna_art_preview.tscn").instantiate()
 root.add_child(scene)
 scene.set_process(false)
 scene.cast_released.connect(_on_release)
 await process_frame
 var directions := [Vector2.DOWN, Vector2(1,1), Vector2.RIGHT, Vector2(1,-1), Vector2.UP, Vector2(-1,-1), Vector2.LEFT, Vector2(-1,1)]
 for i in range(192):
  var move := Vector2.ZERO
  var aim := Vector2(1,1)
  if i < 80:
   aim = directions[i / 10]
   move = aim.normalized()
  if i == 80: scene.blink_wait = 0.001
  if i in [96,112,128,144]:
   var view = {96:"front_right",112:"side_right",128:"back_right",144:"front"}[i]
   scene._show_view(view)
   scene.request_cast()
  if i >= 96 and i < 160:
   aim = {0:Vector2(1,1),1:Vector2.RIGHT,2:Vector2(1,-1),3:Vector2.DOWN}[(i - 96) / 16]
  if i == 160:
   scene.hair_wait = 0.001
   scene.blink_wait = 99.0
  scene.advance_animation(1.0/16.0, move, aim)
  await process_frame
  await RenderingServer.frame_post_draw
  var full := root.get_texture().get_image()
  var feet = scene.luna.get_global_transform_with_canvas().origin
  var crop := Rect2i(int(feet.x)-240, int(feet.y)-340, 480, 400)
  assert(full.get_region(crop).save_png(out + "/%03d.png" % i) == OK)
  if i in [0,100,132,164]: full.save_png("res://docs/screenshots/luna_live_%03d.png" % i)
 assert(releases == 4)
 print("Captured 192 real Godot controller frames: walks, blink, casts and hair idle")
 quit()
