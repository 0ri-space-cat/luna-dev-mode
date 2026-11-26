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
const MIRROR_SNAIL := "W7_MIRROR_SNAIL"
const MIRROR_BIRTH := Vector2(3000, 465)
const DUPLICATE_MODULE_ID := "DUPLICATE_W7_MIRROR_SNAIL"
const DUPLICATE_MODULE := {"ability_id": "DUPLICATE", "enabled": true, "protected": false}
const DUPLICATE_INTERVAL := 12.0
const DUPLICATE_LIMIT := 4
const DUPLICATE_PREFIX := "DUPLICATE_W7_COPY_"
const DUPLICATE_CATEGORIES := ["mirror_snail", "fox", "trollik"]
const FISH_POINTS := {
	"DEV_POOL_FISH_A": Vector2(2532, 375),
	"DEV_POOL_FISH_B": Vector2(2559, 424),
	"DEV_POOL_FISH_C": Vector2(2576, 476),
}
const Lake = preload("res://scripts/skeleton/duplicate_lake_layout.gd")
const Valley = preload("res://scripts/skeleton/valley_dry_layout.gd")
const Coast = preload("res://scripts/skeleton/coast_layout.gd")
const ADDRESS_SCHEMA := 12
const City = preload("res://scripts/skeleton/luma_city_layout.gd")
const Social = preload("res://scripts/runtime2d/friend_progress_2d.gd")
const Music = preload("res://scripts/runtime2d/flute_2d.gd")
const Visits = preload("res://scripts/skeleton/oni_music_layout.gd")
const ATTRACTION_SECONDS := 14.0
const Life = preload("res://scripts/skeleton/coastal_life_layout.gd")
const LAB_ICE_SECONDS := 40.0
const CoastExtra = preload("res://scripts/skeleton/coast_observation_layout.gd")
const LAKE_CHIBI_PREFIX := "W6_CHIBI_"
const LAKE_PROP_PREFIX := "W6_PROP_COPY_"
const LAKE_CHIBI_LIMIT := 3
const LAKE_PROP_LIMIT := 3
const LAKE_INTERVAL := 5.0
const LAKE_STONE_ID := "W6_SHORE_STONE"
const Crystal = preload("res://scripts/skeleton/crystal_observation_layout.gd")
const Gaze = preload("res://scripts/runtime2d/observer_query_2d.gd")
const Solidity = preload("res://scripts/runtime2d/observation_body_2d.gd")
const Tunnel = preload("res://scripts/skeleton/waterfall_tunnel_layout.gd")
const BUBBLE_SECONDS := 30.0
const MiaLab = preload("res://scripts/skeleton/mia_lab_layout.gd")
const AlchemyPanel = preload("res://scripts/skeleton/alchemy_panel_2d.gd")
const GLOW_SECONDS := 35.0
const WandPair = preload("res://scripts/skeleton/wand_pair_2d.gd")
const WAND_HOLD_SECONDS := 3.0
const Meadows = preload("res://scripts/skeleton/meadows_layout.gd")
const WorldClock = preload("res://scripts/runtime2d/world_clock_2d.gd")
const ActiveDuration = preload("res://scripts/runtime2d/active_duration_2d.gd")
const ISLAND_ID := "ET_START_ISLAND"
const AREA_LABELS := {
	ISLAND_ID: "Стартовый остров", Meadows.LOCATION_ID: "Большие луга",
	Lake.LOCATION_ID: "Озеро Дубликатов", ForestBank.LOCATION_ID: "Лес",
	AncientConsole.LOCATION_ID: "Лесная поляна", Valley.LOCATION_ID: "Долина водопадов",
	Valley.CRYSTAL_ID: "Кристальные пещеры", Coast.LOCATION_ID: "Побережье",
	Coast.HOUSE_ID: "Дом вечерних окон", Coast.GROTTO_ID: "Морской грот",
	Valley.TOWER_ID: "Башня отражений", Tunnel.LOCATION_ID: "Подводный тоннель",
	City.CITY_ID: "Люма", City.CAFE_ID: "Кафе", City.HOME_ID: "Комната Луны",
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
var _initial_mirror_state: Dictionary = {}
var _duplicate_elapsed := 0.0
var _lake_elapsed := 0.0
var _lake_entered := false
var _initial_lake_stone: Dictionary = {}
var hourglass_owned := false
var flask_state := 0 # 0 Mia, 1 loan, 2 gift. One original.
var flask_effect := ""
var mia_experienced := false
var mia_route_step := 0
var _lab_ice := ActiveDuration.new(LAB_ICE_SECONDS)
var _pool_water: WaterVolume
var _initial_life_states: Array[Dictionary] = []
var social := Social.new()
var oni_route_index := 0
var _initial_oni: Dictionary = {}
var _initial_city_states: Array[Dictionary] = []
var public_ride_requested: Callable
var city_bench_active := true
var city_bench_step := 0
var city_bench_observed := false
var city_ray_settled := false
var flute_owned := false
var prism_active := false
var music_focus := false
var music := Music.new()
var _note_audio: AudioStreamPlayer
var _tones: Dictionary = {}
var _attraction := ActiveDuration.new(ATTRACTION_SECONDS)
var _music_original_scale := 0.0
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
var coast_house_phase: int = WorldClock.Phase.EVENING
var _alchemy_panel: PanelContainer
var _alchemy_glow := ActiveDuration.new(GLOW_SECONDS)
var _alchemy_bubble := ActiveDuration.new(BUBBLE_SECONDS)
var _bubble_started := false
var crystal_observer := Gaze.new()
var _crystal_door: StaticBody2D
var _crystal_door_solid := false
var _alchemy_light: PointLight2D
var _coast_tide: WaterVolume
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
	if observation_fixture:
		var city_address := City.location_at(point)
		if not city_address.is_empty():
			return city_address
	return _entity_location_v11(point)


func _entity_location_v11(point: Vector2) -> String:
	if observation_fixture:
		if CoastExtra.grotto_contains(point):
			return Coast.GROTTO_ID
		if CoastExtra.shelf_contains(point):
			return Coast.LOCATION_ID
	return _entity_location_v10(point)


func _entity_location_v10(point: Vector2) -> String:
	if observation_fixture and Crystal.contains(point):
		return Valley.CRYSTAL_ID
	return _entity_location_v9(point)


func _entity_location_v9(point: Vector2) -> String:
	if observation_fixture and Tunnel.contains(point):
		return Tunnel.LOCATION_ID
	return _entity_location_v8(point)


func _entity_location_v8(point: Vector2) -> String:
	if observation_fixture and MiaLab.contains(point):
		return Valley.LOCATION_ID
	return _entity_location_v7(point)


func _entity_location_v7(point: Vector2) -> String:
	if observation_fixture:
		if Coast.HOUSE_ROOM.has_point(point):
			return Coast.HOUSE_ID
		if Coast.grotto_contains(point):
			return Coast.GROTTO_ID
		if Coast.contains(point):
			return Coast.LOCATION_ID
		var extension := Valley.location_at(point)
		if not extension.is_empty():
			return extension
	return _legacy_entity_location(point)


# M3.84 partition before the reflection tower.
func _entity_location_v6(point: Vector2) -> String:
	if observation_fixture:
		if Coast.HOUSE_ROOM.has_point(point):
			return Coast.HOUSE_ID
		if Coast.grotto_contains(point):
			return Coast.GROTTO_ID
		if Coast.contains(point):
			return Coast.LOCATION_ID
		var extension := Valley.location_at_v6(point)
		if not extension.is_empty():
			return extension
	return _legacy_entity_location(point)


# M3.83b partition before the grotto and headland.
func _entity_location_v5(point: Vector2) -> String:
	if observation_fixture:
		if Coast.HOUSE_ROOM.has_point(point):
			return Coast.HOUSE_ID
		if Coast.contains_v5(point):
			return Coast.LOCATION_ID
		var extension := Valley.location_at_v6(point)
		if not extension.is_empty():
			return extension
	return _legacy_entity_location(point)


# M3.82 partition before the veranda and separate house interior.
func _entity_location_v4(point: Vector2) -> String:
	if observation_fixture:
		if Coast.contains_v4(point):
			return Coast.LOCATION_ID
		var extension := Valley.location_at_v6(point)
		if not extension.is_empty():
			return extension
	return _legacy_entity_location(point)


# M3.74d partition before the river and coast extension.
func _entity_location_v3(point: Vector2) -> String:
	if observation_fixture:
		var extension := Valley.location_at_v3(point)
		if not extension.is_empty():
			return extension
	return _legacy_entity_location(point)


# M3.74b partition before the crystal approach.
func _entity_location_v2(point: Vector2) -> String:
	if observation_fixture:
		var extension := Valley.location_at_v2(point)
		if not extension.is_empty():
			return extension
	return _legacy_entity_location(point)


# M3.73 partition before the W1 expansion.
func _entity_location_v1(point: Vector2) -> String:
	if observation_fixture:
		var extension := Valley.location_at_v1(point)
		if not extension.is_empty():
			return extension
	return _legacy_entity_location(point)


# The pre-M3.73 spatial partition, with the lake alias normalized.
func _legacy_entity_location(point: Vector2) -> String:
	if ancient_console_enabled and AncientConsole.CLEARING.has_point(point):
		return AncientConsole.LOCATION_ID
	if observation_fixture and ForestBank.FOREST.has_point(point):
		return ForestBank.LOCATION_ID
	if point.x >= Lake.BOUNDARY:
		return Lake.LOCATION_ID
	return Meadows.LOCATION_ID if point.x >= Meadows.WEST_BOUNDARY else ISLAND_ID


func _entity_limit() -> int:
	# The adventure now contains multiple authored regions; small fixtures
	# keep their original limit. Individual copy systems remain capped.
	return 64 if observation_fixture else super._entity_limit()


func _starts_alive(category: String) -> bool:
	return category in ["fox", "trollik", "fish", "mirror_snail", "chibi_luna", "mia", "crab", "turtle", "oni", "cat", "ray", "toffi", "yuki", "ori", "lizard", "resident"] or super._starts_alive(category)


func _editor_parent() -> Node:
	return $Interface


func _ready() -> void:
	wand_pair.original = projection
	world_clock.minute_changed.connect(_update_world_light)
	_ice_duration.active_changed.connect(_update_ice_support)
	_lab_ice.active_changed.connect(_update_lab_ice)
	_update_world_light()
	_decks.assign(ISLAND_DECKS)
	var ground := Meadows.DECKS + Lake.DECKS
	if observation_fixture:
		ground.append_array(ForestBank.DECKS + [FRIDGE_COURT, FRIDGE_PATH])
		ground.append_array(Valley.DECKS + Coast.DECKS + MiaLab.DECKS + Tunnel.DECKS + Crystal.DECKS + [CoastExtra.LANDING] + City.DECKS)
		_water_volumes.append(WaterVolume.new(ForestBank.RIVER, -110.0, 0.0, Vector2(12, 0), 1.3))
	if ancient_console_enabled:
		ground.append_array(AncientConsole.DECKS)
	for bounds in ground:
		_decks.append({"bounds": bounds, "height": 0.0})
	if observation_fixture:
		for tread in Coast.ESCAPE_DECKS + Valley.TOWER_DECKS + MiaLab.ELEVATED + CoastExtra.SHELF_STEPS + [City.TABLE]:
			_decks.append(tread.duplicate())
	_surfaces.assign(_decks)
	if observation_fixture:
		_surfaces.append(Crystal.LOWER)
		_surfaces.append(CoastExtra.LOWER)
		_surfaces.append(Lake.SHALLOW_SURFACE)
		for surface in Tunnel.WATER_SURFACES:
			_surfaces.append(surface.duplicate())
		_water_volumes.append(WaterVolume.new(Tunnel.WATER, Tunnel.BED, 0.0, Vector2.ZERO, 1.2))
		for water in MiaLab.WATER:
			_surfaces.append(water.duplicate())
			_water_volumes.append(WaterVolume.new(water["bounds"], water["height"], 0.0, Vector2.ZERO, 1.2))
		_surfaces.append({"bounds": Coast.FOAM_BRIDGE, "height": 0.0, "safe": false, "feature_id": Coast.FOAM_BRIDGE_ID})
		_surfaces.append({"bounds": Coast.TIDAL_MOUTH, "height": 0.0, "safe": false})
		_coast_tide = WaterVolume.new(Coast.TIDAL_MOUTH, 0.0, Coast.tide_height(world_clock.minute_of_day()), Vector2(-60, 0), 2.0)
		_water_volumes.append(_coast_tide)
		_pool_water = WaterVolume.new(Life.POOL, 0.0, Coast.tide_height(world_clock.minute_of_day()) * 8.0 / 30.0, Vector2(28, 0), 2.0)
		_pool_water.ground_hold_mass = 4.0
		_water_volumes.append(_pool_water)
		_surfaces.append({"bounds": Valley.RAIN_BRIDGE, "height": 0.0, "safe": false, "feature_id": Valley.RAIN_BRIDGE_ID})
		_surfaces.append({"bounds": Coast.SEA, "height": Coast.SEA_BED, "safe": false})
		_water_volumes.append(WaterVolume.new(Coast.SEA, Coast.SEA_BED, 0.0, Vector2(8, 0), 1.2))
		_surfaces.append({"bounds": Valley.ORDINARY_POOL, "height": Valley.ORDINARY_BED, "safe": false})
		_water_volumes.append(WaterVolume.new(Valley.ORDINARY_POOL, Valley.ORDINARY_BED, 0.0, Vector2.ZERO, 1.2))
	_surfaces.append({"bounds": Lake.POOL, "height": Lake.BED_HEIGHT, "safe": false})
	_fish_surfaces.assign([{"bounds": Lake.POOL, "height": Lake.BED_HEIGHT}])
	_water_volumes.append(WaterVolume.new(Lake.POOL, Lake.BED_HEIGHT, 0.0, Vector2.ZERO, 1.2))
	_water_volumes.append(WaterVolume.new(Meadows.CREEK, Meadows.CREEK_BED, 0.0,
		Vector2(0, 18), 1.5))
	_walls.assign(BRIDGE_RAILS)
	if observation_fixture:
		_walls.append({"bounds": ForestBank.REST_SPOT, "height": 96.0, "layer": 2})
		_walls.append({"bounds": Coast.HOUSE_SHELL, "height": 96.0, "layer": 2})
		for wall in City.WALLS:
			_walls.append(wall)
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
		_setup_alchemy()
		_setup_crystal_observation()
		if ecology_fixture:
			_spawn_mirror_snail()
		_spawn_lake_stone()
		_spawn_coastal_life()
		_spawn_oni()
		_spawn_city()
		_setup_yuki()
		if ecology_fixture:
			_setup_ori()
		_setup_flute()
	if ancient_console_enabled:
		ancient_console = AncientConsole.new()
		add_child(ancient_console)
		ancient_console.attach_interface($Interface)
	_camera.position = actor.position


func _setup_crystal_observation() -> void:
	_crystal_door = StaticBody2D.new()
	_crystal_door.collision_mask = 0
	_crystal_door.collision_layer = 0
	_crystal_door.disable_mode = CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
	var bounds: Rect2 = Crystal.DOOR["bounds"]
	_crystal_door.position = bounds.get_center()
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = bounds.size
	collider.shape = shape
	_crystal_door.add_child(collider)
	add_child(_crystal_door)
	_sync_crystal_observation()


func set_luna_eyes(open: bool) -> void:
	crystal_observer.luna_eyes_open = open
	_sync_crystal_observation()


func _set_crystal_door(solid: bool) -> void:
	if _crystal_door == null or _crystal_door_solid == solid:
		return
	_crystal_door_solid = solid
	if solid:
		_walls.append(Crystal.DOOR)
	else:
		_walls.erase(Crystal.DOOR)
	_crystal_door.collision_layer = int(Crystal.DOOR["layer"]) if solid else 0
	queue_redraw()


func _door_occupied() -> bool:
	var bounds: Rect2 = Crystal.DOOR["bounds"]
	for identity in entities.list_ids():
		var body := entities.get_entity(identity) as EntityBody
		if body.motion.elevation < float(Crystal.DOOR["height"]) \
				and bounds.grow(body.foot_radius()).has_point(body.position):
			return true
	return false


func _sync_crystal_observation() -> void:
	if _crystal_door == null:
		return
	var bridge_bounds: Rect2 = Crystal.BRIDGE["bounds"]
	var state := crystal_observer.evaluate(actor, null, bridge_bounds.get_center())
	# The same observer law as the standalone fixture. No camera dependency.
	var solid := Solidity.solid_for(Solidity.WHEN_UNOBSERVED, Solidity.LUNA, state)
	if solid and not _surfaces.has(Crystal.BRIDGE):
		_surfaces.append(Crystal.BRIDGE)
	elif not solid:
		_surfaces.erase(Crystal.BRIDGE)
	var coast_bounds: Rect2 = CoastExtra.BRIDGE["bounds"]
	var coast_state := crystal_observer.evaluate(actor, null, coast_bounds.get_center())
	var coast_solid := Solidity.solid_for(Solidity.WHEN_UNOBSERVED, Solidity.LUNA, coast_state)
	if coast_solid and not _surfaces.has(CoastExtra.BRIDGE):
		_surfaces.append(CoastExtra.BRIDGE)
	elif not coast_solid:
		_surfaces.erase(CoastExtra.BRIDGE)
	# Reclose only after the actual body clears the doorway, never crush it.
	_set_crystal_door(crystal_observer.luna_eyes_open and not _door_occupied())


# The notebook and its physical experimental carrier share the regular world.
const YukiProgram = preload("res://scripts/runtime2d/yuki_program_2d.gd")
const YukiPanel = preload("res://scripts/skeleton/yuki_panel_2d.gd")
const YUKI_FRIDGE := "C4_YUKI_FRIDGE"
const YUKI_CAT_PREFIX := "YUKI_CAT_"
const YUKI_FRIDGE_POINT := Vector2(5625, 600)
const YUKI_CAT_POINTS := [Vector2(5775, 650), Vector2(5110, 420), Vector2(1330, 430), Vector2(5270, 470), Vector2(5635, 655), Vector2(4605, 400), Vector2(1285, 435), Vector2(5185, 550)]
var yuki := YukiProgram.new()
var _yuki_panel: PanelContainer
var _initial_yuki_fridge: Dictionary = {}


func _setup_yuki() -> void:
	var fridge := spawn_entity({"id": YUKI_FRIDGE, "category": "fridge", "label": "Холодильник Юки", "material": "METAL"}, YUKI_FRIDGE_POINT, 0.0)
	if fridge == null:
		push_error("Could not place Yuki's fridge")
	else:
		fridge.set_parameter("pickable", true)
		fridge.set_parameter("mass", 1.0)
		for entry in make_snapshot()["entities"]:
			if entry["id"] == YUKI_FRIDGE:
				_initial_yuki_fridge = entry
	var panel := YukiPanel.new()
	$Interface.add_child(panel)
	_yuki_panel = panel


func _near_yuki() -> bool:
	var friend_body := entities.get_entity(City.YUKI) as EntityBody
	return observation_fixture and friend_body != null and City.WORKSHOP.has_point(actor.position) and City.WORKSHOP.has_point(friend_body.position) and friend_body.get_parameter("alive") and _within_reach(friend_body.position, friend_body.motion.elevation) and (actor as EntityBody).accepts_player_input()


func _yuki_action() -> String:
	if not _near_yuki():
		return ""
	if yuki.ownership == 0:
		return "Одолжить ноутбук Юки"
	if yuki.ownership == 1 and yuki.observed and not yuki.has_active_cat_rule():
		return "Обсудить эксперимент с Юки"
	return ""


func _interact_yuki() -> bool:
	match _yuki_action():
		"Одолжить ноутбук Юки":
			yuki.ownership = 1
			return true
		"Обсудить эксперимент с Юки":
			yuki.ownership = 2
			social.complete("YUKI")
			return true
	return false


func return_yuki_loan() -> bool:
	if yuki.ownership != 1 or not _near_yuki():
		return false
	yuki.ownership = 0
	return true


func _yuki_host_allowed(body: EntityBody) -> bool:
	return body != null and body.record.category in ["fridge", "prop", "cat", "fox", "ray", "trollik", "crab", "turtle", "mirror_snail"]


func yuki_nearby_hosts() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for identity in entities.list_ids():
		var body := entities.get_entity(identity) as EntityBody
		if _yuki_host_allowed(body) and body.location_id == _entity_location(actor.position) and _within_reach(body.position, body.motion.elevation):
			result.append({"id": identity, "label": body.record.display_name + "  (" + identity + ")"})
	return result


func install_yuki_rule(host: String, source: String) -> bool:
	if not observation_fixture or yuki.ownership == 0 or not (actor as EntityBody).accepts_player_input():
		return false
	if not host.is_empty() and not yuki_nearby_hosts().any(func(item): return item["id"] == host):
		return false
	return yuki.install(host, source)


func set_yuki_running(enabled: bool) -> bool:
	if yuki.ownership == 0:
		return false
	yuki.running = enabled
	return true


func _execute_yuki_rule(rule: Dictionary) -> bool:
	var host: String = rule["host"]
	var body := entities.get_entity(host) as EntityBody
	if not host.is_empty() and not _yuki_host_allowed(body):
		return false
	if rule["action"] == "SPAWN_CAT":
		return _yuki_spawn_cat()
	if body == null:
		return false
	var key: String = {"SET_SPEED": "speed", "SET_ALIVE": "alive", "SET_AI": "ai_enabled"}.get(rule["action"], "")
	return not key.is_empty() and commands.execute_set(body, key, rule["value"], ENTITY_ID, "yuki:rule")


func _yuki_spawn_cat() -> bool:
	if yuki.spawn_serial >= YukiProgram.MAX_CATS:
		return false
	var id := YUKI_CAT_PREFIX + str(yuki.spawn_serial + 1)
	for index in YUKI_CAT_POINTS.size():
		var point: Vector2 = YUKI_CAT_POINTS[(yuki.spawn_serial + index) % YUKI_CAT_POINTS.size()]
		var cat := spawn_entity({"id": id, "category": "cat", "label": "Котик", "material": "FABRIC"}, point, 0.0)
		if cat != null:
			yuki.spawn_serial += 1
			# New bodies use the ordinary size parameter and physical checks.
			cat.set_parameter("size", [0.5, 0.8, 1.2, 1.6][(yuki.spawn_serial - 1) % 4])
			return true
	return false


func _tick_yuki(delta: float) -> void:
	if not observation_fixture:
		return
	yuki.advance(delta * WorldClock.MINUTES_PER_SIM_SECOND, _execute_yuki_rule)
	if yuki.ownership != 1 or yuki.observed:
		return
	for identity in entities.list_ids():
		if identity.begins_with(YUKI_CAT_PREFIX):
			var cat := entities.get_entity(identity) as EntityBody
			if cat.location_id == _entity_location(actor.position) and _within_reach(cat.position, cat.motion.elevation):
				yuki.observed = true
				return


func _open_yuki() -> bool:
	if yuki.ownership == 0 or not is_instance_valid(_yuki_panel) or not (actor as EntityBody).accepts_player_input() or is_instance_valid(_debug_editor):
		return false
	_active_city_tool = "yuki"
	_yuki_panel.open_for(self)
	apply_player_input(Vector2.ZERO)
	return true


const OriCatalog = preload("res://scripts/runtime2d/ori_catalog_2d.gd")
const OriPanel = preload("res://scripts/skeleton/ori_panel_2d.gd")
const ORI_GLOW_DONOR := "C3_GLOW_LIZARD"
const ORI_FLY_DONOR := "C3_FLY_RAY"
const ORI_CUSTOMER := "C3_CUSTOMER"
const ORI_GLOW_INSTANCE := "GLOW_C3_LIZARD"
const ORI_FLY_INSTANCE := "FLY_C3_RAY"
const ORI_MODULES := {ORI_GLOW_INSTANCE: "GLOW", ORI_FLY_INSTANCE: "FLY"}
const ORI_CREATED_PREFIX := "ORI_CREATED_"
var ori := OriCatalog.new()
var _ori_panel: PanelContainer
var _initial_ori_states: Array[Dictionary] = []
var _active_city_tool := ""


func _setup_ori() -> void:
	for definition in [
		{"id": ORI_GLOW_DONOR, "category": "lizard", "label": "Неоновая ящерка", "material": "FABRIC", "point": Vector2(5950, 590), "module": ORI_GLOW_INSTANCE},
		{"id": ORI_FLY_DONOR, "category": "ray", "label": "Скат", "material": "FABRIC", "point": Vector2(6125, 595), "module": ORI_FLY_INSTANCE},
		{"id": ORI_CUSTOMER, "category": "resident", "label": "Посетитель", "material": "FABRIC", "point": Vector2(6110, 675), "module": ""}
	]:
		var resident := spawn_entity(definition, definition["point"], 0.0)
		if resident == null:
			push_error("Could not place Ori shop resident " + definition["id"])
			continue
		resident.set_parameter("behavior_mode", "IDLE")
		if not definition["module"].is_empty():
			resident.record.set_component("ABILITY_SET", {"instances": {definition["module"]: {"ability_id": ORI_MODULES[definition["module"]], "enabled": true, "protected": false}}})
	for state in make_snapshot()["entities"]:
		if state["id"] in [ORI_GLOW_DONOR, ORI_FLY_DONOR, ORI_CUSTOMER]:
			_initial_ori_states.append(state)
	var panel := OriPanel.new()
	$Interface.add_child(panel)
	_ori_panel = panel


func _near_ori() -> bool:
	var friend_body := entities.get_entity(City.ORI) as EntityBody
	return observation_fixture and ecology_fixture and friend_body != null and City.SHOP.has_point(actor.position) and City.SHOP.has_point(friend_body.position) and friend_body.get_parameter("alive") and _within_reach(friend_body.position, friend_body.motion.elevation) and (actor as EntityBody).accepts_player_input()


func _ori_action() -> String:
	if not _near_ori():
		return ""
	if ori.ownership == 0:
		return "Одолжить Каталог Ори"
	return ""


func _interact_ori() -> bool:
	match _ori_action():
		"Одолжить Каталог Ори":
			ori.ownership = 1
			_tick_ori()
			return true
	return false


func return_ori_loan() -> bool:
	if ori.ownership != 1 or not _near_ori():
		return false
	ori.ownership = 0
	return true


func _tick_ori() -> void:
	if not observation_fixture or not ecology_fixture:
		return
	var location := _entity_location(actor.position)
	var customer := entities.get_entity(ORI_CUSTOMER) as EntityBody
	for identity in entities.list_ids():
		var body := entities.get_entity(identity) as EntityBody
		if body == null or body.location_id != location or not body.visible or not body.get_parameter("alive"):
			continue
		if _within_reach(body.position, body.motion.elevation):
			ori.discover(body.record.category)
		if ori.order_id.is_empty() and ori.ownership > 0 and customer != null and identity.begins_with(ORI_CREATED_PREFIX) and body.record.category == "cat" and body.get_parameter("luna_relation") == "FRIEND" and body.has_active_ability("GLOW") and City.SHOP.has_point(customer.position) and City.SHOP.has_point(body.position) and body.position.distance_to(customer.position) <= 50.0 and _within_reach(customer.position, customer.motion.elevation):
			ori.order_id = identity
			social.complete("ORI")
			$Interface/SaveNotice.text = "Ори: А кого бы ты придумала для себя?"


func _can_extract_ori(target: EntityBody) -> bool:
	return ori.ownership > 0 and target != null and target != actor and target.get_parameter("alive") and target.visible and target.location_id == _entity_location(actor.position) and _within_reach(target.position, target.motion.elevation) and wand_policy.authorize(actor, target, _entity_location(actor.position), projection, access, parameters, "mass")


func request_extract_ori(target_id: String, instance_id: String) -> bool:
	var target := entities.get_entity(target_id) as EntityBody
	return ORI_MODULES.has(instance_id) and _can_extract_ori(target) and ability_bank.move_instance(ENTITY_ID, target_id, instance_id, true)


func catalog_create(data: Dictionary) -> String:
	if ori.ownership == 0 or not ecology_fixture or not (actor as EntityBody).accepts_player_input() or not actor.motion.grounded or not ori.valid_template(data) or ori.serial >= OriCatalog.MAX_CREATIONS:
		return ""
	var identity := ORI_CREATED_PREFIX + str(ori.serial + 1)
	var form: String = data["form"]
	var location := _entity_location(actor.position)
	for offset in [Vector2(42, 0), Vector2(-42, 0), Vector2(0, 42), Vector2(0, -42), Vector2(50, 45), Vector2(-50, 45)]:
		var point: Vector2 = actor.position + offset
		# The four ordinary city interiors share the city ID but not geometry.
		if _entity_location(point) != location:
			continue
		var creature := spawn_entity({"id": identity, "category": form, "label": OriCatalog.FORMS[form], "material": "FABRIC"}, point, actor.motion.elevation)
		if creature == null:
			continue
		ori.serial += 1
		ori.template = data.duplicate(true)
		creature.set_parameter("size", float(data["size"]))
		creature.set_parameter("luna_relation", data["relation"])
		if data["relation"] == "FRIEND":
			creature.set_parameter("behavior_mode", "FOLLOW")
		var bank: Dictionary = actor.record.get_component("ABILITY_BANK").get("instances", {})
		for instance_id in bank:
			if ORI_MODULES.get(instance_id, "") == data["ability"] and not str(data["ability"]).is_empty():
				if ability_bank.move_instance(ENTITY_ID, identity, instance_id, false) and data["ability"] == "FLY":
					creature.set_parameter("rideable", true)
				break
		return identity
	return ""


func catalog_repeat() -> String:
	return catalog_create(ori.template)


func _open_ori() -> bool:
	if ori.ownership == 0 or not is_instance_valid(_ori_panel) or not (actor as EntityBody).accepts_player_input() or is_instance_valid(_debug_editor):
		return false
	_active_city_tool = "ori"
	_ori_panel.open_for(self)
	apply_player_input(Vector2.ZERO)
	return true


func _spawn_city() -> void:
	for definition in City.DEFINITIONS:
		var body := spawn_entity(definition, definition["point"], definition["height"])
		if body == null:
			push_error("Could not place city entity " + definition["id"])
			continue
		match body.entity_id:
			City.BREAD:
				body.set_parameter("size", 0.45)
				body.set_parameter("mass", 0.15)
				body.set_parameter("pickable", true)
				body.set_parameter("behavior_mode", "WANDER")
			City.BENCH:
				body.set_parameter("alive", true)
				body.set_parameter("behavior_mode", "IDLE")
				body.set_parameter("size", 1.3)
				body.set_parameter("speed", 0.6)
				body.set_parameter("mass", 4.0)
			City.CAT:
				body.set_parameter("size", 0.6)
				body.set_parameter("speed", 0.7)
			City.RAY:
				body.set_parameter("size", 0.65)
				body.set_parameter("speed", 0.75)
				body.set_parameter("behavior_mode", "IDLE")
			City.TOFFI, City.YUKI, City.ORI:
				body.set_parameter("behavior_mode", "IDLE")
			City.CRATE:
				body.set_parameter("mass", 1.3)
				body.set_parameter("pickable", true)
	for entry in make_snapshot()["entities"]:
		for definition in City.DEFINITIONS:
			if entry["id"] == definition["id"]:
				_initial_city_states.append(entry)


func _tick_city() -> void:
	if not observation_fixture:
		return
	var bench := entities.get_entity(City.BENCH) as EntityBody
	if bench != null and city_bench_active and bench.get_parameter("alive") and bench.get_parameter("ai_enabled") \
			and not bench.is_attached() and City.PLAZA.merge(City.STREET).merge(City.STATION).has_point(bench.position):
		var target: Vector2 = City.BENCH_ROUTE[city_bench_step]
		if bench.position.distance_to(target) <= 5.0 and bench.motion.grounded:
			city_bench_step = (city_bench_step + 1) % City.BENCH_ROUTE.size() if city_bench_step != City.BENCH_ROUTE.size() - 1 else city_bench_step
			target = City.BENCH_ROUTE[city_bench_step]
		bench.autonomous_destination = target
		if City.STREET.merge(City.PLAZA).has_point(actor.position) and bench.position.distance_to(actor.position) <= 150.0 \
				and bench.direction.length_squared() > 0.05:
			city_bench_observed = true
	elif bench != null:
		bench.autonomous_destination = Vector2.INF
	var ray := entities.get_entity(City.RAY) as EntityBody
	if ray != null and not city_ray_settled and City.STATION.has_point(actor.position) and ray.get_parameter("ai_enabled") \
			and not ray.is_attached():
		if ray.position.distance_to(City.RAY_REST) <= 5.0 and ray.motion.grounded:
			city_ray_settled = true
			ray.autonomous_destination = Vector2.INF
		else:
			ray.autonomous_destination = City.RAY_REST


func _city_door_action() -> Dictionary:
	if not observation_fixture or not actor.motion.grounded or actor.is_attached():
		return {}
	for door in City.DOORS:
		var outside: Vector2 = door["outside"]
		var inside: Vector2 = door["inside"]
		if actor.position.distance_to(outside) <= 21.0 and absf(actor.motion.elevation) < 1.0:
			return {"point": inside, "address": door["address"], "label": "Войти: " + door["name"]}
		if actor.position.distance_to(inside) <= 21.0 and absf(actor.motion.elevation) < 1.0:
			return {"point": outside, "address": City.CITY_ID, "label": "Выйти на улицу"}
	return {}


func _city_station_destination() -> String:
	if not observation_fixture or not public_ride_requested.is_valid() or not actor.motion.grounded or actor.is_attached():
		return ""
	if actor.position.distance_to(City.MEADOWS_STATION) <= 22.0 and is_zero_approx(actor.motion.elevation):
		return City.CITY_ID
	if actor.position.distance_to(City.BOARD) <= 22.0 and is_zero_approx(actor.motion.elevation):
		return Meadows.LOCATION_ID
	return ""


func _city_friend_action() -> String:
	if not observation_fixture or not actor.motion.grounded or actor.is_attached():
		return ""
	var toffi := entities.get_entity(City.TOFFI) as EntityBody
	var ray := entities.get_entity(City.RAY) as EntityBody
	if toffi != null and ray != null and City.STATION.has_point(actor.position) and City.STATION.has_point(toffi.position) \
			and toffi.get_parameter("alive") and _within_reach(toffi.position, toffi.motion.elevation) \
			and city_ray_settled and ray.position.distance_to(City.RAY_REST) <= 15.0:
		return "Посмотреть на ската с Тоффи"
	var yuki_body := entities.get_entity(City.YUKI) as EntityBody
	if yuki_body != null and City.WORKSHOP.has_point(actor.position) and City.WORKSHOP.has_point(yuki_body.position) \
			and yuki_body.get_parameter("alive") and _within_reach(yuki_body.position, yuki_body.motion.elevation) and city_bench_observed and city_bench_active:
		return "Обсудить скамейку с Юки"
	return ""


func _city_friend_interact(action: String) -> bool:
	if action != _city_friend_action():
		return false
	if action == "Посмотреть на ската с Тоффи":
		social.complete("TOFFI")
		$Interface/SaveNotice.text = "Тоффи: Ну всё, теперь у них собрание."
		return true
	if action == "Обсудить скамейку с Юки":
		city_bench_active = false
		var bench := entities.get_entity(City.BENCH) as EntityBody
		if bench != null:
			bench.autonomous_destination = Vector2.INF
		social.complete("YUKI")
		$Interface/SaveNotice.text = "Юки: Кажется, скамейка решила дождаться рейса."
		return true
	return false


func _spawn_oni() -> void:
	var oni := spawn_entity({"id": Visits.ONI_ID, "category": "oni", "label": "Они", "material": "FABRIC"}, Visits.LAKE, 0.0)
	if oni == null:
		push_error("Could not place Oni")
		return
	oni.set_parameter("behavior_mode", "IDLE")
	oni.set_parameter("speed", 1.25)
	oni.set_parameter("color", Color("efb68e"))
	for entry in make_snapshot()["entities"]:
		if entry["id"] == Visits.ONI_ID:
			_initial_oni = entry


func _tick_oni() -> void:
	var oni := entities.get_entity(Visits.ONI_ID) as EntityBody
	if oni == null or not oni.get_parameter("ai_enabled") or oni.is_attached() or oni.has_passenger():
		return
	var towards_cape := world_clock.phase() in [WorldClock.Phase.DAY, WorldClock.Phase.EVENING]
	var last := Visits.ROUTE.size() - 1
	var target: Vector2 = Visits.ROUTE[oni_route_index]
	if oni.motion.grounded and oni.position.distance_to(target) < 5.0:
		var next := clampi(oni_route_index + (1 if towards_cape else -1), 0, last)
		if next == oni_route_index:
			oni.autonomous_destination = Vector2.INF
			return
		oni_route_index = next
		target = Visits.ROUTE[oni_route_index]
	oni.autonomous_destination = target


func _oni_site() -> String:
	if not observation_fixture or not actor.motion.grounded or actor.is_attached():
		return ""
	var oni := entities.get_entity(Visits.ONI_ID) as EntityBody
	if oni == null or not oni.motion.grounded or oni.is_attached() or not _within_reach(oni.position, oni.motion.elevation):
		return ""
	if oni.position.distance_to(Visits.LAKE) <= 10.0 and _entity_location(actor.position) == Valley.LOCATION_ID:
		return "W1"
	if oni.position.distance_to(Visits.CAPE) <= 10.0 and Coast.CAPE.has_point(actor.position):
		return "K6"
	return ""


func _observe_with_oni() -> bool:
	var site := _oni_site()
	if site.is_empty():
		return false
	var fresh := social.observe_with_oni(site)
	if fresh:
		if site == "W1":
			$Interface/SaveNotice.text = "Они: Смотри, отражение и берег. Как любопытно." if world_clock.phase() != WorldClock.Phase.EVENING else "Они: Теперь башня и на берегу, и в воде."
		else:
			$Interface/SaveNotice.text = "Они: Иногда мне кажется, море помнит, каким был берег. Сейчас " + ("отлив." if _coast_tide.surface < 1.0 else "вода поднялась.")
		if social.oni_sites.size() == 2 and not social.prism_owned:
			social.prism_owned = true
			$Interface/SaveNotice.text = "Они: Возьми эту Призму. Мне интересно, что ты обнаружишь."
	else:
		$Interface/SaveNotice.text = "Они: Хорошо здесь, правда?"
	return true


func _setup_flute() -> void:
	_note_audio = AudioStreamPlayer.new()
	add_child(_note_audio)
	for letter in Music.GLYPHS:
		_tones[letter] = Music.tone(letter)


func _can_take_flute() -> bool:
	return observation_fixture and not flute_owned and actor.motion.grounded \
		and _entity_location(actor.position) == ForestBank.LOCATION_ID \
		and actor.position.distance_to(Visits.FLUTE) <= 22.0


func _take_flute() -> bool:
	if not _can_take_flute():
		return false
	flute_owned = true
	queue_redraw()
	return true


func toggle_prism() -> bool:
	if not social.prism_owned or is_instance_valid(_debug_editor):
		return false
	prism_active = not prism_active
	queue_redraw()
	return true


func _set_music_focus(active: bool) -> bool:
	if active and (not flute_owned or not (actor as EntityBody).accepts_player_input() or actor.is_attached() \
			or not actor.motion.grounded or is_instance_valid(_debug_editor)):
		return false
	music_focus = active
	music.clear()
	apply_player_input(Vector2.ZERO)
	return true


func _play_note(letter: String) -> bool:
	if not music_focus or not music.note(letter):
		return false
	if _note_audio != null:
		_note_audio.stream = _tones[letter]
		_note_audio.play()
	return true


func perform_music(phrase: String) -> bool:
	if not flute_owned or not (actor as EntityBody).accepts_player_input() \
			or actor.is_attached() or actor.has_passenger() or not actor.motion.grounded:
		return false
	match Music.resolve(phrase):
		"M02":
			_attraction.start()
			return true
		"M03":
			if _music_original_scale > 0.0:
				return true
			var prior: float = actor.body_size
			if not actor.set_parameter("size", minf(prior, 0.5)):
				return false
			_music_original_scale = prior
			return true
		"M04":
			if _music_original_scale <= 0.0 or not actor.set_parameter("size", _music_original_scale):
				return false
			_music_original_scale = 0.0
			return true
		"M06":
			for point in [CoastExtra.HIGH_VIEW, Vector2(2410, 818), Vector2(2430, 818)]:
				if _ordinary_arrival_is_safe(Coast.LOCATION_ID, point, 18.0):
					_move_home_travelers(point, Coast.LOCATION_ID, 18.0)
					return true
	return false


func _tick_music(delta: float) -> void:
	_attraction.tick(delta)
	for identity in entities.list_ids():
		var animal := entities.get_entity(identity) as EntityBody
		animal.music_interest = Vector2.INF
		if _attraction.remaining <= 0.0 or animal.record.category not in ["fox", "trollik", "crab", "turtle", "mirror_snail"] \
				or animal.location_id != _entity_location(actor.position) or animal.position.distance_to(actor.position) > 160.0 \
				or not animal.get_parameter("alive") or not animal.visible:
			continue
		animal.music_interest = actor.position


func _spawn_coastal_life() -> void:
	var mia := spawn_entity({"id": Life.MIA_ID, "category": "mia", "label": "Мия", "material": "FABRIC"}, Life.MIA_START, 0.0)
	if mia != null:
		mia.set_parameter("behavior_mode", "IDLE")
		mia.set_parameter("speed", 1.0)
		mia.set_parameter("color", Color("8ed7bd"))
	for identity in Life.FAUNA:
		var category: String = Life.FAUNA_CATEGORY[identity]
		var animal := spawn_entity({"id": identity, "category": category,
			"label": "Краб" if category == "crab" else "Черепаха", "material": "FABRIC"}, Life.FAUNA[identity], 0.0)
		if animal != null:
			animal.set_parameter("size", 0.55 if category == "crab" else 0.7)
			animal.set_parameter("speed", 0.45 if category == "crab" else 0.24)
	# These are dry at low tide, wet at high tide. Spawn on real existing floor,
	# before reapplying water to the shallow basin.
	var water_level := _pool_water.surface
	_pool_water.surface = 0.0
	var shell := spawn_entity({"id": Life.SHELL_ID, "category": "prop", "label": "Пустая ракушка", "material": "STONE"}, Life.SHELL_START, 0.0)
	var stone := spawn_entity({"id": Life.STONE_ID, "category": "prop", "label": "Морской камень", "material": "STONE"}, Life.STONE_START, 0.0)
	_pool_water.surface = water_level
	if shell != null:
		shell.set_parameter("mass", 0.25)
		shell.set_parameter("size", 0.55)
		shell.set_parameter("pickable", true)
		shell.configure_water(1.2, false)
	if stone != null:
		stone.set_parameter("mass", 5.0)
		stone.set_parameter("size", 0.6)
	for entry in make_snapshot()["entities"]:
		if entry["id"] in [Life.MIA_ID, Life.SHELL_ID, Life.STONE_ID] or Life.FAUNA.has(entry["id"]):
			_initial_life_states.append(entry)


func _take_hourglass() -> bool:
	if hourglass_owned or not observation_fixture or _entity_location(actor.position) != Coast.HOUSE_ID \
			or not actor.motion.grounded or actor.position.distance_to(Life.HOURGLASS_POINT) > 20.0:
		return false
	hourglass_owned = true
	queue_redraw()
	return true


func cycle_hourglass() -> bool:
	if not hourglass_owned or is_instance_valid(_debug_editor):
		return false
	var modes := [WorldClock.SLOW, WorldClock.NORMAL, WorldClock.FAST]
	return world_clock.set_mode(modes[(modes.find(world_clock.mode) + 1) % modes.size()])


func _borrow_flask() -> bool:
	if flask_state != 0 or not mia_experienced or not _at_alchemy_station():
		return false
	flask_state = 1
	mia_route_step = 0
	$Interface/SaveNotice.text = "Мия: Сюда! Здесь просто чудесно. Как доберёшься, покажу."
	queue_redraw()
	return true


func _mia_at_upper() -> bool:
	var mia := entities.get_entity(Life.MIA_ID) as EntityBody
	return flask_state == 1 and mia_route_step >= Life.MIA_ROUTE.size() and mia != null \
		and actor.motion.grounded and actor.motion.elevation >= 18.0 \
		and _within_reach(mia.position, mia.motion.elevation)


func _tick_mia() -> void:
	if flask_state != 1:
		return
	var mia := entities.get_entity(Life.MIA_ID) as EntityBody
	if mia == null or mia_route_step >= Life.MIA_ROUTE.size():
		return
	var target: Vector2 = Life.MIA_ROUTE[mia_route_step]
	if mia.position.distance_to(target) < 5.0 and mia.motion.grounded:
		mia_route_step += 1
		if mia_route_step >= Life.MIA_ROUTE.size():
			mia.autonomous_destination = Vector2.INF
			return
		target = Life.MIA_ROUTE[mia_route_step]
	mia.autonomous_destination = target


func _gift_flask() -> bool:
	if not _mia_at_upper():
		return false
	flask_state = 2
	$Interface/SaveNotice.text = "Мия: Оставь склянку себе!"
	return true


func _fill_flask(effect_id: String) -> void:
	if flask_state > 0 and effect_id in AlchemyPanel.IMPLEMENTED:
		flask_effect = effect_id
		_alchemy_panel.hide()
		$Interface/SaveNotice.text = "Состав в склянке: " + AlchemyPanel.Recipes.NAMES[effect_id]


func _update_lab_ice(active: bool) -> void:
	for surface in Life.ICE:
		if active and not _surfaces.has(surface):
			_surfaces.append(surface)
		elif not active:
			_surfaces.erase(surface)
	queue_redraw()


func _freeze_lab_water() -> bool:
	if not observation_fixture or actor.position.distance_to(MiaLab.SHALLOW.get_center()) > 115.0:
		return false
	_lab_ice.start()
	return true


func _setup_alchemy() -> void:
	var panel := AlchemyPanel.new()
	$Interface.add_child(panel)
	panel.try_effect.connect(_apply_lab_effect)
	panel.fill_effect.connect(_fill_flask)
	panel.borrow_requested.connect(_borrow_flask)
	_alchemy_panel = panel
	_alchemy_light = PointLight2D.new()
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color(1.0, 0.92, 0.65, 1.0), Color(1.0, 0.92, 0.65, 0.0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 256
	texture.height = 256
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	_alchemy_light.texture = texture
	_alchemy_light.energy = 1.1
	_alchemy_light.enabled = false
	add_child(_alchemy_light)


func _at_alchemy_station() -> bool:
	return observation_fixture and actor.motion.grounded and not actor.is_attached() \
		and MiaLab.LAB.has_point(actor.position) and _within_reach(MiaLab.STATION)


func _apply_lab_effect(effect_id: String) -> void:
	if not _at_alchemy_station():
		return
	if _apply_alchemy(effect_id):
		mia_experienced = true
		var mia := entities.get_entity(Life.MIA_ID) as EntityBody
		if mia != null and _within_reach(mia.position, mia.motion.elevation) and mia.get_parameter("alive"):
			social.complete("MIA")
			$Interface/SaveNotice.text = "Мия: Вот это да! Посмотри, что получилось."
		_alchemy_panel.configure_access(false, flask_state > 0, flask_state == 0)
		_alchemy_panel.hide()


func _apply_alchemy(effect_id: String) -> bool:
	match effect_id:
		"ALC-R08":
			_alchemy_glow.start()
		"ALC-R09":
			_alchemy_glow.restore(0.0)
			_clear_bubble()
			_lab_ice.restore(0.0)
		"ALC-R20":
			if not _freeze_lab_water():
				return false
		"ALC-R21":
			_alchemy_bubble.start()
			_bubble_started = false
			actor.temporary_swim = true
		"ALC-R30":
			world_clock.set_time_of_day(WorldClock.NIGHT_MINUTE)
		_:
			return false
	_update_alchemy_light()
	return true


func _clear_bubble() -> void:
	var was_active := _alchemy_bubble.remaining > 0.0 or actor.temporary_swim
	_alchemy_bubble.restore(0.0)
	_bubble_started = false
	actor.temporary_swim = false
	if was_active and not actor.is_attached() and not actor.can_swim() \
			and not actor._is_dry(actor.position, actor.motion.elevation):
		# The same previously reached dry anchor, never the far side of W5.
		actor._recover_after_carrier_loss()
		actor._update_rider_position()
		actor._sync_projection()
		for body in actor.map_travelers():
			(body as EntityBody).location_id = _entity_location(body.position)


func _tick_bubble(delta: float) -> void:
	if _alchemy_bubble.remaining <= 0.0:
		return
	actor.temporary_swim = true
	if not actor._is_dry(actor.position, actor.motion.elevation):
		_bubble_started = true
	if _bubble_started:
		_alchemy_bubble.tick(delta)
		if _alchemy_bubble.remaining <= 0.0:
			_clear_bubble()


func _update_alchemy_light() -> void:
	if _alchemy_light != null:
		_alchemy_light.position = actor.position - Vector2(0, actor.motion.elevation + 12.0)
		_alchemy_light.enabled = _alchemy_glow.remaining > 0.0


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


func _spawn_lake_stone() -> void:
	var stone := spawn_entity({"id": LAKE_STONE_ID, "category": "prop", "label": "Гладкий камень", "material": "STONE"},
		Lake.STONE_START, 0.0)
	if stone == null:
		return
	stone.set_parameter("pickable", true)
	stone.set_parameter("size", 0.55)
	stone.set_parameter("mass", 0.7)
	for entry in make_snapshot()["entities"]:
		if entry["id"] == LAKE_STONE_ID:
			_initial_lake_stone = entry


func _lake_wet(body: EntityBody) -> bool:
	return Lake.POOL.has_point(body.position) and not body._is_dry(body.position, body.motion.elevation)


func _lake_place_point() -> Vector2:
	if not observation_fixture or not actor.has_passenger() or not actor.motion.grounded:
		return Vector2.INF
	var item := actor._rider as EntityBody
	if item == null or not item.is_carried() or item.record.category != "prop" or item.entity_id == ECOLOGY_CATALOG:
		return Vector2.INF
	var point := Vector2(2507, clampf(actor.position.y, 405.0, 445.0))
	if point.distance_to(actor.position) > 58.0 or not Lake.SHALLOW_SURFACE["bounds"].has_point(point):
		return Vector2.INF
	return point


func _lake_spawn(identity: String, category: String, label_text: String, material: String) -> EntityBody:
	for point in Lake.BIRTH_POINTS:
		var body := spawn_entity({"id": identity, "category": category, "label": label_text, "material": material}, point, 0.0)
		if body != null:
			return body
	return null


func _spawn_lake_chibi() -> bool:
	for index in range(1, LAKE_CHIBI_LIMIT + 1):
		var identity := LAKE_CHIBI_PREFIX + str(index)
		if entities.get_entity(identity) != null:
			continue
		var chibi := _lake_spawn(identity, "chibi_luna", "Чиби-Луна", "FABRIC")
		if chibi == null:
			return false
		chibi.set_parameter("size", 0.5)
		chibi.set_parameter("speed", 0.65)
		chibi.set_parameter("color", actor.get_parameter("color"))
		return true
	return false


func _copy_lake_prop(source: EntityBody) -> bool:
	if source == null or source.record.category != "prop" or source.entity_id == ECOLOGY_CATALOG \
			or source.entity_id.begins_with(LAKE_PROP_PREFIX) or source.is_attached() or not _lake_wet(source):
		return false
	var identity := LAKE_PROP_PREFIX + source.entity_id
	if identity.length() > 96 or entities.get_entity(identity) != null:
		return false
	var count := 0
	for existing in entities.list_ids():
		if existing.begins_with(LAKE_PROP_PREFIX):
			count += 1
	if count >= LAKE_PROP_LIMIT:
		return false
	var copy := _lake_spawn(identity, "prop", source.record.display_name, source.get_parameter("material"))
	if copy == null:
		return false
	for parameter in ["size", "mass", "color", "pickable"]:
		copy.set_parameter(parameter, source.get_parameter(parameter))
	return true


func _tick_lake(delta: float) -> void:
	if not observation_fixture:
		return
	if _lake_wet(actor):
		if not _lake_entered:
			if _spawn_lake_chibi():
				_lake_entered = true
			_lake_elapsed = 0.0
		else:
			_lake_elapsed = minf(LAKE_INTERVAL, _lake_elapsed + delta)
			if _lake_elapsed >= LAKE_INTERVAL and _spawn_lake_chibi():
				_lake_elapsed = 0.0
	else:
		_lake_entered = false
		_lake_elapsed = 0.0
	for identity in entities.list_ids():
		var body := entities.get_entity(identity) as EntityBody
		if body.record.category == "prop" and _lake_wet(body):
			_copy_lake_prop(body)


func _spawn_mirror_snail() -> void:
	var snail := spawn_entity({"id": MIRROR_SNAIL, "category": "mirror_snail",
		"label": "Зеркальная улитка", "material": "FABRIC"}, MIRROR_BIRTH, 0.0)
	if snail == null:
		push_error("Could not place the mirror snail")
		return
	snail.set_parameter("size", 0.55)
	snail.set_parameter("speed", 0.18)
	snail.set_parameter("color", Color("99c1d9"))
	snail.record.set_component("ABILITY_SET", {"instances": {DUPLICATE_MODULE_ID: DUPLICATE_MODULE}})
	for entry in make_snapshot()["entities"]:
		if entry["id"] == MIRROR_SNAIL:
			_initial_mirror_state = entry


func _duplicate_holder() -> EntityBody:
	for identity in entities.list_ids():
		var body := entities.get_entity(identity) as EntityBody
		var module: Dictionary = body.record.get_component("ABILITY_SET").get("instances", {}).get(DUPLICATE_MODULE_ID, {})
		if module.get("enabled") == true and module.get("ability_id") == "DUPLICATE":
			return body
	return null


func _tick_duplicate(delta: float) -> void:
	if not ecology_fixture or not observation_fixture:
		return
	var source := _duplicate_holder()
	if source == null or not source.get_parameter("alive") or not source.visible \
			or not source.motion.grounded or source.is_attached() or source.has_passenger():
		_duplicate_elapsed = 0.0
		return
	# Budget the nearby living world; an unseen region is not populated to its
	# cap before its first visit. The timer is independent of gaze and camera.
	if source.location_id != _entity_location(actor.position) or source.position.distance_to(actor.position) > Gaze.EYE_RANGE:
		return
	_duplicate_elapsed = minf(DUPLICATE_INTERVAL, _duplicate_elapsed + delta)
	if _duplicate_elapsed >= DUPLICATE_INTERVAL and _duplicate_self(source):
		_duplicate_elapsed = 0.0


func _duplicate_self(source: EntityBody) -> bool:
	if source == null or source != _duplicate_holder() or not source.get_parameter("alive") \
			or source.record.category not in DUPLICATE_CATEGORIES or not source.motion.grounded \
			or source.is_attached() or source.has_passenger():
		return false
	var new_id := ""
	for index in range(1, DUPLICATE_LIMIT + 1):
		var candidate_id := DUPLICATE_PREFIX + str(index)
		if entities.get_entity(candidate_id) == null:
			new_id = candidate_id
			break
	if new_id.is_empty():
		return false
	for offset in [Vector2(36, 0), Vector2(-36, 0), Vector2(0, 36), Vector2(0, -36),
			Vector2(30, 30), Vector2(-30, -30)]:
		var point: Vector2 = source.position + offset
		if _entity_location(point) != source.location_id:
			continue
		var copy := spawn_entity({"id": new_id, "category": source.record.category,
			"label": source.record.display_name, "material": source.get_parameter("material")},
			point, source.motion.elevation)
		if copy == null:
			continue
		# Copy ordinary body appearance and movement. No rare module, bank,
		# ownership, attachment, control assignment or death timer is copied.
		for parameter in ["size", "speed", "color", "behavior_mode", "luna_relation"]:
			copy.set_parameter(parameter, source.get_parameter(parameter))
		return true
	return false


func _can_transfer_duplicate(target: EntityBody) -> bool:
	if not ecology_fixture or not observation_fixture or target == null or not _holds_ecology_catalog() \
			or target.record.category not in DUPLICATE_CATEGORIES or not target.get_parameter("alive") \
			or not target.visible or target.location_id != _entity_location(actor.position):
		return false
	return wand_policy.authorize(actor, target, _entity_location(actor.position), projection, access, parameters, "mass")


func request_extract_duplicate(target_id: String) -> bool:
	var target := entities.get_entity(target_id) as EntityBody
	return _can_transfer_duplicate(target) \
		and ability_bank.move_instance(ENTITY_ID, target_id, DUPLICATE_MODULE_ID, true)


func request_install_duplicate(target_id: String) -> bool:
	var target := entities.get_entity(target_id) as EntityBody
	return _can_transfer_duplicate(target) \
		and ability_bank.move_instance(ENTITY_ID, target_id, DUPLICATE_MODULE_ID, false)


func _create_entity_body(identity: String, category: String) -> EntityBody:
	if observation_fixture and Life.FAUNA.has(identity) and category == Life.FAUNA_CATEGORY[identity]:
		var animal := Fauna.new()
		animal.birth_point = Life.FAUNA[identity]
		animal.respawned.connect(fauna_respawned.emit)
		return animal
	if observation_fixture and ecology_fixture and identity == MIRROR_SNAIL and category == "mirror_snail":
		var snail := Fauna.new()
		snail.birth_point = MIRROR_BIRTH
		snail.respawned.connect(fauna_respawned.emit)
		return snail
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
	if not active and is_instance_valid(_yuki_panel):
		_yuki_panel.hide()
	if not active and is_instance_valid(_ori_panel):
		_ori_panel.hide()
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


# Only implemented ordinary locations have authored landing candidates.
# No address catalogue is exposed to the player, and a Feature ID is not a destination.
func _ordinary_arrival_points(address: String) -> Array[Vector2]:
	match address:
		City.CITY_ID:
			if observation_fixture:
				return [City.ARRIVAL, Vector2(4590, 410)]
		City.CAFE_ID:
			if observation_fixture:
				return [Vector2(5590, 390), Vector2(5650, 375)]
		City.HOME_ID:
			if observation_fixture:
				return [Vector2(5930, 390), Vector2(5990, 375)]
		ISLAND_ID:
			return [SPAWN, Vector2(410, 374)]
		Meadows.LOCATION_ID:
			return [Vector2(1285, 375), Vector2(1320, 375)]
		ForestBank.LOCATION_ID:
			if observation_fixture:
				return [Vector2(1950, 52), Vector2(2010, 90)]
		AncientConsole.LOCATION_ID:
			if ancient_console_enabled:
				return [AncientConsole.RETURN_POINT, Vector2(2350, 110)]
		Valley.LOCATION_ID:
			if observation_fixture:
				return [Vector2(2135, 300), Vector2(2210, 305)]
		Lake.LOCATION_ID:
			return [Lake.SHORE, Vector2(2360, 435)]
		Valley.CRYSTAL_ID:
			if observation_fixture:
				return [Valley.W7_ENTRY, Vector2(3000, 420)]
		Coast.LOCATION_ID:
			if observation_fixture:
				return [Coast.ENTRY, Coast.BEACH_ENTRY]
		Coast.GROTTO_ID:
			if observation_fixture:
				return [Coast.GROTTO_ENTRY]
	return []


func _ordinary_arrival_is_safe(address: String, point: Vector2, height: float = 0.0) -> bool:
	if _entity_location(point) != address or not can_return_traveler(point, height) or not actor._is_dry(point, height):
		return false
	var travelers := actor.map_travelers()
	for identity in entities.list_ids():
		var other := entities.get_entity(identity) as EntityBody
		if other == null or other in travelers:
			continue
		for body in travelers:
			if other.position.distance_to(point) < other.foot_radius() + body.foot_radius():
				return false
	if actor.has_passenger():
		var rider := actor._rider
		var feet: float = height + actor._attachment_height(rider._carried)
		if not rider.fits_walls_at(point, feet, rider.foot_radius()):
			return false
	return true


func teleport_known_location(address: String) -> bool:
	if not at_ancient_console() or access.wand_mode == AccessState.ORDINARY:
		return false
	for point in _ordinary_arrival_points(address):
		if not _ordinary_arrival_is_safe(address, point):
			continue
		_move_home_travelers(point, address)
		return true
	return false


func _move_home_travelers(point: Vector2, address: String, height: float = 0.0) -> void:
	actor.position = point
	actor.motion.reset_on_surface(point, height)
	actor.direction = Vector2.ZERO
	actor.velocity = Vector2.ZERO
	actor._impulse_velocity = Vector2.ZERO
	actor.thrust_requested = false
	actor.swim_intent = 0.0
	actor._update_rider_position()
	for body in actor.map_travelers():
		(body as EntityBody).location_id = address
		body._sync_projection()
	_update_local_camera()
	_camera.reset_smoothing()
	_update_world_light()


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
	if not actor.direction.is_zero_approx():
		crystal_observer.facing = actor.direction.normalized()
	_sync_crystal_observation()
	if not is_instance_valid(_debug_editor):
		world_clock.advance(delta)
		donut_refill = maxf(0.0, donut_refill - delta)
		_ice_duration.tick(delta)
		_alchemy_glow.tick(delta)
		_tick_bubble(world_clock.sim_delta(delta))
		_tick_duplicate(world_clock.sim_delta(delta))
		_tick_lake(world_clock.sim_delta(delta))
		_lab_ice.tick(world_clock.sim_delta(delta))
		_tick_mia()
		_tick_oni()
		_tick_city()
		_tick_yuki(world_clock.sim_delta(delta))
		_tick_ori()
		_tick_music(world_clock.sim_delta(delta))
		_update_yeti_route()
		_refresh_plank_surface()
	_update_alchemy_light()
	if _alchemy_panel != null and _alchemy_panel.visible and not _at_alchemy_station() and flask_state == 0:
		_alchemy_panel.hide()
	var at_bank := _at_forest_bank()
	if _was_at_bank and not at_bank:
		forest_bank_left.emit()
	_was_at_bank = at_bank
	_update_local_camera()
	var area: String = AREA_LABELS[_entity_location(actor.position)]
	var local_phase: int = coast_house_phase if _entity_location(actor.position) == Coast.HOUSE_ID else world_clock.phase()
	_world_light.color = PHASE_TINTS[local_phase]
	var wand := "Обычная палочка" if access.wand_mode == AccessState.ORDINARY else access.wand_mode
	_status.text = "%s  ·  %s  ·  %s" % [area, PHASE_LABELS[local_phase], wand]
	if has_donut:
		_status.text += "  ·  Пончик"
	if freeze_selected:
		_status.text += "  ·  Заморозка"
	if not crystal_observer.luna_eyes_open:
		_status.text += "  ·  Глаза закрыты"
	if _alchemy_bubble.remaining > 0.0:
		_status.text += "  ·  Пузырь %d" % ceili(_alchemy_bubble.remaining)
	if flute_owned:
		_status.text += "  ·  M: свирель"
	if social.prism_owned:
		_status.text += "  ·  P: Призма" + (" ✓" if prism_active else "")
	if music_focus:
		_status.text += "  ·  " + Music.arrows(music.phrase) + "  Enter"
	if hourglass_owned:
		_status.text += "  ·  H " + world_clock.mode
	if flask_state > 0:
		_status.text += "  ·  Enter: склянка"
	if yuki.ownership > 0:
		_status.text += "  ·  J: ноутбук"
	if ori.ownership > 0:
		_status.text += "  ·  K: Каталог, L: повтор"
	if restriction_text.is_valid():
		_status.text += restriction_text.call()
	var action := _nearby_action()
	_prompt.text = "" if action.is_empty() or is_instance_valid(_debug_editor) \
		or (ancient_console != null and ancient_console.is_open()) else "E  " + action


func _update_local_camera() -> void:
	if observation_fixture:
		for room in [City.CAFE, City.ROOM, City.WORKSHOP, City.SHOP]:
			if room.has_point(actor.position):
				_camera.position = room.get_center()
				_camera.zoom = Vector2(2.25, 2.25)
				return
	_camera.position = actor.position
	_camera.zoom = Vector2(1.25, 1.25)


func _apply_keyboard_input() -> void:
	if (is_instance_valid(_yuki_panel) and _yuki_panel.visible) or (is_instance_valid(_ori_panel) and _ori_panel.visible):
		apply_player_input(Vector2.ZERO)
		return
	if music_focus:
		apply_player_input(Vector2.ZERO)
		return
	if _alchemy_panel != null and _alchemy_panel.visible:
		apply_player_input(Vector2.ZERO)
		return
	if ancient_console != null and ancient_console.is_open():
		if at_ancient_console():
			apply_player_input(Vector2.ZERO)
			return
		ancient_console.close()
	super._apply_keyboard_input()
	for identity in entities.list_ids():
		var body := entities.get_entity(identity) as EntityBody
		if body.accepts_player_input():
			body.swim_intent = float(Input.is_physical_key_pressed(KEY_SPACE)) - float(Input.is_physical_key_pressed(KEY_SHIFT))


func _update_world_light(_minute: int = 0) -> void:
	if _coast_tide != null:
		_coast_tide.surface = Coast.tide_height(world_clock.minute_of_day())
	if _pool_water != null:
		_pool_water.surface = Coast.tide_height(world_clock.minute_of_day()) * 8.0 / 30.0
	var phase: int = world_clock.phase()
	if observation_fixture and is_instance_valid(actor) and Coast.HOUSE_ROOM.has_point(actor.position):
		phase = coast_house_phase
	_world_light.color = PHASE_TINTS[phase]
	queue_redraw()


func _tower_action() -> String:
	if not observation_fixture or not actor.motion.grounded or actor.is_attached():
		return ""
	if _entity_location(actor.position) == Valley.TOWER_ID:
		if _within_reach(Valley.TOWER_ENTRY):
			return "Выйти из Башни"
	elif Valley.W3_SITE.has_point(actor.position) and _within_reach(Valley.W3_VIEW) \
			and world_clock.phase() == WorldClock.Phase.EVENING:
		return "Войти в Башню"
	return ""


func _use_tower_door(entering: bool) -> bool:
	if entering and world_clock.phase() != WorldClock.Phase.EVENING:
		return false
	var point := Valley.TOWER_ENTRY if entering else Valley.W3_VIEW
	var address := Valley.TOWER_ID if entering else Valley.LOCATION_ID
	if not _ordinary_arrival_is_safe(address, point):
		return false
	_move_home_travelers(point, address)
	return true


func _coast_house_action() -> String:
	if not observation_fixture or not actor.motion.grounded or actor.is_attached():
		return ""
	var inside := Coast.HOUSE_ROOM.has_point(actor.position)
	if inside:
		if _within_reach(Coast.DIAL_INSIDE):
			return "Повернуть циферблат"
		if _within_reach(Coast.HOUSE_INSIDE):
			return "Выйти из дома"
	elif Coast.HOUSE_VERANDA.has_point(actor.position):
		if _within_reach(Coast.DIAL_OUTSIDE):
			return "Повернуть циферблат"
		if _within_reach(Coast.HOUSE_OUTSIDE):
			return "Войти в дом" if coast_house_phase == world_clock.phase() else ""
	return ""


func _use_coast_house_door(entering: bool) -> bool:
	if entering and coast_house_phase != world_clock.phase():
		return false
	var point := Coast.HOUSE_INSIDE if entering else Coast.HOUSE_OUTSIDE
	var address := Coast.HOUSE_ID if entering else Coast.LOCATION_ID
	if not _ordinary_arrival_is_safe(address, point):
		return false
	_move_home_travelers(point, address)
	return true


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


func _tunnel_action() -> String:
	if not observation_fixture or actor.is_attached() or actor.has_passenger():
		return ""
	if Tunnel.WEST.has_point(actor.position) and _within_reach(Tunnel.WEST_EXIT):
		return "К тихому озеру"
	if Tunnel.EAST.has_point(actor.position) and _within_reach(Tunnel.EAST_EXIT):
		return "К Озеру Дубликатов"
	if not actor.can_swim() or actor.motion.elevation > -12.0:
		return ""
	if Valley.ORDINARY_POOL.has_point(actor.position) and _within_reach(Tunnel.W1_MOUTH, -24.0):
		return "Нырнуть в тоннель"
	if Lake.POOL.has_point(actor.position) and _within_reach(Tunnel.W6_MOUTH, -24.0):
		return "Нырнуть в обратный тоннель"
	return ""


func _use_tunnel(point: Vector2, address: String) -> bool:
	if not _ordinary_arrival_is_safe(address, point):
		return false
	_move_home_travelers(point, address)
	return true


func _nearby_action() -> String:
	var city_door := _city_door_action()
	if not city_door.is_empty():
		return city_door["label"]
	var station := _city_station_destination()
	if not station.is_empty():
		return "Рейс в Люму" if station == City.CITY_ID else "Рейс на Большие луга"
	var friend_action := _city_friend_action()
	if not friend_action.is_empty():
		return friend_action
	var yuki_action := _yuki_action()
	if not yuki_action.is_empty():
		return yuki_action
	var ori_action := _ori_action()
	if not ori_action.is_empty():
		return ori_action
	var tunnel_action := _tunnel_action()
	if not tunnel_action.is_empty():
		return tunnel_action
	if observation_fixture and not hourglass_owned and actor.motion.grounded \
			and _entity_location(actor.position) == Coast.HOUSE_ID and actor.position.distance_to(Life.HOURGLASS_POINT) <= 20.0:
		return "Взять Песочные часы"
	if _mia_at_upper():
		return "Поговорить с Мией"
	if _can_take_flute():
		return "Взять свирель"
	if not _oni_site().is_empty():
		return "Посмотреть вместе с Они"
	if _at_alchemy_station():
		return "Алхимическая установка"
	if at_ancient_console():
		return "Осмотреть Древнюю Консоль"
	var tower_action := _tower_action()
	if not tower_action.is_empty():
		return tower_action
	var house_action := _coast_house_action()
	if not house_action.is_empty():
		return house_action
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
	if actor.has_passenger() and _lake_place_point().is_finite():
		return "Опустить предмет в озеро"
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
	var city_door := _city_door_action()
	if not city_door.is_empty():
		if not _ordinary_arrival_is_safe(city_door["address"], city_door["point"]):
			return false
		_move_home_travelers(city_door["point"], city_door["address"])
		return true
	var station := _city_station_destination()
	if not station.is_empty():
		return public_ride_requested.call(station)
	var friend_action := _city_friend_action()
	if not friend_action.is_empty():
		return _city_friend_interact(friend_action)
	if not _yuki_action().is_empty():
		return _interact_yuki()
	if not _ori_action().is_empty():
		return _interact_ori()
	match _nearby_action():
		"Нырнуть в тоннель":
			return _use_tunnel(Tunnel.WEST_EXIT, Tunnel.LOCATION_ID)
		"Нырнуть в обратный тоннель":
			return _use_tunnel(Tunnel.EAST_EXIT, Tunnel.LOCATION_ID)
		"К тихому озеру":
			return _use_tunnel(Tunnel.W1_RETURN, Valley.LOCATION_ID)
		"К Озеру Дубликатов":
			return _use_tunnel(Lake.SHORE, Lake.LOCATION_ID)
		"Взять Песочные часы":
			return _take_hourglass()
		"Поговорить с Мией":
			return _gift_flask()
		"Взять свирель":
			return _take_flute()
		"Посмотреть вместе с Они":
			return _observe_with_oni()
		"Алхимическая установка":
			_alchemy_panel.configure_access(false, flask_state > 0, mia_experienced and flask_state == 0)
			_alchemy_panel.show()
			apply_player_input(Vector2.ZERO)
			return true
		"Войти в Башню":
			return _use_tower_door(true)
		"Выйти из Башни":
			return _use_tower_door(false)
		"Повернуть циферблат":
			coast_house_phase = (coast_house_phase + 1) % 4
			_update_world_light()
			return true
		"Войти в дом":
			return _use_coast_house_door(true)
		"Выйти из дома":
			return _use_coast_house_door(false)
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
		"Опустить предмет в озеро":
			var point := _lake_place_point()
			return point.is_finite() and actor.try_place_carried(point, Lake.SHALLOW_SURFACE["height"])
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
	if is_instance_valid(_ori_panel) and _ori_panel.visible:
		if event.keycode == KEY_ESCAPE:
			_ori_panel.hide()
		get_viewport().set_input_as_handled()
		return
	if is_instance_valid(_yuki_panel) and _yuki_panel.visible:
		if event.keycode == KEY_ESCAPE:
			_yuki_panel.hide()
		get_viewport().set_input_as_handled()
		return
	if _alchemy_panel != null and _alchemy_panel.visible:
		if event.keycode == KEY_ESCAPE:
			_alchemy_panel.hide()
		get_viewport().set_input_as_handled()
		return
	if ancient_console != null and ancient_console.is_open():
		if event.keycode == KEY_ESCAPE:
			ancient_console.close()
		if event.keycode not in [KEY_F5, KEY_F7, KEY_F9]:
			get_viewport().set_input_as_handled()
		return
	if music_focus:
		match event.keycode:
			KEY_UP: _play_note("U")
			KEY_DOWN: _play_note("D")
			KEY_LEFT: _play_note("L")
			KEY_RIGHT: _play_note("R")
			KEY_BACKSPACE: music.clear()
			KEY_ENTER:
				var phrase := music.phrase
				_set_music_focus(false)
				if not perform_music(phrase):
					$Interface/SaveNotice.text = "Мелодия не изменила окружение."
			KEY_ESCAPE, KEY_M: _set_music_focus(false)
		get_viewport().set_input_as_handled()
		return
	match event.keycode:
		KEY_K:
			if _open_ori():
				get_viewport().set_input_as_handled()
		KEY_J:
			if _open_yuki():
				get_viewport().set_input_as_handled()
		KEY_M:
			if _set_music_focus(true):
				get_viewport().set_input_as_handled()
		KEY_P:
			if toggle_prism():
				get_viewport().set_input_as_handled()
		KEY_F2:
			if observation_fixture and not is_instance_valid(_debug_editor):
				set_luna_eyes(not crystal_observer.luna_eyes_open)
				get_viewport().set_input_as_handled()
		KEY_E:
			if interact():
				get_viewport().set_input_as_handled()
			elif not is_instance_valid(_debug_editor):
				if _active_city_tool == "ori" and ori.ownership > 0:
					if not catalog_repeat().is_empty():
						get_viewport().set_input_as_handled()
				elif flask_state > 0 and not flask_effect.is_empty() and _apply_alchemy(flask_effect):
					get_viewport().set_input_as_handled()
		KEY_L:
			if not is_instance_valid(_debug_editor) and not catalog_repeat().is_empty():
				get_viewport().set_input_as_handled()
		KEY_H:
			if cycle_hourglass():
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
			if not is_instance_valid(_debug_editor):
				if ori.ownership > 0 and (_near_ori() or _active_city_tool == "ori") and _open_ori():
					get_viewport().set_input_as_handled()
				elif yuki.ownership > 0 and (_near_yuki() or _active_city_tool == "yuki" or flask_state == 0) and _open_yuki():
					get_viewport().set_input_as_handled()
				elif flask_state > 0 and _alchemy_panel != null:
					_active_city_tool = ""
					_alchemy_panel.configure_access(true, true, false)
					_alchemy_panel.show()
					apply_player_input(Vector2.ZERO)
					get_viewport().set_input_as_handled()
				elif ori.ownership > 0 and _open_ori():
					get_viewport().set_input_as_handled()
				elif _restore_nearby_swim():
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
	if not tabs.is_empty():
		for rule in yuki.rules:
			if rule["host"] == target_id:
				var rule_id := int(rule["id"])
				var enabled: bool = rule["enabled"]
				tabs["Общее"].append({"id": "YUKI_RULE_" + str(rule_id), "label": "SCRIPT " + str(rule_id), "kind": "action", "value": "Стоп" if enabled else "Пуск", "action": func(): return yuki.set_enabled(rule_id, not enabled)})
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
	if not tabs.is_empty() and _can_transfer_duplicate(entities.get_entity(target_id) as EntityBody):
		var target := entities.get_entity(target_id) as EntityBody
		var installed: Dictionary = target.record.get_component("ABILITY_SET").get("instances", {})
		var bank: Dictionary = actor.record.get_component("ABILITY_BANK").get("instances", {})
		if installed.has(DUPLICATE_MODULE_ID):
			tabs["Способности"] = [{"id": DUPLICATE_MODULE_ID, "label": "DUPLICATE", "kind": "action",
				"value": "В банк", "action": func(): return request_extract_duplicate(target_id)}]
		elif bank.has(DUPLICATE_MODULE_ID):
			tabs["Способности"] = [{"id": DUPLICATE_MODULE_ID, "label": "DUPLICATE", "kind": "action",
				"value": "Установить", "action": func(): return request_install_duplicate(target_id)}]
	if not tabs.is_empty() and ori.ownership > 0:
		var target := entities.get_entity(target_id) as EntityBody
		if _can_extract_ori(target):
			var installed: Dictionary = target.record.get_component("ABILITY_SET").get("instances", {})
			for module_id in ORI_MODULES:
				if installed.has(module_id):
					var id: String = module_id
					if not tabs.has("Способности"):
						tabs["Способности"] = []
					tabs["Способности"].append({"id": id, "label": ORI_MODULES[id], "kind": "action", "value": "В банк", "action": func(): return request_extract_ori(target_id, id)})
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
	data["address_schema"] = ADDRESS_SCHEMA
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
	data["coast_house_phase"] = coast_house_phase
	data["alchemy_glow"] = _alchemy_glow.remaining
	data["alchemy_bubble"] = _alchemy_bubble.remaining
	data["bubble_started"] = _bubble_started
	if observation_fixture:
		data["lake_layout"] = 1
		data["lake_elapsed"] = _lake_elapsed
		data["lake_entered"] = _lake_entered
	if observation_fixture:
		data["coastal_life_layout"] = 1
		data["hourglass_owned"] = hourglass_owned
		data["flask_state"] = flask_state
		data["flask_effect"] = flask_effect
		data["mia_experienced"] = mia_experienced
		data["mia_route_step"] = mia_route_step
		data["lab_ice"] = _lab_ice.remaining
		data["city_layout"] = 1
		data["yuki_layout"] = 1
		data["yuki"] = yuki.snapshot()
		if ecology_fixture:
			data["ori_layout"] = 1
			data["ori"] = ori.snapshot()
		data["city_bench_active"] = city_bench_active
		data["city_bench_step"] = city_bench_step
		data["city_bench_observed"] = city_bench_observed
		data["city_ray_settled"] = city_ray_settled
		data["friend_layout"] = 1
		data["social"] = social.snapshot()
		data["oni_route_index"] = oni_route_index
		data["flute_owned"] = flute_owned
		data["prism_active"] = prism_active
		data["music_scale"] = _music_original_scale
		data["music_attraction"] = _attraction.remaining
	data["luna_eyes_open"] = crystal_observer.luna_eyes_open
	data["luna_facing"] = [crystal_observer.facing.x, crystal_observer.facing.y]
	if observation_fixture and ecology_fixture:
		data["crystal_fauna_layout"] = 1
		data["duplicate_elapsed"] = _duplicate_elapsed
	data["wand_pair"] = wand_pair.snapshot()
	return data


func apply_snapshot(data: Dictionary) -> bool:
	var schema: Variant = data.get("address_schema", 0)
	if typeof(schema) not in [TYPE_INT, TYPE_FLOAT] or float(schema) not in [0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, float(ADDRESS_SCHEMA)]:
		return false
	if int(schema) < ADDRESS_SCHEMA:
		data = _migrate_home_addresses(data, int(schema))
	var island: Variant = data.get("island")
	var states: Variant = data.get("entities")
	if not island is Dictionary or not states is Array:
		return false
	var next_access := AccessState.new()
	var next_projection := WandProjection.new()
	var next_clock := WorldClock.new()
	var next_bench: Variant = data.get("city_bench_active", true)
	var next_bench_step: Variant = data.get("city_bench_step", 0)
	var next_bench_seen: Variant = data.get("city_bench_observed", false)
	var next_ray: Variant = data.get("city_ray_settled", false)
	if not next_bench is bool or not next_bench_seen is bool or not next_ray is bool \
			or typeof(next_bench_step) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(next_bench_step)) \
			or float(next_bench_step) != floorf(float(next_bench_step)) or int(next_bench_step) < 0 \
			or int(next_bench_step) >= City.BENCH_ROUTE.size():
		return false
	var next_ori := OriCatalog.new()
	if not next_ori.restore(data.get("ori", next_ori.snapshot())):
		return false
	var next_yuki := YukiProgram.new()
	if not next_yuki.restore(data.get("yuki", next_yuki.snapshot())):
		return false
	var next_social := Social.new()
	var next_oni: Variant = data.get("oni_route_index", 0)
	var next_flute: Variant = data.get("flute_owned", false)
	var next_prism: Variant = data.get("prism_active", false)
	var next_music_scale: Variant = data.get("music_scale", 0.0)
	var next_attraction := ActiveDuration.new(ATTRACTION_SECONDS)
	if data.has("social") and not next_social.restore(data["social"]):
		return false
	if not next_flute is bool or not next_prism is bool or (next_prism and not next_social.prism_owned) \
			or typeof(next_oni) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(next_oni)) \
			or float(next_oni) != floorf(float(next_oni)) or int(next_oni) < 0 or int(next_oni) >= Visits.ROUTE.size() \
			or typeof(next_music_scale) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(next_music_scale)) \
			or (float(next_music_scale) != 0.0 and (not next_flute or float(next_music_scale) < 0.5 or float(next_music_scale) > 2.0)) \
			or not next_attraction.restore(data.get("music_attraction", 0.0)) or (not next_flute and next_attraction.remaining > 0.0):
		return false
	var next_hourglass: Variant = data.get("hourglass_owned", false)
	var next_flask: Variant = data.get("flask_state", 0)
	var next_recipe: Variant = data.get("flask_effect", "")
	var next_experience: Variant = data.get("mia_experienced", false)
	var next_mia_step: Variant = data.get("mia_route_step", 0)
	var next_lab_ice := ActiveDuration.new(LAB_ICE_SECONDS)
	if not next_hourglass is bool or not next_experience is bool or not next_recipe is String \
			or typeof(next_flask) not in [TYPE_INT, TYPE_FLOAT] or float(next_flask) not in [0.0, 1.0, 2.0] \
			or typeof(next_mia_step) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(next_mia_step)) \
			or float(next_mia_step) != floorf(float(next_mia_step)) or int(next_mia_step) < 0 or int(next_mia_step) > Life.MIA_ROUTE.size() \
			or (next_recipe != "" and (next_flask == 0 or next_recipe not in AlchemyPanel.IMPLEMENTED)) \
			or (next_flask > 0 and not next_experience) or not next_lab_ice.restore(data.get("lab_ice", 0.0)):
		return false
	var next_eyes: Variant = data.get("luna_eyes_open", true)
	var raw_facing: Variant = data.get("luna_facing", [0.0, 1.0])
	if not next_eyes is bool or not raw_facing is Array or raw_facing.size() != 2:
		return false
	for coordinate in raw_facing:
		if typeof(coordinate) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(coordinate)):
			return false
	var next_facing := Vector2(float(raw_facing[0]), float(raw_facing[1]))
	if not is_equal_approx(next_facing.length(), 1.0):
		return false
	var next_lake_elapsed: Variant = data.get("lake_elapsed", 0.0)
	var next_lake_entered: Variant = data.get("lake_entered", false)
	if not next_lake_entered is bool or typeof(next_lake_elapsed) not in [TYPE_INT, TYPE_FLOAT] \
			or not is_finite(float(next_lake_elapsed)) or float(next_lake_elapsed) < 0.0 \
			or float(next_lake_elapsed) > LAKE_INTERVAL:
		return false
	var next_duplicate: Variant = data.get("duplicate_elapsed", 0.0)
	if typeof(next_duplicate) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(next_duplicate)) \
			or float(next_duplicate) < 0.0 or float(next_duplicate) > DUPLICATE_INTERVAL:
		return false
	var next_glow := ActiveDuration.new(GLOW_SECONDS)
	var next_bubble := ActiveDuration.new(BUBBLE_SECONDS)
	var next_started: Variant = data.get("bubble_started", false)
	if not next_started is bool or not next_bubble.restore(data.get("alchemy_bubble", 0.0)) \
			or (next_started and next_bubble.remaining <= 0.0):
		return false
	if not next_glow.restore(data.get("alchemy_glow", 0.0)):
		return false
	var next_house_phase: Variant = data.get("coast_house_phase", WorldClock.Phase.EVENING)
	if typeof(next_house_phase) not in [TYPE_INT, TYPE_FLOAT] or float(next_house_phase) not in [0.0, 1.0, 2.0, 3.0]:
		return false
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
	if observation_fixture and ecology_fixture:
		if not candidate.has("crystal_fauna_layout"):
			if _initial_mirror_state.is_empty():
				return false
			candidate = candidate.duplicate(true)
			candidate["entities"].append(_initial_mirror_state.duplicate(true))
		elif candidate["crystal_fauna_layout"] != 1:
			return false
	if observation_fixture:
		if not candidate.has("lake_layout"):
			if _initial_lake_stone.is_empty():
				return false
			candidate = candidate.duplicate(true)
			candidate["entities"].append(_initial_lake_stone.duplicate(true))
		elif candidate["lake_layout"] != 1:
			return false
	if observation_fixture:
		if not candidate.has("coastal_life_layout"):
			candidate = candidate.duplicate(true)
			for entry in _initial_life_states:
				candidate["entities"].append(entry.duplicate(true))
		elif candidate["coastal_life_layout"] != 1:
			return false
	if observation_fixture:
		if not candidate.has("friend_layout"):
			if _initial_oni.is_empty():
				return false
			candidate = candidate.duplicate(true)
			candidate["entities"].append(_initial_oni.duplicate(true))
		elif candidate["friend_layout"] != 1:
			return false
	if observation_fixture:
		if not candidate.has("city_layout"):
			if _initial_city_states.size() != City.DEFINITIONS.size():
				return false
			candidate = candidate.duplicate(true)
			for entry in _initial_city_states:
				candidate["entities"].append(entry.duplicate(true))
		elif candidate["city_layout"] != 1:
			return false
	if observation_fixture:
		if not candidate.has("yuki_layout"):
			if _initial_yuki_fridge.is_empty():
				return false
			candidate = candidate.duplicate(true)
			if not candidate["entities"].any(func(entry): return entry.get("id") == YUKI_FRIDGE):
				candidate["entities"].append(_initial_yuki_fridge.duplicate(true))
		elif candidate["yuki_layout"] != 1:
			return false
		for rule in next_yuki.rules:
			if not rule["host"].is_empty() and not candidate["entities"].any(func(entry): return entry.get("id") == rule["host"] and entry.get("category") in ["fridge", "prop", "cat", "fox", "ray", "trollik", "crab", "turtle", "mirror_snail"]):
				return false
		var cats := 0
		for entry in candidate["entities"]:
			if str(entry.get("id", "")).begins_with(YUKI_CAT_PREFIX):
				var suffix: String = str(entry["id"]).trim_prefix(YUKI_CAT_PREFIX)
				if not suffix.is_valid_int() or int(suffix) < 1 or int(suffix) > next_yuki.spawn_serial or entry.get("category") != "cat":
					return false
				cats += 1
		if cats != next_yuki.spawn_serial:
			return false
	if observation_fixture and ecology_fixture:
		if not candidate.has("ori_layout"):
			if _initial_ori_states.size() != 3:
				return false
			candidate = candidate.duplicate(true)
			for initial in _initial_ori_states:
				if not candidate["entities"].any(func(entry): return entry.get("id") == initial["id"]):
					candidate["entities"].append(initial.duplicate(true))
		elif candidate["ori_layout"] != 1:
			return false
		var created := 0
		for entry in candidate["entities"]:
			if str(entry.get("id", "")).begins_with(ORI_CREATED_PREFIX):
				var suffix: String = str(entry["id"]).trim_prefix(ORI_CREATED_PREFIX)
				if not suffix.is_valid_int() or int(suffix) < 1 or int(suffix) > next_ori.serial or entry.get("category") not in next_ori.known:
					return false
				created += 1
		if created != next_ori.serial:
			return false
		if not next_ori.order_id.is_empty() and not candidate["entities"].any(func(entry): return entry.get("id") == next_ori.order_id and entry.get("category") == "cat"):
			return false
	var plank: Dictionary = {}
	for state in candidate["entities"]:
		if state is Dictionary and state.get("id") == Meadows.PLANK_ID and state.get("category") == "prop":
			plank = state
			break
	if plank.is_empty():
		return false
	# A saved conditional contact is re-evaluated with the restored observer.
	# Temporarily permit the physical span and open doorway for candidate validation.
	var previous_door := _crystal_door_solid
	var previous_bridge := _surfaces.has(Crystal.BRIDGE)
	var previous_coast_bridge := _surfaces.has(CoastExtra.BRIDGE)
	if observation_fixture:
		if not previous_coast_bridge:
			_surfaces.append(CoastExtra.BRIDGE)
		_set_crystal_door(false)
		if not previous_bridge:
			_surfaces.append(Crystal.BRIDGE)
	var previous_lab_ice := _lab_ice.remaining
	_lab_ice.restore(next_lab_ice.remaining)
	var previous_ice := ice_remaining
	var previous_plank := _plank_surface
	_ice_duration.restore(next_ice.remaining)
	_set_plank_surface(_saved_plank_surface(plank))
	if not super.apply_snapshot(candidate):
		_lab_ice.restore(previous_lab_ice)
		_ice_duration.restore(previous_ice)
		_set_plank_surface(previous_plank)
		if observation_fixture:
			_set_crystal_door(previous_door)
			if not previous_bridge:
				_surfaces.erase(Crystal.BRIDGE)
			if not previous_coast_bridge:
				_surfaces.erase(CoastExtra.BRIDGE)
		return false
	ori = next_ori
	_active_city_tool = ""
	if is_instance_valid(_ori_panel):
		_ori_panel.hide()
	yuki = next_yuki
	if is_instance_valid(_yuki_panel):
		_yuki_panel.hide()
	city_bench_active = next_bench
	city_bench_step = int(next_bench_step)
	city_bench_observed = next_bench_seen
	city_ray_settled = next_ray
	social = next_social
	oni_route_index = int(next_oni)
	flute_owned = next_flute
	prism_active = next_prism
	_music_original_scale = float(next_music_scale)
	_attraction.restore(next_attraction.remaining)
	music_focus = false
	music.clear()
	hourglass_owned = next_hourglass
	flask_state = int(next_flask)
	flask_effect = next_recipe
	mia_experienced = next_experience
	mia_route_step = int(next_mia_step)
	_duplicate_elapsed = float(next_duplicate)
	_lake_elapsed = float(next_lake_elapsed)
	_lake_entered = next_lake_entered
	crystal_observer.luna_eyes_open = next_eyes
	crystal_observer.facing = next_facing
	_sync_crystal_observation()
	access = next_access
	wand_pair = pair
	projection = wand_pair.active()
	_wand_hold = 0.0
	queue_redraw()
	coast_house_phase = int(next_house_phase)
	_alchemy_glow.restore(next_glow.remaining)
	_alchemy_bubble.restore(next_bubble.remaining)
	_bubble_started = next_started
	actor.temporary_swim = next_bubble.remaining > 0.0
	if _alchemy_panel != null:
		_alchemy_panel.hide()
	_update_alchemy_light()
	world_clock.restore(next_clock.snapshot())
	_update_world_light()
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


# Migrate only location-bearing records from the old schema. Leave all
# positions, attachment IDs, modules and timers untouched. The normal
# snapshot validator still checks every position and physical support.
func _migrate_home_addresses(source: Dictionary, previous_schema: int) -> Dictionary:
	var result := source.duplicate(true)
	var states: Variant = result.get("entities")
	if states is Array:
		for state in states:
			if state is Dictionary:
				_migrate_address_entry(state, false, previous_schema)
	var island: Variant = result.get("island")
	if island is Dictionary and island.get("projection") is Dictionary:
		_migrate_address_entry(island["projection"], true, previous_schema)
	var pair: Variant = result.get("wand_pair")
	if pair is Dictionary and pair.get("duplicate") is Dictionary:
		_migrate_address_entry(pair["duplicate"], true, previous_schema)
	result["address_schema"] = ADDRESS_SCHEMA
	return result


func _migrate_address_entry(entry: Dictionary, is_field: bool, previous_schema: int) -> void:
	var stored: Variant = entry.get("location_id")
	if not stored is String:
		return
	var canonical: String = Lake.LOCATION_ID if stored == Lake.LEGACY_LOCATION_ID else stored
	# A carried wand may retain its previous ground location.
	if is_field and entry.get("carried") == true:
		entry["location_id"] = canonical
		return
	var raw: Variant = entry.get("position")
	if not raw is Array or raw.size() != 2:
		return
	for coordinate in raw:
		if typeof(coordinate) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(coordinate)):
			return
	var point := Vector2(float(raw[0]), float(raw[1]))
	var previous_location := _legacy_entity_location(point)
	if previous_schema == 1:
		previous_location = _entity_location_v1(point)
	elif previous_schema == 2:
		previous_location = _entity_location_v2(point)
	elif previous_schema == 3:
		previous_location = _entity_location_v3(point)
	elif previous_schema == 4:
		previous_location = _entity_location_v4(point)
	elif previous_schema == 5:
		previous_location = _entity_location_v5(point)
	elif previous_schema == 6:
		previous_location = _entity_location_v6(point)
	elif previous_schema == 7:
		previous_location = _entity_location_v7(point)
	elif previous_schema == 8:
		previous_location = _entity_location_v8(point)
	elif previous_schema == 9:
		previous_location = _entity_location_v9(point)
	elif previous_schema == 10:
		previous_location = _entity_location_v10(point)
	elif previous_schema == 11:
		previous_location = _entity_location_v11(point)
	if canonical == previous_location:
		entry["location_id"] = _entity_location(point)


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
		var machine: EntityBody = candidates.get(YUKI_FRIDGE)
		if machine == null or machine.record.category != "fridge":
			return false
		for definition in City.DEFINITIONS:
			var resident: EntityBody = candidates.get(definition["id"])
			if resident == null or resident.record.category != definition["category"]:
				return false
		var oni: EntityBody = candidates.get(Visits.ONI_ID)
		if oni == null or oni.record.category != "oni":
			return false
		var stone: EntityBody = candidates.get(LAKE_STONE_ID)
		if stone == null or stone.record.category != "prop":
			return false
		var prop_count := 0
		for identity in candidates:
			if identity.begins_with(LAKE_CHIBI_PREFIX):
				var suffix: String = identity.trim_prefix(LAKE_CHIBI_PREFIX)
				if not suffix.is_valid_int() or int(suffix) < 1 or int(suffix) > LAKE_CHIBI_LIMIT \
						or candidates[identity].record.category != "chibi_luna":
					return false
			elif identity.begins_with(LAKE_PROP_PREFIX):
				prop_count += 1
				if candidates[identity].record.category != "prop":
					return false
		if prop_count > LAKE_PROP_LIMIT:
			return false
		for identity in COURT_FRIDGES:
			var fridge: EntityBody = candidates.get(identity)
			if fridge == null or fridge.record.category != "fridge":
				return false
	if not ecology_fixture:
		return super._validate_saved_entities(candidates)
	var counts := {}
	if observation_fixture:
		var snail: EntityBody = candidates.get(MIRROR_SNAIL)
		if snail == null or not snail is Fauna or snail.record.category != "mirror_snail":
			return false
		var copies := 0
		for identity in candidates:
			if identity.begins_with(DUPLICATE_PREFIX):
				var suffix: String = identity.trim_prefix(DUPLICATE_PREFIX)
				if not suffix.is_valid_int() or int(suffix) < 1 or int(suffix) > DUPLICATE_LIMIT \
						or candidates[identity].record.category not in DUPLICATE_CATEGORIES:
					return false
				copies += 1
		if copies > DUPLICATE_LIMIT:
			return false
		counts[DUPLICATE_MODULE_ID] = 0
		for resident_id in [ORI_GLOW_DONOR, ORI_FLY_DONOR, ORI_CUSTOMER]:
			var resident: EntityBody = candidates.get(resident_id)
			var expected: String = {ORI_GLOW_DONOR: "lizard", ORI_FLY_DONOR: "ray", ORI_CUSTOMER: "resident"}[resident_id]
			if resident == null or resident.record.category != expected:
				return false
		for module_id in ORI_MODULES:
			counts[module_id] = 0
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
				if ORI_MODULES.has(module):
					if items[module]["ability_id"] != ORI_MODULES[module] or items[module]["protected"] or (component == "ABILITY_BANK" and identity != ENTITY_ID) or (component == "ABILITY_SET" and candidates[identity].record.category not in OriCatalog.FORMS):
						return false
					counts[module] += 1
					continue
				if module == DUPLICATE_MODULE_ID:
					if items[module]["ability_id"] != "DUPLICATE" or items[module]["protected"] \
							or (component == "ABILITY_BANK" and identity != ENTITY_ID) \
							or (component == "ABILITY_SET" and candidates[identity].record.category not in DUPLICATE_CATEGORIES):
						return false
					counts[module] += 1
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
	if observation_fixture:
		Valley.draw_on(self, world_clock.phase() == WorldClock.Phase.EVENING)
		MiaLab.draw_on(self)
		Tunnel.draw_on(self)
		Crystal.draw_on(self, _crystal_door_solid)
		CoastExtra.draw_on(self)
		Lake.draw_shallow_on(self)
		Coast.draw_on(self, coast_house_phase, world_clock.phase(), Coast.tide_height(world_clock.minute_of_day()))
		Life.draw_on(self, Coast.tide_height(world_clock.minute_of_day()) * 8.0 / 30.0, hourglass_owned, flask_state, _lab_ice.remaining > 0.0)
		Visits.draw_on(self, flute_owned, prism_active)
		City.draw_on(self)
	for field in [wand_pair.original, wand_pair.duplicate]:
		if field != null and not field.carried:
			var point: Vector2 = field.ground_position
			draw_line(point + Vector2(-11, 7), point + Vector2(11, -7), Color("ead1ff"), 5.0)
			draw_circle(point + Vector2(11, -7), 4.0, Color("ffd98d"))
