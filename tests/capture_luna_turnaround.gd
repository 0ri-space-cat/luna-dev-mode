extends SceneTree
## A real Godot render of the current eight-direction art, four columns by two rows.
func _initialize() -> void:
 call_deferred("_capture")

func _capture() -> void:
 var scene = load("res://scenes/2d/luna_art_preview.tscn").instantiate()
 root.add_child(scene)
 scene.set_process(false)
 await process_frame
 for child in scene.get_node("LunaRig").get_children():
  if child is Sprite2D: child.visible = false
 var views := [["Front", false], ["FrontRight", false], ["SideRight", false], ["BackRight", false], ["Back", false], ["BackRight", true], ["SideRight", true], ["FrontRight", true]]
 for i in range(views.size()):
  var original = scene.get_node("LunaRig/" + views[i][0])
  var sprite := Sprite2D.new()
  sprite.texture = original.texture
  sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
  sprite.scale = original.scale
  sprite.flip_h = views[i][1]
  sprite.position = original.position + Vector2(-450 + (i % 4) * 300, -40 if i < 4 else 320)
  scene.get_node("LunaRig").add_child(sprite)
 await process_frame
 await RenderingServer.frame_post_draw
 var captured := root.get_texture().get_image()
 assert(captured.save_png("res://docs/screenshots/luna_explorer_turnaround.png") == OK)
 print("Captured eight-view Godot art gallery at ", captured.get_size())
 quit()
