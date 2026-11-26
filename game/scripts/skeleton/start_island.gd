extends "res://scripts/skeleton/entity_fixture.gd"
## Continuous P9-03 graybox. The island and meadows share the simulation and camera.

signal frost_cast(active_seconds: float)
signal fauna_respawned(identity: String)
signal help_completed(outcome: String, identity: String)
signal forest_bank_interacted
signal forest_bank_left

const ForestBank = preload("res://scripts/skeleton/forest_bank_2d.gd")
const FOREST_BANK_SCENE = preload("res://scenes/skeleton/forest_bank.tscn")
const AncientConsole = preload("res://scripts/skeleton/ancient_console_2d.gd")
const CONSOLE_FOX := {"category": "fox", "label": "Лисичка", "material": "FABRIC"}
const CONSOLE_SPAWN_OFFSETS := [Vector2(-48, 26), Vector2(48, 26), Vector2(-72, -5),
	Vector2(72, -5), Vector2(-48, -35), Vector2(48, -35), Vector2(0, 60)]
const FRIDGE_COURT := Rect2(1416, -22, 307, 205)
const FRIDGE_PATH := Rect2(1643, 130, 105, 125)
const COURT_FRIDGES := {
	"DEV_FRIDGE_A": Vector2(1463, 28), "DEV_FRIDGE_B": Vector2(1530, 28), "DEV_FRIDGE_C": Vector2(1597, 28),
	"DEV_FRIDGE_D": Vector2(1463, 106), "DEV_FRIDGE_E": Vector2(1530, 106), "DEV_FRIDGE_F": Vector2(1597, 106),
}
const SystemPause = preload("res://scripts/runtime2d/system_pause_2d.gd")
const Administrator = preload("res://scripts/skeleton/administrator_body_2d.gd")
const Fauna = preload("res://scripts/skeleton/fauna_body_2d.gd")
const AbilityBank = preload("res://scripts/core/ability_bank_service.gd")
const FOX_START := Vector2(1684, 414)
const ECOLOGY_CATALOG := "DEV_ECOLOGY_CATALOG"
const CATALOG_SPOT := Vector2(2413, 486)
const SWIM_MODULE := {"ability_id": "SWIM", "enabled": true, "protected": false}
const FISH_POINTS := {
	"DEV_POOL_FISH_A": Vector2(2532, 375),
	"DEV_POOL_FISH_B": Vector2(2559, 424),
	"DEV_POOL_FISH_C": Vector2(2576, 476),
}
const Lake = preload("res://scripts/skeleton/duplicate_lake_layout.gd")
const WandPair = preload("res://scripts/skeleton/wand_pair_2d.gd")
const WAND_HOLD_SECONDS := 3.0
const Meadows = preload("res://scripts/skeleton/meadows_layout.gd")
const WorldClock = preload("res://scripts/runtime2d/world_clock_2d.gd")
const ActiveDuration = preload("res://scripts/runtime2d/active_duration_2d.gd")
const ISLAND_ID := "ET_START_ISLAND"
const AREA_LABELS := {
	ISLAND_ID: "Стартовый остров", Meadows.LOCATION_ID: "Большие луга",
	Lake.LOCATION_ID: "Озеро Дубликатов", ForestBank.LOCATION_ID: "Лес",
	AncientConsole.LOCATION_ID: "Лесная поляна",
}
const FRIDGE_ID := "START_FRIDGE"
const BRIDGE_YETI_ID := "START_YETI"
const SPAWN := Vector2(320, 374)
const FRIDGE_SPOT := Vector2(320, 222)
const RIFT_SPOT := Vector2(320, 524)
const BRIDGE_SPOT := Vector2(740, 374)
const YETI_RETREAT := [Vector2(975, 374), Vector2(975, 482)]
const INTERACT_REACH := 64.0
const DONUT_REFILL_SECONDS := 8.0
const SAVE_PATH := "user://luna_start_island.json"
const CAMP_REACH := 40.0
const PHASE_LABELS := {
	WorldClock.Phase.MORNING: "Утро", WorldClock.Phase.DAY: "День",
	WorldClock.Phase.EVENING: "Вечер", WorldClock.Phase.NIGHT: "Ночь",
}
const PHASE_TINTS := {
	WorldClock.Phase.MORNING: Color("e8dcef"), WorldClock.Phase.DAY: Color.WHITE,
	WorldClock.Phase.EVENING: Color("e9b8a8"), WorldClock.Phase.NIGHT: Color("8194c6"),
}
const ISLAND_DECKS: Array[Dictionary] = [
	{"bounds": Rect2(95, 142, 565, 456), "height": 0.0},
	{"bounds": Rect2(623, 344, 261, 60), "height": 0.0},
	{"bounds": Rect2(850, 244, 350, 306), "height": 0.0},
]
const BRIDGE_RAILS: Array[Dictionary] = [
	{"bounds": Rect2(656, 326, 199, 18), "height": 92.0, "layer": 1},
	{"bounds": Rect2(656, 404, 199, 18), "height": 92.0, "layer": 1},
]

@export var ecology_fixture := false
@export var observation_fixture := false
@export var ancient_console_enabled := false
var forest_bank: ForestBank
var ancient_console: AncientConsole
var _was_at_bank := false
var _initial_observation_states: Array[Dictionary] = []
var ability_bank := AbilityBank.new(entities, commands)
var _initial_ecology_states: Array[Dictionary] = []
var _fish_surfaces: Array[Dictionary] = []
var wand_pair := WandPair.new()
var wand_mode_requested: Callable
var frost_cast_allowed: Callable
var restriction_text: Callable
var system_pause: SystemPause
var administrator: Administrator
var managed_save := false
var _wand_hold := 0.0
var has_donut := false
var donut_refill := 0.0
var retreat_step := -1
var world_clock := WorldClock.new()
var _ice_duration := ActiveDuration.new(Meadows.ICE_SECONDS)
var ice_remaining: float:
	get:
		return _ice_duration.remaining
var freeze_selected := false
var _initial_meadow_states: Array[Dictionary] = []
var _plank_surface := {}
var _store := SaveStore.new()

@onready var _camera: Camera2D = $Camera
@onready var _status: Label = $Interface/Status
@onready var _prompt: Label = $Interface/Prompt
@onready var _world_light: CanvasModulate = $WorldLight


func _location_id() -> String:
	return ISLAND_ID


func _entity_location(point: Vector2) -> String:
	if ancient_console_enabled and AncientConsole.CLEARING.has_point(point):
		return AncientConsole.LOCATION_ID
	if observation_fixture and ForestBank.FOREST.has_point(point):
		return ForestBank.LOCATION_ID
	if point.x >= Lake.BOUNDARY:
		return Lake.LOCATION_ID
	return Meadows.LOCATION_ID if point.x >= Meadows.WEST_BOUNDARY else ISLAND_ID


func _starts_alive(category: String) -> bool:
	return category in ["fox", "trollik", "fish"] or super._starts_alive(category)


func _editor_parent() -> Node:
	return $Interface


func _ready() -> void:
	wand_pair.original = projection
	world_clock.minute_changed.connect(_update_world_light)
	_ice_duration.active_changed.connect(_update_ice_support)
	_update_world_light()
	_decks.assign(ISLAND_DECKS)
	var ground := Meadows.DECKS + Lake.DECKS
	if observation_fixture:
		ground.append_array(ForestBank.DECKS + [FRIDGE_COURT, FRIDGE_PATH])
		_water_volumes.append(WaterVolume.new(ForestBank.RIVER, -110.0, 0.0, Vector2(12, 0), 1.3))
	if ancient_console_enabled:
		ground.append_array(AncientConsole.DECKS)
	for bounds in ground:
		_decks.append({"bounds": bounds, "height": 0.0})
	_surfaces.assign(_decks)
	_surfaces.append({"bounds": Lake.POOL, "height": Lake.BED_HEIGHT, "safe": false})
	_fish_surfaces.assign([{"bounds": Lake.POOL, "height": Lake.BED_HEIGHT}])
	_water_volumes.append(WaterVolume.new(Lake.POOL, Lake.BED_HEIGHT, 0.0, Vector2.ZERO, 1.2))
	_water_volumes.append(WaterVolume.new(Meadows.CREEK, Meadows.CREEK_BED, 0.0,
		Vector2(0, 18), 1.5))
	_walls.assign(BRIDGE_RAILS)
	if observation_fixture:
		_walls.append({"bounds": ForestBank.REST_SPOT, "height": 96.0, "layer": 2})
	if ancient_console_enabled:
		_walls.append({"bounds": AncientConsole.CONSOLE_BODY, "height": 92.0, "layer": 2})
	for wall in _walls:
		_build_wall(wall)
	commands.configure_world(entities)
	access.set_wand_mode(AccessState.ORDINARY)
	actor = spawn_entity(PLAYER_DEFINITION, SPAWN, 0.0)
	var fridge := spawn_entity({
		"id": FRIDGE_ID, "category": "fridge", "label": "Холодильник", "material": "METAL",
	}, FRIDGE_SPOT, 0.0)
	var yeti := spawn_entity({
		"id": BRIDGE_YETI_ID, "category": "yeti", "label": "Йетти", "material": "FABRIC",
	}, BRIDGE_SPOT, 0.0)
	if actor == null or fridge == null or yeti == null:
		set_physics_process(false)
		push_error("Could not place the start island entities")
		return
	yeti.set_parameter("size", 2.0)
	yeti.set_parameter("behavior_mode", "IDLE")
	_connect_bridge_body()
	_spawn_meadow_entities()
	if ecology_fixture:
		_spawn_ecology_fixture()
	if observation_fixture:
		_spawn_observation_fixture()
	if ancient_console_enabled:
		ancient_console = AncientConsole.new()
		add_child(ancient_console)
		ancient_console.attach_interface($Interface)
	_camera.position = actor.position


func _spawn_meadow_entities() -> void:
	var fox := spawn_entity({
		"id": Meadows.FOX_ID, "category": "fox", "label": "Лисичка", "material": "FABRIC",
	}, FOX_START, 0.0)
	var trollik := spawn_entity({
		"id": Meadows.TROLLIK_ID, "category": "trollik", "label": "Троллик", "material": "FABRIC",
	}, Vector2(1870, 325), 0.0)
	var plank := spawn_entity({
		"id": Meadows.PLANK_ID, "category": "prop", "label": "Упавшая ветвь", "material": "WOOD",
	}, Meadows.PLANK_START, 0.0)
	if fox == null or trollik == null or plank == null:
		push_error("Could not place the meadow entities")
		return
	fox.set_parameter("size", 0.7)
	fox.set_parameter("speed", 1.05)
	trollik.set_parameter("speed", 0.85)
	trollik.set_parameter("behavior_mode", "CHASE")
	trollik.set_parameter("target_group", "LUNA")
	trollik.set_parameter("sense_range", 1.7)
	plank.set_parameter("pickable", true)
	plank.set_parameter("mass", 0.8)
	plank.set_parameter("color", Color("efb68e"))
	_configure_plank_marker(plank)
	for entry in make_snapshot()["entities"]:
		if entry["id"] in [Meadows.FOX_ID, Meadows.TROLLIK_ID, Meadows.PLANK_ID]:
			_initial_meadow_states.append(entry)


func _spawn_observation_fixture() -> void:
	forest_bank = FOREST_BANK_SCENE.instantiate()
	add_child(forest_bank)
	for identity in COURT_FRIDGES:
		var fridge := spawn_entity({"id": identity, "category": "fridge", "label": "Холодильник",
			"material": "METAL"}, COURT_FRIDGES[identity], 0.0)
		if fridge != null:
			fridge.set_parameter("behavior_mode", "IDLE")
	for state in make_snapshot()["entities"]:
		if COURT_FRIDGES.has(state["id"]):
			_initial_observation_states.append(state)


func _at_forest_bank() -> bool:
	return forest_bank != null and ForestBank.MEANDER.has_point(actor.position) \
		and ForestBank.FOREST.has_point(actor.position)


func at_ancient_console() -> bool:
	return ancient_console != null and not is_instance_valid(_debug_editor) \
		and is_instance_valid(actor) and (actor as EntityBody).accepts_player_input() and actor.motion.grounded \
		and not actor.is_attached() and ancient_console.can_interact(actor.position, actor.motion.elevation)


func spawn_console_species(species_id: String) -> bool:
	if species_id != "FOX":
		return false
	var definition := CONSOLE_FOX.duplicate()
	for index in MAX_ENTITIES:
		var identity := "FOREST_CONSOLE_FOX_%02d" % index
		if entities.get_entity(identity) == null:
			definition["id"] = identity
			break
	for offset in CONSOLE_SPAWN_OFFSETS:
		var point: Vector2 = actor.position + offset
		if AncientConsole.CLEARING.grow(-ElevationBody.FOOT_RADIUS).has_point(point):
			var fox := spawn_entity(definition, point, 0.0)
			if fox != null:
				fox.set_parameter("behavior_mode", "IDLE")
				return true
	return false


func awake_fridges_nearby() -> int:
	var count := 0
	for identity in entities.query_ids({"category": "fridge", "alive": true}, MAX_ENTITIES):
		var fridge := entities.get_entity(identity) as EntityBody
		if fridge.visible and fridge.location_id == actor.location_id \
				and fridge.position.distance_squared_to(actor.position) <= 290.0 * 290.0:
			count += 1
	return count


func _spawn_ecology_fixture() -> void:
	for identity in FISH_POINTS:
		var fish := spawn_entity({"id": identity, "category": "fish", "label": "Рыба",
			"material": "FABRIC"}, FISH_POINTS[identity], Lake.BED_HEIGHT)
		if fish != null:
			fish.record.set_component("ABILITY_SET", {"instances": {_swim_id(identity): SWIM_MODULE}})
			fish.set_parameter("size", 0.56)
			fish.set_parameter("speed", 0.48)
	var tool := spawn_entity({"id": ECOLOGY_CATALOG, "category": "prop", "label": "Каталог · технический",
		"material": "METAL"}, CATALOG_SPOT, 0.0)
	if tool != null:
		tool.set_parameter("pickable", true)
	for entry in make_snapshot()["entities"]:
		if entry["id"] == ECOLOGY_CATALOG or FISH_POINTS.has(entry["id"]):
			_initial_ecology_states.append(entry)


func _create_entity_body(identity: String, category: String) -> EntityBody:
	if identity == Meadows.FOX_ID and category == "fox":
		var fox := Fauna.new()
		fox.birth_point = FOX_START
		fox.respawned.connect(fauna_respawned.emit)
		return fox
	if ecology_fixture and category == "fish" and FISH_POINTS.has(identity):
		var fish := Fauna.new()
		fish.birth_point = FISH_POINTS[identity]
		fish.birth_height = Lake.BED_HEIGHT
		fish.aquatic_bounds = Lake.POOL
		fish.respawned.connect(fauna_respawned.emit)
		return fish
	return super._create_entity_body(identity, category)


func get_natural_fauna(identity: String) -> Fauna:
	return entities.get_entity(identity) as Fauna


func _spawn_on_support(body: EntityBody, point: Vector2, height: float) -> bool:
	if body is Fauna and body.aquatic_bounds.has_area():
		return body.motion.start_on_safe_support(point, height, body.surfaces)
	return super._spawn_on_support(body, point, height)


func _holds_ecology_catalog() -> bool:
	var item := entities.get_entity(ECOLOGY_CATALOG) as EntityBody
	return item != null and item.is_carried_by(actor)


func request_wand_parameter_edit(target_id: String, parameter_id: String, value: Variant) -> bool:
	if parameter_id == "SWIM_ENABLED":
		return value is bool and _set_swim_enabled(target_id, value)
	return super.request_wand_parameter_edit(target_id, parameter_id, value)


func _set_swim_enabled(target_id: String, enabled: bool) -> bool:
	var target := get_natural_fauna(target_id)
	if not _holds_ecology_catalog() or not _in_fish_reach(target) \
			or not wand_policy.authorize(actor, target, _entity_location(actor.position), projection, access, parameters, "mass"):
		return false
	var before: Dictionary = target.record.get_components()
	var after := before.duplicate(true)
	var module: Dictionary = after.get("ABILITY_SET", {}).get("instances", {}).get(_swim_id(target_id), {})
	if module.is_empty():
		return false
	if module["enabled"] == enabled:
		return true
	module["enabled"] = enabled
	var steps: Array[Dictionary] = [{"kind": "components", "entity_id": target_id,
		"target": target, "before": before, "after": after}]
	return commands.execute_batch(steps, ENTITY_ID, "wand:ability_enabled")


func request_extract_swim(target_id: String) -> bool:
	var target := get_natural_fauna(target_id)
	if not _holds_ecology_catalog() or not _in_fish_reach(target) \
			or not wand_policy.authorize(actor, target, _entity_location(actor.position), projection, access, parameters, "mass"):
		return false
	return ability_bank.move_instance(ENTITY_ID, target_id, _swim_id(target_id), true)


func request_restore_swim(target_id: String) -> bool:
	var target := get_natural_fauna(target_id)
	return _holds_ecology_catalog() and _in_fish_reach(target) \
		and ability_bank.move_instance(ENTITY_ID, target_id, _swim_id(target_id), false)


func _restore_nearby_swim() -> bool:
	for identity in FISH_POINTS:
		if request_restore_swim(identity):
			return true
	return false


func _in_fish_reach(target: Fauna) -> bool:
	if target == null or not target.aquatic_bounds.has_area() or not target.get_parameter("alive") \
			or target.location_id != _entity_location(actor.position) or not (actor as EntityBody).accepts_player_input():
		return false
	var offset: Vector2 = actor.position - target.position
	var height_gap: float = actor.motion.elevation - target.motion.elevation
	return Vector3(offset.x, offset.y, height_gap).length_squared() <= WandPolicy.REACH_PX * WandPolicy.REACH_PX


func _swim_id(identity: String) -> String:
	return "SWIM_" + identity


func _configure_plank_marker(plank: EntityBody) -> void:
	var edge := Meadows.PLANK_SIZE / 2.0
	plank._marker.polygon = PackedVector2Array([
		# Reversible branch silhouette for graybox, not the final mossy sprite.
		Vector2(-edge.x, -edge.y * 0.8), Vector2(-edge.x * 0.35, -edge.y),
		Vector2(edge.x * 0.15, -edge.y * 0.85), Vector2(edge.x * 0.65, -edge.y),
		Vector2(edge.x, -edge.y * 0.85), Vector2(edge.x, edge.y * 0.9),
		Vector2(edge.x * 0.15, edge.y), Vector2(-edge.x * 0.4, edge.y * 0.85),
		Vector2(-edge.x, edge.y),
	])
	actor.z_index = 1


func _configure_body(body: ElevationBody, entity_id: String) -> void:
	super._configure_body(body, entity_id)
	body.emergency_anchor = Vector3(SPAWN.x, SPAWN.y, 0.0)
	if body is Fauna and body.aquatic_bounds.has_area():
		body.surfaces = _fish_surfaces
		body.emergency_anchor = Vector3(body.birth_point.x, body.birth_point.y, body.birth_height)


func set_home_active(active: bool) -> void:
	if not active and ancient_console != null:
		ancient_console.close()
	process_mode = Node.PROCESS_MODE_PAUSABLE if active else Node.PROCESS_MODE_DISABLED
	visible = active
	$Interface.visible = active
	_camera.enabled = active
	if active:
		_camera.position = actor.position
		_camera.make_current()
		_camera.reset_smoothing()


func can_return_traveler(point: Vector2, height: float) -> bool:
	return actor.motion._has_support(point, height, _decks, true) \
		and ElevationBody.clears_walls(point, height, actor.foot_radius(), _walls)


func return_traveler(point: Vector2, height: float) -> void:
	for body in actor.map_travelers():
		body.surfaces = _surfaces
		body.walls = _walls
		body.water_volumes = _water_volumes
		body.reparent_for_map(self)
		body.show()
		(body as EntityBody).location_id = _entity_location(point)
	actor.position = point
	actor.motion.reset_on_surface(point, height)
	actor.emergency_anchor = Vector3(SPAWN.x, SPAWN.y, 0.0)
	actor.gravity_scale = actor.get_parameter("gravity_scale")
	actor.direction = Vector2.ZERO
	actor.velocity = Vector2.ZERO
	actor._impulse_velocity = Vector2.ZERO
	actor._sync_projection()
	actor._update_rider_position()
	_connect_bridge_body()
	set_home_active(true)


func _connect_bridge_body() -> void:
	var yeti := entities.get_entity(BRIDGE_YETI_ID) as EntityBody
	yeti.collision_layer = EntityBody.BODY_OBSTACLE_LAYER
	(actor as EntityBody).step_obstacle = yeti


func _physics_process(delta: float) -> void:
	for identity in entities.list_ids():
		var body := entities.get_entity(identity) as EntityBody
		body.location_id = _entity_location(body.position)
	if keyboard:
		_apply_keyboard_input()
		tick_wand_self_hack(delta, Input.is_physical_key_pressed(KEY_TAB))
	if not is_instance_valid(_debug_editor):
		world_clock.advance(delta)
		donut_refill = maxf(0.0, donut_refill - delta)
		_ice_duration.tick(delta)
		_update_yeti_route()
		_refresh_plank_surface()
	var at_bank := _at_forest_bank()
	if _was_at_bank and not at_bank:
		forest_bank_left.emit()
	_was_at_bank = at_bank
	_camera.position = actor.position
	var area: String = AREA_LABELS[_entity_location(actor.position)]
	var wand := "Обычная палочка" if access.wand_mode == AccessState.ORDINARY else access.wand_mode
	_status.text = "%s  ·  %s  ·  %s" % [area, PHASE_LABELS[world_clock.phase()], wand]
	if has_donut:
		_status.text += "  ·  Пончик"
	if freeze_selected:
		_status.text += "  ·  Заморозка"
	if restriction_text.is_valid():
		_status.text += restriction_text.call()
	var action := _nearby_action()
	_prompt.text = "" if action.is_empty() or is_instance_valid(_debug_editor) \
		or (ancient_console != null and ancient_console.is_open()) else "E  " + action


func _apply_keyboard_input() -> void:
	if ancient_console != null and ancient_console.is_open():
		if at_ancient_console():
			apply_player_input(Vector2.ZERO)
			return
		ancient_console.close()
	super._apply_keyboard_input()


func _update_world_light(_minute: int = 0) -> void:
	_world_light.color = PHASE_TINTS[world_clock.phase()]


func _update_yeti_route() -> void:
	var yeti := entities.get_entity(BRIDGE_YETI_ID) as EntityBody
	yeti.autonomous_destination = Vector2.INF
	if retreat_step < 0 or retreat_step >= YETI_RETREAT.size() or yeti.get_parameter("behavior_mode") != "IDLE":
		return
	var goal: Vector2 = YETI_RETREAT[retreat_step]
	if yeti.position.distance_squared_to(goal) <= 4.0:
		retreat_step += 1
		if retreat_step == YETI_RETREAT.size():
			help_completed.emit("START_YETI_DONUT", BRIDGE_YETI_ID)
			return
		goal = YETI_RETREAT[retreat_step]
	yeti.autonomous_destination = goal


func _within_reach(point: Vector2, height: float = 0.0) -> bool:
	var offset := point - actor.position
	return Vector3(offset.x, offset.y, height - actor.motion.elevation).length_squared() <= INTERACT_REACH * INTERACT_REACH


func _nearby_action() -> String:
	if at_ancient_console():
		return "Осмотреть Древнюю Консоль"
	if access.wand_mode == AccessState.ORDINARY and projection.carried and _within_reach(RIFT_SPOT):
		return "Поднести палочку"
	if wand_pair.duplicate == null and projection.carried and actor.motion.grounded \
			and actor.position.x < Lake.POOL.position.x and _within_reach(Lake.CONTACT):
		return "Коснуться воды палочкой"
	var fridge := entities.get_entity(FRIDGE_ID) as EntityBody
	if not has_donut and donut_refill <= 0.0 and _within_reach(fridge.position, fridge.motion.elevation):
		return "Взять пончик"
	var yeti := entities.get_entity(BRIDGE_YETI_ID) as EntityBody
	if has_donut and not yeti.get_parameter("asleep") and _within_reach(yeti.position, yeti.motion.elevation):
		return "Предложить пончик"
	var plank := entities.get_entity(Meadows.PLANK_ID) as EntityBody
	if plank != null:
		if actor.has_passenger():
			if _plank_placement(plank).is_finite():
				return "Положить ветвь поперёк ручья"
			return "Отпустить"
		if not plank.is_attached() and plank.get_parameter("pickable") \
				and actor.position.distance_squared_to(plank.position) <= ElevationBody.BOARD_RADIUS * ElevationBody.BOARD_RADIUS \
				and absf(actor.motion.elevation - plank.motion.elevation) <= ElevationBody.BOARD_HEIGHT:
			return "Взять ветвь"
	if actor.motion.grounded and not actor.is_attached() \
			and actor.position.distance_squared_to(Meadows.CAMP_SPOT) <= CAMP_REACH * CAMP_REACH:
		return "Отдохнуть до утра" if _rest_until_morning() else "Отдохнуть до ночи"
	if freeze_selected and _can_freeze_creek():
		return "Заморозить воду"
	return ""


func _rest_until_morning() -> bool:
	return world_clock.phase() in [WorldClock.Phase.EVENING, WorldClock.Phase.NIGHT]


func _plank_placement(plank: EntityBody) -> Vector2:
	if not plank.is_carried() or plank._carrier != actor or not actor.motion.grounded:
		return Vector2.INF
	var side := signf(Meadows.CREEK.get_center().x - actor.position.x)
	var point := actor.position + Vector2(side * 58.0, 0.0)
	return point if not Meadows.plank_support(point, plank.body_size).is_empty() else Vector2.INF


func _refresh_plank_surface() -> void:
	var plank := entities.get_entity(Meadows.PLANK_ID) as EntityBody
	var surface := {}
	if plank != null and not plank.is_attached() and plank.motion.grounded and is_zero_approx(plank.motion.elevation):
		surface = Meadows.plank_support(plank.position, plank.body_size)
	_set_plank_surface(surface)


func _set_plank_surface(surface: Dictionary) -> void:
	if surface == _plank_surface:
		return
	if not _plank_surface.is_empty():
		_surfaces.erase(_plank_surface)
	_plank_surface = surface
	if not surface.is_empty():
		_surfaces.append(surface)


func _can_freeze_creek() -> bool:
	if ice_remaining > 0.0 or not projection.carried or not actor.motion.grounded:
		return false
	if frost_cast_allowed.is_valid() and not frost_cast_allowed.call():
		return false
	var closest := actor.position.clamp(Meadows.ICE_BOUNDS.position, Meadows.ICE_BOUNDS.end)
	return actor.position.distance_squared_to(closest) <= Meadows.FREEZE_REACH * Meadows.FREEZE_REACH


func _update_ice_support(active: bool) -> void:
	if active:
		_surfaces.append(Meadows.ICE_SURFACE)
	else:
		_surfaces.erase(Meadows.ICE_SURFACE)
	queue_redraw()


func interact() -> bool:
	if not (actor as EntityBody).accepts_player_input() or is_instance_valid(_debug_editor):
		return false
	if at_ancient_console():
		ancient_console.open()
		apply_player_input(Vector2.ZERO)
		return true
	if forest_bank != null and forest_bank.can_interact(actor.position, actor.motion.elevation):
		_was_at_bank = true
		forest_bank.respond()
		forest_bank_interacted.emit()
		return true
	match _nearby_action():
		"Поднести палочку":
			return _set_wand_mode(AccessState.PLAYFUL)
		"Коснуться воды палочкой":
			var duplicated := wand_pair.duplicate_in_water(Lake.SHORE + Vector2(17, 0), Lake.LOCATION_ID)
			queue_redraw()
			return duplicated
		"Взять пончик":
			has_donut = true
			donut_refill = DONUT_REFILL_SECONDS
			return true
		"Предложить пончик":
			has_donut = false
			if retreat_step < 0:
				retreat_step = 0
			return true
		"Заморозить воду":
			_ice_duration.start()
			frost_cast.emit(Meadows.ICE_SECONDS)
			return true
		"Отдохнуть до утра":
			return world_clock.set_time_of_day(WorldClock.MORNING_MINUTE)
		"Отдохнуть до ночи":
			return world_clock.set_time_of_day(WorldClock.NIGHT_MINUTE)
		"Положить ветвь поперёк ручья":
			var plank := entities.get_entity(Meadows.PLANK_ID) as EntityBody
			if not actor.try_place_carried(_plank_placement(plank), 0.0):
				return false
			_refresh_plank_surface()
			return true
		"Взять ветвь":
			if not interact_with_attachment(Meadows.PLANK_ID):
				return false
			_refresh_plank_surface()
			return true
	return interact_with_attachment()


func exchange_nearby_wand() -> bool:
	if not (actor as EntityBody).accepts_player_input() or not actor.motion.grounded \
			or not actor.motion._has_support(actor.position, actor.motion.elevation, _surfaces, true):
		return false
	if not wand_pair.exchange(actor.position, _entity_location(actor.position)):
		return false
	projection = wand_pair.active()
	_wand_hold = 0.0
	queue_redraw()
	return true


func _can_hack_second_wand() -> bool:
	return access.wand_mode == AccessState.PLAYFUL and (actor as EntityBody).accepts_player_input() \
		and actor.motion.grounded and not is_instance_valid(_debug_editor) \
		and wand_pair.can_hack_other(actor.position, _entity_location(actor.position))


func tick_wand_self_hack(delta: float, held_down: bool) -> bool:
	if not held_down or not _can_hack_second_wand():
		_wand_hold = 0.0
		return false
	_wand_hold = minf(_wand_hold + delta, WAND_HOLD_SECONDS)
	if _wand_hold < WAND_HOLD_SECONDS:
		return false
	_wand_hold = 0.0
	return _set_wand_mode(AccessState.DEVELOPER)


func _set_wand_mode(mode: String) -> bool:
	if wand_mode_requested.is_valid() and not wand_mode_requested.call(mode):
		return false
	return access.set_wand_mode(mode)


func _unhandled_key_input(event: InputEvent) -> void:
	if not keyboard or not event is InputEventKey or not event.pressed or event.echo:
		return
	if ancient_console != null and ancient_console.is_open():
		if event.keycode == KEY_ESCAPE:
			ancient_console.close()
		if event.keycode not in [KEY_F5, KEY_F7, KEY_F9]:
			get_viewport().set_input_as_handled()
		return
	match event.keycode:
		KEY_E:
			if interact():
				get_viewport().set_input_as_handled()
		KEY_TAB:
			if not _can_hack_second_wand() or not get_wand_editor_tabs(Administrator.ID).is_empty():
				_toggle_debug_editor()
			get_viewport().set_input_as_handled()
		KEY_2:
			if not is_instance_valid(_debug_editor):
				freeze_selected = true
		KEY_1, KEY_3, KEY_4:
			if not is_instance_valid(_debug_editor):
				freeze_selected = false
		KEY_ESCAPE:
			if is_instance_valid(_debug_editor):
				_toggle_debug_editor()
				get_viewport().set_input_as_handled()
		KEY_G:
			exchange_nearby_wand()
		KEY_ENTER:
			if not is_instance_valid(_debug_editor) and _restore_nearby_swim():
				get_viewport().set_input_as_handled()
		KEY_F5:
			if not managed_save and _store.write_snapshot(make_snapshot(), SAVE_PATH):
				$Interface/SaveNotice.text = "Сохранено"
		KEY_F9:
			if managed_save:
				return
			var saved := _store.read_snapshot(SAVE_PATH)
			$Interface/SaveNotice.text = "Загружено" if apply_snapshot(saved) else "Нет подходящего сохранения"


func show_administrator(mercy_request: Callable, disposition: String = Administrator.ANGER) -> bool:
	hide_administrator()
	var vicinity := [Vector2(72, 0), Vector2(-72, 0), Vector2(0, 68), Vector2(0, -68),
		Vector2(46, 0), Vector2(-46, 0)]
	for offset in vicinity:
		var point: Vector2 = actor.position + offset
		var location := _entity_location(point)
		if location != _entity_location(actor.position) or _intersects_wall(point, 0.0) \
				or _spawn_is_occupied(point, 0.0) or not actor.motion._has_support(point, 0.0, _decks, true):
			continue
		administrator = Administrator.new()
		_configure_body(administrator, Administrator.ID)
		administrator.record = EntityRecord.new(Administrator.ID, Administrator.CATEGORY, "Администратор",
			parameters, {"alive": false, "ai_enabled": false, "luna_relation": disposition})
		administrator.world_registry = entities
		administrator.location_id = location
		administrator.position = point
		administrator.motion.reset_on_surface(point, 0.0)
		administrator.mercy_requested = mercy_request
		add_child(administrator)
		administrator.set_physics_process(false)
		var label := Label.new()
		label.text = administrator.record.display_name
		label.position = Vector2(-63, -58)
		administrator.add_child(label)
		return true
	return false


func hide_administrator() -> void:
	if is_instance_valid(administrator):
		administrator.free()
	administrator = null


func _wand_target(target_id: String) -> EntityBody:
	if target_id == Administrator.ID:
		return administrator
	var target := super._wand_target(target_id)
	return null if target is Fauna and not target.visible else target


func _wand_target_ids() -> Array[String]:
	var ids := super._wand_target_ids()
	if is_instance_valid(administrator):
		ids.append(Administrator.ID)
	return ids


func get_wand_editor_tabs(target_id: String) -> Dictionary:
	if target_id == ECOLOGY_CATALOG:
		return {}
	var tabs := super.get_wand_editor_tabs(target_id)
	if target_id == Administrator.ID and not tabs.is_empty():
		return {} if tabs["Отношения"].is_empty() else {"Отношения": tabs["Отношения"]}
	if not tabs.is_empty() and _holds_ecology_catalog() and FISH_POINTS.has(target_id):
		var target := get_natural_fauna(target_id)
		if target != null and target.get_parameter("alive"):
			var module_id := _swim_id(target_id)
			if target.record.get_component("ABILITY_SET").get("instances", {}).has(module_id):
				tabs["Способности"] = [
					{"id": "SWIM_ENABLED", "label": "SWIM", "kind": "bool", "value": target.has_vital_swim()},
					{"id": module_id, "label": "SWIM", "kind": "action", "value": "В банк",
						"action": func(): return request_extract_swim(target_id)},
				]
	return tabs


func _toggle_debug_editor() -> void:
	if not is_instance_valid(_debug_editor) and not get_wand_editor_tabs(Administrator.ID).is_empty():
		_open_debug_editor(Administrator.ID)
	else:
		super._toggle_debug_editor()
	var editor_open := is_instance_valid(_debug_editor)
	if system_pause != null:
		if editor_open:
			_debug_editor.process_mode = Node.PROCESS_MODE_ALWAYS
			if system_pause.mode.is_empty():
				system_pause.begin(SystemPause.EDITOR, self, actor)
		elif system_pause.mode == SystemPause.EDITOR:
			system_pause.finish()
		return
	for identity in entities.list_ids():
		var body := entities.get_entity(identity) as EntityBody
		body.set_physics_process(not editor_open)


func make_snapshot() -> Dictionary:
	var data := super.make_snapshot()
	if observation_fixture:
		data["observation_layout"] = 1
	if ecology_fixture:
		data["ecology_layout"] = 1
		for entry in data["entities"]:
			entry["components"] = entities.get_entity(entry["id"]).record.get_components()
	data["island"] = {
		"access": access.snapshot(), "projection": wand_pair.original.snapshot(), "has_donut": has_donut,
		"donut_refill": donut_refill, "retreat_step": retreat_step,
	}
	data["meadows"] = {"ice_remaining": ice_remaining, "layout_version": 2}
	data["world_clock"] = world_clock.snapshot()
	data["wand_pair"] = wand_pair.snapshot()
	return data


func apply_snapshot(data: Dictionary) -> bool:
	var island: Variant = data.get("island")
	var states: Variant = data.get("entities")
	if not island is Dictionary or not states is Array:
		return false
	var next_access := AccessState.new()
	var next_projection := WandProjection.new()
	var next_clock := WorldClock.new()
	if data.has("world_clock") and not next_clock.restore(data["world_clock"]):
		return false
	var access_data: Variant = island.get("access")
	var projection_data: Variant = island.get("projection")
	var food: Variant = island.get("has_donut")
	var refill: Variant = island.get("donut_refill")
	var step: Variant = island.get("retreat_step")
	if not access_data is Dictionary or not next_access.restore(access_data) \
			or not projection_data is Dictionary or not next_projection.restore(projection_data) \
			or not food is bool:
		return false
	var pair := WandPair.new()
	var legacy_held := WandPair.ORIGINAL if next_projection.carried else ""
	var wand_data: Variant = data.get("wand_pair", {"held": legacy_held, "retained": WandPair.ORIGINAL, "duplicate": {}})
	if not pair.restore(next_projection, wand_data):
		return false
	if pair.duplicate != null and (not _valid_ground_wand(pair.original) or not _valid_ground_wand(pair.duplicate)):
		return false
	if typeof(refill) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(refill)) \
			or float(refill) < 0.0 or float(refill) > DONUT_REFILL_SECONDS:
		return false
	if typeof(step) not in [TYPE_INT, TYPE_FLOAT] or float(step) not in [-1.0, 0.0, 1.0, 2.0]:
		return false
	var meadow_state: Variant = data.get("meadows", {"ice_remaining": 0.0})
	if not meadow_state is Dictionary:
		return false
	var next_ice := ActiveDuration.new(Meadows.ICE_SECONDS)
	if not next_ice.restore(meadow_state.get("ice_remaining")):
		return false
	var layout: Variant = meadow_state.get("layout_version", 1)
	if typeof(layout) not in [TYPE_INT, TYPE_FLOAT] or float(layout) not in [1.0, 2.0]:
		return false
	var fridge_found := false
	var yeti_found := false
	for state in states:
		if state is Dictionary:
			fridge_found = fridge_found or (state.get("id") == FRIDGE_ID and state.get("category") == "fridge")
			yeti_found = yeti_found or (state.get("id") == BRIDGE_YETI_ID and state.get("category") == "yeti")
	if not fridge_found or not yeti_found:
		return false
	var candidate := data
	if float(layout) == 1.0:
		candidate = data.duplicate(true)
		for entry in _initial_meadow_states:
			if not data.has("meadows") or entry["id"] == Meadows.PLANK_ID:
				candidate["entities"].append(entry)
	if ecology_fixture and not candidate.has("ecology_layout"):
		candidate = candidate.duplicate(true)
		for entry in _initial_ecology_states:
			candidate["entities"].append(entry)
	elif ecology_fixture and candidate["ecology_layout"] != 1:
		return false
	if observation_fixture and not candidate.has("observation_layout"):
		candidate = candidate.duplicate(true)
		for entry in _initial_observation_states:
			candidate["entities"].append(entry)
	elif observation_fixture and candidate["observation_layout"] != 1:
		return false
	var plank: Dictionary = {}
	for state in candidate["entities"]:
		if state is Dictionary and state.get("id") == Meadows.PLANK_ID and state.get("category") == "prop":
			plank = state
			break
	if plank.is_empty():
		return false
	var previous_ice := ice_remaining
	var previous_plank := _plank_surface
	_ice_duration.restore(next_ice.remaining)
	_set_plank_surface(_saved_plank_surface(plank))
	if not super.apply_snapshot(candidate):
		_ice_duration.restore(previous_ice)
		_set_plank_surface(previous_plank)
		return false
	access = next_access
	wand_pair = pair
	projection = wand_pair.active()
	_wand_hold = 0.0
	queue_redraw()
	world_clock.restore(next_clock.snapshot())
	has_donut = food
	donut_refill = float(refill)
	retreat_step = int(step)
	_was_at_bank = _at_forest_bank()
	if ancient_console != null:
		ancient_console.close()
	_connect_bridge_body()
	_configure_plank_marker(entities.get_entity(Meadows.PLANK_ID) as EntityBody)
	_camera.position = actor.position
	return true


func _build_saved_entity(state: Variant, version: int) -> EntityBody:
	var body := super._build_saved_entity(state, version)
	# Preserve the original stable ID, position, ownership and editable state.
	if body != null and body.entity_id == Meadows.PLANK_ID and body.record.display_name == "Доска":
		body.record.display_name = "Упавшая ветвь"
	if body != null and ecology_fixture and not body.record.set_components(state.get("components", {})):
		body.free()
		return null
	return body


func _validate_saved_entities(candidates: Dictionary) -> bool:
	if observation_fixture:
		for identity in COURT_FRIDGES:
			var fridge: EntityBody = candidates.get(identity)
			if fridge == null or fridge.record.category != "fridge":
				return false
	if not ecology_fixture:
		return super._validate_saved_entities(candidates)
	var counts := {}
	var catalog: EntityBody = candidates.get(ECOLOGY_CATALOG)
	if catalog == null or catalog.record.category != "prop":
		return false
	for identity in FISH_POINTS:
		if not candidates.get(identity) is Fauna:
			return false
		counts[_swim_id(identity)] = 0
	for identity in candidates:
		for component in ["ABILITY_SET", "ABILITY_BANK"]:
			var items := AbilityBank.instances(candidates[identity].record.get_components(), component)
			for module in items:
				if not counts.has(module):
					continue
				if items[module]["ability_id"] != "SWIM" or items[module]["protected"] \
						or (component == "ABILITY_BANK" and identity != ENTITY_ID) \
						or (component == "ABILITY_SET" and module != _swim_id(identity)):
					return false
				counts[module] += 1
	return counts.values().all(func(count): return count == 1)


func _valid_ground_wand(field: WandProjection) -> bool:
	return field.carried or (field.ground_location_id == _entity_location(field.ground_position) \
		and actor.motion._has_support(field.ground_position, 0.0, _decks, true))


func _saved_plank_surface(state: Dictionary) -> Dictionary:
	var motion: Variant = state.get("motion")
	var attachment: Variant = state.get("attachment")
	var movement: Variant = state.get("movement")
	var point: Variant = state.get("position")
	if not motion is Dictionary or not attachment is Dictionary or not movement is Dictionary \
			or not point is Array or point.size() != 2:
		return {}
	if motion.get("grounded") != true or motion.get("elevation") != 0 or attachment.get("carrier_id") != "":
		return {}
	var size: Variant = movement.get("size")
	for value in [point[0], point[1], size]:
		if typeof(value) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(value)):
			return {}
	if float(size) < 0.5 or float(size) > 2.0:
		return {}
	return Meadows.plank_support(Vector2(float(point[0]), float(point[1])), float(size))


func _draw() -> void:
	for index in _decks.size():
		var deck: Rect2 = _decks[index]["bounds"]
		var color := Color("7c6a72") if index == 1 else Color("4b655c")
		draw_rect(deck.grow(5.0), Color("2b393d"))
		draw_rect(deck, color)
	for wall in _walls:
		if wall["bounds"] not in [ForestBank.REST_SPOT, AncientConsole.CONSOLE_BODY]:
			draw_rect(wall["bounds"], Color("b5a0b0"))
	draw_rect(Rect2(FRIDGE_SPOT - Vector2(55, 35), Vector2(110, 70)), Color("657572"))
	draw_circle(RIFT_SPOT, 22.0, Color("3c3354"))
	draw_arc(RIFT_SPOT, 22.0, -0.8, 4.8, 28, Color("bca3e4"), 3.0, true)
	draw_polyline(PackedVector2Array([RIFT_SPOT + Vector2(4, -20), RIFT_SPOT + Vector2(-5, -4),
		RIFT_SPOT + Vector2(7, 3), RIFT_SPOT + Vector2(-3, 22)]), Color("eee0fa"), 2.0, true)
	var font := ThemeDB.fallback_font
	draw_string(font, FRIDGE_SPOT + Vector2(-48, -47), "Холодильник")
	draw_string(font, RIFT_SPOT + Vector2(-28, 48), "Разлом")
	draw_string(font, Vector2(1005, 339), "К Большим лугам →")
	Meadows.draw_on(self, ice_remaining > 0.0)
	Lake.draw_on(self)
	for field in [wand_pair.original, wand_pair.duplicate]:
		if field != null and not field.carried:
			var point: Vector2 = field.ground_position
			draw_line(point + Vector2(-11, 7), point + Vector2(11, -7), Color("ead1ff"), 5.0)
			draw_circle(point + Vector2(11, -7), 4.0, Color("ffd98d"))
