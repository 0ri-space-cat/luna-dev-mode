extends RefCounted
## P0 candidate math only: no window, viewport, collision or camera mutation.
const WORLD_GRIDS := [Vector2i(320, 180), Vector2i(640, 360)]
const TILE_OPTIONS := [16, 32]
const ART_SCALES := [0.5, 1.0, 2.0]


static func integer_fit(logical: Vector2i, available: Vector2i) -> Dictionary:
	if logical.x <= 0 or logical.y <= 0 or available.x <= 0 or available.y <= 0:
		return {}
	var factor := mini(floori(float(available.x) / logical.x), floori(float(available.y) / logical.y))
	if factor < 1:
		return {}
	var size := logical * factor
	var origin := Vector2i(floori((available.x - size.x) / 2.0), floori((available.y - size.y) / 2.0))
	return {"scale": factor, "rect": Rect2i(origin, size)}


static func snap_display(point: Vector2, units_per_pixel: float) -> Vector2:
	if not point.is_finite() or not is_finite(units_per_pixel) or units_per_pixel <= 0.0:
		return point
	return (point / units_per_pixel).round() * units_per_pixel
