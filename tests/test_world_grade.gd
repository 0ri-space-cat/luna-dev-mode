extends SceneTree

const WorldGradeRect = preload("res://scripts/world/world_grade_rect.gd")

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var world := SubViewport.new()
	world.transparent_bg = true
	root.add_child(world)
	var grade := WorldGradeRect.new()
	root.add_child(grade)
	var hud := CanvasLayer.new()
	root.add_child(hud)
	assert(grade.bind_world_viewport(world))
	assert(grade.texture == world.get_texture())
	assert(grade.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST)
	assert(hud.get_parent() == grade.get_parent())
	assert(grade.set_grade({"saturation": 0.5, "tint": Color(0.9, 0.8, 1.0)}))
	var shader := grade.material as ShaderMaterial
	assert(is_equal_approx(shader.get_shader_parameter("saturation"), 0.5))
	assert(not grade.set_grade({"saturation": INF}))
	assert(not grade.set_grade({"contrast": 3.0}))
	assert(is_equal_approx(shader.get_shader_parameter("saturation"), 0.5))
	assert(grade.set_grade({"saturation": 0.9}, 0.05))
	await create_timer(0.1).timeout
	assert(is_equal_approx(shader.get_shader_parameter("saturation"), 0.9))
	hud.free()
	grade.free()
	world.free()
	print("World grading: dedicated viewport, nearest sampling and profile transition passed")
	quit(0)
