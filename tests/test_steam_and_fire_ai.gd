extends SceneTree
## 0.16: steam is a saved world field, and ambient fire avoidance does not
## overwrite player-selected behavior or social relationships.

const Registry = preload("res://scripts/core/parameter_registry.gd")
const World = preload("res://scripts/core/world_registry.gd")
const Commands = preload("res://scripts/core/command_processor.gd")
const Effects = preload("res://scripts/core/effect_engine.gd")
const Surfaces = preload("res://scripts/core/surface_field_service.gd")
const Elements = preload("res://scripts/core/elemental_status_service.gd")
const Save = preload("res://scripts/core/save_service.gd")
const Hackable = preload("res://scripts/hackable_entity.gd")

const TEMP := "user://luna_steam_avoidance_test.json"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if FileAccess.file_exists(TEMP):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEMP))
	var registry = Registry.new()
	var world = World.new()
	var commands = Commands.new()
	var effects = Effects.new(world, commands)
	var surfaces = Surfaces.new()
	var statuses = Elements.new(world, effects, surfaces)
	var luna := Node3D.new()
	root.add_child(luna)
	luna.position = Vector3(10.0, 0, 0)
	assert(world.register_entity("luna", luna, "LUNA"))
	var torch = Hackable.new()
	var wanderer = Hackable.new()
	var chaser = Hackable.new()
	root.add_child(torch)
	root.add_child(wanderer)
	root.add_child(chaser)
	torch.configure("torch", "tree", Vector3.ZERO, registry, world, null, {}, statuses)
	wanderer.configure("wanderer", "fridge", Vector3(2, 0, 2), registry, world, null, {}, statuses)
	chaser.configure("chaser", "fridge", Vector3(2, 0, 0), registry, world, null, {}, statuses)
	assert(world.register_entity("torch", torch, "TREE"))
	assert(world.register_entity("wanderer", wanderer, "FRIDGE"))
	assert(world.register_entity("chaser", chaser, "FRIDGE"))
	assert(wanderer.set_parameter("alive", true))
	assert(chaser.set_parameter("alive", true))
	assert(chaser.set_parameter("behavior_mode", "CHASE"))
	assert(wanderer.get_parameter("behavior_mode") == "WANDER")
	var original_speed: float = float(wanderer.get_parameter("speed"))

	# Wandering actors temporarily flee real burning hazards without a
	# permanent command, and return to ordinary behavior after fire ends.
	assert(statuses.apply_element("torch", "FIRE"))
	assert(statuses.nearest_fire("wanderer", wanderer.global_position)["id"] == "torch")
	wanderer._physics_process(0.05)
	assert(wanderer.brain.last_decision == "FLEE")
	assert(wanderer.get_parameter("behavior_mode") == "WANDER")
	assert(float(wanderer.get_parameter("speed")) == original_speed)
	assert(statuses.apply_element("torch", "FROST"))
	assert(not statuses.has_status("torch", "BURN"))
	assert(statuses.nearest_fire("wanderer", wanderer.global_position).is_empty())
	wanderer._physics_process(0.05)
	assert(wanderer.brain.last_decision != "FLEE")

	# FIRE after FROST produces temporary STEAM, melting the ICE.
	# Ambient fog limits vision but does not change permanent sense_range.
	assert(statuses.apply_element("torch", "FIRE"))
	assert(surfaces.get_fields().size() == 1)
	assert(surfaces.get_fields()[0]["kind"] == "STEAM")
	assert(is_equal_approx(surfaces.traction(Vector3.ZERO), 1.0))
	assert(surfaces.visibility_factor(Vector3(2, 0, 0)) < 1.0)
	assert(surfaces.visibility_factor(Vector3(8, 0, 0)) == 1.0)
	assert(chaser.get_parameter("sense_range") == 12.0)
	chaser._physics_process(0.05)
	assert(chaser.brain.last_target_id.is_empty())

	# Both the cloud and active elemental timers survive a world checkpoint.
	var save := Save.new(TEMP)
	assert(save.save_world(world, luna, null, statuses, surfaces))
	var snap: Dictionary = save.snapshot(world, luna, null, statuses, surfaces)
	assert(snap["surface_fields"]["fields"][0]["kind"] == "STEAM")
	assert(surfaces.import_data({}))
	assert(surfaces.visibility_factor(Vector3.ZERO) == 1.0)
	assert(save.load_world(world, luna, null, Callable(), null, statuses, surfaces))
	assert(surfaces.visibility_factor(Vector3.ZERO) < 1.0)
	assert(statuses.has_status("torch", "BURN"))
	var invalid: Dictionary = snap.duplicate(true)
	invalid["surface_fields"]["fields"][0]["radius"] = 999.0
	assert(not save.apply_snapshot(invalid, world, luna, null, Callable(), null, statuses, surfaces))
	assert(surfaces.visibility_factor(Vector3.ZERO) < 1.0)
	for second in range(4):
		surfaces.advance(1.0)
	assert(surfaces.get_fields().is_empty())
	assert(surfaces.visibility_factor(Vector3.ZERO) == 1.0)

	torch.free()
	wanderer.free()
	chaser.free()
	luna.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEMP))
	print("LUNA 0.16: steam fields, persistence and instinctive fire avoidance passed")
	quit(0)
