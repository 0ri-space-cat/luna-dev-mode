extends RefCounted
## Graybox crossing. A route can have a different source of observation from
## the Luna that walks on it. Start and end banks are safe in both states.

const FALL_MARGIN := 0.10

var span: Rect2
var observer: String
var landing: Vector2
var checkpoint := Vector2.ZERO
var exposure := 0.0

func _init(bounds: Rect2, source: String, destination: Vector2) -> void:
	span = bounds
	observer = source
	landing = destination

func supports(game) -> bool:
	if observer == "CAMERA":
		# Check the whole section so a bridge that is partly in frame cannot
		# be crossed by hiding only Luna or only the far end.
		var screen: Rect2 = game.camera.get_viewport_rect()
		var extent: Vector2 = screen.size / game.camera.zoom
		var world_view := Rect2(game.camera.get_screen_center_position() - extent * 0.5, extent)
		return not world_view.intersects(span)
	return not game.luna_eyes_open or game.projection.is_underside_at(game.player.position,game.current_location_id)

func advance(game, delta: float) -> bool:
	if not span.has_point(game.player.position):
		checkpoint = game.player.position
		exposure = 0.0
		return true
	if supports(game):
		exposure = 0.0
		return true
	exposure += delta
	if exposure >= FALL_MARGIN:
		game.player.position = checkpoint
		exposure = 0.0
		return false
	return true
