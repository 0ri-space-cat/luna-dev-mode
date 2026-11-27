extends RefCounted
## Isolated physical prototype for Pixel's personal AIR_STEP, not an ability
## instance. A scene binds its own Pixel marker; ordinary entities cannot use
## the same instance. No arbitrary coordinates, inventory or bank APIs.
const LIFETIME := 2.5
const MIN_TRAVEL := 18.0
const MAX_TRAVEL := 64.0
const MAX_RISE := 24.0
const MAX_ACTIVE := 5
const SIZE := Vector2(56, 48)
var _pixel: Node2D
var _last := Vector2.INF
var _last_height := 0.0
var _serial := 0
var _steps: Array[Dictionary] = []


func bind(pixel: Node2D) -> bool:
	if is_instance_valid(_pixel) or not _steps.is_empty() or not is_instance_valid(pixel):
		return false
	_pixel = pixel
	_last = pixel.position
	_last_height = 0.0
	return true


func observe_step(source: Node2D, height: float, surfaces: Array[Dictionary]) -> bool:
	if not is_instance_valid(_pixel) or source != _pixel or not is_finite(height) or height < 0.0:
		return false
	var point := source.position
	if not point.is_finite():
		return false
	var distance := point.distance_to(_last)
	if distance < MIN_TRAVEL:
		return false
	var rise := absf(height - _last_height)
	_last = point
	_last_height = height
	if distance > MAX_TRAVEL or rise > MAX_RISE or _steps.size() >= MAX_ACTIVE:
		return false
	_serial += 1
	var support := {"bounds": Rect2(point - SIZE / 2.0, SIZE), "height": height,
		"safe": false, "pixel_step": _serial}
	_steps.append({"surface": support, "remaining": LIFETIME})
	surfaces.append(support)
	return true


func advance(delta: float, surfaces: Array[Dictionary]) -> void:
	if not is_finite(delta) or delta <= 0.0:
		return
	for index in range(_steps.size() - 1, -1, -1):
		_steps[index]["remaining"] = maxf(0.0, float(_steps[index]["remaining"]) - delta)
		if _steps[index]["remaining"] <= 0.0:
			surfaces.erase(_steps[index]["surface"])
			_steps.remove_at(index)


func clear(surfaces: Array[Dictionary]) -> void:
	for step in _steps:
		surfaces.erase(step["surface"])
	_steps.clear()
	_pixel = null
	_last = Vector2.INF
	_last_height = 0.0


func active_count() -> int:
	return _steps.size()


func live_surfaces() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for step in _steps:
		result.append(step["surface"].duplicate(true))
	return result


func supports(point: Vector2, height: float) -> bool:
	for step in _steps:
		var surface: Dictionary = step["surface"]
		if is_equal_approx(float(surface["height"]), height) and surface["bounds"].has_point(point):
			return true
	return false
