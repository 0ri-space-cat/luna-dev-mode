extends RefCounted
## Fixed camera bases. Physics still owns an unprojected XY plane and elevation.

var ground_to_screen: Transform2D
var screen_to_ground: Transform2D


func _init(isometric: bool) -> void:
	if isometric:
		ground_to_screen = Transform2D(Vector2(1.13, 0.60), Vector2(-1.13, 0.60), Vector2(605, 246))
	else:
		ground_to_screen = Transform2D(Vector2(1.5, 0.035), Vector2(-0.31, 0.70), Vector2(225, 355))
	screen_to_ground = ground_to_screen.affine_inverse()


func point(world: Vector2, height: float = 0.0) -> Vector2:
	return ground_to_screen * world - Vector2(0, height)


func movement(screen: Vector2) -> Vector2:
	var input := screen.limit_length()
	return screen_to_ground.basis_xform(input).normalized() * input.length()


func depth(world: Vector2) -> int:
	return roundi(point(world).y)
