extends SceneTree
## Environment simulation: fire spreads only through editable flammable
## materials, ice fields change traction and survive world snapshots.

const Registry = preload("res://scripts/core/parameter_registry.gd")
const Materials = preload("res://scripts/core/material_profile.gd")
const World = preload("res://scripts/core/world_registry.gd")
const Commands = preload("res://scripts/core/command_processor.gd")
const Effects = preload("res://scripts/core/effect_engine.gd")
const Conditions = preload("res://scripts/core/elemental_status_service.gd")
const Surfaces = preload("res://scripts/core/surface_field_service.gd")
const Save = preload("res://scripts/core/save_service.gd")
const Hackable = preload("res://scripts/hackable_entity.gd")

const TEST_PATH := "user://luna_environment_test.json"
var spreads: Array[Dictionary] = []


func _initialize() -> void:
	call_deferred("_run")


func _on_spread(details: Dictionary) -> void:
	spreads.append(details.duplicate(true))


func _run() -> void:
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	var registry = Registry.new()
	var world = World.new()
	var commands = Commands.new()
	var effects = Effects.new(world, commands)
	var surface = Surfaces.new()
	var conditions = Conditions.new(world, effects, surface)
	conditions.fire_spread.connect(_on_spread)
	var luna := Node3D.new()
	root.add_child(luna)
	assert(world.register_entity("luna", luna, "LUNA"))
	var actors: Array[Node] = []
	for row in [
		{"id":"tree_1","type":"tree","x":0.0},
		{"id":"fridge","type":"fridge","x":1.0},
		{"id":"tree_2","type":"tree","x":2.1},
		{"id":"tree_3","type":"tree","x":4.4},
		{"id":"tree_far","type":"tree","x":13.0}
	]:
		var actor = Hackable.new()
		root.add_child(actor)
		actor.configure(str(row["id"]), str(row["type"]),
			Vector3(float(row["x"]), 0, 0), registry, world, null, {}, conditions)
		assert(world.register_entity(str(row["id"]), actor, str(row["type"]).to_upper()))
		actors.append(actor)
	assert(actors[0].get_parameter("material") == "WOOD")
	assert(actors[1].get_parameter("material") == "METAL")
	assert(Materials.is_flammable("WOOD"))
	assert(not Materials.is_flammable("METAL"))
	assert(Materials.is_conductive("METAL"))
	assert(not Materials.is_conductive("STONE"))

	assert(conditions.apply_element("tree_1", "FIRE"))
	conditions.advance(1.0)
	conditions.advance(1.0)
	assert(spreads.size() == 1)
	assert(spreads[0]["from_id"] == "tree_1")
	assert(spreads[0]["to_id"] == "tree_2")
	assert(conditions.has_status("tree_2", "BURN"))
	assert(not conditions.has_status("fridge", "BURN"))
	assert(not conditions.has_status("tree_3", "BURN"))
	conditions.advance(1.0)
	conditions.advance(1.0)
	assert(spreads.size() == 2)
	assert(spreads[1]["from_id"] == "tree_2")
	assert(spreads[1]["to_id"] == "tree_3")
	assert(conditions.has_status("tree_3", "BURN"))
	assert(not conditions.has_status("tree_far", "BURN"))

	# Material is a hackable property; turning a fridge to wood lets it catch fire.
	assert(actors[1].set_parameter("material", "WOOD"))
	assert(actors[1].get_parameter("material") == "WOOD")
	assert(conditions.apply_element("tree_1", "FIRE"))
	conditions.advance(1.0)
	conditions.advance(1.0)
	assert(conditions.has_status("fridge", "BURN"))
	assert(spreads.size() == 3)
	assert(spreads[2]["to_id"] == "fridge")
	assert(not conditions.has_status("tree_far", "BURN"))

	# FROST leaves a visible patch around the struck object. Movement inertia
	# uses the same value for Luna and every moving entity.
	assert(conditions.apply_element("fridge", "FROST"))
	assert(surface.get_fields().size() == 1)
	assert(is_equal_approx(surface.traction(Vector3(1, 0.1, 0)), 0.2))
	assert(is_equal_approx(surface.traction(Vector3(10, 0, 0)), 1.0))
	assert(conditions.apply_element("fridge", "FROST")) # Refresh, no duplicate patch
	assert(surface.get_fields().size() == 1)
	surface.advance(2.0) # Clamped to 1 second per tick.
	assert(is_equal_approx(surface.get_fields()[0]["remaining"], 5.0))

	var save = Save.new(TEST_PATH)
	assert(save.save_world(world, luna, null, conditions, surface))
	var snap: Dictionary = save.snapshot(world, luna, null, conditions, surface)
	assert(snap["surface_fields"]["fields"].size() == 1)
	assert(surface.import_data({}))
	assert(surface.get_fields().is_empty())
	assert(save.load_world(world, luna, null, Callable(), null, conditions, surface))
	assert(surface.get_fields().size() == 1)
	assert(surface.traction(Vector3(1, 0, 0)) < 1.0)

	# The entire snapshot is rejected before existing objects are touched.
	var corrupted: Dictionary = snap.duplicate(true)
	corrupted["surface_fields"]["fields"][0]["radius"] = 99.0
	var before_health: int = actors[1].get_parameter("health")
	assert(not save.apply_snapshot(corrupted, world, luna, null,
		Callable(), null, conditions, surface))
	assert(actors[1].get_parameter("health") == before_health)
	assert(surface.get_fields().size() == 1)
	assert(surface.validate_data({})) # Original worlds had no surface section.

	for tick in range(8):
		surface.advance(1.0)
	assert(surface.get_fields().is_empty())
	assert(surface.traction(Vector3(1, 0, 0)) == 1.0)
	for actor in actors:
		actor.free()
	luna.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	print("LUNA 0.15: fire propagation, material hacking, ice traction and saves passed")
	quit(0)
