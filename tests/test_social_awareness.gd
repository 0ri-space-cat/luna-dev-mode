extends SceneTree
## Actual damage creates short-lived social reactions without overwriting
## player-authored directed relationships, behavior parameters or permanent saves.

const Registry = preload("res://scripts/core/parameter_registry.gd")
const World = preload("res://scripts/core/world_registry.gd")
const Relations = preload("res://scripts/core/relationship_service.gd")
const Commands = preload("res://scripts/core/command_processor.gd")
const Effects = preload("res://scripts/core/effect_engine.gd")
const Spells = preload("res://scripts/core/spell_service.gd")
const Awareness = preload("res://scripts/core/social_awareness_service.gd")
const Save = preload("res://scripts/core/save_service.gd")
const Hackable = preload("res://scripts/hackable_entity.gd")

const PATH := "user://luna_social_awareness_test.json"

var social


func _initialize() -> void:
	call_deferred("_run")


func _on_damage(details: Dictionary) -> void:
	var targets: Array[String] = []
	for entity_id in details["targets"]:
		targets.append(str(entity_id))
	social.observe_damage(str(details["caster_id"]), targets)


func _run() -> void:
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	var registry = Registry.new()
	var world = World.new()
	var relations = Relations.new()
	var commands = Commands.new()
	var effects = Effects.new(world, commands, relations)
	social = Awareness.new(world, relations)
	var spells = Spells.new(world, effects)
	spells.damage_applied.connect(_on_damage)
	var luna := Node3D.new()
	root.add_child(luna)
	luna.position = Vector3.ZERO
	assert(world.register_entity("luna", luna, "LUNA"))
	var victim = Hackable.new()
	var witness = Hackable.new()
	var faraway = Hackable.new()
	root.add_child(victim)
	root.add_child(witness)
	root.add_child(faraway)
	victim.configure("victim", "fridge", Vector3(1, 0, 0),
		registry, world, relations, {}, null, social)
	witness.configure("witness", "tree", Vector3(4, 0, 0),
		registry, world, relations, {}, null, social)
	faraway.configure("faraway", "tree", Vector3(20, 0, 0),
		registry, world, relations, {}, null, social)
	assert(world.register_entity("victim", victim, "FRIDGE"))
	assert(world.register_entity("witness", witness, "TREE"))
	assert(world.register_entity("faraway", faraway, "TREE"))
	for actor in [victim, witness, faraway]:
		assert(actor.set_parameter("alive", true))
		assert(actor.get_parameter("behavior_mode") == "WANDER")

	# Friendly/harmless spells must not create hostility or witness alerts.
	assert(spells.resolve_impact("PINKIFY", "luna", "victim"))
	assert(spells.resolve_impact("AWAKEN", "luna", "victim"))
	assert(social.get_alert("victim").is_empty())
	assert(social.get_alert("witness").is_empty())
	assert(relations.export_data().is_empty())

	# Fireball damages only the fridge: the nearby tree is a bystander.
	assert(spells.resolve_impact("FIREBALL", "luna", "victim"))
	assert(victim.get_parameter("health") == 76)
	assert(witness.get_parameter("health") == 65)
	assert(social.get_alert("victim")["reason"] == "DIRECT")
	assert(social.get_alert("witness")["reason"] == "WITNESS")
	assert(social.get_alert("faraway").is_empty())
	assert(social.get_alert("victim")["aggressor_id"] == "luna")
	# The signal-driven visual is intentionally simple in the graybox.
	victim.show_social_alert(social.get_alert("victim"))
	witness.show_social_alert(social.get_alert("witness"))
	assert(victim.social_label.visible and victim.social_label.text == "!")
	assert(witness.social_label.visible and witness.social_label.text == "?")
	assert(relations.export_data().is_empty())

	# A neutral living victim flees; a witness also flees if no prior order.
	victim._physics_process(0.05)
	witness._physics_process(0.05)
	assert(victim.brain.last_decision == "FLEE")
	assert(witness.brain.last_decision == "FLEE")
	assert(victim.get_parameter("behavior_mode") == "WANDER")
	assert(witness.get_parameter("behavior_mode") == "WANDER")

	# Explicit FRIEND is respected; HOSTILE changes the temporary response
	# to chase, but a manual IDLE order retains absolute priority.
	assert(relations.set_attitude("witness", "luna", "FRIEND"))
	witness._physics_process(0.05)
	assert(witness.brain.last_decision != "FLEE")
	assert(relations.set_attitude("witness", "luna", "HOSTILE"))
	witness._physics_process(0.05)
	assert(witness.brain.last_decision == "CHASE")
	assert(witness.set_parameter("behavior_mode", "IDLE"))
	witness._physics_process(0.05)
	assert(witness.brain.last_decision == "IDLE")
	assert(relations.get_attitude("witness", "luna") == "HOSTILE")

	# Temporary emotions survive save/load without new file format version.
	var save = Save.new(PATH)
	assert(save.save_world(world, luna, relations, null, null, social))
	var snapshot: Dictionary = save.snapshot(world, luna, relations, null, null, social)
	assert(snapshot["social_awareness"]["alerts"]["victim"]["reason"] == "DIRECT")
	assert(social.import_data({}))
	assert(social.get_alert("victim").is_empty())
	assert(save.load_world(world, luna, relations, Callable(), null, null, null, social))
	assert(social.get_alert("victim")["reason"] == "DIRECT")
	assert(relations.get_attitude("witness", "luna") == "HOSTILE")

	# All saved fields validate before anything in the world is changed.
	var invalid: Dictionary = snapshot.duplicate(true)
	invalid["social_awareness"]["alerts"]["victim"]["remaining"] = "eternity"
	assert(not save.apply_snapshot(invalid, world, luna, relations, Callable(), null, null, null, social))
	assert(social.get_alert("victim")["reason"] == "DIRECT")
	assert(social.validate_data({})) # Prior save files still load.

	for tick in range(5):
		social.advance(1.0)
	assert(social.get_alert("victim").is_empty())
	assert(social.get_alert("witness").is_empty())
	victim._physics_process(0.05)
	assert(victim.brain.last_decision != "FLEE")

	victim.free()
	witness.free()
	faraway.free()
	luna.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	print("LUNA 0.17: actual damage, witnesses, social priorities and saves passed")
	quit(0)
