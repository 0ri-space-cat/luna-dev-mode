extends RefCounted
## DEV presentation only. No Entity, collision, route, reward or input capture.
const Director = preload("res://scripts/runtime2d/rare_encounter_director_2d.gd")


static func draw_on(canvas: Node2D, identity: String, anchor: Vector2, elapsed: float, body_scale: float, tint: Color) -> void:
	var t := clampf(elapsed / Director.SCENE_SECONDS, 0.0, 1.0)
	if identity == Director.REFLECTION:
		var fade := 1.0 - smoothstep(0.65, 1.0, t)
		var ink := Color(tint.r, tint.g, tint.b, 0.55 * fade)
		var size := clampf(body_scale, 0.5, 1.5)
		# A fixed inverted graybox body in the water; a brief independent wave.
		canvas.draw_circle(anchor + Vector2(0, 8) * size, 6.0 * size, ink)
		canvas.draw_line(anchor, anchor + Vector2(0, -10) * size, ink, 8.0 * size)
		var hand := anchor + Vector2(12, -4 + sin(t * TAU * 3.0) * 4) * size
		canvas.draw_line(anchor, hand, ink, 3.0 * size)
		canvas.draw_arc(anchor, 8.0 + 16.0 * t, 0.0, TAU, 24, Color(0.65, 0.9, 0.9, 0.25 * fade), 1.0)
	elif identity == Director.HAND:
		var envelope := sin(t * PI)
		var reach := 13.0 * envelope
		canvas.draw_line(anchor + Vector2(0, -12) * envelope, anchor + Vector2(0, 12) * envelope, Color(0.19, 0.12, 0.31, envelope), 4.0)
		# Abstract hand and sleeve only; final character appearance is deferred.
		if t > 0.2 and t < 0.8:
			canvas.draw_line(anchor, anchor + Vector2(reach, -3), Color(0.75, 0.69, 0.85, envelope), 4.0)
			canvas.draw_circle(anchor + Vector2(reach, -3), 3.0, Color(0.9, 0.83, 0.91, envelope))
