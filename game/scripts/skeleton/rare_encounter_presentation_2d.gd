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
		var opening := smoothstep(0.04, 0.24, t) * (1.0 - smoothstep(0.63, 0.82, t))
		var reach := smoothstep(0.18, 0.37, t) * (1.0 - smoothstep(0.57, 0.70, t))
		if opening > 0.0:
			canvas.draw_line(anchor + Vector2(0, -13) * opening, anchor + Vector2(0, 13) * opening,
				Color(0.29, 0.23, 0.43, opening), 3.0)
		if reach > 0.0:
			var end := anchor + Vector2(16.0 * reach, -3.0 * reach)
			canvas.draw_line(anchor, end, Color(0.75, 0.69, 0.85, opening), 4.0, true)
			canvas.draw_circle(end, 3.0 * reach, Color(0.9, 0.83, 0.91, opening))
		if t > 0.70:
			var ripple := smoothstep(0.70, 1.0, t)
			canvas.draw_arc(anchor, 5.0 + 14.0 * ripple, 0.0, TAU, 20,
				Color(0.73, 0.66, 0.87, 0.30 * (1.0 - ripple)), 1.0, true)
