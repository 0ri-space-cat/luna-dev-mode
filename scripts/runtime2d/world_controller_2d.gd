extends Node2D
## Minimal, authored-content-free 2D runtime. Gameplay visuals use their
## own VisualAnchor; screen-space UI is supplied separately after asset delivery.
## Existing 3D tests stay intact for now.

signal location_entered(address: String)
signal perception_changed(is_underside: bool)
signal gameplay_event(event_data: Dictionary)
signal entity_state_changed(change: Dictionary)
signal integrity_notice(reason: String)

const ParameterRegistry = preload("res://scripts/core/parameter_registry.gd")
const WorldRegistry = preload("res://scripts/core/world_registry.gd")
const CommandProcessor = preload("res://scripts/core/command_processor.gd")
const Actor = preload("res://scripts/runtime2d/actor_body_2d.gd")
const WandProjectionField = preload("res://scripts/runtime2d/projection_field_2d.gd")
const LocationRouter = preload("res://scripts/runtime2d/location_router_2d.gd")
const AccessState = preload("res://scripts/runtime2d/access_state_2d.gd")
const SaveStore = preload("res://scripts/runtime2d/save_store_2d.gd")
const DevDoor = preload("res://scripts/runtime2d/dev_door_2d.gd")
const ObserverQuery = preload("res://scripts/runtime2d/observer_query_2d.gd")
const EventBus = preload("res://scripts/core/event_bus.gd")
const AbilityBankService = preload("res://scripts/core/ability_bank_service.gd")

const DEV_CATALOG := "res://data/runtime2d/DEV_LOCATIONS.json"
const DEV_GEOMETRY := "res://data/runtime2d/DEV_SANDBOX_GEOMETRY.json"
const MAX_ACTORS := 48
const MAX_CHECKPOINTS := 8

var parameter_registry
var world_registry
var command_processor
var router
var access
var projection
var store
var player
var camera
var current_location_id := ""
var luna_eyes_open := true
var observer
var event_bus
var ability_bank
var _trusted_visuals: Dictionary = {}

var _level_slot: Node2D
var _actor_slot: Node2D
var _live_level
var _door
var _serial := 0
var _was_underside := false
var _checkpoints: Array[Dictionary] = []


func _ready() -> void:
	_level_slot = get_node("World/Level")
	_actor_slot = get_node("World/Actors")
	camera = get_node("World/Camera")
	parameter_registry = ParameterRegistry.new()
	parameter_registry.register_parameter({
		"id": "is_visible", "label": "IS_VISIBLE", "kind": "bool",
		"default": true, "hint": "Видна ли сущность в обычном изображении мира."
	})
	world_registry = WorldRegistry.new()
	command_processor = CommandProcessor.new()
	command_processor.configure_world(world_registry)
	command_processor.component_changed.connect(_on_entity_component_changed)
	command_processor.parameter_changed.connect(_on_entity_parameter_changed)
	router = LocationRouter.new()
	access = AccessState.new()
	projection = WandProjectionField.new()
	store = SaveStore.new()
	observer = ObserverQuery.new()
	event_bus = EventBus.new()
	event_bus.event_dropped.connect(_on_event_overflow)
	ability_bank = AbilityBankService.new(world_registry, command_processor)

	# Only development fixtures, NOT real Ethernia locations or canon geography.
	assert(router.load_catalog_json(DEV_CATALOG))

	player = spawn_actor("luna", "luna", "Луна", Vector2(-160, 0), true)
	var fixture = spawn_actor("DEV_ENTITY_01", "object", "Тестовая Entity", Vector2(60, 50))
	if fixture != null:
		fixture.set_parameter("alive", true)
		fixture.set_parameter("ai_enabled", true)
	camera.target = player
	camera.make_current()
	_enter_location("DEV_SANDBOX_A")


func _attach_actor_services(actor: Node) -> void:
	actor.world_registry = world_registry
	actor.passive_ability_applied.connect(_on_passive_ability_applied)


func _on_passive_ability_applied(event_data: Dictionary) -> void:
	queue_world_event(event_data)


func spawn_actor(entity_id: String, category: String, label: String,
		at: Vector2, is_player: bool = false):
	if world_registry.count_live() >= MAX_ACTORS:
		integrity_notice.emit("ENTITY_BUDGET_REACHED")
		return null
	if world_registry.get_entity(entity_id) != null:
		return null
	var actor = Actor.new()
	if not actor.configure(entity_id, category, label, parameter_registry, is_player):
		actor.free()
		return null
	actor.position = at
	_attach_actor_services(actor)
	actor.location_id = current_location_id if not current_location_id.is_empty() else "DEV_SANDBOX_A"
	_actor_slot.add_child(actor)
	_apply_trusted_visual(actor)
	if not world_registry.register_entity(entity_id, actor, category.to_upper()):
		actor.queue_free()
		return null
	return actor


func clone_actor(entity_id: String):
	if world_registry.count_live() >= MAX_ACTORS:
		integrity_notice.emit("CLONE_BUDGET_REACHED")
		return null
	var original = world_registry.get_entity(entity_id)
	if original == null or not original.has_method("clone_as"):
		return null
	_serial += 1
	while world_registry.get_entity("COPY_%d" % _serial) != null:
		_serial += 1
	var copied_id := "COPY_%d" % _serial
	var clone = original.clone_as(copied_id)
	if clone == null:
		return null
	_attach_actor_services(clone)
	_actor_slot.add_child(clone)
	clone.attach_visual(original.get_visual_scene())
	if not world_registry.register_entity(copied_id, clone, str(clone.record.category).to_upper()):
		clone.queue_free()
		return null
	_update_actor_activation()
	return clone


func set_entity_parameter(entity_id: String, key: String, value: Variant) -> bool:
	var actor: Node = world_registry.get_entity(entity_id)
	return actor != null and command_processor.execute_set(actor, key, value, "luna", "wand:luna")


func set_entity_ability(entity_id: String, ability_id: String, enabled: bool) -> bool:
	# Other approved abilities await their real behavior adapters; no fake grant.
	if ability_id not in ["FLY", "GLOW", "REGENERATION"]:
		return false
	var actor: Node = world_registry.get_entity(entity_id)
	if actor == null:
		return false
	var ids: Array = actor.record.get_component("ABILITY_SET").get("ids", []).duplicate()
	if enabled and not ids.has(ability_id):
		ids.append(ability_id)
	elif not enabled:
		ids.erase(ability_id)
	if ids.is_empty():
		if not actor.record.has_component("ABILITY_SET"):
			return true
		return command_processor.execute_component(actor, "REMOVE_COMPONENT", "ABILITY_SET", {}, "luna", "wand:luna")
	return command_processor.execute_component(actor, "SET_COMPONENT", "ABILITY_SET", {"ids": ids}, "luna", "wand:luna")


## Bank operations reuse the original atomic component transfer engine.
## Physical proximity and current-room checks are enforced here, not by UI.
func transfer_ability(holder_id: String, other_id: String, ability_id: String,
		extract: bool = true) -> bool:
	if ability_id not in ["FLY", "GLOW", "REGENERATION"]:
		return false
	var holder: Node2D = world_registry.get_entity(holder_id) as Node2D
	var other: Node2D = world_registry.get_entity(other_id) as Node2D
	if holder == null or other == null or holder == other:
		return false
	if not holder.has_method("get_world_location_id") or not other.has_method("get_world_location_id"):
		return false
	if holder.get_world_location_id() != current_location_id or other.get_world_location_id() != current_location_id:
		return false
	if holder.global_position.distance_squared_to(other.global_position) > 96.0 * 96.0:
		return false
	return ability_bank.extract(holder_id, other_id, ability_id) if extract else ability_bank.inject(holder_id, other_id, ability_id)


func find_nearby_entities(origin_id: String, radius: float,
		target_group: String = "ANY") -> Array[Dictionary]:
	var origin: Node2D = world_registry.get_entity(origin_id) as Node2D
	if origin == null:
		return []
	return world_registry.candidates_2d(origin_id, origin.global_position,
		target_group, radius, current_location_id)


func register_visual(category: String, scene: PackedScene) -> bool:
	# Art integration API; no screen-space UI or sprite is included.
	if category.is_empty() or not category.is_valid_identifier() or scene == null:
		return false
	var sample: Node = scene.instantiate()
	var compatible: bool = sample is Node2D
	sample.free()
	if not compatible:
		return false
	_trusted_visuals[category] = scene
	for entity_id in world_registry.list_ids():
		var actor = world_registry.get_entity(entity_id)
		if actor != null and actor.record.category == category:
			actor.attach_visual(scene)
	return true


func _apply_trusted_visual(actor: Node) -> void:
	var scene: PackedScene = _trusted_visuals.get(str(actor.record.category), null)
	if scene != null:
		actor.attach_visual(scene)


func _update_actor_activation() -> void:
	for child in _actor_slot.get_children():
		if not (child is CharacterBody2D):
			continue
		var active: bool = child.player_controlled or child.location_id == current_location_id
		child.visible = active
		child.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
		child.collision_layer = 2 if active else 0
		child.collision_mask = (1 | 2 | 4) if active else 0
		if active:
			child.refresh_capabilities()


func _on_entity_component_changed(change: Dictionary) -> void:
	var actor = world_registry.get_entity(str(change.get("entity_id", "")))
	if actor != null:
		actor.refresh_capabilities()
	entity_state_changed.emit(change)
	queue_world_event({"type": "COMPONENT_CHANGED", "change": change.duplicate(true)})


func _on_entity_parameter_changed(change: Dictionary) -> void:
	entity_state_changed.emit(change)
	queue_world_event({"type": "PARAMETER_CHANGED", "change": change.duplicate(true)})


func queue_world_event(event_data: Dictionary) -> bool:
	# Reuses the original bounded EventBus: no recursive rule execution,
	# no unbounded event flood from user-authored spell/console programs.
	return event_bus.enqueue(event_data)


func process_event(event_data: Dictionary) -> void:
	gameplay_event.emit(event_data)


func _on_event_overflow(reason: String) -> void:
	integrity_notice.emit(reason)


func _on_zone_entered(zone_id: String, entity_id: String) -> void:
	queue_world_event({"type": "ZONE_ENTERED", "zone_id": zone_id,
		"entity_id": entity_id, "location_id": current_location_id})


func _on_zone_exited(zone_id: String, entity_id: String) -> void:
	queue_world_event({"type": "ZONE_EXITED", "zone_id": zone_id,
		"entity_id": entity_id, "location_id": current_location_id})


func _enter_location(address: String, entry_id: String = "entry", place_player: bool = true,
		authority_override: int = -1) -> bool:
	var authority: int = access.avatar_access_level if authority_override < 0 else authority_override
	var plan: Dictionary = router.resolve_address(address, authority, entry_id)
	if not bool(plan.get("ok", false)):
		return false
	var level_scene: PackedScene = load(str(plan["scene"])) as PackedScene
	if level_scene == null:
		return false
	var next_level: Node = level_scene.instantiate()
	if not (next_level is Node2D):
		next_level.free()
		return false
	if address.begins_with("DEV_SANDBOX_"):
		next_level.set("geometry_json_path", DEV_GEOMETRY)
	if is_instance_valid(_live_level):
		_level_slot.remove_child(_live_level)
		_live_level.queue_free()
	_level_slot.add_child(next_level)
	_live_level = next_level
	if _live_level.has_signal("zone_entered"):
		_live_level.zone_entered.connect(_on_zone_entered)
		_live_level.zone_exited.connect(_on_zone_exited)
	current_location_id = address
	if place_player and is_instance_valid(player):
		player.global_position = plan["position"]
	_mount_dev_door()
	_update_actor_activation()
	_update_perception(true)
	location_entered.emit(address)
	return true


func _mount_dev_door() -> void:
	# Only the diagnostic rooms get temporary drawn doors. Real scenes place
	# their own Doorway2D nodes using author-approved geometry.
	_door = null
	if current_location_id not in ["DEV_SANDBOX_A", "DEV_SANDBOX_B"]:
		return
	_door = DevDoor.new()
	_door.entity_id = "DEV_DOOR_A" if current_location_id == "DEV_SANDBOX_A" else "DEV_DOOR_B"
	_door.position = Vector2(260, 0)
	_live_level.add_child(_door)


func _nearest_door(max_reach: float = 100.0) -> Node:
	if not is_instance_valid(_live_level) or not is_instance_valid(player):
		return null
	var nearest: Node = null
	var distance_sq: float = max_reach * max_reach
	for candidate in get_tree().get_nodes_in_group("runtime2d_address_doors"):
		if not _live_level.is_ancestor_of(candidate):
			continue
		if not candidate.has_method("can_interact_from"):
			continue
		var identity: String = str(candidate.get("entity_id"))
		if identity.is_empty() or not router.door_destinations.has(identity):
			continue
		var d: float = player.global_position.distance_squared_to(candidate.global_position)
		if d > distance_sq or not candidate.can_interact_from(player.global_position):
			continue
		distance_sq = d
		nearest = candidate
	return nearest


func enter_nearby_door() -> bool:
	var nearby: Node = _nearest_door(100.0)
	if nearby == null:
		return false
	var plan: Dictionary = router.resolve_door(str(nearby.get("entity_id")),
		access.avatar_access_level, str(nearby.get("destination_entry_id")))
	return bool(plan.get("ok", false)) and _enter_location(str(plan["address"]),
		str(nearby.get("destination_entry_id")))


func redirect_nearby_door(address: String) -> bool:
	var nearby: Node = _nearest_door(100.0)
	if nearby == null:
		return false
	if not projection.carried:
		return false
	return router.redirect_door(str(nearby.get("entity_id")), address, access.wand_mode)


func _process(_delta: float) -> void:
	_update_perception()


func _physics_process(_delta: float) -> void:
	if is_instance_valid(player) and player.velocity.length_squared() > 0.01:
		observer.facing = player.velocity.normalized()
	observer.luna_eyes_open = luna_eyes_open
	for law in get_tree().get_nodes_in_group("runtime2d_observation_law"):
		if law.has_method("apply_observation"):
			law.apply_observation(observation_at(law.global_position, bool(law.get("invisible_to_luna"))))
	event_bus.drain(self)

func _update_perception(force: bool = false) -> void:
	if not is_instance_valid(player):
		return
	var underside: bool = projection.is_underside_at(player.global_position, current_location_id)
	if underside != _was_underside or force:
		_was_underside = underside
		if is_instance_valid(_live_level):
			_live_level.set_underside(underside)
		perception_changed.emit(underside)


func observation_at(point: Vector2, invisible_to_luna: bool = false) -> Dictionary:
	# Camera footprint and Luna's eyes are independent. This is intentionally
	# NOT a substitute for future wall occlusion or entity-specific perception.
	observer.luna_eyes_open = luna_eyes_open
	return observer.evaluate(player, camera, point, invisible_to_luna)


func make_snapshot() -> Dictionary:
	var entries: Array[Dictionary] = []
	for entity_id in world_registry.list_ids():
		var actor = world_registry.get_entity(entity_id)
		if actor != null and actor.has_method("snapshot"):
			entries.append(actor.snapshot())
	return {
		"format": 2, "location": current_location_id,
		"entities": entries, "routes": router.snapshot_routes(),
		"access": access.snapshot(), "projection": projection.snapshot(),
		"camera_mode": camera.mode,
		"camera_position": [camera.global_position.x, camera.global_position.y],
		"eyes_open": luna_eyes_open
	}


func apply_snapshot(data: Dictionary) -> bool:
	# Validate the entire portable state before replacing live scene objects.
	if int(data.get("format", -1)) != 2:
		return false
	var incoming: Variant = data.get("entities", [])
	var routes: Variant = data.get("routes", {})
	var a: Variant = data.get("access", {})
	var p: Variant = data.get("projection", {})
	var camera_xy: Variant = data.get("camera_position", [])
	var mode := str(data.get("camera_mode", ""))
	if not (incoming is Array) or incoming.is_empty() or incoming.size() > MAX_ACTORS:
		return false
	if not router.validate_routes(routes) or not (a is Dictionary) or not (p is Dictionary):
		return false
	if not (camera_xy is Array) or camera_xy.size() != 2 or (mode != "FOLLOW" and mode != "LOCKED"):
		return false
	var new_access = AccessState.new()
	var new_projection = WandProjectionField.new()
	if not new_access.restore(a) or not new_projection.restore(p):
		return false
	var destination := str(data.get("location", ""))
	if not bool(router.resolve_address(destination, new_access.avatar_access_level).get("ok", false)):
		return false
	var built: Array = []
	var used := {}
	var new_player = null
	for item in incoming:
		if not (item is Dictionary):
			_free_unparented(built)
			return false
		var actor = Actor.new()
		if not actor.load_snapshot(item, parameter_registry) or used.has(actor.record.id):
			actor.free()
			_free_unparented(built)
			return false
		used[actor.record.id] = true
		if actor.player_controlled:
			if new_player != null:
				actor.free()
				_free_unparented(built)
				return false
			new_player = actor
		built.append(actor)
	if new_player == null or new_player.record.id != "luna":
		_free_unparented(built)
		return false
	if not _enter_location(destination, "entry", false, new_access.avatar_access_level):
		_free_unparented(built)
		return false
	for id in world_registry.list_ids():
		world_registry.unregister_entity(id)
	for old in _actor_slot.get_children():
		_actor_slot.remove_child(old)
		old.queue_free()
	for actor in built:
		_attach_actor_services(actor)
		_actor_slot.add_child(actor)
		_apply_trusted_visual(actor)
		world_registry.register_entity(actor.record.id, actor, str(actor.record.category).to_upper())
	player = new_player
	camera.target = player
	command_processor.clear_history()
	event_bus.clear_pending()
	_update_actor_activation()
	router.restore_routes(routes)
	access = new_access
	projection = new_projection
	camera.global_position = Vector2(float(camera_xy[0]), float(camera_xy[1]))
	camera.set_mode(mode)
	luna_eyes_open = bool(data.get("eyes_open", true))
	_update_perception(true)
	return true


func _free_unparented(values: Array) -> void:
	for actor in values:
		if is_instance_valid(actor):
			actor.free()


func save_to_disk() -> bool:
	return store.write_snapshot(make_snapshot())


func load_from_disk() -> bool:
	var value: Dictionary = store.read_snapshot()
	return not value.is_empty() and apply_snapshot(value)


func record_checkpoint() -> void:
	_checkpoints.append(make_snapshot().duplicate(true))
	if _checkpoints.size() > MAX_CHECKPOINTS:
		_checkpoints.pop_front()


func restore_checkpoint() -> bool:
	if _checkpoints.is_empty():
		return false
	return apply_snapshot(_checkpoints.back().duplicate(true))


func _unhandled_input(event: InputEvent) -> void:
	# These F-keys are diagnostic shortcuts, never the intended final UX.
	# E remains reserved for spells; TAB remains reserved for wand hacking.
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_F2:
			luna_eyes_open = not luna_eyes_open
		KEY_F3:
			enter_nearby_door()
		KEY_F4:
			if projection.carried:
				projection.drop_at(player.global_position, current_location_id)
			else:
				projection.pick_up_from(player.global_position, 36.0, current_location_id)
		KEY_F5:
			clone_actor("DEV_ENTITY_01")
		KEY_F6:
			save_to_disk()
		KEY_F8:
			if event.shift_pressed:
				restore_checkpoint()
			else:
				record_checkpoint()
		KEY_F9:
			load_from_disk()
		KEY_F10:
			camera.toggle_mode()
		_:
			return
	get_viewport().set_input_as_handled()
