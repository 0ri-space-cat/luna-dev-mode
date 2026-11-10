extends SceneTree
## Independent system-contract tests for food, wand permissions, doors and ability transfer.
## Run: godot --headless --path . --script res://tests/test_v3_system_foundation.gd

const Registry = preload("res://scripts/core/parameter_registry.gd")
const World = preload("res://scripts/core/world_registry.gd")
const Commands = preload("res://scripts/core/command_processor.gd")
const Effects = preload("res://scripts/core/effect_engine.gd")
const Access = preload("res://scripts/core/world_access_service.gd")
const Consumables = preload("res://scripts/core/consumable_service.gd")
const Bank = preload("res://scripts/core/ability_bank_service.gd")
const Fixture = preload("res://tests/helpers/v3_entity.gd")

var registry
var world
var commands
var effects
var access
var consumables
var bank


func _initialize() -> void:
	call_deferred("_run")


func _make(entity_id: String, category: String, at: Vector3,
		overrides: Dictionary = {}):
	var entity = Fixture.new()
	entity.configure(entity_id, category, registry, overrides)
	entity.position = at
	root.add_child(entity)
	assert(world.register_entity(entity_id, entity, category.to_upper()))
	return entity


func _run() -> void:
	registry = Registry.new()
	world = World.new()
	commands = Commands.new()
	commands.configure_world(world)
	access = Access.new(world, commands)
	commands.configure_access(access)
	effects = Effects.new(world, commands)
	consumables = Consumables.new(world, commands, effects)
	bank = Bank.new(world, commands)
	var luna = _make("luna", "character", Vector3.ZERO, {
		"alive": true, "health": 40, "speed": 2.0
	})
	var victim = _make("victim", "character", Vector3(2, 0, 0), {
		"alive": true, "health": 30
	})
	var snack = _make("juice", "drink", Vector3(1, 0, 0), {
		"portions": 2
	})
	assert(consumables.hack_contents("juice", [
		{"operation": "ADD", "parameter_id": "health", "value": 15}
	]))
	assert(consumables.consume("juice", "luna"))
	assert(int(luna.get_parameter("health")) == 55)
	assert(int(snack.get_parameter("portions")) == 1)
	# Undo treats the drink's depletion and the buff as the same action.
	assert(commands.undo())
	assert(int(luna.get_parameter("health")) == 40)
	assert(int(snack.get_parameter("portions")) == 2)
	assert(commands.redo())
	assert(int(luna.get_parameter("health")) == 55)
	assert(int(snack.get_parameter("portions")) == 1)
	assert(consumables.hack_contents("juice", [
		{"operation": "ADD", "parameter_id": "health", "value": 10}
	], "SPLASH", 4.0, 2))
	assert(consumables.consume("juice", "luna"))
	assert(int(luna.get_parameter("health")) == 65)
	assert(int(victim.get_parameter("health")) == 40)
	assert(int(snack.get_parameter("portions")) == 0)
	assert(not consumables.consume("juice", "luna"))
	assert(commands.undo())
	assert(int(luna.get_parameter("health")) == 55)
	assert(int(victim.get_parameter("health")) == 30)
	assert(int(snack.get_parameter("portions")) == 1)
	# Invalid effect must not charge an edible item.
	assert(consumables.hack_contents("juice", [
		{"operation": "ADD", "parameter_id": "not_a_real_parameter", "value": 100}
	]))
	var before_portions: int = int(snack.get_parameter("portions"))
	assert(not consumables.consume("juice", "luna"))
	assert(int(snack.get_parameter("portions")) == before_portions)

	# Real ability transfer moves the donor's module into a stored bank stock.
	var donor = _make("donor", "creature", Vector3(0, 0, 1), {"alive": true})
	var fridge = _make("fridge", "fridge", Vector3(0, 0, 1))
	assert(donor.record.set_component("ABILITY_SET", {"ids": ["FLY"]}))
	assert(bank.extract("luna", "donor", "FLY"))
	assert(not donor.record.has_component("ABILITY_SET"))
	assert(bank.amount("luna", "FLY") == 1)
	assert(bank.inject("luna", "fridge", "FLY"))
	assert(bank.amount("luna", "FLY") == 0)
	assert(fridge.record.get_component("ABILITY_SET")["ids"] == ["FLY"])
	assert(commands.undo())
	assert(bank.amount("luna", "FLY") == 1)
	assert(not fridge.record.has_component("ABILITY_SET"))
	assert(commands.redo())
	assert(bank.amount("luna", "FLY") == 0)

	# A modified ADMIN role never creates genuine system permissions.
	var door = _make("door", "door", Vector3(1, 0, 0))
	assert(door.record.set_component("DOOR_LINK", {"destination": "ET_MARKET"}))
	assert(access.register_location("ET_MARKET", 0, "ETERNIA", "MARKET_ENTRY"))
	assert(access.register_location("VOID_DEEP", 3, "VOID", "DEEP_ENTRY"))
	var wand = _make("wand_original", "wand", Vector3.ZERO)
	var copy = _make("wand_copy", "wand", Vector3.ZERO)
	assert(wand.record.set_component("PICKUP", {"holder_id": "luna"}))
	assert(copy.record.set_component("PICKUP", {"holder_id": "luna"}))
	copy.set_meta("copy_origin", "wand_original")
	assert(access.redirect("door", "ET_MARKET", "luna", "wand_original"))
	assert(not access.redirect("door", "VOID_DEEP", "luna", "wand_original"))
	assert(luna.record.add_role("ADMIN"))
	assert(not access.redirect("door", "VOID_DEEP", "luna", "wand_original"))
	assert(not commands.execute_set(wand, "access_level", 3, "luna", "wand:wand_original"))
	assert(commands.execute_set(wand, "access_level", 3, "luna", "wand:wand_copy"))
	assert(int(wand.get_parameter("access_level")) == 3)
	assert(not commands.execute_component(door, "SET_COMPONENT", "DOOR_LINK",
		{"destination": "VOID_DEEP"}, "luna", "wand:wand_original"))
	assert(access.redirect("door", "VOID_DEEP", "luna", "wand_original"))
	assert(access.resolve("door", "luna")["address_id"] == "VOID_DEEP")
	# Opening a preconfigured restricted door is allowed even without wand permissions.
	assert(commands.undo())
	assert(access.resolve("door", "luna")["address_id"] == "ET_MARKET")
	assert(commands.redo())
	assert(access.resolve("door", "luna")["address_id"] == "VOID_DEEP")
	assert(access.register_intrinsic_authority("yuki", 2))
	var yuki = _make("yuki", "character", Vector3.ZERO, {"alive": true})
	assert(access.redirect("door", "ET_MARKET", "yuki"))
	assert(not access.redirect("door", "VOID_DEEP", "yuki"))
	assert(access.register_intrinsic_authority("yuki", 3))
	assert(access.redirect("door", "VOID_DEEP", "yuki"))

	# A bare SceneTree test owns all mock actors directly; unlike Main, no
	# scene _exit_tree hook will release the bidirectional access-policy link.
	commands.clear_history()
	commands.configure_access(null)
	for entity_id in world.list_ids():
		var actor: Node = world.get_entity(entity_id)
		world.unregister_entity(entity_id)
		if is_instance_valid(actor):
			actor.free()
	print("LUNA V3: edible effects, atomic ability bank, physical access and doors passed")
	quit(0)
