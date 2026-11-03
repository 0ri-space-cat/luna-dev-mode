extends SceneTree
## Environmental interaction: flame removes a temporary ice surface without
## touching distant patches, and FIRE + CHILL still follows the STEAM rule.

const Registry = preload("res://scripts/core/parameter_registry.gd")
const World = preload("res://scripts/core/world_registry.gd")
const Commands = preload("res://scripts/core/command_processor.gd")
const Effects = preload("res://scripts/core/effect_engine.gd")
const Surfaces = preload("res://scripts/core/surface_field_service.gd")
const Elements = preload("res://scripts/core/elemental_status_service.gd")
const Hackable = preload("res://scripts/hackable_entity.gd")

var reactions: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _reaction(info: Dictionary) -> void:
	reactions.append(str(info["reaction"]))


func _run() -> void:
	var registry = Registry.new()
	var world = World.new()
	var commands = Commands.new()
	var effects = Effects.new(world, commands)
	var surfaces = Surfaces.new()
	var statuses = Elements.new(world, effects, surfaces)
	statuses.reaction_triggered.connect(_reaction)
	var near = Hackable.new()
	var far = Hackable.new()
	root.add_child(near)
	root.add_child(far)
	near.configure("near", "fridge", Vector3(0, 0, 0), registry, world, null, {}, statuses)
	far.configure("far", "fridge", Vector3(10, 0, 0), registry, world, null, {}, statuses)
	assert(world.register_entity("near", near, "FRIDGE"))
	assert(world.register_entity("far", far, "FRIDGE"))

	# A patch is removed by fire at the target, not by an unrelated hit.
	assert(surfaces.add_ice_at(Vector3.ZERO))
	assert(surfaces.add_ice_at(Vector3(10, 0, 0)))
	assert(surfaces.get_fields().size() == 2)
	assert(statuses.apply_element("near", "FIRE"))
	assert(reactions.has("THAW"))
	assert(surfaces.get_fields().size() == 1)
	assert(is_equal_approx(surfaces.traction(Vector3.ZERO), 1.0))
	assert(surfaces.traction(Vector3(10, 0, 0)) < 1.0)

	# A freeze creates ground ice as before; a following flame produces
	# STEAM and melts the terrain as part of the same interaction.
	assert(statuses.apply_element("near", "FROST"))
	assert(statuses.has_status("near", "CHILL"))
	assert(surfaces.get_fields().size() == 2)
	assert(statuses.apply_element("near", "FIRE"))
	assert(reactions.has("STEAM"))
	assert(not statuses.has_status("near", "CHILL"))
	assert(statuses.has_status("near", "BURN"))
	assert(surfaces.get_fields().size() == 1)
	assert(surfaces.traction(Vector3.ZERO) == 1.0)
	assert(surfaces.traction(Vector3(10, 0, 0)) < 1.0)

	# Invalid coordinates do not mutate the ground.
	assert(surfaces.melt_at(Vector3(INF, 0, 0)) == 0)
	assert(surfaces.get_fields().size() == 1)
	assert(surfaces.melt_at(Vector3(10, 0, 0)) == 1)
	assert(surfaces.get_fields().is_empty())
	near.free()
	far.free()
	print("LUNA 0.15: flame melts ice and leaves distant surfaces intact")
	quit(0)
