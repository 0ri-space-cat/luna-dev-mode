extends SceneTree
## Full bank coverage plus animation transitions, aim locking and release event timing.
var release_count := 0
func _initialize() -> void: call_deferred("_run")
func _on_release(_direction: Vector2) -> void: release_count += 1
func _run() -> void:
 var scene = load("res://scenes/2d/luna_art_preview.tscn").instantiate()
 root.add_child(scene)
 scene.set_process(false)
 # Retain coverage of the optional previous mouse-facing mode.
 scene.face_movement_direction = false
 await process_frame
 for view in scene.ASSETS:
  var expected := {"walk":4, "cast":2, "hair":1}
  if view in ["front", "front_right", "side_right"]:
   expected["blink"] = 1
   expected["cast"] = 3
  for clip in expected:
   var frames: Array = scene.animator.frames(view, clip)
   assert(frames.size() == expected[clip], "Incomplete " + view + "/" + clip)
   var seen := {}
   for frame in frames:
    assert(frame is Dictionary and FileAccess.file_exists(frame.path))
    assert(not seen.has(frame.sha256), "Repeated identical cel")
    seen[frame.sha256] = true
    var image := Image.load_from_file(ProjectSettings.globalize_path(frame.path))
    assert(image.get_size() == Vector2i(1024,1536))
    assert(frame.pivot[1] > 1300 and frame.pivot[1] < 1536)
   for multiplier in [0.5, 1.0, 2.0]:
    var sprite: Sprite2D = scene.sprite_for_view(view)
    scene.animator.apply(sprite, view, clip, 0.10 if clip == "blink" else 0.21, scene.BASE_SCALE * multiplier, 0.0)
    var feet: float = sprite.position.y + (float(sprite.get_meta("feet_y")) - sprite.texture.get_height()*0.5)*sprite.scale.y
    assert(is_zero_approx(feet))
 scene._show_view("side_right")
 assert(scene._stable_view_from_aim((Vector2.from_angle(deg_to_rad(24)) * 10.0)) == "side_right")
 assert(scene._stable_view_from_aim((Vector2.from_angle(deg_to_rad(30)) * 10.0)) == "front_right")
 scene._show_view("front_right")
 assert(scene._stable_view_from_aim((Vector2.from_angle(deg_to_rad(20)) * 10.0)) == "front_right")
 assert(scene._stable_view_from_aim((Vector2.from_angle(deg_to_rad(15)) * 10.0)) == "side_right")
 # Movement remains independent from facing; opposite movement reverses gait phase.
 scene.cast_active = false
 scene.blink_wait = 99.0
 scene.hair_wait = 99.0
 var start: Vector2 = scene.luna.position
 scene.advance_animation(0.1, Vector2.RIGHT, Vector2.UP)
 assert(scene.current_view == "back" and scene.animation_state == "walk")
 assert(scene.luna.position.is_equal_approx(start + Vector2(21,0)))
 var forward_phase: float = scene.walk_phase
 scene.advance_animation(0.1, Vector2.DOWN, Vector2.UP)
 assert(scene.walk_phase < forward_phase)
 scene.advance_animation(0.1, Vector2.ZERO, Vector2.DOWN)
 assert(scene.animation_state == "idle" and scene.walk_phase == 0.0)
 # Exactly one release, no retrigger, no aim flip or sliding during the short cast.
 scene.cast_released.connect(_on_release)
 scene._show_view("front_right")
 scene.request_cast()
 scene.request_cast()
 start = scene.luna.position
 scene.advance_animation(0.10, Vector2.RIGHT, Vector2.UP)
 assert(scene.current_view == "front_right" and scene.animation_state == "cast")
 assert(scene.luna.position == start and release_count == 0)
 assert(scene.front_right.get_meta("cel_path").ends_with("cast_00.png"))
 scene.advance_animation(0.04, Vector2.RIGHT, Vector2.UP)
 assert(release_count == 0 and scene.front_right.get_meta("cel_path").ends_with("cast_01.png"))
 scene.advance_animation(0.07, Vector2.RIGHT, Vector2.UP)
 assert(release_count == 1)
 assert(scene.front_right.get_meta("cel_path").ends_with("cast_02.png"))
 scene.advance_animation(0.23, Vector2.ZERO, Vector2.DOWN)
 assert(not scene.cast_active and scene.animation_state == "idle" and release_count == 1)
 # Idle variants expire and always restore the exact approved base cel.
 scene.blink_wait = 0.001
 scene.hair_wait = 99.0
 scene.advance_animation(0.06, Vector2.ZERO, Vector2.DOWN)
 assert(scene.front.get_meta("cel_path").ends_with("blink_00.png"))
 scene.advance_animation(0.20, Vector2.ZERO, Vector2.DOWN)
 assert(scene.front.get_meta("cel_path") == scene.ASSETS.front)
 scene.blink_wait = 99.0
 scene.hair_wait = 0.001
 scene.advance_animation(0.15, Vector2.ZERO, Vector2.DOWN)
 assert(scene.front.get_meta("cel_path").ends_with("hair_00.png"))
 scene.advance_animation(0.4, Vector2.ZERO, Vector2.DOWN)
 assert(scene.front.get_meta("cel_path") == scene.ASSETS.front)
 scene.queue_free()
 print("Luna full animation bank, movement/facing, cast timing, blink, hair and SIZE PASS")
 quit()
