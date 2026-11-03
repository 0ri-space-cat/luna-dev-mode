extends SceneTree
## v0.10: classic spells are composed of readable facets, launch visible
## projectiles and only apply typed effects once the projectile arrives.

const Registry = preload("res://scripts/core/parameter_registry.gd")
const World = preload("res://scripts/core/world_registry.gd")
const Commands = preload("res://scripts/core/command_processor.gd")
const Effects = preload("res://scripts/core/effect_engine.gd")
const Spells = preload("res://scripts/core/spell_service.gd")
const Grammar = preload("res://scripts/core/arcane_grammar.gd")
const Projectile = preload("res://scripts/spells/arcane_projectile.gd")
const Workshop = preload("res://scripts/core/spell_workshop_service.gd")
const Hackable = preload("res://scripts/hackable_entity.gd")

const TEMP := "user://luna_arcane_test.json"

var requests: Array[Dictionary] = []
var hits := 0


func _initialize() -> void:
	call_deferred("_run")


func _on_requested(details: Dictionary) -> void:
	requests.append(details.duplicate(true))


func _on_struck(spell_id: String, caster_id: String, target_id: String, service) -> void:
	assert(service.resolve_impact(spell_id, caster_id, target_id))
	hits += 1


func _run() -> void:
	if FileAccess.file_exists(TEMP):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEMP))
	var registry = Registry.new()
	var world = World.new()
	var commands = Commands.new()
	var effects = Effects.new(world, commands)
	var spells = Spells.new(world, effects)
	var luna := Node3D.new()
	var fridge = Hackable.new()
	root.add_child(luna)
	root.add_child(fridge)
	luna.position = Vector3.ZERO
	fridge.configure("fridge_test", "fridge", Vector3(5, 0, 0), registry, world)
	assert(world.register_entity("luna", luna, "LUNA"))
	assert(world.register_entity("fridge_test", fridge, "FRIDGE"))
	spells.projectile_requested.connect(_on_requested)
	assert(spells.list_spell_ids() == ["FIREBALL", "FROST_SHARD", "ARC_BOLT"])
	assert(spells.contains_spell("AWAKEN")) # old utility recipes still resolve
	assert(spells.get_spell("FIREBALL")["effects"][0]["parameter_id"] == "health")
	assert(Grammar.readable(spells.get_spell("FIREBALL")["manifestation"]).contains("Огонь"))
	assert(Grammar.valid(Grammar.make("ORB", "FIRE")))
	assert(not Grammar.valid(Grammar.make("CUBE", "FIRE")))
	assert(not Grammar.valid(Grammar.make("ORB", "WATER")))
	var invalid: Dictionary = Grammar.make("ORB", "FIRE")
	invalid["speed"] = NAN
	assert(not Grammar.valid(invalid))

	assert(spells.cast_spell("FIREBALL", "luna", "fridge_test"))
	assert(requests.size() == 1)
	assert(fridge.get_parameter("health") == 100) # No damage before impact!
	assert(requests[0]["manifestation"]["shape"] == "ORB")
	var projectile = Projectile.new()
	root.add_child(projectile)
	projectile.configure(
		requests[0]["manifestation"], luna, fridge,
		"FIREBALL", "luna", "fridge_test"
	)
	assert(projectile.get_child(0) is MeshInstance3D)
	assert((projectile.get_child(0) as MeshInstance3D).mesh is SphereMesh)
	projectile.struck.connect(_on_struck.bind(spells))
	for tick in range(120):
		if hits >= 1:
			break
		projectile._physics_process(1.0 / 60.0)
	assert(hits == 1)
	assert(fridge.get_parameter("health") == 76)
	assert(commands.get_recent_audit(1)[0]["source_id"] == "spell:FIREBALL")

	assert(spells.cast_spell("FROST_SHARD", "luna", "fridge_test"))
	assert(requests.size() == 2)
	assert(requests[1]["manifestation"]["shape"] == "SHARD")
	assert(spells.resolve_impact("FROST_SHARD", "luna", "fridge_test"))
	assert(fridge.get_parameter("health") == 66)
	assert(is_equal_approx(float(fridge.get_parameter("speed")), 1.7))
	assert(commands.undo())
	assert(fridge.get_parameter("health") == 76)
	assert(is_equal_approx(float(fridge.get_parameter("speed")), 2.6))

	# Dissect the classic fireball, reassemble into a storm shard, and persist.
	var workshop = Workshop.new(registry, spells, TEMP)
	var remix: Dictionary = spells.get_spell("FIREBALL")["manifestation"].duplicate(true)
	remix["shape"] = "SHARD"
	remix["element"] = "STORM"
	remix["speed"] = 18.0
	var actions: Array[Dictionary] = [
		{"operation": "ADD", "parameter_id": "health", "value": -12},
		{"operation": "SET", "parameter_id": "alive", "value": true}
	]
	assert(workshop.create_recipe("Моя грозовая пакость", 14.0, actions, remix) == "CUSTOM_001")
	assert(spells.get_spell("CUSTOM_001")["manifestation"]["element"] == "STORM")
	assert(workshop.create_recipe("Ошибка", 15.0, actions, invalid).is_empty())
	var next_spells = Spells.new(world, effects)
	var library = Workshop.new(registry, next_spells, TEMP)
	assert(library.load_library())
	assert(next_spells.get_spell("CUSTOM_001")["manifestation"]["shape"] == "SHARD")
	assert(next_spells.cast_spell("CUSTOM_001", "luna", "fridge_test"))
	assert(fridge.get_parameter("health") == 76) # Projectile needs to land.
	assert(next_spells.resolve_impact("CUSTOM_001", "luna", "fridge_test"))
	assert(fridge.get_parameter("health") == 64)
	assert(fridge.get_parameter("alive"))

	fridge.free()
	luna.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEMP))
	print("LUNA 0.10: elemental spell facets, projectiles and remixes passed")
	quit(0)
