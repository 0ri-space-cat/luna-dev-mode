extends Node2D
## Replace this node's geometry with effect frames; origin belongs to the carrier.
var carrier: Node2D
var direction := Vector2.RIGHT
var ability := ""
var elapsed := 0.0

func _process(delta: float) -> void:
	elapsed += delta
	if not is_instance_valid(carrier) or elapsed >= 0.45:
		queue_free()
		return
	var body = carrier.art_anchor.get_node_or_null("Body")
	var reach: float = body.mouth_radius if body else 13.0
	global_position = carrier.art_anchor.to_global(Vector2(0,-9)+direction*reach)
	rotation = direction.angle()
	queue_redraw()

func _draw() -> void:
	var tint: Color = {"FIRE_BREATH":Color.CORAL,"FROST":Color.SKY_BLUE,"STORM":Color.GOLD,"SPLASH":Color.AQUAMARINE,"INK":Color.MEDIUM_PURPLE}.get(ability,Color.PLUM)
	draw_colored_polygon(PackedVector2Array([Vector2.ZERO,Vector2(90,-16),Vector2(115,0),Vector2(90,16)]),Color(tint,1.0-elapsed/0.46))
