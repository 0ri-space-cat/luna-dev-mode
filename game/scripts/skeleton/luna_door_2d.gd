extends "res://scripts/skeleton/entity_body_2d.gd"
## The one physical room-door artifact. Its position and PICKABLE value use
## the ordinary Entity/attachment snapshot, not a second inventory body.
const ID := "C2_LUNA_ROOM_DOOR"
const HOME_POINT := Vector2(5960, 390)
const TOOL_KEY := "LUNA_ROOM_DOOR"
const LAYOUT_VERSION := 1


func _ready() -> void:
	super._ready()
	_marker.polygon = PackedVector2Array([Vector2(-10, 0), Vector2(-10, -39), Vector2(10, -39), Vector2(10, 0)])
	queue_redraw()


func _draw() -> void:
	super._draw()
	# The shared shadow renderer leaves its local transform active.
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_rect(Rect2(Vector2(-8, -37 - motion.elevation), Vector2(16, 35)), Color("e5c79b"), false, 1.5)
	draw_circle(Vector2(4, -18 - motion.elevation), 2.0, Color("e5c79b"))


func is_placed_at(point: Vector2) -> bool:
	return motion.grounded and not is_attached() and not has_passenger() and is_zero_approx(motion.elevation) and position.distance_to(point) < 1.0


static func migrate_legacy(initial: Dictionary, owned: bool, session: Dictionary) -> Dictionary:
	var entry := initial.duplicate(true)
	if entry.is_empty():
		return {}
	entry["attachment"]["pickable"] = owned
	if not session.is_empty():
		var point := Vector2(float(session["x"]), float(session["y"]))
		entry["position"] = [point.x, point.y]
		entry["location_id"] = session["address"]
		entry["motion"] = {"elevation": 0.0, "vertical_speed": 0.0, "grounded": true, "anchor": [point.x, point.y, 0.0]}
	return entry
