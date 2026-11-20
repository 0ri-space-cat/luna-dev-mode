extends RefCounted
## Atomic, physical capability transfer. The bank stores counts in a typed
## component on a real entity; it is not an XP/perk unlock or a global cheat.
## Ability runtime behaviors are resolved separately by AbilityService.

const MAX_STOCK_PER_ABILITY := 8
var world
var commands
var last_error := ""


func _init(world_registry, command_processor) -> void:
	world = world_registry
	commands = command_processor


func extract(holder_id: String, donor_id: String, ability_id: String) -> bool:
	last_error = ""
	var holder: Node = world.get_entity(holder_id)
	var donor: Node = world.get_entity(donor_id)
	if not _valid_pair(holder, donor, holder_id, donor_id, ability_id):
		return false
	var donor_record: Variant = donor.get("record")
	var holder_record: Variant = holder.get("record")
	var set_data: Dictionary = donor_record.get_component("ABILITY_SET")
	var ids: Array = set_data.get("ids", []).duplicate()
	if not ids.has(ability_id):
		return _fail("Donor does not have this ability")
	var bank_data: Dictionary = holder_record.get_component("ABILITY_BANK")
	var stock: Dictionary = bank_data.get("stock", {}).duplicate(true)
	if int(stock.get(ability_id, 0)) >= MAX_STOCK_PER_ABILITY:
		return _fail("Ability bank stack is full")
	ids.erase(ability_id)
	stock[ability_id] = int(stock.get(ability_id, 0)) + 1
	var donor_before: Dictionary = donor_record.get_components()
	var donor_after: Dictionary = donor_before.duplicate(true)
	if ids.is_empty():
		donor_after.erase("ABILITY_SET")
	else:
		donor_after["ABILITY_SET"] = {"ids": ids}
	var holder_before: Dictionary = holder_record.get_components()
	var holder_after: Dictionary = holder_before.duplicate(true)
	holder_after["ABILITY_BANK"] = {"stock": stock}
	return _commit(holder, holder_id, holder_before, holder_after,
		donor, donor_id, donor_before, donor_after, "ability:extract")


func inject(holder_id: String, recipient_id: String, ability_id: String) -> bool:
	last_error = ""
	var holder: Node = world.get_entity(holder_id)
	var recipient: Node = world.get_entity(recipient_id)
	if not _valid_pair(holder, recipient, holder_id, recipient_id, ability_id):
		return false
	var holder_record: Variant = holder.get("record")
	var target_record: Variant = recipient.get("record")
	var bank_data: Dictionary = holder_record.get_component("ABILITY_BANK")
	var stock: Dictionary = bank_data.get("stock", {}).duplicate(true)
	if int(stock.get(ability_id, 0)) < 1:
		return _fail("Ability not held in the bank")
	var ids: Array = target_record.get_component("ABILITY_SET").get("ids", []).duplicate()
	if ids.has(ability_id) or ids.size() >= 16:
		return _fail("Target already has this ability or slots are full")
	ids.append(ability_id)
	ids.sort()
	if int(stock[ability_id]) == 1:
		stock.erase(ability_id)
	else:
		stock[ability_id] = int(stock[ability_id]) - 1
	var holder_before: Dictionary = holder_record.get_components()
	var holder_after: Dictionary = holder_before.duplicate(true)
	if stock.is_empty():
		holder_after.erase("ABILITY_BANK")
	else:
		holder_after["ABILITY_BANK"] = {"stock": stock}
	var recipient_before: Dictionary = target_record.get_components()
	var recipient_after: Dictionary = recipient_before.duplicate(true)
	recipient_after["ABILITY_SET"] = {"ids": ids}
	return _commit(holder, holder_id, holder_before, holder_after,
		recipient, recipient_id, recipient_before, recipient_after, "ability:inject")


func amount(holder_id: String, ability_id: String) -> int:
	var holder: Node = world.get_entity(holder_id)
	if holder == null or holder.get("record") == null:
		return 0
	var bank: Dictionary = holder.get("record").get_component("ABILITY_BANK")
	return int(bank.get("stock", {}).get(ability_id, 0))


func _valid_pair(a: Node, b: Node, id_a: String, id_b: String, ability_id: String) -> bool:
	if id_a.is_empty() or id_a == id_b or a == null or b == null:
		return _fail("Transfer requires two different live entities")
	if a.get("record") == null or b.get("record") == null:
		return _fail("Entity has no editable record")
	if ability_id.length() > 64 or not ability_id.is_valid_identifier():
		return _fail("Invalid ability identifier")
	return true


func _commit(a: Node, id_a: String, before_a: Dictionary, after_a: Dictionary,
		b: Node, id_b: String, before_b: Dictionary, after_b: Dictionary,
		source_id: String) -> bool:
	var steps: Array[Dictionary] = [
		{"kind": "components", "target": a, "entity_id": id_a, "before": before_a, "after": after_a},
		{"kind": "components", "target": b, "entity_id": id_b, "before": before_b, "after": after_b}
	]
	if not commands.execute_batch(steps, id_a, source_id):
		return _fail("Atomic component transfer was rejected")
	return true


func _fail(message: String) -> bool:
	last_error = message
	return false
