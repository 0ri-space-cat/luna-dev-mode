extends SceneTree
## Chain lightning: closest living neighbor per hop, diminishing damage,
## no repeated targets, fully atomic hit, editable saved recipe.

const Registry = preload("res://scripts/core/parameter_registry.gd")
const World = preload("res://scripts/core/world_registry.gd")
const Commands = preload("res://scripts/core/command_processor.gd")
const Effects = preload("res://scripts/core/effect_engine.gd")
const Statuses = preload("res://scripts/core/elemental_status_service.gd")
const Resolver = preload("res://scripts/core/target_resolver.gd")
const Spells = preload("res://scripts/core/spell_service.gd")
const Workshop = preload("res://scripts/core/spell_workshop_service.gd")
const Grammar = preload("res://scripts/core/arcane_grammar.gd")
const Hackable = preload("res://scripts/hackable_entity.gd")

const TEST_PATH := "user://luna_chain_lightning_test.json"
var last_chain: Dictionary = {}
var chain_count := 0


func _initialize() -> void:
	call_deferred("_run")


func _on_chain(details: Dictionary) -> void:
	last_chain = details.duplicate(true)
	chain_count += 1


func _run() -> void:
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	var registry = Registry.new()
	var world = World.new()
	var commands = Commands.new()
	var effects = Effects.new(world, commands)
	var statuses = Statuses.new(world, effects)
	var spells = Spells.new(world, effects, statuses)
	spells.chain_resolved.connect(_on_chain)
	var luna := Node3D.new()
	root.add_child(luna)
	luna.position = Vector3(-2.0, 0, 0)
	assert(world.register_entity("luna", luna, "LUNA"))
	var actors: Array[Node] = []
	for data in [
		{"id":"fridge", "kind":"fridge", "x":0.0, "alive":false},
		{"id":"inert", "kind":"tree", "x":1.0, "alive":false},
		{"id":"first", "kind":"tree", "x":2.0, "alive":true},
		{"id":"second", "kind":"tree", "x":5.3, "alive":true},
		{"id":"third", "kind":"tree", "x":8.6, "alive":true},
		{"id":"too_far", "kind":"tree", "x":18.0, "alive":true}
	]:
		var actor = Hackable.new()
		root.add_child(actor)
		actor.configure(str(data["id"]), str(data["kind"]),
			Vector3(float(data["x"]), 0, 0), registry, world, null, {}, statuses)
		assert(actor.set_parameter("alive", data["alive"]))
		assert(world.register_entity(str(data["id"]), actor, "TREE"))
		actors.append(actor)
	var expected: Array[String] = ["fridge", "first", "second", "third"]
	assert(Resolver.chain(world, "fridge", 4.5, 3) == expected)
	assert(Resolver.chain(world, "fridge", 4.5, 0) == ["fridge"])
	assert(Resolver.chain(world, "fridge", -2.0, 3).is_empty())
	assert(Resolver.chain(world, "fridge", 40.0, 3).is_empty())
	assert(Resolver.chain(world, "fridge", 4.5, 5).is_empty())
	assert(Resolver.chain(world, "invalid", 4.5, 3).is_empty())

	var bolt: Dictionary = spells.get_spell("ARC_BOLT")
	assert(bolt["impact"]["mode"] == "CHAIN")
	assert(bolt["impact"]["radius"] == 4.5)
	assert(bolt["impact"]["jumps"] == 3)
	assert(spells.cast_spell("ARC_BOLT", "luna", "fridge"))
	assert(chain_count == 0) # Projectile has not landed yet.
	assert(actors[0].get_parameter("health") == 100)
	assert(spells.resolve_impact("ARC_BOLT", "luna", "fridge"))
	assert(chain_count == 1)
	assert(last_chain["targets"] == expected)
	assert(last_chain["links"].size() == 3)
	assert(last_chain["links"][1]["from_id"] == "first")
	assert(last_chain["links"][1]["to_id"] == "second")
	assert(actors[0].get_parameter("health") == 84)
	assert(actors[2].get_parameter("health") == 55)
	assert(actors[3].get_parameter("health") == 58)
	assert(actors[4].get_parameter("health") == 61)
	assert(actors[1].get_parameter("health") == 65)
	assert(actors[5].get_parameter("health") == 65)
	assert(statuses.has_status("fridge", "SHOCK"))
	assert(statuses.has_status("first", "SHOCK"))
	assert(statuses.has_status("second", "SHOCK"))
	assert(statuses.has_status("third", "SHOCK"))
	assert(not statuses.has_status("inert", "SHOCK"))
	assert(commands.undo()) # Entire chain is one history entry.
	assert(actors[0].get_parameter("health") == 100)
	assert(actors[2].get_parameter("health") == 65)
	assert(actors[3].get_parameter("health") == 65)
	assert(actors[4].get_parameter("health") == 65)

	var before_audit: int = commands.get_audit_log().size()
	var invalid_plans: Array[Dictionary] = [
		{"target_id": "fridge",
		 "actions": [{"operation": "ADD", "parameter_id": "health", "value": -5}]},
		{"target_id": "first",
		 "actions": [{"operation": "SET", "parameter_id": "health", "value": "nope"}]}
	]
	assert(not effects.apply_targeted_batches(invalid_plans, "luna", "test:invalid"))
	assert(actors[0].get_parameter("health") == 100)
	assert(actors[2].get_parameter("health") == 65)
	assert(commands.get_audit_log().size() == before_audit)
	assert(not spells.register_spell({
		"id":"ILLEGAL", "label":"invalid", "cast_range":10.0,
		"effects":[{"operation":"ADD","parameter_id":"health","value":-3}],
		"impact":{"mode":"CHAIN","radius":4.0,"jumps":19}
	}))

	var workshop = Workshop.new(registry, spells, TEST_PATH)
	var chain_id: String = workshop.create_recipe("Моя молния", 12.0,
		[{"operation":"ADD","parameter_id":"health","value":-8}],
		Grammar.make("BOLT", "STORM"), {"mode":"CHAIN","radius":3.5,"jumps":2})
	assert(chain_id == "CUSTOM_001")
	var reload_spells = Spells.new(world, effects, statuses)
	var library = Workshop.new(registry, reload_spells, TEST_PATH)
	assert(library.load_library())
	assert(reload_spells.get_spell(chain_id)["impact"]["mode"] == "CHAIN")
	assert(reload_spells.get_spell(chain_id)["impact"]["jumps"] == 2)
	assert(reload_spells.get_spell(chain_id)["impact"]["radius"] == 3.5)

	# Hacking a material changes how far the discharge travels.
	# METAL extends the source radius, STONE does not.
	assert(actors[2].set_parameter("alive", false))
	assert(actors[0].get_parameter("material") == "METAL")
	assert(Resolver.chain(world, "fridge", 4.5, 1) == ["fridge", "second"])
	assert(actors[0].set_parameter("material", "STONE"))
	assert(Resolver.chain(world, "fridge", 4.5, 1) == ["fridge"])

	for actor in actors:
		actor.free()
	luna.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	print("LUNA 0.14: chain lightning, dampening, all-or-none, recipe persistence passed")
	quit(0)
