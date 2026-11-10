extends SceneTree
## Verify the playable turnaround: all eight directions, mirrors and feet at SIZE extremes.
func _initialize() -> void:
 call_deferred("_run")

func _run() -> void:
 var scene = load("res://scenes/2d/luna_art_preview.tscn").instantiate()
 root.add_child(scene)
 scene.set_process(false)
 await process_frame
 var sprites := []
 for name in ["Front", "FrontRight", "SideRight", "Back", "BackRight"]:
  var sprite := scene.get_node("LunaRig/" + name) as Sprite2D
  assert(sprite.texture != null)
  assert(sprite.texture.get_size() == Vector2(1024, 1536))
  assert(sprite.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST)
  sprites.append(sprite)
 var cases := [
  [Vector2.DOWN, "front", "Front", false],
  [Vector2(1,1), "front_right", "FrontRight", false],
  [Vector2(-1,1), "front_left", "FrontRight", true],
  [Vector2.RIGHT, "side_right", "SideRight", false],
  [Vector2.LEFT, "side_left", "SideRight", true],
  [Vector2.UP, "back", "Back", false],
  [Vector2(1,-1), "back_right", "BackRight", false],
  [Vector2(-1,-1), "back_left", "BackRight", true],
 ]
 for entry in cases:
  assert(scene.view_from_aim(entry[0]) == entry[1])
  scene._show_view(entry[1])
  var expected = scene.get_node("LunaRig/" + entry[2])
  for sprite in sprites:
   assert(sprite.visible == (sprite == expected))
  assert(expected.flip_h == entry[3])
 assert(scene.view_from_aim(Vector2.ZERO).is_empty())
 # Classic controls: movement wins over an opposing cursor, including normalized diagonals.
 assert(scene.face_movement_direction)
 scene.blink_wait = 99.0
 scene.hair_wait = 99.0
 for entry in cases:
  var movement: Vector2 = entry[0].normalized()
  scene.advance_animation(0.02, movement, -movement * 100.0)
  assert(scene.current_view == entry[1] and scene.animation_state == "walk")
  scene.advance_animation(0.02, Vector2.ZERO, -movement * 100.0)
  assert(scene.current_view == entry[1] and scene.animation_state == "idle")
  scene.request_cast()
  assert(scene.cast_direction.is_equal_approx(movement))
  scene.advance_animation(0.1, -movement, -movement * 100.0)
  assert(scene.current_view == entry[1])
  scene.advance_animation(0.4, Vector2.ZERO, Vector2.ZERO)
 for multiplier in [0.5, 1.0, 2.0]:
  scene.size_multiplier = multiplier
  scene._apply_size()
  for sprite in sprites:
   assert(is_equal_approx(sprite.scale.x, 0.1875 * multiplier))
   var foot_world = sprite.position.y + (float(sprite.get_meta("feet_y")) - sprite.texture.get_height() * 0.5) * sprite.scale.y
   assert(is_zero_approx(foot_world))
 assert(scene.get_node("Ground").texture != null)
 scene.queue_free()
 print("Luna explorer: classic movement facing, retained idle/cast direction, mirrors, feet and SIZE PASS")
 quit()
