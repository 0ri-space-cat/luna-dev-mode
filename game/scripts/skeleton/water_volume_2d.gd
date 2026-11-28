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

## First contact of the swept point with this water's actual XYZ volume.
func segment_entry(from: Vector3, to: Vector3) -> float:
	var lower := Vector3(bounds.position.x, bounds.position.y, bottom)
	var upper := Vector3(bounds.end.x, bounds.end.y, surface)
	var travel := to - from
	var begin := 0.0
	var end := 1.0
	for axis in 3:
		if is_zero_approx(travel[axis]):
			if from[axis] < lower[axis] or from[axis] > upper[axis]:
				return INF
			continue
		var near: float = (lower[axis] - from[axis]) / travel[axis]
		var far: float = (upper[axis] - from[axis]) / travel[axis]
		begin = maxf(begin, minf(near, far))
		end = minf(end, maxf(near, far))
		if begin > end:
			return INF
	return begin
