extends TextureRect
## Displays a composited world viewport. HUD belongs outside that viewport.

const GRADE_SHADER = preload("res://shaders/world_grade.gdshader")
const NEUTRAL := {"saturation": 1.0, "contrast": 1.0, "brightness": 1.0, "tint": Color.WHITE}
var _grade := NEUTRAL.duplicate()
var _grade_material := ShaderMaterial.new()
var _grade_tween: Tween


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_grade_material.shader = GRADE_SHADER
	material = _grade_material
	_apply_grade(_grade)


func bind_world_viewport(world_viewport: SubViewport) -> bool:
	if not is_instance_valid(world_viewport) or world_viewport.is_ancestor_of(self):
		return false
	texture = world_viewport.get_texture()
	return true


## A partial profile uses neutral values for omitted fields. Reject invalid
## inputs before touching the current profile or an in-progress transition.
func set_grade(profile: Dictionary, transition_seconds: float = 0.0) -> bool:
	if not is_finite(transition_seconds) or transition_seconds < 0.0 or transition_seconds > 60.0:
		return false
	var target := NEUTRAL.duplicate()
	for key in profile:
		if not target.has(key):
			return false
		var value: Variant = profile[key]
		if key == "tint":
			if typeof(value) != TYPE_COLOR:
				return false
			var tint: Color = value
			for channel in [tint.r, tint.g, tint.b]:
				if not is_finite(channel) or channel < 0.0 or channel > 1.0:
					return false
			target[key] = Color(tint.r, tint.g, tint.b)
		else:
			if typeof(value) not in [TYPE_FLOAT, TYPE_INT] or not is_finite(float(value)):
				return false
			if float(value) < 0.0 or float(value) > 2.0:
				return false
			target[key] = float(value)
	if _grade_tween != null:
		_grade_tween.kill()
	if transition_seconds == 0.0 or not is_inside_tree():
		_apply_grade(target)
	else:
		var start := _grade.duplicate()
		_grade_tween = create_tween()
		_grade_tween.tween_method(_blend_grade.bind(start, target), 0.0, 1.0, transition_seconds)
	return true


func _blend_grade(weight: float, start: Dictionary, target: Dictionary) -> void:
	var blended := {}
	for key in ["saturation", "contrast", "brightness"]:
		blended[key] = lerpf(start[key], target[key], weight)
	blended["tint"] = (start["tint"] as Color).lerp(target["tint"], weight)
	_apply_grade(blended)


func _apply_grade(profile: Dictionary) -> void:
	_grade = profile
	for key in ["saturation", "contrast", "brightness"]:
		_grade_material.set_shader_parameter(key, profile[key])
	var tint: Color = profile["tint"]
	_grade_material.set_shader_parameter("tint", Vector3(tint.r, tint.g, tint.b))
