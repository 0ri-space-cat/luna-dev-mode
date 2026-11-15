extends RefCounted
## Bounded functional adapters for a subset of author-approved abilities.
## Combat recipes and exact species balance are deliberately NOT prescribed.
##
## REGENERATION: every 2 game seconds, restores one HEALTH to its authored
## registry default (100 in the existing prototype), without magic global buffs.
## GLOW uses a PointLight2D on the owning actor, independent of screen UI.
## FLY is applied by ActorBody2D's real physics collision mask.

const REGEN_INTERVAL := 2.0
const MAX_REGEN_TICKS_PER_FRAME := 2
const LIGHT_WIDTH := 96

var _regeneration_elapsed := 0.0


func advance(actor: Node, delta: float) -> Dictionary:
	if not actor.has_ability("REGENERATION") or not bool(actor.get_parameter("alive")):
		_regeneration_elapsed = 0.0
		return {}
	_regeneration_elapsed = minf(_regeneration_elapsed + maxf(delta, 0.0), 4.0)
	var target_health: int = int(actor.record.registry.get_spec(
		str(actor.record.category), "health").get("default", 100))
	if int(actor.get_parameter("health")) >= target_health:
		_regeneration_elapsed = minf(_regeneration_elapsed, REGEN_INTERVAL)
		return {}
	var prior: int = int(actor.get_parameter("health"))
	var ticks := 0
	while _regeneration_elapsed >= REGEN_INTERVAL and ticks < MAX_REGEN_TICKS_PER_FRAME:
		_regeneration_elapsed -= REGEN_INTERVAL
		ticks += 1
	if ticks == 0:
		return {}
	var result: int = mini(prior + ticks, target_health)
	if not actor.set_parameter("health", result):
		return {}
	return {"type": "ABILITY_REGENERATION", "entity_id": str(actor.record.id),
		"before": prior, "after": result}


static func setup_light(actor: Node2D, present_light: PointLight2D, enabled: bool) -> PointLight2D:
	var source: PointLight2D = present_light
	if source == null and enabled:
		source = PointLight2D.new()
		source.name = "WorldGlowLight"
		var texture := GradientTexture2D.new()
		texture.width = LIGHT_WIDTH
		texture.height = LIGHT_WIDTH
		texture.fill = GradientTexture2D.FILL_RADIAL
		texture.fill_from = Vector2(0.5, 0.5)
		texture.fill_to = Vector2(0.5, 0.0)
		var gradient := Gradient.new()
		gradient.set_color(0, Color(1, 1, 1, 1))
		gradient.set_color(1, Color(1, 1, 1, 0))
		texture.gradient = gradient
		source.texture = texture
		source.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		source.energy = 0.8
		actor.add_child(source)
	if source != null:
		source.enabled = enabled
	return source
