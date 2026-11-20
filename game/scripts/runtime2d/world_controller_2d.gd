extends Node2D
## Minimal, authored-content-free 2D runtime. Gameplay visuals use their
## own VisualAnchor; screen-space UI is supplied separately after asset delivery.
## Existing 3D tests stay intact for now.

signal location_entered(address: String)
signal perception_changed(is_underside: bool)
signal gameplay_event(event_data: Dictionary)
signal entity_state_changed(change: Dictionary)
signal integrity_notice(reason: String)
signal recovery_available(reason: String)

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
const WorldTimeline2D = preload("res://scripts/runtime2d/world_timeline_2d.gd")
const WandEditPolicy2D = preload("res://scripts/runtime2d/wand_edit_policy_2d.gd")
const EntityBlueprint2D = preload("res://scripts/runtime2d/entity_blueprint_2d.gd")
const WorldRuleEngine2D = preload("res://scripts/runtime2d/world_rule_engine_2d.gd")
const WorldClock2D = preload("res://scripts/runtime2d/world_clock_2d.gd")
const GameRecovery2D = preload("res://scripts/runtime2d/game_recovery_2d.gd")
const PhysicalMotionBatch2D = preload("res://scripts/runtime2d/physical_motion_batch_2d.gd")
const SpellProgram2D = preload("res://scripts/runtime2d/spell_program_2d.gd")

const DEV_CATALOG := "res://data/runtime2d/DEV_LOCATIONS.json"
const DEV_GEOMETRY := "res://data/runtime2d/DEV_SANDBOX_GEOMETRY.json"
const MAX_ACTORS := 48
const MAX_CHECKPOINTS := 8

@export_file("*.json") var catalog_path := DEV_CATALOG
@export var starting_location := "DEV_SANDBOX_A"

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
var timeline
var wand_edit_policy
var spell_program
var world_rules
var world_clock
var recovery_guard
var _timeline_rollback := false
var _trusted_visuals: Dictionary = {}

var _level_slot: Node2D
var _actor_slot: Node2D
var _live_level
var _door
var _serial := 0
var _was_underside := false
var _nav_dynamic_rejected := false
var last_push_error := ""
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
	parameter_registry.register_parameter({
		"id": "rideable", "label": "RIDEABLE", "kind": "bool",
		"default": false, "hint": "Можно ли физически сесть на эту сущность."
	})
	parameter_registry.register_parameter({
		"id": "pushable", "label": "PUSHABLE", "kind": "bool",
		"default": false, "hint": "Можно ли физически двигать объект толчком."
	})
	for spec in additional_parameters():
		parameter_registry.register_parameter(spec)
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
	timeline = WorldTimeline2D.new()
	wand_edit_policy = WandEditPolicy2D.new()
	spell_program = SpellProgram2D.new()
	world_rules = WorldRuleEngine2D.new()
	world_rules.rule_rejected.connect(_on_rule_rejected)
	world_clock = WorldClock2D.new()
	world_clock.minute_changed.connect(_update_world_light)
	recovery_guard = GameRecovery2D.new()
	integrity_notice.connect(_on_gameplay_integrity)
	recovery_guard.recovery_requested.connect(_on_recovery_requested)

	# Only development fixtures, NOT real Ethernia locations or canon geography.
	if not router.load_catalog_json(catalog_path):
		push_error(router.last_error)
		return

	player = spawn_actor("luna", "luna", "Луна", Vector2(-160, 0), true)
	camera.target = player
	camera.make_current()
	_enter_location(starting_location)
	timeline.reset(make_snapshot())
	mark_safe_state()


func _attach_actor_services(actor: Node) -> void:
	actor.world_registry = world_registry
	actor.time_clock = world_clock
	actor.passive_ability_applied.connect(_on_passive_ability_applied)


func _on_passive_ability_applied(event_data: Dictionary) -> void:
	queue_world_event(event_data)


func spawn_actor(entity_id: String, category: String, label: String,
		at: Vector2, is_player: bool = false):
	if world_registry.count_live() >= actor_capacity():
		integrity_notice.emit("ENTITY_BUDGET_REACHED")
		return null
	if world_registry.get_entity(entity_id) != null or world_registry.was_deleted(entity_id):
		return null
	var actor = Actor.new()
	if not actor.configure(entity_id, category, label, parameter_registry, is_player):
		actor.free()
		return null
	actor.position = at
	actor.location_id = current_location_id if not current_location_id.is_empty() else starting_location
	if not register_spawned_actor(actor):
		actor.free()
		return null
	return actor


func register_spawned_actor(actor: CharacterBody2D) -> bool:
	if not world_registry.register_entity(actor.record.id, actor, str(actor.record.category).to_upper()):
		return false
	_attach_actor_services(actor)
	_actor_slot.add_child(actor)
	_apply_trusted_visual(actor)
	if is_instance_valid(_live_level):
		_update_actor_activation()
	return true


func clone_actor(entity_id: String):
	if world_registry.count_live() >= actor_capacity():
		integrity_notice.emit("CLONE_BUDGET_REACHED")
		return null
	var original = world_registry.get_entity(entity_id)
	if original == null or not original.has_method("clone_as"):
		return null
	_serial += 1
	while world_registry.get_entity("COPY_%d" % _serial) != null \
			or world_registry.was_deleted("COPY_%d" % _serial):
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


## Trusted lifecycle command. Gameplay/UI delete actions will add permission
## checks later; it never removes the player or silently resets entity identity.
func retire_actor(entity_id: String) -> bool:
	if entity_id == "luna":
		return false
	var actor: Node = world_registry.get_entity(entity_id)
	if actor == null or not (actor is CharacterBody2D):
		return false
	if not str(actor.carried_by_id()).is_empty():
		return false # First drop an object before permanently retiring it.
	for other_id in world_registry.list_ids():
		var other = world_registry.get_entity(other_id)
		if other != null and str(other.riding_id) == entity_id:
			return false # Do not leave a passenger attached to a deleted carrier.
		if other != null and other.has_method("carried_by_id") \
				and str(other.carried_by_id()) == entity_id:
			return false # Same guard for physically held items.
	if not world_registry.retire_entity(entity_id):
		return false
	_actor_slot.remove_child(actor)
	actor.queue_free()
	command_processor.clear_history()
	queue_world_event({"type": "ENTITY_RETIRED", "entity_id": entity_id})
	return true


## Physical carry uses the existing validated PICKUP component.
## No UI slots, inventories or species-specific object exceptions live here.
func _has_carried_entity(holder_id: String) -> bool:
	for id in world_registry.list_ids():
		var entity = world_registry.get_entity(id)
		if entity != null and entity.has_method("carried_by_id") \
				and str(entity.carried_by_id()) == holder_id:
			return true
	return false


## Real collision-driven pushing, independent of sprite art and camera.
## The caller may choose a bounded motion, but collision determines how far
## the object actually travels. Any displacement is part of world snapshots.
func push_entity(source_id: String, target_id: String, direction: Vector2,
		distance_px: float = 28.0) -> bool:
	return push_chain(source_id, [target_id], direction, distance_px)


## All targets share one physical movement and ONE Undo record. The caller
## supplies explicit identities, never an unrestricted nearby wildcard.
## The farthest object moves first, preserving the physical gap as nearer
## objects advance. The solver stops every body at real walls/actors.
func push_chain(source_id: String, target_ids: Array, direction: Vector2,
		distance_px: float = 28.0) -> bool:
	last_push_error = ""
	if target_ids.is_empty() or target_ids.size() > 4 \
			or not is_finite(distance_px) or distance_px < 1.0 or distance_px > 64.0 \
			or not is_finite(direction.x) or not is_finite(direction.y) \
			or direction.length_squared() < 0.01:
		last_push_error = "INVALID_REQUEST"
		return false
	var source: CharacterBody2D = world_registry.get_entity(source_id) as CharacterBody2D
	if source == null or str(source.location_id) != current_location_id \
			or source.collision_layer & 2 == 0 \
			or not str(source.riding_id).is_empty() \
			or not str(source.carried_by_id()).is_empty():
		last_push_error = "INVALID_SOURCE"
		return false
	var heading: Vector2 = direction.normalized()
	var sorted_targets: Array[Dictionary] = []
	var found := {}
	for identity in target_ids:
		if typeof(identity) != TYPE_STRING or identity == "luna" \
				or str(identity) == source_id or found.has(str(identity)):
			last_push_error = "INVALID_TARGET_ID"
			return false
		var target: CharacterBody2D = world_registry.get_entity(str(identity)) as CharacterBody2D
		if target == null or str(target.location_id) != current_location_id \
				or target.collision_layer & 2 == 0 \
				or not bool(target.get_parameter("pushable")) \
				or not str(target.riding_id).is_empty() \
				or not str(target.carried_by_id()).is_empty() \
				or _has_carried_entity(str(identity)):
			last_push_error = "INVALID_TARGET_STATE"
			return false
		for peer_id in world_registry.list_ids():
			var peer = world_registry.get_entity(peer_id)
			if peer != null and str(peer.riding_id) == str(identity):
				last_push_error = "TARGET_HAS_PASSENGER"
				return false
		var difference: Vector2 = target.global_position - source.global_position
		var ahead: float = difference.dot(heading)
		var lateral: float = absf(difference.cross(heading))
		if ahead <= 20.0 or lateral > 24.0:
			last_push_error = "OUTSIDE_PUSH_LANE"
			return false
		found[str(identity)] = true
		sorted_targets.append({
			"target": target, "entity_id": str(identity), "ahead": ahead
		})
	# Deterministic ordering prevents caller-supplied IDs from changing the
	# result and ensures stable reproducibility for saves and tests.
	sorted_targets.sort_custom(func(a: Dictionary, b: Dictionary):
		return float(a["ahead"]) > float(b["ahead"])
	)
	var nearest: float = float(sorted_targets.back()["ahead"])
	if nearest > 70.0:
		last_push_error = "BEYOND_REACH"
		return false
	for i in range(sorted_targets.size() - 1):
		var front: CharacterBody2D = sorted_targets[i]["target"]
		var rear: CharacterBody2D = sorted_targets[i + 1]["target"]
		var gap: float = float(sorted_targets[i]["ahead"]) - float(sorted_targets[i + 1]["ahead"])
		var minimum: float = 11.0 * (float(front.get_parameter("size")) \
			+ float(rear.get_parameter("size"))) + 0.5
		if gap < minimum or gap > 54.0:
			last_push_error = "CHAIN_GAP_INVALID"
			return false
	var bodies: Array[CharacterBody2D] = []
	for item in sorted_targets:
		bodies.append(item["target"])
	# Sweep the whole set against actual Godot physics BEFORE moving any
	# member. This avoids false collisions against a front body whose
	# transform is not yet synchronized into the physics server.
	var common_travel: Vector2 = PhysicalMotionBatch2D.safe_common_motion(
		bodies, heading * distance_px)
	if common_travel.length() < 0.5:
		last_push_error = "PHYSICAL_COLLISION_BLOCKED"
		return false
	var motions: Array[Dictionary] = []
	for item in sorted_targets:
		var target: CharacterBody2D = item["target"]
		var before: Vector2 = target.global_position
		var after: Vector2 = before + common_travel
		target.global_position = after
		motions.append({
			"target": target, "entity_id": str(item["entity_id"]),
			"before": before, "after": after
		})
	if not command_processor.record_physical_moves(motions, source_id, "world:push"):
		_rollback_unrecorded_push(motions)
		last_push_error = "HISTORY_REJECTED"
		return false
	for item in motions:
		queue_world_event({
			"type": "ENTITY_PUSHED", "entity_id": str(item["entity_id"]),
			"source_id": source_id,
			"distance": (item["after"] as Vector2).distance_to(item["before"]),
			"location_id": current_location_id
		})
	return true


func _rollback_unrecorded_push(motions: Array[Dictionary]) -> void:
	for i in range(motions.size() - 1, -1, -1):
		var motion: Dictionary = motions[i]
		var target: CharacterBody2D = motion["target"]
		if is_instance_valid(target):
			target.global_position = motion["before"]


func pick_up_entity(holder_id: String, target_id: String) -> bool:
	if holder_id == target_id or target_id == "luna":
		return false
	var holder: CharacterBody2D = world_registry.get_entity(holder_id) as CharacterBody2D
	var target: CharacterBody2D = world_registry.get_entity(target_id) as CharacterBody2D
	if holder == null or target == null:
		return false
	if holder.location_id != current_location_id or target.location_id != current_location_id:
		return false
	if not holder.riding_id.is_empty() or not target.riding_id.is_empty() \
			or not holder.carried_by_id().is_empty() or _has_carried_entity(holder_id):
		return false
	if not target.record.has_component("PICKUP"):
		return false
	var state: Dictionary = target.record.get_component("PICKUP")
	if not bool(state.get("enabled", false)) or not str(state.get("holder_id", "")).is_empty():
		return false
	if holder.global_position.distance_squared_to(target.global_position) > 64.0 * 64.0:
		return false
	for other_id in world_registry.list_ids():
		var other = world_registry.get_entity(other_id)
		if other != null and str(other.riding_id) in [target_id, holder_id]:
			return false # Do not pocket or pick up a moving passenger carrier.
	state["holder_id"] = holder_id
	# The original ground position is recoverable by Undo.
	state["world_position"] = [target.global_position.x, target.global_position.y, 0.0]
	var changed: bool = command_processor.execute_component(
		target, "SET_COMPONENT", "PICKUP", state, holder_id, "world:pickup")
	if changed:
		queue_world_event({"type": "ENTITY_PICKED_UP", "entity_id": target_id,
			"holder_id": holder_id, "location_id": current_location_id})
	return changed


func drop_held_entity(holder_id: String, target_id: String) -> bool:
	var holder: CharacterBody2D = world_registry.get_entity(holder_id) as CharacterBody2D
	var target: CharacterBody2D = world_registry.get_entity(target_id) as CharacterBody2D
	if holder == null or target == null or str(target.carried_by_id()) != holder_id:
		return false
	if holder.location_id != current_location_id or target.location_id != current_location_id:
		return false
	for radius in [36.0, 48.0, 60.0]:
		for direction in [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT,
				Vector2.UP, Vector2(1, 1).normalized(), Vector2(-1, 1).normalized(),
				Vector2(-1, -1).normalized(), Vector2(1, -1).normalized()]:
			var landing: Vector2 = holder.global_position + direction * radius
			if not _valid_dismount_space(target, holder, landing):
				continue
			var state: Dictionary = target.record.get_component("PICKUP")
			state["holder_id"] = ""
			state["world_position"] = [landing.x, landing.y, 0.0]
			var changed: bool = command_processor.execute_component(
				target, "SET_COMPONENT", "PICKUP", state, holder_id, "world:drop")
			if changed:
				queue_world_event({"type": "ENTITY_DROPPED", "entity_id": target_id,
					"holder_id": holder_id, "location_id": current_location_id})
			return changed
	return false


## A future transport/creature's RIDEABLE parameter controls physical
## boarding. No special case for airships, animals or puzzle-specific mounts.
func mount_actor(rider_id: String, carrier_id: String,
		offset: Vector2 = Vector2(0, -18)) -> bool:
	if rider_id == carrier_id or not is_finite(offset.x) or not is_finite(offset.y) or offset.length() > 70.0:
		return false
	var rider: CharacterBody2D = world_registry.get_entity(rider_id) as CharacterBody2D
	var carrier: CharacterBody2D = world_registry.get_entity(carrier_id) as CharacterBody2D
	if rider == null or carrier == null:
		return false
	if str(rider.location_id) != current_location_id or str(carrier.location_id) != current_location_id:
		return false
	if not str(rider.riding_id).is_empty() or not str(carrier.riding_id).is_empty() \
			or not str(rider.carried_by_id()).is_empty() \
			or not str(carrier.carried_by_id()).is_empty() \
			or _has_carried_entity(rider_id) or _has_carried_entity(carrier_id):
		return false # No nested carried/riding chains.
	if not bool(carrier.get_parameter("rideable")):
		return false
	if rider.global_position.distance_squared_to(carrier.global_position) > 52.0 * 52.0:
		return false
	var aboard := 0
	for other_id in world_registry.list_ids():
		var other = world_registry.get_entity(other_id)
		if other != null and str(other.riding_id) == carrier_id:
			aboard += 1
	if aboard >= 4:
		return false
	rider.riding_id = carrier_id
	rider.seat_offset = offset
	rider.global_position = carrier.global_position + offset
	rider.velocity = Vector2.ZERO
	rider.refresh_capabilities()
	queue_world_event({"type": "ENTITY_MOUNTED", "entity_id": rider_id,
		"carrier_id": carrier_id, "location_id": current_location_id})
	return true


func dismount_actor(rider_id: String) -> bool:
	var rider: CharacterBody2D = world_registry.get_entity(rider_id) as CharacterBody2D
	if rider == null or str(rider.riding_id).is_empty():
		return false
	var carrier: CharacterBody2D = world_registry.get_entity(str(rider.riding_id)) as CharacterBody2D
	if carrier == null or str(rider.location_id) != current_location_id:
		return false
	# Prefer actual free physical ground near the carrier. Never warp a
	# passenger through a wall or abandon it within a swim/climb-only region.
	for radius in [36.0, 48.0, 60.0]:
		for direction in [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT,
				Vector2.UP, Vector2(1, 1).normalized(), Vector2(-1, 1).normalized(),
				Vector2(-1, -1).normalized(), Vector2(1, -1).normalized()]:
			var landing: Vector2 = carrier.global_position + direction * radius
			if not _valid_dismount_space(rider, carrier, landing):
				continue
			var old_carrier: String = str(rider.riding_id)
			rider.riding_id = ""
			rider.global_position = landing
			rider.refresh_capabilities()
			queue_world_event({"type": "ENTITY_DISMOUNTED", "entity_id": rider_id,
				"carrier_id": old_carrier, "location_id": current_location_id})
			return true
	return false


func _valid_dismount_space(rider: CharacterBody2D, carrier: CharacterBody2D,
		landing: Vector2) -> bool:
	if not _live_level.geometry.navigation.is_walkable(landing,
			rider.has_ability("FLY"), rider.has_ability("SWIM"), rider.has_ability("CLIMB")):
		return false
	var state := rider.get_world_2d().direct_space_state
	var shape := CircleShape2D.new()
	shape.radius = 11.0 * float(rider.get_parameter("size"))
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, landing)
	query.collision_mask = 1 | 2 | 4 | 8 | 16
	query.exclude = [rider.get_rid(), carrier.get_rid()]
	if not state.intersect_shape(query, 8).is_empty():
		return false
	# A free endpoint across a wall is not a safe dismount path.
	var ray := PhysicsRayQueryParameters2D.create(carrier.global_position, landing,
		1 | 4 | 8 | 16)
	ray.exclude = [rider.get_rid(), carrier.get_rid()]
	return state.intersect_ray(ray).is_empty()


func set_entity_parameter(entity_id: String, key: String, value: Variant) -> bool:
	var actor: Node = world_registry.get_entity(entity_id)
	return actor != null and command_processor.execute_set(actor, key, value, "luna", "wand:luna")


func set_world_time_mode(mode: String) -> bool:
	if not world_clock.set_mode(mode):
		return false
	queue_world_event({"type": "WORLD_TIME_MODE_CHANGED", "mode": world_clock.mode})
	return true


func request_wand_parameter_edit(target_id: String, parameter_id: String,
		requested_value: Variant) -> bool:
	# Public integration entry for the future TAB editor. The trusted
	# set_entity_parameter() remains available for level authoring/tests.
	var actor: Node2D = world_registry.get_entity(target_id) as Node2D
	if actor == null or not wand_edit_policy.authorize(player, actor, current_location_id,
			projection, access, parameter_registry, parameter_id):
		return false
	return command_processor.execute_set(actor, parameter_id, requested_value, "luna", "wand:luna")


## Future E-spell integration: the UI may select a typed command bundle.
## Target selection/projectile hit-testing happens elsewhere; this entry
## checks the same permissions as the TAB wand before any parameter changes.
func request_wand_spell_program(target_id: String, program: Variant) -> bool:
	return spell_program.apply_to(self, target_id, program)


func set_entity_ability(entity_id: String, ability_id: String, enabled: bool) -> bool:
	# Other approved abilities await their real behavior adapters; no fake grant.
	if ability_id not in EntityBlueprint2D.ABILITIES:
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
		child.world_active = active
		child.visible = active
		child.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
		child.navigation = _live_level.geometry.navigation if active else null
		child.refresh_capabilities()


func _sync_pickup_transition(actor: Node2D, change: Dictionary) -> void:
	var before: Variant = change.get("before", {})
	var after: Variant = change.get("after", {})
	if not (before is Dictionary) or not (after is Dictionary):
		return
	var prior: Variant = before.get("PICKUP", {})
	var current: Variant = after.get("PICKUP", {})
	if not (prior is Dictionary) or not (current is Dictionary):
		return
	if str(prior.get("holder_id", "")).is_empty() \
			or not str(current.get("holder_id", "")).is_empty():
		return
	# Releasing an item uses the recorded ground position; Undo of pickup
	# restores the original pre-pickup coordinates from the held component.
	var record: Dictionary = prior if str(change.get("action", "")) == "UNDO_COMPONENT" else current
	var position_value: Variant = record.get("world_position", null)
	if not (position_value is Array) or position_value.size() != 3:
		return
	actor.global_position = Vector2(float(position_value[0]), float(position_value[1]))


func _on_entity_component_changed(change: Dictionary) -> void:
	var actor = world_registry.get_entity(str(change.get("entity_id", "")))
	if actor != null:
		_sync_pickup_transition(actor, change)
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
	world_rules.process_event(event_data, self)
	gameplay_event.emit(event_data)


func _on_event_overflow(reason: String) -> void:
	integrity_notice.emit(reason)


func _on_rule_rejected(rule_id: String, reason: String) -> void:
	integrity_notice.emit("WORLD_RULE:%s:%s" % [rule_id, reason])


func _on_gameplay_integrity(reason: String) -> void:
	recovery_guard.report(reason)


func _on_recovery_requested(reason: String) -> void:
	recovery_available.emit(reason)


func _on_zone_entered(zone_id: String, entity_id: String) -> void:
	queue_world_event({"type": "ZONE_ENTERED", "zone_id": zone_id,
		"entity_id": entity_id, "location_id": current_location_id})


func _on_zone_exited(zone_id: String, entity_id: String) -> void:
	queue_world_event({"type": "ZONE_EXITED", "zone_id": zone_id,
		"entity_id": entity_id, "location_id": current_location_id})


func _prepare_authored_entities(address: String) -> Variant:
	# Assemble and validate every new author-provided Entity before replacing
	# the current level. Revisited worlds retain their modified live records.
	var planned: Array = []
	var definitions: Array = router.locations.get(address, {}).get("entities", [])
	for definition in definitions:
		var identity: String = str(definition.get("id", ""))
		var existing = world_registry.get_entity(identity)
		if existing != null:
			if str(existing.location_id) != address:
				_free_unparented(planned)
				return null
			continue
		if world_registry.was_deleted(identity):
			continue
		if world_registry.count_live() + planned.size() >= actor_capacity():
			_free_unparented(planned)
			integrity_notice.emit("ENTITY_BUDGET_REACHED")
			return null
		var actor = EntityBlueprint2D.create_actor(definition, address, parameter_registry)
		if actor == null:
			_free_unparented(planned)
			integrity_notice.emit("AUTHORED_ENTITY_REJECTED")
			return null
		planned.append(actor)
	return planned


func _enter_location(address: String, entry_id: String = "entry", place_player: bool = true,
		authority_override: int = -1) -> bool:
	if place_player and is_instance_valid(player) \
			and (not str(player.riding_id).is_empty() or _has_carried_entity("luna")):
		return false
	var authority: int = access.avatar_access_level if authority_override < 0 else authority_override
	var plan: Dictionary = router.resolve_address(address, authority, entry_id)
	if not bool(plan.get("ok", false)):
		return false
	var level_scene: PackedScene = load(str(plan["scene"])) as PackedScene
	if level_scene == null:
		return false
	var next_level: Node = level_scene.instantiate()
	if not (next_level is Node2D) or not next_level.has_method("set_underside") \
			or not next_level.has_method("preflight_geometry"):
		next_level.free()
		return false
	# Set any fixture geometry *before* verifying the next level; never
	# destroy the currently playable room for a missing/corrupt map file.
	if address.begins_with("DEV_SANDBOX_"):
		next_level.set("geometry_json_path", DEV_GEOMETRY)
	if not next_level.preflight_geometry():
		next_level.free()
		return false
	var staged: Variant = _prepare_authored_entities(address)
	if staged == null:
		next_level.free()
		return false
	if not world_rules.configure_location(address, router.locations[address].get("rules", [])):
		_free_unparented(staged)
		next_level.free()
		return false
	if is_instance_valid(_live_level):
		_level_slot.remove_child(_live_level)
		_live_level.queue_free()
	_level_slot.add_child(next_level)
	_live_level = next_level
	if _live_level.has_signal("zone_entered"):
		_live_level.zone_entered.connect(_on_zone_entered)
		_live_level.zone_exited.connect(_on_zone_exited)
	current_location_id = address
	for actor in staged:
		_attach_actor_services(actor)
		_actor_slot.add_child(actor)
		_apply_trusted_visual(actor)
		world_registry.register_entity(str(actor.record.id), actor, str(actor.record.category).to_upper())
	if is_instance_valid(player):
		player.location_id = address
		if place_player:
			player.global_position = plan["position"]
	_mount_dev_door()
	_update_actor_activation()
	_update_perception(true)
	_update_world_light()
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


func _nearest_door(max_reach: float = 100.0, require_open: bool = false) -> Node:
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
		if require_open and candidate.has_method("is_open_at") and not candidate.is_open_at(world_clock):
			continue
		var d: float = player.global_position.distance_squared_to(candidate.global_position)
		if d > distance_sq or not candidate.can_interact_from(player.global_position):
			continue
		distance_sq = d
		nearest = candidate
	return nearest


func enter_nearby_door() -> bool:
	if not is_instance_valid(player) or not str(player.riding_id).is_empty() \
			or _has_carried_entity("luna"):
		return false
	var nearby: Node = _nearest_door(100.0, true)
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


func _update_world_light(_minute: int = 0) -> void:
	if is_instance_valid(_live_level) and _live_level.has_method("light_tint_at"):
		$World.modulate = _live_level.light_tint_at(world_clock)
	else:
		$World.modulate = Color.WHITE


func _physics_process(delta: float) -> void:
	world_clock.advance(delta)
	if is_instance_valid(player) and player.velocity.length_squared() > 0.01:
		observer.facing = player.velocity.normalized()
	observer.luna_eyes_open = luna_eyes_open
	var physical_observation_walls := {}
	if is_instance_valid(_live_level):
		for law in get_tree().get_nodes_in_group("runtime2d_observation_law"):
			if not _live_level.is_ancestor_of(law) or not law.has_method("apply_observation"):
				continue
			law.apply_observation(observation_at(law.global_position, bool(law.get("invisible_to_luna"))))
			# An invisible, gaze-dependent body must still obstruct NPC paths
			# whenever its real collision shape is currently solid.
			var raw_size: Variant = law.get("physical_size")
			if not bool(law.get("is_solid")) or not (raw_size is Vector2):
				continue
			var half_size: Vector2 = raw_size * 0.5
			var p1: Vector2 = law.to_global(Vector2(-half_size.x, -half_size.y))
			var p2: Vector2 = law.to_global(Vector2(half_size.x, -half_size.y))
			var p3: Vector2 = law.to_global(Vector2(half_size.x, half_size.y))
			var p4: Vector2 = law.to_global(Vector2(-half_size.x, half_size.y))
			var lower := Vector2(
				minf(minf(p1.x, p2.x), minf(p3.x, p4.x)),
				minf(minf(p1.y, p2.y), minf(p3.y, p4.y)))
			var upper := Vector2(
				maxf(maxf(p1.x, p2.x), maxf(p3.x, p4.x)),
				maxf(maxf(p1.y, p2.y), maxf(p3.y, p4.y)))
			physical_observation_walls[str(law.get_instance_id())] = Rect2(lower, upper - lower)
		if not _live_level.geometry.navigation.set_dynamic_walls(physical_observation_walls):
			if not _nav_dynamic_rejected:
				_nav_dynamic_rejected = true
				integrity_notice.emit("DYNAMIC_NAVIGATION_LIMIT")
		else:
			_nav_dynamic_rejected = false
	event_bus.drain(self)
	if timeline.tick(delta):
		timeline.record(make_snapshot())

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
		"deleted_ids": world_registry.deleted_ids(),
		"rule_flags": world_rules.snapshot_flags(),
		"access": access.snapshot(), "projection": projection.snapshot(),
		"camera_mode": camera.mode,
		"camera_position": [camera.global_position.x, camera.global_position.y],
		"eyes_open": luna_eyes_open,
		"time_clock": world_clock.snapshot()
	}


func apply_snapshot(data: Dictionary) -> bool:
	# Validate the entire portable state before replacing live scene objects.
	if typeof(data.get("format", null)) not in [TYPE_INT, TYPE_FLOAT] or float(data["format"]) != 2.0:
		return false
	if typeof(data.get("eyes_open", null)) != TYPE_BOOL:
		return false
	var incoming: Variant = data.get("entities", [])
	var deleted: Variant = data.get("deleted_ids", [])
	var flags: Variant = data.get("rule_flags", [])
	var routes: Variant = data.get("routes", {})
	var a: Variant = data.get("access", {})
	var p: Variant = data.get("projection", {})
	var camera_xy: Variant = data.get("camera_position", [])
	var mode := str(data.get("camera_mode", ""))
	if not (incoming is Array) or incoming.is_empty() or incoming.size() > actor_capacity():
		return false
	if not world_registry.validate_deleted_ids(deleted) or deleted.has("luna"):
		return false
	if not world_rules.validate_flags(flags):
		return false
	if not router.validate_routes(routes) or not (a is Dictionary) or not (p is Dictionary):
		return false
	if not (camera_xy is Array) or camera_xy.size() != 2 or (mode != "FOLLOW" and mode != "LOCKED"):
		return false
	for coordinate in camera_xy:
		if typeof(coordinate) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(coordinate)) or absf(float(coordinate)) > 100000.0:
			return false
	var new_access = AccessState.new()
	var new_projection = WandProjectionField.new()
	var new_clock = WorldClock2D.new()
	if not new_access.restore(a) or not new_projection.restore(p) or not new_clock.restore(data.get("time_clock", {"mode":"NORMAL"})):
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
		if not router.locations.has(actor.location_id):
			actor.free()
			_free_unparented(built)
			return false
		if deleted.has(actor.record.id):
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
	if new_player == null or new_player.record.id != "luna" or new_player.location_id != destination:
		_free_unparented(built)
		return false
	# Validate every transport link before replacing the live world. A corrupt
	# save cannot create cross-room riders, nested cycles or infinite stacks.
	var staged_by_id := {}
	for candidate in built:
		staged_by_id[str(candidate.record.id)] = candidate
	# A corrupt V2 save must not attach items to nonexistent holders, create
	# carried cycles, or transport items between overlapping room coordinates.
	var held_counts := {}
	for candidate in built:
		var picked_id: String = str(candidate.carried_by_id())
		if picked_id.is_empty():
			continue
		var holder = staged_by_id.get(picked_id, null)
		if holder == null or holder == candidate or not candidate.riding_id.is_empty() \
				or not holder.riding_id.is_empty() \
				or not holder.carried_by_id().is_empty() \
				or str(holder.location_id) != str(candidate.location_id) \
				or not bool(candidate.record.get_component("PICKUP").get("enabled", false)):
			_free_unparented(built)
			return false
		held_counts[picked_id] = int(held_counts.get(picked_id, 0)) + 1
		if int(held_counts[picked_id]) > 1:
			_free_unparented(built)
			return false
	var passengers := {}
	for candidate in built:
		if str(candidate.riding_id).is_empty():
			continue
		var carrier = staged_by_id.get(str(candidate.riding_id), null)
		if carrier == null or carrier == candidate or not str(carrier.riding_id).is_empty() \
				or str(carrier.location_id) != str(candidate.location_id) \
				or not bool(carrier.get_parameter("rideable")) \
				or held_counts.has(str(carrier.record.id)) \
				or held_counts.has(str(candidate.record.id)):
			_free_unparented(built)
			return false
		passengers[carrier.record.id] = int(passengers.get(carrier.record.id, 0)) + 1
		if int(passengers[carrier.record.id]) > 4:
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
	world_registry.restore_deleted_ids(deleted)
	world_rules.restore_flags(flags)
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
	world_clock.restore(new_clock.snapshot())
	_update_perception(true)
	if not _timeline_rollback:
		timeline.reset(make_snapshot())
	return true


func _free_unparented(values: Array) -> void:
	for actor in values:
		if is_instance_valid(actor):
			actor.free()


func rewind_world(seconds_back: float) -> bool:
	# Integration point for the approved Time Button, recovery scripting or
	# other safe in-world temporal mechanics. No artifact/UI is spawned here.
	var candidate: Dictionary = timeline.preview(seconds_back)
	if candidate.is_empty():
		return false
	_timeline_rollback = true
	var succeeded: bool = apply_snapshot(candidate["world"])
	_timeline_rollback = false
	if succeeded:
		timeline.commit_rewind(float(candidate["time"]))
	return succeeded


func mark_safe_state() -> bool:
	return recovery_guard.capture(make_snapshot())


func recover_last_safe_state() -> bool:
	var saved: Dictionary = recovery_guard.snapshot_for_recovery()
	if saved.is_empty():
		return false
	if not apply_snapshot(saved):
		return false
	recovery_guard.acknowledge()
	return true


func save_to_disk() -> bool:
	var result: bool = store.write_snapshot(make_snapshot())
	if result:
		mark_safe_state()
	return result


func load_from_disk() -> bool:
	var value: Dictionary = store.read_snapshot()
	return not value.is_empty() and apply_snapshot(value)


func record_checkpoint() -> void:
	_checkpoints.append(make_snapshot().duplicate(true))
	mark_safe_state()
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


func additional_parameters() -> Array:
	return []


func actor_capacity() -> int:
	return MAX_ACTORS
