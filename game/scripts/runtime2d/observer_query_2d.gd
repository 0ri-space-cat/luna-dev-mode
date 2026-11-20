extends RefCounted
## Distinguishes player CAMERA observation from Luna's personal gaze.
## Camera footprint works while locked and while Luna is off-screen.
## Luna gaze is a bounded, occlusion-aware 2D cone, independent of the HUD.

const EYE_RANGE := 460.0
const GAZE_DOT_LIMIT := -0.1 # Wide exploratory view, not omniscience.

var luna_eyes_open := true
var facing := Vector2.DOWN


func evaluate(player: Node2D, camera: Camera2D, point: Vector2, invisible_to_luna: bool = false) -> Dictionary:
	var camera_seen: bool = camera != null and bool(camera.call("contains_world_point", point))
	var luna_seen := false
	if luna_eyes_open and not invisible_to_luna and is_instance_valid(player):
		var delta: Vector2 = point - player.global_position
		if delta.length_squared() < EYE_RANGE * EYE_RANGE:
			var direction := facing.normalized()
			if delta.length_squared() < 0.001 or direction.dot(delta.normalized()) >= GAZE_DOT_LIMIT:
				luna_seen = not _occluded(player, point)
	return {"player_camera": camera_seen, "luna_eyes": luna_seen}


func _occluded(player: Node2D, world_point: Vector2) -> bool:
	if not player.is_inside_tree() or player.get_world_2d() == null:
		return false
	var query := PhysicsRayQueryParameters2D.create(player.global_position, world_point, 1)
	if player is CollisionObject2D:
		query.exclude = [(player as CollisionObject2D).get_rid()]
	var result: Dictionary = player.get_world_2d().direct_space_state.intersect_ray(query)
	return not result.is_empty()
