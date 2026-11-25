extends RefCounted
## Atomic capability transfer over the shared bank and entity components.
## The legacy runtime uses stock counts. New modules keep their identity.

const Components = preload("res://scripts/core/component_registry.gd")
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
	_write_collection(donor_after, "ABILITY_SET", "ids", ids)
	var holder_before: Dictionary = holder_record.get_components()
	var holder_after: Dictionary = holder_before.duplicate(true)
	_write_collection(holder_after, "ABILITY_BANK", "stock", stock)
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
	_write_collection(holder_after, "ABILITY_BANK", "stock", stock)
	var recipient_before: Dictionary = target_record.get_components()
	var recipient_after: Dictionary = recipient_before.duplicate(true)
	_write_collection(recipient_after, "ABILITY_SET", "ids", ids)
	return _commit(holder, holder_id, holder_before, holder_after,
		recipient, recipient_id, recipient_before, recipient_after, "ability:inject")


func amount(holder_id: String, ability_id: String) -> int:
	var holder: Node = world.get_entity(holder_id)
	if holder == null or holder.get("record") == null:
		return 0
	var bank: Dictionary = holder.get("record").get_component("ABILITY_BANK")
	var count: int = int(bank.get("stock", {}).get(ability_id, 0))
	for entry in bank.get("instances", {}).values():
		if entry["ability_id"] == ability_id:
			count += 1
	return count


func move_instance(holder_id: String, other_id: String, instance_id: String, extracting: bool) -> bool:
	last_error = ""
	var holder: Node = world.get_entity(holder_id)
	var other: Node = world.get_entity(other_id)
	if not _valid_pair(holder, other, holder_id, other_id, instance_id):
		return false
	var holder_before: Dictionary = holder.record.get_components()
	var other_before: Dictionary = other.record.get_components()
	if other.record.category in ["player", "luna"]:
		return _fail("Playable heroes cannot transfer permanent modules")
	var stock := instances(holder_before, "ABILITY_BANK")
	var installed := instances(other_before, "ABILITY_SET")
	var source := installed if extracting else stock
	var destination := stock if extracting else installed
	if not source.has(instance_id) or destination.has(instance_id) or destination.size() >= 16:
		return _fail("Instance unavailable at this source or destination")
	var module: Dictionary = source[instance_id]
	if module["protected"]:
		return _fail("Protected module")
	if not extracting:
		if other_before.get("ABILITY_SET", {}).get("ids", []).has(module["ability_id"]):
			return _fail("Target already has this capability")
		for existing in installed.values():
			if existing["ability_id"] == module["ability_id"]:
				return _fail("Target already has this capability")
	source.erase(instance_id)
	destination[instance_id] = module
	var holder_after := holder_before.duplicate(true)
	var other_after := other_before.duplicate(true)
	_write_collection(holder_after, "ABILITY_BANK", "instances", stock)
	_write_collection(other_after, "ABILITY_SET", "instances", installed)
	var operation := "ability:extract_instance" if extracting else "ability:install_instance"
	return _commit(holder, holder_id, holder_before, holder_after,
		other, other_id, other_before, other_after, operation)


static func instances(components: Dictionary, component_id: String) -> Dictionary:
	return components.get(component_id, {}).get("instances", {}).duplicate(true)


func _write_collection(components: Dictionary, component_id: String, field: String, value: Variant) -> void:
	var component: Dictionary = components.get(component_id, {}).duplicate(true)
	if value.is_empty():
		component.erase(field)
	else:
		component[field] = value
	# Empty defaults must not keep a component alive after its last module moved.
	for key in component.keys():
		if component[key].is_empty():
			component.erase(key)
	if component.is_empty():
		components.erase(component_id)
	else:
		components[component_id] = Components.validate(component_id, component)["value"]


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
