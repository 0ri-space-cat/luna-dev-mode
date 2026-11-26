extends RefCounted
## Water fills an XY footprint between a bottom and a free surface in world Z.

var bounds: Rect2
var bottom: float
var surface: float
var flow: Vector2
var resistance: float
# Optional physical resting-body threshold for shallow rough beds.
var ground_hold_mass := INF


func _init(footprint: Rect2, bottom_z: float, surface_z: float,
		current: Vector2, drag: float) -> void:
	bounds = footprint
	bottom = bottom_z
	surface = surface_z
	flow = current
	resistance = drag


func submerged_fraction(point: Vector2, feet: float, height: float) -> float:
	if not bounds.has_point(point):
		return 0.0
	var immersed_height := minf(surface, feet + height) - maxf(bottom, feet)
	return clampf(immersed_height / height, 0.0, 1.0)
