extends RefCounted
## Inventory references real Entity IDs. A carried item retains its record,
## abilities, roles and future art; only its physical presence is suspended.
const DEFAULT_SLOTS := 12
const DEFAULT_WEIGHT := 50.0
const PICKUP_REACH := 3.5
const DROP_REACH := 4.0

var world
var commands
var abilities
var events
var last_error := ""


func _init(world_registry, command_processor, ability_service, event_bus) -> void:
	world = world_registry
	commands = command_processor
	abilities = ability_service
	events = event_bus


func make_pickup(entity_id: String, weight: float = 1.0,
		initiator_id: String = "luna") -> bool:
	last_error = ""
	var actor: Node = world.get_entity(entity_id)
	if not (actor is Node3D) or not is_finite(weight) or weight < 0.1 or weight > 100.0:
		return _fail("Invalid pickup target or weight")
	var current: Dictionary = actor.record.get_component("PICKUP")
	if not current.is_empty() and not str(current["holder_id"]).is_empty():
		return _fail("Item is already carried")
	var pos: Vector3 = (actor as Node3D).position
	return commands.execute_component(actor, "SET_COMPONENT", "PICKUP", {
		"enabled": true, "holder_id": "", "weight": weight,
		"world_position": [pos.x, pos.y, pos.z]
	}, initiator_id, "inventory:configure")


func add_inventory(entity_id: String, slots: int = 8,
		max_weight: float = 30.0) -> bool:
	last_error = ""
	var actor: Node = world.get_entity(entity_id)
	if actor == null or actor.get("record") == null:
		return _fail("Carrier is not a hackable Entity")
	if not commands.execute_component(actor, "SET_COMPONENT", "INVENTORY", {
		"max_slots": slots, "max_weight": max_weight
	}, "luna", "inventory:configure"):
		return _fail("Invalid inventory capacity")
	return true


func list_items(owner_id: String) -> Array[String]:
	var found: Array[String] = []
	for entity_id in world.list_ids():
		var actor: Node = world.get_entity(entity_id)
		if actor == null:
			continue
		var record: Variant = actor.get("record")
		if record == null or not record.has_component("PICKUP"):
			continue
		var data: Dictionary = record.get_component("PICKUP")
		if str(data["holder_id"]) == owner_id:
			found.append(entity_id)
	found.sort()
	return found


func pickup(owner_id: String, item_id: String) -> bool:
	last_error = ""
	var owner: Node = world.get_entity(owner_id)
	var item: Node = world.get_entity(item_id)
	if not (owner is Node3D) or not (item is Node3D) or owner_id == item_id:
		return _fail("Invalid carrier or item")
	var data: Dictionary = _pickup_data(item)
	if data.is_empty() or not bool(data["enabled"]) or not str(data["holder_id"]).is_empty():
		return _fail("Item is unavailable")
	if not _can_hold(owner_id, item_id, float(data["weight"])):
		return false
	if (owner as Node3D).global_position.distance_squared_to(
			(item as Node3D).global_position) > PICKUP_REACH * PICKUP_REACH:
		return _fail("Item is out of reach")
	var point: Vector3 = (item as Node3D).position
	data["holder_id"] = owner_id
	data["world_position"] = [point.x, point.y, point.z]
	if not commands.execute_component(item, "SET_COMPONENT", "PICKUP",
			data, owner_id, "inventory:pickup"):
		return _fail("Unable to pick up item")
	sync_item(item_id)
	_announce("item.picked_up", owner_id, item_id)
	return true


func transfer(from_id: String, to_id: String, item_id: String) -> bool:
	last_error = ""
	var origin: Node = world.get_entity(from_id)
	var target: Node = world.get_entity(to_id)
	var item: Node = world.get_entity(item_id)
	if from_id == to_id or not (origin is Node3D) or not (target is Node3D) or item == null:
		return _fail("Invalid item transfer")
	var data: Dictionary = _pickup_data(item)
	if data.is_empty() or str(data["holder_id"]) != from_id:
		return _fail("Item is not carried by the source")
	if (origin as Node3D).global_position.distance_squared_to(
			(target as Node3D).global_position) > PICKUP_REACH * PICKUP_REACH:
		return _fail("Recipient is out of reach")
	if not _can_hold(to_id, item_id, float(data["weight"])):
		return false
	data["holder_id"] = to_id
	if not commands.execute_component(item, "SET_COMPONENT", "PICKUP",
			data, from_id, "inventory:transfer"):
		return _fail("Unable to transfer item")
	sync_item(item_id)
	_announce("item.transferred", from_id, item_id, to_id)
	return true


func drop(owner_id: String, item_id: String, where: Vector3) -> bool:
	last_error = ""
	var owner: Node = world.get_entity(owner_id)
	var item: Node = world.get_entity(item_id)
	if not (owner is Node3D) or not (item is Node3D):
		return _fail("Unknown carrier or item")
	var data: Dictionary = _pickup_data(item)
	if data.is_empty() or str(data["holder_id"]) != owner_id:
		return _fail("Item is not in this inventory")
	if not is_finite(where.x) or not is_finite(where.y) or not is_finite(where.z):
		return _fail("Invalid drop position")
	if (owner as Node3D).global_position.distance_squared_to(where) > DROP_REACH * DROP_REACH:
		return _fail("Drop position is out of reach")
	data["holder_id"] = ""
	data["world_position"] = [where.x, where.y, where.z]
	if not commands.execute_component(item, "SET_COMPONENT", "PICKUP",
			data, owner_id, "inventory:drop"):
		return _fail("Unable to drop item")
	sync_item(item_id)
	_announce("item.dropped", owner_id, item_id)
	return true


func use(owner_id: String, item_id: String, ability_id: String,
		target_id: String) -> bool:
	last_error = ""
	var item: Node = world.get_entity(item_id)
	var owner: Node = world.get_entity(owner_id)
	if item == null or owner == null or str(_pickup_data(item).get("holder_id", "")) != owner_id:
		return _fail("Item does not belong to this carrier")
	if abilities == null or not abilities.activate(item_id, ability_id, target_id, owner_id):
		return _fail(abilities.last_error if abilities != null else "Ability engine missing")
	_announce("item.used", owner_id, item_id, target_id)
	return true


func sync_all() -> void:
	for entity_id in world.list_ids():
		sync_item(entity_id)


func sync_item(entity_id: String) -> void:
	var actor: Node = world.get_entity(entity_id)
	if not (actor is Node3D):
		return
	var data: Dictionary = _pickup_data(actor)
	if data.is_empty():
		if actor.has_meta("inventory_original_layer"):
			_restore_presence(actor)
		return
	if str(data["holder_id"]).is_empty():
		_restore_presence(actor)
		var packed: Array = data["world_position"]
		(actor as Node3D).position = Vector3(float(packed[0]), float(packed[1]), float(packed[2]))
	elif world.get_entity(str(data["holder_id"])) != null:
		_suspend_presence(actor)
	else:
		# Defensive fallback if a future corrupted save references a missing
		# carrier. Never leave an invisible, non-interactable ghost.
		_restore_presence(actor)


func _pickup_data(actor: Node) -> Dictionary:
	if actor == null:
		return {}
	var record: Variant = actor.get("record")
	if record == null or not record.has_component("PICKUP"):
		return {}
	return record.get_component("PICKUP")


func _can_hold(owner_id: String, item_id: String, weight: float) -> bool:
	var actor: Node = world.get_entity(owner_id)
	if actor == null:
		return _fail("Carrier is missing")
	var slots := DEFAULT_SLOTS
	var capacity := DEFAULT_WEIGHT
	if owner_id != "luna":
		var record: Variant = actor.get("record")
		if record == null or not record.has_component("INVENTORY"):
			return _fail("Recipient cannot carry items")
		var spec: Dictionary = record.get_component("INVENTORY")
		slots = int(spec["max_slots"])
		capacity = float(spec["max_weight"])
	var contents: Array[String] = list_items(owner_id)
	if contents.size() >= slots:
		return _fail("Inventory is full")
	var total := weight
	for id in contents:
		total += float(_pickup_data(world.get_entity(id))["weight"])
	if total > capacity:
		return _fail("Inventory weight limit reached")
	# Prevent containers from containing themselves, including indirectly.
	var current := owner_id
	var visited := {}
	while not current.is_empty():
		if current == item_id or visited.has(current):
			return _fail("Circular inventory ownership")
		visited[current] = true
		current = str(_pickup_data(world.get_entity(current)).get("holder_id", ""))
	return true


func _suspend_presence(actor: Node) -> void:
	if not actor.has_meta("inventory_original_layer") and actor is CollisionObject3D:
		actor.set_meta("inventory_original_layer", (actor as CollisionObject3D).collision_layer)
		actor.set_meta("inventory_original_mask", (actor as CollisionObject3D).collision_mask)
	if actor is CollisionObject3D:
		(actor as CollisionObject3D).collision_layer = 0
		(actor as CollisionObject3D).collision_mask = 0
	(actor as Node3D).visible = false
	actor.set_physics_process(false)


func _restore_presence(actor: Node) -> void:
	if actor is CollisionObject3D and actor.has_meta("inventory_original_layer"):
		(actor as CollisionObject3D).collision_layer = int(actor.get_meta("inventory_original_layer"))
		(actor as CollisionObject3D).collision_mask = int(actor.get_meta("inventory_original_mask"))
		actor.remove_meta("inventory_original_layer")
		actor.remove_meta("inventory_original_mask")
	(actor as Node3D).visible = true
	actor.set_physics_process(true)


func _announce(kind: String, actor_id: String, item_id: String,
		recipient_id: String = "") -> void:
	if events == null:
		return
	events.enqueue({
		"type": kind, "source_id": actor_id, "target_id": item_id,
		"payload": {"item_id": item_id, "recipient_id": recipient_id}
	})


func _fail(message: String) -> bool:
	last_error = message
	return false
