extends "res://scripts/skeleton/entity_fixture.gd"
## Continuous P9-03 graybox. The island and meadows share the simulation and camera.

signal frost_cast(active_seconds: float)
signal fauna_respawned(identity: String)
signal help_completed(outcome: String, identity: String)
signal forest_bank_interacted
signal forest_bank_left

const ForestBank = preload("res://scripts/skeleton/forest_bank_2d.gd")
const FairyBranch = preload("res://scripts/skeleton/fairy_branch_layout.gd")
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
const ADDRESS_SCHEMA := 20
const Runes = preload("res://scripts/runtime2d/latin_runes_2d.gd")
const RuneRoom = preload("res://scripts/skeleton/rune_room_layout.gd")
const QuietRegions = preload("res://scripts/skeleton/quiet_regions_layout.gd")
const SecretFinds = preload("res://scripts/skeleton/secret_finds_layout.gd")
const FriendRoutes = preload("res://scripts/skeleton/friend_routes_2d.gd")
const Edge = preload("res://scripts/skeleton/forgotten_edge_layout.gd")
const EdgeState = preload("res://scripts/runtime2d/forgotten_edge_state.gd")
var edge := EdgeState.new()
const Anomaly = preload("res://scripts/runtime2d/edge_anomaly_2d.gd")
var anomalies := Anomaly.new()
var _initial_anomaly_states: Array[Dictionary] = []
const TimeHistory = preload("res://scripts/runtime2d/world_timeline_2d.gd")
var _time_history := TimeHistory.new()
var _time_address := ""
var _forward_remaining := 0.0
var _forward_behavior := ""
var ghost_ride_requested: Callable
var meta_merged: Callable
var ghost_offer := ""
const Mountain = preload("res://scripts/skeleton/mountain_layout.gd")
const Highland = preload("res://scripts/runtime2d/highland_artifacts_2d.gd")
var highland := Highland.new()
var _initial_highland_states: Array[Dictionary] = []
var _mountain_echo := 0.0
const AM = preload("res://scripts/runtime2d/antimemetic_2d.gd")
var antimemetic := AM.new()
var _initial_am_states: Array[Dictionary] = []
var _am_tracks: Dictionary = {}
var _am_audio: AudioStreamPlayer2D
var _am_stomp: AudioStreamWAV
var _am_echo_id := ""
var _am_echo_remaining := 0.0
const City = preload("res://scripts/skeleton/luma_city_layout.gd")
const LunaDoor = preload("res://scripts/skeleton/luna_door_2d.gd")
const Social = preload("res://scripts/runtime2d/friend_progress_2d.gd")
const HeroProfile = preload("res://scripts/skeleton/hero_profile_2d.gd")
const HeroProfilePanel = preload("res://scripts/skeleton/hero_profile_panel_2d.gd")
var hero_profile := HeroProfile.new()
var _profile_panel: HeroProfilePanel
const Music = preload("res://scripts/runtime2d/flute_2d.gd")
const Visits = preload("res://scripts/skeleton/oni_music_layout.gd")
const ATTRACTION_SECONDS := 14.0
const Life = preload("res://scripts/skeleton/coastal_life_layout.gd")
const ShellCollection = preload("res://scripts/skeleton/shell_collection_2d.gd")
var shell_collection_ready := false
var shell_collection_delivered := false
const LAB_ICE_SECONDS := 40.0
const CoastExtra = preload("res://scripts/skeleton/coast_observation_layout.gd")
const LAKE_CHIBI_PREFIX := "W6_CHIBI_"
const LAKE_PROP_PREFIX := "W6_PROP_COPY_"
const LAKE_CHIBI_LIMIT := 3
const LAKE_PROP_LIMIT := 3
const LAKE_INTERVAL := 5.0
const LAKE_STONE_ID := "W6_SHORE_STONE"
const Crystal = preload("res://scripts/skeleton/crystal_observation_layout.gd")
const W8 = preload("res://scripts/skeleton/underside_refuge_layout.gd")
const BackdropRoute = preload("res://scripts/skeleton/interior_backdrop_2d.gd")
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
	W8.PASSAGE: "Кристальные пещеры", W8.REFUGE: "Малое убежище",
	Coast.HOUSE_ID: "Дом вечерних окон", Coast.GROTTO_ID: "Морской грот",
	Valley.TOWER_ID: "Башня отражений", Tunnel.LOCATION_ID: "Подводный тоннель",
	City.CITY_ID: "Люма", City.CAFE_ID: "Кафе", City.HOME_ID: "Комната Луны",
	Mountain.MOUNTAIN: "Горы", Mountain.UPDRAFT: "Долина восходящего ветра", Mountain.SKY: "Небесные острова", Mountain.ORACLE: "Обзор Оракула",
	Edge.ID: "Забытый край", Edge.SERVICE: "Служебный карман", Edge.BANK: "Скрытый берег", Edge.REFUGE: "Убежище",
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
var _c6_facade: Node2D
var public_ride_requested: Callable
var desktop_requested: Callable
# Only an author-designated room may configure this. Default Adventure has none.
var backdrop_route: BackdropRoute
const WindowFrame = preload("res://scripts/skeleton/window_frame_2d.gd")
var game_mode := "FULLSCREEN"
var game_frame_solid := true
var _window_frame: WindowFrame
var _frame_panel: PanelContainer
var _frame_switch: CheckButton
var _frame_previous := Vector2.INF
var _frame_crossing := false
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
var _w8_wall: StaticBody2D
var _w8_open := false
var _crystal_door_solid := false
var _alchemy_light: PointLight2D
var _coast_tide: WaterVolume
var _ice_duration := ActiveDuration.new(Meadows.ICE_SECONDS)
var ice_remaining: float:
	get:
		return _ice_duration.remaining
var freeze_selected := false
var _initial_meadow_states: Array[Dictionary] = []
var _initial_quiet_states: Array[Dictionary] = []
var _initial_quiet_region_states: Array[Dictionary] = []
var _initial_f2_food_states: Array[Dictionary] = []
const CAFE_SNACK := "C2_CAFE_SNACK"
const WAND_COPY_PREFIX := "WAND_COPY_"
const WAND_COPY_LIMIT := 32
var _secret_find_visibility := Vector2i(-1, -1)
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
		var underside_address := W8.address(point)
		if not underside_address.is_empty():
			return underside_address
	if observation_fixture and (ShellCollection.COVE.has_point(point) or ShellCollection.PATH.has_point(point)):
		return Coast.LOCATION_ID
	if observation_fixture and FairyBranch.ROOM.has_point(point):
		return FairyBranch.ID
	if observation_fixture and RuneRoom.contains(point):
		return ForestBank.LOCATION_ID
	return _entity_location_v19(point)


func _entity_location_v19(point: Vector2) -> String:
	if observation_fixture:
		var quiet_address := QuietRegions.address(point)
		if not quiet_address.is_empty():
			return quiet_address
		var edge_address := Edge.address(point)
		if not edge_address.is_empty():
			return edge_address
	return _entity_location_v15(point)


func _entity_location_v18(point: Vector2) -> String:
	if observation_fixture:
		var quiet_address := QuietRegions.address(point)
		if not quiet_address.is_empty():
			return quiet_address
	return _entity_location_v16(point)


func _entity_location_v17(point: Vector2) -> String:
	if observation_fixture:
		var quiet_address := QuietRegions.address(point, false)
		if not quiet_address.is_empty():
			return quiet_address
	return _entity_location_v16(point)


func _entity_location_v16(point: Vector2) -> String:
	if observation_fixture:
		var edge_address := Edge.address_v18(point)
		if not edge_address.is_empty():
			return edge_address
	return _entity_location_v15(point)


func _entity_location_v15(point: Vector2) -> String:
	if observation_fixture:
		var mountain_address := Mountain.address(point)
		if not mountain_address.is_empty():
			return mountain_address
	return _entity_location_v13(point)


func _entity_location_v13(point: Vector2) -> String:
	if observation_fixture:
		var city_address := City.location_at(point)
		if not city_address.is_empty():
			return city_address
	return _entity_location_v11(point)


func _entity_location_v12(point: Vector2) -> String:
	if observation_fixture:
		var city_address := City.location_at(point, false)
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
	return 80 + QuietRegions.FAUNA.size() + WAND_COPY_LIMIT + ShellCollection.REQUIRED if observation_fixture else super._entity_limit()


func _starts_alive(category: String) -> bool:
	return category in ["octopus", "fairy", "fox", "trollik", "fish", "mirror_snail", "chibi_luna", "mia", "crab", "turtle", "oni", "cat", "ray", "toffi", "yuki", "ori", "lizard", "resident", "mouse", "leia", "emot", "emot_giant", "oracle", "glitch_fox", "return_cat", "double_rabbit"] or super._starts_alive(category)


func _editor_parent() -> Node:
	return $Interface


func _ready() -> void:
	_setup_window_frame()
	_setup_profile_panel()
	wand_pair.original = projection
	world_clock.minute_changed.connect(_update_world_light)
	_ice_duration.active_changed.connect(_update_ice_support)
	_lab_ice.active_changed.connect(_update_lab_ice)
	_update_world_light()
	_decks.assign(ISLAND_DECKS)
	var ground := Meadows.DECKS + Lake.DECKS
	if observation_fixture:
		ground.append_array(ForestBank.DECKS + [FRIDGE_COURT, FRIDGE_PATH])
		ground.append_array(QuietRegions.decks())
		ground.append_array([RuneRoom.KEY_PATH, RuneRoom.KEY_ROOM, FairyBranch.ROOM])
		ground.append_array(ShellCollection.DECKS)
		ground.append_array([W8.APPROACH, W8.LANDING, W8.ROOM])
		ground.append_array(Valley.DECKS + Coast.DECKS + MiaLab.DECKS + Tunnel.DECKS + Crystal.DECKS + [CoastExtra.LANDING] + City.DECKS + Mountain.GROUND + Edge.GROUND)
		_water_volumes.append(WaterVolume.new(ForestBank.RIVER, -110.0, 0.0, Vector2(12, 0), 1.3))
	if ancient_console_enabled:
		ground.append_array(AncientConsole.DECKS)
	for bounds in ground:
		_decks.append({"bounds": bounds, "height": 0.0})
	if observation_fixture:
		for tread in Coast.ESCAPE_DECKS + Valley.TOWER_DECKS + MiaLab.ELEVATED + CoastExtra.SHELF_STEPS + [City.TABLE] + Mountain.STAIRS + Edge.LOWER_STEPS + [Edge.LOWER] + SecretFinds.GRAVITY_STEPS + SecretFinds.FLUTE_STEPS + FairyBranch.STEPS:
			_decks.append(tread.duplicate())
	_surfaces.assign(_decks)
	if observation_fixture:
		_surfaces.append({"bounds": Edge.WATER, "height": -48.0, "safe": false})
		_water_volumes.append(WaterVolume.new(Edge.WATER, -48.0, -5.0, Vector2(0, -230), 3.0))
		_surfaces.append(Edge.CYCLE_SPAN)
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
		_walls.append(AM.MONUMENT)
		_walls.append_array(Mountain.ROOT_WALLS)
		_walls.append_array(RuneRoom.WALLS)
		_walls.append(Mountain.ANCHOR_WALL)
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
	_spawn_quiet_meadow_fauna()
	if ecology_fixture:
		_spawn_ecology_fixture()
	if observation_fixture:
		_spawn_observation_fixture()
		_setup_alchemy()
		_setup_crystal_observation()
		_setup_w8()
		if ecology_fixture:
			_spawn_mirror_snail()
		_spawn_lake_stone()
		_spawn_coastal_life()
		_spawn_oni()
		_spawn_city()
		_setup_city_tools()
		_setup_friend_extra()
		_setup_yuki()
		if ecology_fixture:
			_setup_ori()
		_setup_flute()
		_setup_antimemetic()
		_setup_highland()
		_setup_anomalies()
		_spawn_quiet_region_fauna()
		_setup_f2_food()
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


func _setup_w8() -> void:
	_w8_wall = StaticBody2D.new()
	_w8_wall.collision_mask = 0
	_w8_wall.disable_mode = CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
	var bounds: Rect2 = W8.SEAM["bounds"]
	_w8_wall.position = bounds.get_center()
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = bounds.size
	collider.shape = shape
	_w8_wall.add_child(collider)
	add_child(_w8_wall)
	_set_w8_open(false)


func _set_w8_open(open: bool) -> void:
	if not is_instance_valid(_w8_wall):
		return
	_w8_open = open
	if open:
		if not _surfaces.has(W8.BRIDGE):
			_surfaces.append(W8.BRIDGE)
		_walls.erase(W8.SEAM)
		_w8_wall.collision_layer = 0
	else:
		_surfaces.erase(W8.BRIDGE)
		if not _walls.has(W8.SEAM):
			_walls.append(W8.SEAM)
		_w8_wall.collision_layer = int(W8.SEAM["layer"])
	queue_redraw()


func _sync_w8() -> void:
	if not observation_fixture or not is_instance_valid(_w8_wall):
		return
	var outside := wand_pair.outside_all_on_plane(actor.position)
	# When a field returns while a body overlaps the seam, do not crush it.
	# The bridge itself still follows the field immediately.
	if not outside:
		_surfaces.erase(W8.BRIDGE)
		var bounds: Rect2 = W8.SEAM["bounds"]
		for id in entities.list_ids():
			var body := entities.get_entity(id) as EntityBody
			if body != null and body.motion.elevation < float(W8.SEAM["height"]) and bounds.grow(body.foot_radius()).has_point(body.position):
				_w8_open = false
				_walls.erase(W8.SEAM)
				_w8_wall.collision_layer = 0
				queue_redraw()
				return
	if outside != _w8_open or (not outside and not _walls.has(W8.SEAM)):
		_set_w8_open(outside)


func _w8_action() -> String:
	if not observation_fixture or not actor.motion.grounded or actor.is_attached() or actor.has_passenger():
		return ""
	if W8.ROOM.has_point(actor.position):
		# All three targets may overlap within wand reach. Choose the real
		# nearest reachable object/body rather than hiding Oni behind the note.
		var nearest := INF
		var action := ""
		if _within_reach(W8.NOTE):
			nearest = actor.position.distance_squared_to(W8.NOTE)
			action = "Рассмотреть старую запись"
		if _within_reach(W8.ENTRY):
			var entry_distance: float = actor.position.distance_squared_to(W8.ENTRY)
			if entry_distance < nearest:
				nearest = entry_distance
				action = "Выйти из малого убежища"
		if _oni_w8_near():
			var oni := entities.get_entity(Visits.ONI_ID) as EntityBody
			var offset := Vector3(actor.position.x - oni.position.x, actor.position.y - oni.position.y, actor.motion.elevation - oni.motion.elevation)
			if offset.length_squared() < nearest:
				action = "Поговорить с Они в убежище"
		return action
	elif _w8_open and W8.LANDING.has_point(actor.position) and _within_reach(W8.FAR):
		return "Войти в малое убежище"
	return ""


func _interact_w8() -> bool:
	match _w8_action():
		"Войти в малое убежище":
			if not _ordinary_arrival_is_safe(W8.REFUGE, W8.ENTRY):
				return false
			_move_home_travelers(W8.ENTRY, W8.REFUGE)
		"Выйти из малого убежища":
			# If the field has been restored, the same return has a safe shore.
			var point := W8.FAR if wand_pair.outside_all_on_plane(W8.FAR) else W8.NEAR
			if not _ordinary_arrival_is_safe(W8.PASSAGE, point):
				return false
			_move_home_travelers(point, W8.PASSAGE)
		"Рассмотреть старую запись":
			$Interface/SaveNotice.text = "Два рисунка одного камня: один цельный, у другого линии продолжаются за краем. Кто-то долго сравнивал их."
		"Поговорить с Они в убежище":
			if not _oni_w8_near():
				return false
			if social.complete_oni_deep():
				$Interface/SaveNotice.text = "Они: Ты тоже нашла этот проход? Здесь линии продолжаются там, где их не должно быть."
			else:
				$Interface/SaveNotice.text = "Они: Мне всё ещё интересно, что скрывается за этими линиями."
		_:
			return false
	_sync_w8()
	return true


func set_luna_eyes(open: bool) -> void:
	crystal_observer.luna_eyes_open = open
	_sync_crystal_observation()
	queue_redraw()


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
	if yuki.ownership == 1 and yuki.observed:
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
	var applied := not key.is_empty() and commands.execute_set(body, key, rule["value"], ENTITY_ID, "yuki:rule")
	if applied and yuki.ownership == 1 and body.location_id == _entity_location(actor.position) and _within_reach(body.position, body.motion.elevation):
		yuki.observed = true
	return applied


func _yuki_spawn_cat() -> bool:
	# Shared world capacity, not a separate narrative ceiling for cats.
	if entities.count_live() >= _entity_limit() or yuki.spawn_serial >= 999999:
		return false
	var id := YUKI_CAT_PREFIX + str(yuki.spawn_serial + 1)
	for index in YUKI_CAT_POINTS.size():
		var point: Vector2 = YUKI_CAT_POINTS[(yuki.spawn_serial + index) % YUKI_CAT_POINTS.size()]
		var cat := spawn_entity({"id": id, "category": "cat", "label": "Котик", "material": "FABRIC"}, point, 0.0)
		if cat != null:
			yuki.spawn_serial += 1
			# New bodies use the ordinary size parameter and physical checks.
			cat.set_parameter("size", [0.5, 0.8, 1.2, 1.6][randi_range(0, 3)])
			city_tools.cat_sizes[id] = cat.get_parameter("size")
			return true
	return false


func _tick_yuki(delta: float) -> void:
	if not observation_fixture:
		return
	yuki.advance(delta * WorldClock.MINUTES_PER_SIM_SECOND, _execute_yuki_rule)
	_tick_mouse(delta)
	_cleanup_yuki_cats(delta)
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
const ORI_MODULES := {ORI_GLOW_INSTANCE: "GLOW", ORI_FLY_INSTANCE: "FLY", Mountain.FLY_INSTANCE: "FLY"}
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
	if ori.ownership == 1 and ori.serial >= 2:
		return "Поделиться с Ори своими созданиями"
	return ""


func _interact_ori() -> bool:
	match _ori_action():
		"Одолжить Каталог Ори":
			ori.ownership = 1
			_tick_ori()
			return true
		"Поделиться с Ори своими созданиями":
			ori.ownership = 2
			city_tools.ori_stage = 3
			social.complete("ORI")
			$Interface/SaveNotice.text = "Ори: Когда наиграешься, приходи ещё. Каталог твой!"
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
	return _bank_open() and target != null and target != actor and target.get_parameter("alive") and target.visible and target.location_id == _entity_location(actor.position) and _within_reach(target.position, target.motion.elevation) and wand_policy.authorize(actor, target, _entity_location(actor.position), projection, access, parameters, "mass")


func request_extract_ori(target_id: String, instance_id: String) -> bool:
	var target := entities.get_entity(target_id) as EntityBody
	return ORI_MODULES.has(instance_id) and _can_extract_ori(target) and ability_bank.move_instance(ENTITY_ID, target_id, instance_id, true)


func catalog_create(data: Dictionary) -> String:
	if ori.ownership == 0 or not ecology_fixture or not (actor as EntityBody).accepts_player_input() or not actor.motion.grounded or not ori.valid_template(data) or ori.serial >= OriCatalog.MAX_SERIAL or entities.count_live() >= _entity_limit():
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


func catalog_editable_targets() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if ori.ownership == 0:
		return result
	for id in entities.list_ids():
		var target := entities.get_entity(id) as EntityBody
		if target != null and (id == City.CAT or id.begins_with(ORI_CREATED_PREFIX)) and target.record.category in OriCatalog.FORMS and _stamp_target_allowed(target):
			result.append({"id": id, "label": target.record.display_name + " (" + id + ")"})
	return result


func catalog_change_form(id: String, form: String) -> bool:
	if ori.ownership == 0 or form not in ori.known or not catalog_editable_targets().any(func(item): return item["id"] == id):
		return false
	var target := entities.get_entity(id) as EntityBody
	if target.is_attached() or target.has_passenger():
		return false
	# Same Node, ID, body size, relationship, behavior, attachments and components.
	target.record.category = form
	target.record.display_name = OriCatalog.FORMS[form]
	entities.unregister_entity(id)
	entities.register_entity(id, target, _target_group(target))
	target.refresh_form_marker()
	return true


func catalog_install_existing(id: String, ability: String) -> bool:
	if ori.ownership == 0 or ability not in OriCatalog.MODULES or ability.is_empty() or not catalog_editable_targets().any(func(item): return item["id"] == id):
		return false
	var target := entities.get_entity(id) as EntityBody
	for instance_id in actor.record.get_component("ABILITY_BANK").get("instances", {}):
		if ORI_MODULES.get(instance_id, "") == ability and ability_bank.move_instance(ENTITY_ID, id, instance_id, false):
			if ability == "FLY":
				target.set_parameter("rideable", true)
			return true
	return false


func catalog_repeat() -> String:
	return catalog_create(ori.template)


func _open_ori() -> bool:
	if ori.ownership == 0 or not is_instance_valid(_ori_panel) or not (actor as EntityBody).accepts_player_input() or is_instance_valid(_debug_editor):
		return false
	_active_city_tool = "ori"
	_ori_panel.open_for(self)
	apply_player_input(Vector2.ZERO)
	return true


const CityTools = preload("res://scripts/runtime2d/city_tools_2d.gd")
const PASSERBY := "C1_PASSERBY"
const TOOL_POINTS := {"BESTIARY": Vector2(5960, 650), "REALITY_STAMP": Vector2(6160, 660), "GRAVITY_GUN": SecretFinds.GRAVITY_POINT, "PIXEL_GLOBE": Vector2(4780, 285)}
const TOOL_NAMES := {"BESTIARY": "Бестиарий", "REALITY_STAMP": "Штамп реальности", "GRAVITY_GUN": "Гравипушка", "PIXEL_GLOBE": "Глобус", "LUNA_ROOM_DOOR": "Дверь Луны"}
const ORI_PLAZA := Vector2(5170, 525)
const ORI_EXIT := Vector2(5930, 685)
var city_tools := CityTools.new()
var _initial_passerby: Dictionary = {}
var _city_tool_panel: PanelContainer
var _stamp_choice := "GLOW"
var luna_door_session: Dictionary = {}
var _initial_luna_door: Dictionary = {}


func _setup_city_tools() -> void:
	var original := spawn_entity({"id": LunaDoor.ID, "category": "prop", "label": "Дверь Луны", "material": "WOOD"}, LunaDoor.HOME_POINT, 0.0)
	if original == null:
		push_error("Could not place the original Luna room door")
	else:
		original.set_parameter("pickable", false)
		for entry in make_snapshot()["entities"]:
			if entry["id"] == LunaDoor.ID:
				_initial_luna_door = entry
	var passerby := spawn_entity({"id": PASSERBY, "category": "resident", "label": "Прохожий", "material": "FABRIC"}, Vector2(5260, 375), 0.0)
	if passerby != null:
		passerby.set_parameter("behavior_mode", "IDLE")
		for entry in make_snapshot()["entities"]:
			if entry["id"] == PASSERBY:
				_initial_passerby = entry
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -220
	panel.offset_right = 220
	panel.offset_top = -160
	panel.offset_bottom = 160
	$Interface.add_child(panel)
	panel.hide()
	_city_tool_panel = panel


func _door_source(data: Variant) -> Dictionary:
	if not data is Dictionary or data.is_empty():
		return {}
	if data.size() != 3 or not data.get("address") is String or data["address"] not in _ordinary_public_addresses() or data["address"] == City.HOME_ID:
		return {}
	if not CityTools.number(data.get("x"), -10000.0, 10000.0) or not CityTools.number(data.get("y"), -10000.0, 10000.0):
		return {}
	var point := Vector2(float(data["x"]), float(data["y"]))
	if _entity_location(point) != data["address"] or not can_return_traveler(point, 0.0) or not actor._is_dry(point, 0.0):
		return {}
	return data.duplicate(true)


func _door_return_point() -> Dictionary:
	if not _door_session_is_live():
		return {}
	var point := Vector2(float(luna_door_session["x"]), float(luna_door_session["y"]))
	var address: String = luna_door_session["address"]
	for offset in [Vector2.ZERO, Vector2(32, 0), Vector2(-32, 0), Vector2(0, 32), Vector2(0, -32)]:
		var candidate: Vector2 = point + offset
		if _ordinary_arrival_is_safe(address, candidate):
			return {"point": candidate, "address": address, "label": "Вернуться через Дверь Луны"}
	return {}


func _door_body() -> LunaDoor:
	return entities.get_entity(LunaDoor.ID) as LunaDoor


func _door_session_is_live() -> bool:
	var door := _door_body()
	if door == null or luna_door_session.is_empty():
		return false
	var point := Vector2(float(luna_door_session["x"]), float(luna_door_session["y"]))
	return door.is_placed_at(point) and _entity_location(door.position) == luna_door_session["address"]


func _door_at_source() -> bool:
	var door := _door_body()
	return door != null and not door.is_attached() and door.motion.grounded and is_zero_approx(door.motion.elevation) and _entity_location(door.position) == _entity_location(actor.position) and _within_reach(door.position)


func _can_use_placed_luna_door() -> bool:
	return observation_fixture and actor.motion.grounded and not actor.is_attached() and not actor.has_passenger() and is_zero_approx(actor.motion.elevation) and _entity_location(actor.position) != City.HOME_ID and city_tools.owned.has(LunaDoor.TOOL_KEY) and _door_at_source()


func interact_with_attachment(target_id: String = "") -> bool:
	var result := super.interact_with_attachment(target_id)
	var door := _door_body()
	if result and door != null and actor.has_passenger() and actor._rider == door:
		city_tools.acquire(LunaDoor.TOOL_KEY)
		luna_door_session.clear()
		queue_redraw()
	return result


func use_luna_door() -> bool:
	if not observation_fixture or not (actor as EntityBody).accepts_player_input() or actor.is_attached() or not actor.motion.grounded or not is_zero_approx(actor.motion.elevation):
		return false
	var address := _entity_location(actor.position)
	if address == City.HOME_ID:
		if not _within_reach(Vector2(5930, 390)):
			return false
		var back := _door_return_point()
		if back.is_empty():
			return false
		_move_home_travelers(back["point"], back["address"])
		return true
	if not _can_use_placed_luna_door():
		return false
	var door := _door_body()
	var source := _door_source({"address": address, "x": door.position.x, "y": door.position.y})
	if source.is_empty():
		return false
	for point in _ordinary_arrival_points(City.HOME_ID):
		if _ordinary_arrival_is_safe(City.HOME_ID, point):
			luna_door_session = source
			_move_home_travelers(point, City.HOME_ID)
			queue_redraw()
			return true
	return false

func close_luna_door() -> bool:
	if luna_door_session.is_empty() or not (actor as EntityBody).accepts_player_input():
		return false
	var source := Vector2(float(luna_door_session["x"]), float(luna_door_session["y"]))
	if not ((_entity_location(actor.position) == City.HOME_ID and _within_reach(Vector2(5930, 390))) or (_entity_location(actor.position) == luna_door_session["address"] and _within_reach(source))):
		return false
	luna_door_session.clear()
	queue_redraw()
	return true


func _city_tool_action() -> String:
	if not observation_fixture or not actor.motion.grounded or actor.is_attached():
		return ""
	for key in TOOL_POINTS:
		if key in city_tools.owned or _entity_location(TOOL_POINTS[key]) != _entity_location(actor.position):
			continue
		if key == "GRAVITY_GUN":
			if SecretFinds.can_reach(actor.position, actor.motion.elevation, SecretFinds.GRAVITY_POINT, SecretFinds.GRAVITY_HEIGHT):
				return key
		elif _within_reach(TOOL_POINTS[key]):
			return key
	return ""


func _take_city_tool(key: String) -> bool:
	if key != _city_tool_action() or not city_tools.acquire(key):
		return false
	$Interface/SaveNotice.text = "Получено: " + TOOL_NAMES[key]
	queue_redraw()
	return true


func _ordinary_public_addresses() -> Array[String]:
	return [ISLAND_ID, Meadows.LOCATION_ID, ForestBank.LOCATION_ID, Valley.LOCATION_ID, Lake.LOCATION_ID, Valley.CRYSTAL_ID, Coast.LOCATION_ID, City.CITY_ID, City.CAFE_ID, City.HOME_ID, Mountain.MOUNTAIN, Mountain.UPDRAFT, Mountain.SKY, Mountain.ORACLE]


func _observe_city_tools() -> void:
	if not observation_fixture:
		return
	var address := _entity_location(actor.position)
	if address in _ordinary_public_addresses() and address not in city_tools.visited:
		city_tools.visited.append(address)
	for identity in entities.list_ids():
		var target := entities.get_entity(identity) as EntityBody
		if target != null and target.visible and target.get_parameter("alive") and target.location_id == address and _within_reach(target.position, target.motion.elevation):
			city_tools.observe(target.record.category)


func _show_city_tool(key: String) -> bool:
	if key not in city_tools.owned or not is_instance_valid(_city_tool_panel) or not (actor as EntityBody).accepts_player_input() or is_instance_valid(_debug_editor):
		return false
	for child in _city_tool_panel.get_children():
		_city_tool_panel.remove_child(child)
		child.queue_free()
	var content := VBoxContainer.new()
	_city_tool_panel.add_child(content)
	var heading := Label.new()
	heading.text = TOOL_NAMES[key]
	content.add_child(heading)
	match key:
		"BESTIARY":
			var discoveries := Label.new()
			var lines: PackedStringArray = []
			for species in city_tools.seen:
				lines.append(CityTools.SPECIES[species])
			discoveries.text = "\n".join(lines) if not lines.is_empty() else "Пока нет встреченных видов"
			content.add_child(discoveries)
			if not antimemetic.seen.is_empty():
				var hidden_heading := Label.new()
				hidden_heading.text = "Эмоты"
				content.add_child(hidden_heading)
				var hidden_entries := Label.new()
				var names: PackedStringArray = []
				for species in antimemetic.seen:
					names.append(AM.SPECIES[species])
				hidden_entries.text = "\n".join(names)
				content.add_child(hidden_entries)
		"PIXEL_GLOBE":
			var map := Label.new()
			var lines: PackedStringArray = []
			for address in city_tools.visited:
				lines.append(AREA_LABELS.get(address, "Посещённое место"))
			map.text = "\n".join(lines)
			content.add_child(map)
		"REALITY_STAMP":
			for ability in ["GLOW", "FLY"]:
				var button := Button.new()
				button.text = ability + " · доступно %d" % ability_bank.amount(ENTITY_ID, ability)
				button.pressed.connect(_select_stamp.bind(ability))
				content.add_child(button)
			var hint := Label.new()
			hint.text = "T: нанести выбранный временный эффект на ближайшее существо."
			content.add_child(hint)
		"GRAVITY_GUN":
			var hint := Label.new()
			hint.text = "U: притянуть ближайший груз или подтянуться к тяжёлой опоре."
			content.add_child(hint)
	var close := Button.new()
	close.text = "Закрыть"
	close.pressed.connect(_city_tool_panel.hide)
	content.add_child(close)
	_city_tool_panel.show()
	apply_player_input(Vector2.ZERO)
	return true


func _select_stamp(ability: String) -> void:
	_stamp_choice = ability
	_city_tool_panel.hide()


func _bank_open() -> bool:
	return ori.ownership > 0 or tamagotchi_owned or "REALITY_STAMP" in city_tools.owned or _holds_ecology_catalog()


func _stamp_target_allowed(target: EntityBody) -> bool:
	return target != null and target.record.category in OriCatalog.FORMS and target.get_parameter("alive") and target.visible and not target.is_carried() and target.location_id == _entity_location(actor.position) and _within_reach(target.position, target.motion.elevation)


func stamp_ability(target_id: String, ability: String) -> bool:
	if "REALITY_STAMP" not in city_tools.owned or ability not in ["GLOW", "FLY"] or ability_bank.amount(ENTITY_ID, ability) < 1 or not (actor as EntityBody).accepts_player_input():
		return false
	var target := entities.get_entity(target_id) as EntityBody
	if not _stamp_target_allowed(target) or (not city_tools.stamped.has(target_id) and city_tools.stamped.size() >= 12):
		return false
	city_tools.stamped[target_id] = {"ability": ability, "remaining": CityTools.STAMP_SECONDS}
	target.temporary_ability = ability
	return true


func _stamp_nearest() -> bool:
	for id in entities.list_ids():
		if stamp_ability(id, _stamp_choice):
			return true
	return false


func _tick_stamps(delta: float) -> void:
	for id in city_tools.stamped.keys():
		var target := entities.get_entity(id) as EntityBody
		var grant: Dictionary = city_tools.stamped[id]
		grant["remaining"] = maxf(0.0, float(grant["remaining"]) - delta)
		if target == null or grant["remaining"] <= 0.0:
			if target != null:
				target.temporary_ability = ""
			city_tools.stamped.erase(id)
		else:
			target.temporary_ability = grant["ability"]


func gravity_pull(target_id: String = "") -> bool:
	if "GRAVITY_GUN" not in city_tools.owned or not (actor as EntityBody).accepts_player_input() or actor.is_attached():
		return false
	var closest: EntityBody
	var distance := 190.0
	for id in entities.list_ids():
		var target := entities.get_entity(id) as EntityBody
		if target == null or target == actor or target.is_attached() or target.has_passenger() or target.location_id != _entity_location(actor.position) or target.record.category not in ["prop", "fridge"] or (not target_id.is_empty() and target_id != id):
			continue
		if id in [ECOLOGY_CATALOG, Meadows.PLANK_ID, City.BENCH, LAKE_STONE_ID, BRIDGE_YETI_ID]:
			continue
		var gap: float = target.position.distance_to(actor.position)
		if gap < distance and gap > target.foot_radius() + actor.foot_radius() + 3.0 and absf(target.motion.elevation - actor.motion.elevation) <= 35.0:
			closest = target
			distance = gap
	if closest == null:
		return _mountain_anchor_pull() if target_id.is_empty() else false
	var direction_to_actor: Vector2 = (actor.position - closest.position).normalized()
	if float(closest.get_parameter("mass")) > 3.0:
		return actor.apply_impulse(-direction_to_actor * 145.0, 18.0)
	return closest.apply_impulse(direction_to_actor * 115.0 * float(closest.get_parameter("mass")), 20.0)


func _machine_on_plaza() -> bool:
	var fridge := entities.get_entity(YUKI_FRIDGE) as EntityBody
	if fridge == null or fridge.is_attached() or not City.PLAZA.has_point(fridge.position) or not yuki.running:
		return false
	for rule in yuki.rules:
		if rule["enabled"] and rule["action"] == "SPAWN_CAT" and rule["host"] == YUKI_FRIDGE:
			return true
	return false


func _tick_mouse(delta: float) -> void:
	var person := entities.get_entity(PASSERBY) as EntityBody
	if person == null:
		return
	if _machine_on_plaza() and City.PLAZA.has_point(person.position) and person.record.category == "resident" and not person.is_attached() and not person.has_passenger() and person.get_parameter("alive"):
		var size: float = person.get_parameter("size")
		if person.set_parameter("size", 0.55):
			city_tools.mouse_size = size
			city_tools.mouse_time = 0.0
			person.record.category = "mouse"
			person.refresh_form_marker()
	if person.record.category != "mouse":
		return
	if _machine_on_plaza():
		city_tools.mouse_time = 0.0
		return
	city_tools.mouse_time = minf(10.0, city_tools.mouse_time + delta)
	if city_tools.mouse_time < 5.0 or person.is_attached() or person.has_passenger():
		return
	if is_equal_approx(float(person.get_parameter("size")), 0.55) and not person.set_parameter("size", city_tools.mouse_size):
		return
	person.record.category = "resident"
	person.refresh_form_marker()
	city_tools.mouse_size = 0.0
	city_tools.mouse_time = 0.0


func _cleanup_yuki_cats(delta: float) -> void:
	if yuki.has_active_cat_rule():
		city_tools.cleanup = 0.0
		return
	city_tools.cleanup = minf(10.0, city_tools.cleanup + delta)
	if city_tools.cleanup < 1.0:
		return
	city_tools.cleanup = 0.0
	for id in city_tools.cat_sizes.keys():
		var cat := entities.get_entity(id) as EntityBody
		if cat == null:
			city_tools.cat_sizes.erase(id)
			continue
		# Deliberate edits, installed scripts, attachments or permanent modules
		# protect this individual from mass normalization.
		var untouched: bool = cat.record.category == "cat" and is_equal_approx(float(cat.get_parameter("size")), float(city_tools.cat_sizes[id])) and cat.get_parameter("speed") == 2.0 and cat.get_parameter("luna_relation") == "NEUTRAL" and cat.get_parameter("behavior_mode") == "WANDER" and cat.get_parameter("ai_enabled") and cat.get_parameter("control_source") == "NONE" and cat.get_parameter("color") == Color("b790dd") and is_equal_approx(float(cat.get_parameter("mass")), 1.0) and is_zero_approx(float(cat.get_parameter("bounciness"))) and is_equal_approx(float(cat.get_parameter("gravity_scale")), 1.0) and not cat.get_parameter("pickable") and not cat.get_parameter("rideable") and cat.record.get_components().is_empty() and not city_tools.stamped.has(id) and not cat.is_attached() and not cat.has_passenger() and not yuki.rules.any(func(rule): return rule["host"] == id)
		city_tools.cat_sizes.erase(id)
		if untouched:
			entities.unregister_entity(id)
			cat.queue_free()
		return


func _tick_ori_helper() -> void:
	if _friend_at_cafe(City.ORI):
		return
	if ori.ownership != 1 or city_tools.ori_stage == 0 or city_tools.ori_stage == 3:
		return
	var friend_body := entities.get_entity(City.ORI) as EntityBody
	if friend_body == null or friend_body.is_attached() or friend_body.has_passenger() or not friend_body.get_parameter("ai_enabled") or not friend_body.get_parameter("alive"):
		return
	if city_tools.ori_stage == 1:
		if City.SHOP.has_point(friend_body.position):
			friend_body.autonomous_destination = ORI_EXIT
			if friend_body.position.distance_to(ORI_EXIT) < 8.0 and not _spawn_is_occupied(Vector2(5165, 630), 0.0):
				friend_body.position = Vector2(5165, 630)
				friend_body.motion.reset_on_surface(friend_body.position, 0.0)
				friend_body.location_id = City.CITY_ID
		elif City.SOUTH.has_point(friend_body.position) or City.PLAZA.has_point(friend_body.position):
			friend_body.autonomous_destination = ORI_PLAZA
			if friend_body.position.distance_to(ORI_PLAZA) < 8.0:
				friend_body.autonomous_destination = Vector2.INF
				city_tools.ori_stage = 2
	if city_tools.ori_stage != 2 or not City.PLAZA.has_point(friend_body.position):
		return
	if actor.is_riding() and City.PLAZA.has_point(actor.position) and actor.position.distance_to(friend_body.position) < 160.0:
		var carrier := actor._carrier as EntityBody
		if carrier != null and carrier.entity_id.begins_with(ORI_CREATED_PREFIX) and carrier.has_active_ability("FLY") and carrier.motion.elevation > 18.0:
			city_tools.ori_stage = 3
			ori.ownership = 2
			social.complete("ORI")
			$Interface/SaveNotice.text = "Ори: Он правда умеет летать! Каталог теперь твой."


const LEIA_ID := "F1_LEIA"
const LEIA_START := Vector2(1955, -28)
const LEIA_EXIT := Vector2(2058, -28)
const LEIA_TURTLE := "F1_TURTLE"
const LEIA_SEAT := Vector2(1910, -28)
const FRIEND_EXTRA := [
	{"id": LEIA_ID, "category": "leia", "label": "Лея", "material": "FABRIC", "point": LEIA_START},
	{"id": LEIA_TURTLE, "category": "turtle", "label": "Черепашка", "material": "FABRIC", "point": Vector2(1855, -28)},
	{"id": "F1_FOX", "category": "fox", "label": "Лисёнок", "material": "FABRIC", "point": Vector2(1990, -28)},
	{"id": "F1_TROLLIK", "category": "trollik", "label": "Троллик", "material": "FABRIC", "point": Vector2(2026, -28)},
]
const CAFE_TALK := Vector2(5620, 365)
const CAFE_SEATS := [Vector2(5645, 280), Vector2(5645, 330), Vector2(5690, 370), Vector2(5750, 370), Vector2(5795, 330), Vector2(5795, 280), Vector2(5690, 255), Vector2(5750, 255)]
var leia_turtle_seen := false
var leia_free := false
var tamagotchi_owned := false
const TAMAGOTCHI_PET := "TAMAGOTCHI_PET"
const TAMAGOTCHI_FORMS := {"cat": "Котик", "fox": "Лисичка"}
const TamagotchiPanel = preload("res://scripts/skeleton/tamagotchi_panel_2d.gd")
var _tamagotchi_panel: PanelContainer
# A recalled entity is absent from the live registry; its complete record travels in saves.
var _recalled_pet: Dictionary = {}
var evening_stage := 0
var evening_origins: Dictionary = {}
var _evening_delay := 0.0
var _evening_panel: PanelContainer
var _initial_friend_extra: Array[Dictionary] = []


func _friend_ids() -> Array[String]:
	return [City.YUKI, City.ORI, Life.MIA_ID, LEIA_ID, City.TOFFI, Visits.ONI_ID]


func _setup_friend_extra() -> void:
	for definition in FRIEND_EXTRA:
		var body := spawn_entity(definition, definition["point"], 0.0)
		if body == null:
			push_error("Could not place " + definition["id"])
			continue
		body.set_parameter("behavior_mode", "IDLE")
		body.set_parameter("speed", 1.0)
		if definition["id"] != LEIA_ID:
			body.set_parameter("size", 0.65)
	for state in make_snapshot()["entities"]:
		if FRIEND_EXTRA.any(func(definition): return definition["id"] == state["id"]):
			_initial_friend_extra.append(state.duplicate(true))
	_evening_panel = PanelContainer.new()
	_evening_panel.position = Vector2(40, 80)
	$Interface.add_child(_evening_panel)
	_evening_panel.hide()
	_tamagotchi_panel = TamagotchiPanel.new()
	$Interface.add_child(_tamagotchi_panel)


func _tick_leia() -> void:
	if not observation_fixture or _friend_at_cafe(LEIA_ID):
		return
	var leia := entities.get_entity(LEIA_ID) as EntityBody
	var turtle := entities.get_entity(LEIA_TURTLE) as EntityBody
	if leia == null or turtle == null:
		return
	if not leia_turtle_seen and _attraction.remaining <= 0.0 and _schedule_available(turtle):
		turtle.autonomous_destination = LEIA_SEAT
		if turtle.position.distance_to(LEIA_SEAT) < 8.0:
			turtle.autonomous_destination = Vector2.INF
			if actor.position.distance_to(leia.position) < 90.0 and actor.position.distance_to(turtle.position) < 110.0:
				leia_turtle_seen = true
	else:
		turtle.autonomous_destination = Vector2.INF
	if not _schedule_available(leia):
		leia.autonomous_destination = Vector2.INF
		return
	if leia_free:
		leia.autonomous_destination = FriendRoutes.next_point(leia.position, FriendRoutes.LEIA_PATH, world_clock.phase() in [WorldClock.Phase.EVENING, WorldClock.Phase.NIGHT])
		return
	var blocked := false
	for id in ["F1_FOX", "F1_TROLLIK"]:
		var animal := entities.get_entity(id) as EntityBody
		if animal != null and animal.get_parameter("alive") and Geometry2D.get_closest_point_to_segment(animal.position, leia.position, LEIA_EXIT).distance_to(animal.position) < leia.foot_radius() + animal.foot_radius() + 5.0:
			blocked = true
	leia.autonomous_destination = Vector2.INF if blocked else LEIA_EXIT
	if leia.position.distance_to(LEIA_EXIT) < 8.0 and leia.motion.grounded:
		leia_free = true
		leia.autonomous_destination = Vector2.INF


func _sync_leia_pose() -> void:
	if not observation_fixture:
		return
	var leia := entities.get_entity(LEIA_ID) as EntityBody
	if leia == null or not is_instance_valid(leia._marker):
		return
	# Placeholder silhouette only. Collision, size and color are unchanged.
	var buried := not leia_free and not _friend_at_cafe(LEIA_ID) and leia.position.distance_to(LEIA_START) < 25.0
	leia._marker.polygon = PackedVector2Array([Vector2(-12, 0), Vector2(-12, -16), Vector2(-4, -16), Vector2(-4, -5), Vector2(4, -5), Vector2(4, -19), Vector2(12, -19), Vector2(12, 0)]) if buried else PackedVector2Array([Vector2(-12, 0), Vector2(-12, -18), Vector2(0, -32), Vector2(12, -18), Vector2(12, 0)])


func _leia_action() -> String:
	if not observation_fixture or not actor.motion.grounded:
		return ""
	var leia := entities.get_entity(LEIA_ID) as EntityBody
	if not _friend_available(leia) or actor.is_attached() or _entity_location(actor.position) != _entity_location(leia.position) or not _within_reach(leia.position, leia.motion.elevation) or _friend_at_cafe(LEIA_ID):
		return ""
	if leia_free and not tamagotchi_owned:
		return "Помочь Лее"
	if not social.meetings.has("LEIA"):
		return "Посмотреть на черепашку с Леей" if leia_turtle_seen else "Поговорить с Леей"
	return ""


func _interact_leia() -> bool:
	var action := _leia_action()
	if action.is_empty():
		return false
	social.complete("LEIA")
	if leia_free:
		tamagotchi_owned = true
		_active_city_tool = "tamagotchi"
		$Interface/SaveNotice.text = "Лея: Спасибо! Теперь мы можем пройти. Получено: Тамагочи."
	else:
		$Interface/SaveNotice.text = "Лея: Смотри, черепашка добралась!" if leia_turtle_seen else "Лея: Привет! Кажется, меня тут очень любят."
	return true



func spawn_entity(definition: Dictionary, point: Vector2, height: float) -> EntityBody:
	# Keep one capacity slot for the dormant record included in snapshots.
	if definition.get("id") == TAMAGOTCHI_PET or (not _recalled_pet.is_empty() and entities.count_live() >= _entity_limit() - 1):
		return null
	return super.spawn_entity(definition, point, height)


func pet_configuration() -> Dictionary:
	var pet := entities.get_entity(TAMAGOTCHI_PET) as EntityBody
	if pet != null:
		return {"form": pet.record.category, "color": pet.get_parameter("color"), "size": pet.get_parameter("size")}
	if not _recalled_pet.is_empty():
		return {"form": _recalled_pet["category"], "color": Color.html(_recalled_pet["editor"]["color"]), "size": _recalled_pet["movement"]["size"]}
	return {"form": "cat", "color": Color("b790dd"), "size": 0.8}


func _pet_tool_available() -> bool:
	return observation_fixture and ecology_fixture and tamagotchi_owned and (actor as EntityBody).accepts_player_input() and not is_instance_valid(_debug_editor)


func _pet_spawn_point(body: EntityBody) -> Vector2:
	var height: float = actor.motion.elevation
	for offset in [Vector2(42, 0), Vector2(-42, 0), Vector2(0, 42), Vector2(0, -42), Vector2(58, 48), Vector2(-58, 48), Vector2(58, -48), Vector2(-58, -48)]:
		var point: Vector2 = actor.position + offset
		if _entity_location(point) != _entity_location(actor.position) or not _friend_safe(body, point, height):
			continue
		var clear := true
		for id in entities.list_ids():
			var other := entities.get_entity(id) as EntityBody
			if other == null or height >= other.motion.elevation + other.body_height() or other.motion.elevation >= height + body.body_height():
				continue
			if point.distance_to(other.position) < body.foot_radius() + other.foot_radius():
				clear = false
				break
		if clear:
			return point
	return Vector2.INF


func tamagotchi_configure(form: String, color: Color, size: float) -> bool:
	if not _pet_tool_available() or not TAMAGOTCHI_FORMS.has(form) or not parameters.normalize(form, "color", color)["ok"] or not parameters.normalize(form, "size", size)["ok"]:
		return false
	var pet := entities.get_entity(TAMAGOTCHI_PET) as EntityBody
	if pet != null:
		if not pet.get_parameter("alive") or pet.is_attached() or pet.has_passenger() or not pet.motion.grounded or pet.location_id != _entity_location(actor.position) or not _within_reach(pet.position, pet.motion.elevation):
			return false
		# Resize first: geometry rejection must leave the original form and color intact.
		if not pet.set_parameter("size", size):
			return false
		pet.record.category = form
		pet.set_parameter("color", color)
		entities.unregister_entity(TAMAGOTCHI_PET)
		entities.register_entity(TAMAGOTCHI_PET, pet, _target_group(pet))
		pet.refresh_form_marker()
		return true
	if not actor.motion.grounded or actor.is_attached() or entities.count_live() >= _entity_limit():
		return false
	if _recalled_pet.is_empty():
		pet = _build_entity({"id": TAMAGOTCHI_PET, "category": form, "label": "Питомец Луны", "material": "FABRIC"})
		if pet == null:
			return false
		pet.set_parameter("luna_relation", "FRIEND")
		pet.set_parameter("behavior_mode", "FOLLOW")
		pet.set_parameter("target_group", "LUNA")
		pet.set_parameter("follow_distance", 1.0)
	else:
		pet = _build_saved_entity(_recalled_pet, 6)
		if pet == null:
			return false
		pet.record.category = form
	if not pet.restore_movement({"size": size, "speed": pet.get_parameter("speed")}) or not pet.set_parameter("color", color):
		pet.free()
		return false
	var point := _pet_spawn_point(pet)
	if not point.is_finite() or not pet.motion.start_on_safe_support(point, actor.motion.elevation, pet.surfaces):
		pet.free()
		return false
	pet.position = point
	pet.location_id = _entity_location(point)
	if not entities.register_entity(TAMAGOTCHI_PET, pet, _target_group(pet)):
		pet.free()
		return false
	_recalled_pet.clear()
	add_child(pet)
	return true


func tamagotchi_install(ability: String) -> bool:
	if not _pet_tool_available() or ability not in ["GLOW", "FLY"]:
		return false
	var pet := entities.get_entity(TAMAGOTCHI_PET) as EntityBody
	if pet == null or not pet.get_parameter("alive") or not _within_reach(pet.position, pet.motion.elevation) or pet.location_id != _entity_location(actor.position):
		return false
	for instance_id in actor.record.get_component("ABILITY_BANK").get("instances", {}):
		if ORI_MODULES.get(instance_id, "") == ability and ability_bank.move_instance(ENTITY_ID, TAMAGOTCHI_PET, instance_id, false):
			if ability == "FLY":
				pet.set_parameter("rideable", true)
			return true
	return false


func toggle_tamagotchi() -> bool:
	if not _pet_tool_available():
		return false
	var pet := entities.get_entity(TAMAGOTCHI_PET) as EntityBody
	if pet == null:
		var setup := pet_configuration()
		return tamagotchi_configure(setup["form"], setup["color"], float(setup["size"]))
	# Never remove a carrier, a carried body, a temporary stamp, or a live program host.
	if not pet.motion.grounded or pet.is_attached() or pet.has_passenger() or not pet.get_parameter("alive") or city_tools.stamped.has(TAMAGOTCHI_PET) or yuki.rules.any(func(rule): return rule["host"] == TAMAGOTCHI_PET):
		return false
	if not pet.motion._has_support(SPAWN, 0.0, pet.surfaces, true) or not pet.fits_walls_at(SPAWN, 0.0, pet.foot_radius()) or not pet._is_dry(SPAWN, 0.0):
		return false
	# The inactive snapshot uses a stable dry anchor, not a conditional bridge.
	# No active body is left there: the move, record and unregister are synchronous.
	_place_friend(pet, SPAWN, 0.0)
	for state in make_snapshot()["entities"]:
		if state["id"] == TAMAGOTCHI_PET:
			_recalled_pet = state.duplicate(true)
			break
	if _recalled_pet.is_empty():
		return false
	entities.unregister_entity(TAMAGOTCHI_PET)
	# History may reference the removed Node; the saved Entity ID and components survive.
	commands.clear_history()
	pet.free()
	return true


func _open_tamagotchi() -> bool:
	if not _pet_tool_available() or not is_instance_valid(_tamagotchi_panel):
		return false
	_active_city_tool = "tamagotchi"
	_tamagotchi_panel.open_for(self)
	apply_player_input(Vector2.ZERO)
	return true


func _friend_at_cafe(id: String) -> bool:
	return evening_stage in [2, 3] or (evening_stage == 4 and evening_origins.has(id))


func _friend_available(body: EntityBody) -> bool:
	return body != null and body.visible and body.get_parameter("alive") and body.get_parameter("ai_enabled") and not body.is_attached() and not body.has_passenger() and body.motion.grounded


func _friend_safe(body: EntityBody, point: Vector2, height: float, ignore: Array = []) -> bool:
	if not body.motion._has_support(point, height, body.surfaces, true) or not body.fits_walls_at(point, height, body.foot_radius()) or not body._is_dry(point, height):
		return false
	for id in entities.list_ids():
		if id == body.entity_id or id in ignore:
			continue
		var other := entities.get_entity(id) as EntityBody
		if other != null and absf(other.motion.elevation - height) < 1.0 and other.position.distance_to(point) < other.foot_radius() + body.foot_radius():
			return false
	return true


# Ordinary social contact with these three friends needs no tool, recipe,
# catalog order or scripted demonstration. Keep optional tool interactions.
func _ordinary_friend_target() -> String:
	if not observation_fixture or evening_stage in [1, 2, 3] or not actor.motion.grounded or actor.is_attached():
		return ""
	var choices := {City.YUKI: "YUKI", City.ORI: "ORI", Life.MIA_ID: "MIA", City.TOFFI: "TOFFI"}
	var closest := INF
	var result := ""
	for id in choices:
		var friend: String = choices[id]
		var body := entities.get_entity(id) as EntityBody
		if friend in social.meetings or not _friend_available(body) or _friend_at_cafe(id):
			continue
		if id == City.TOFFI and not Meadows.M2.has_point(body.position):
			continue
		if _entity_location(body.position) != _entity_location(actor.position) or not _within_reach(body.position, body.motion.elevation):
			continue
		var distance: float = actor.position.distance_squared_to(body.position)
		# The laboratory's physical controls remain accessible without being
		# intercepted by the nearby NPC.
		if id == Life.MIA_ID and _at_alchemy_station() and actor.position.distance_squared_to(MiaLab.STATION) < distance:
			continue
		if distance < closest:
			closest = distance
			result = friend
	return result


func _meet_ordinary_friend() -> bool:
	var friend := _ordinary_friend_target()
	if friend.is_empty() or not social.complete(friend):
		return false
	var names := {"YUKI": "Юки", "ORI": "Ори", "MIA": "Мия"}
	if friend == "TOFFI":
		$Interface/SaveNotice.text = "Тоффи вздыхает и продолжает играть."
	else:
		$Interface/SaveNotice.text = "Встреча: " + names[friend]
	return true


func _near_city_resident() -> bool:
	if not observation_fixture or not actor.motion.grounded or actor.is_attached() or actor.has_passenger():
		return false
	var resident := entities.get_entity(PASSERBY) as EntityBody
	return _friend_available(resident) and resident.record.category == "resident" and resident.location_id == City.CITY_ID and _entity_location(actor.position) == City.CITY_ID and _within_reach(resident.position, resident.motion.elevation)


func _city_resident_line() -> String:
	# Small optional ordinary remark, not an unlock, tracked quest or marker.
	# The narrow time window is temporary staging, not a published schedule.
	if hero_profile.active == HeroProfile.LUNA and world_clock.is_in_window(16 * 60 + 10, 16 * 60 + 25) and not (meta_merged.is_valid() and meta_merged.call()):
		return "Прохожий: Кажется, я тебя здесь уже видел. Ты что, подстриглась?"
	return "Прохожий: Сегодня на площади довольно спокойно."


func _near_ori_customer() -> bool:
	if not observation_fixture or not actor.motion.grounded or actor.is_attached() or actor.has_passenger() or not City.SHOP.has_point(actor.position):
		return false
	var customer := entities.get_entity(ORI_CUSTOMER) as EntityBody
	return _friend_available(customer) and customer.record.category == "resident" and City.SHOP.has_point(customer.position) and _within_reach(customer.position, customer.motion.elevation)


func _ori_customer_line() -> String:
	# A current observation, not a delivery order, reward or memory flag.
	var customer := entities.get_entity(ORI_CUSTOMER) as EntityBody
	if customer != null:
		for identity in entities.list_ids():
			if not identity.begins_with(ORI_CREATED_PREFIX):
				continue
			var creature := entities.get_entity(identity) as EntityBody
			if creature != null and creature.visible and creature.get_parameter("alive") and City.SHOP.has_point(creature.position) and creature.position.distance_to(customer.position) <= 100.0 and absf(creature.motion.elevation - customer.motion.elevation) <= 48.0 and creature.has_active_ability("GLOW"):
				return "Посетитель: Какая прелесть! С этим зверьком и ночник не нужен."
	return "Посетитель: Зашёл просто посмотреть. Тут каждый раз кто-нибудь новенький."


# Explicit ordinary invitations are independent of the artifact inventory.
func _friend_invitation_target() -> String:
	if not observation_fixture or evening_stage != 0 or not actor.motion.grounded or actor.is_attached():
		return ""
	var friend_by_entity := {
		City.YUKI: "YUKI", City.ORI: "ORI", Life.MIA_ID: "MIA",
		LEIA_ID: "LEIA", City.TOFFI: "TOFFI", Visits.ONI_ID: "ONI",
	}
	var closest := INF
	var result := ""
	for id in friend_by_entity:
		var friend: String = friend_by_entity[id]
		var body := entities.get_entity(id) as EntityBody
		if not social.can_invite(friend) or not _friend_available(body):
			continue
		if id == City.TOFFI and (City.HIDDEN_STREET.has_point(body.position) or AM.NICHE.has_point(body.position)):
			continue
		if _entity_location(body.position) != _entity_location(actor.position) or not _within_reach(body.position, body.motion.elevation):
			continue
		var distance: float = actor.position.distance_squared_to(body.position)
		if id == Life.MIA_ID and _at_alchemy_station() and actor.position.distance_squared_to(MiaLab.STATION) < distance:
			continue
		if distance < closest:
			closest = distance
			result = friend
	return result


func _invite_nearby_friend() -> bool:
	var friend := _friend_invitation_target()
	if friend.is_empty() or not social.invite(friend):
		return false
	var replies := {
		"YUKI": "Юки: Договорились! Загляну после работы.",
		"ORI": "Ори: Конечно, увидимся в кафе!",
		"MIA": "Мия: Отлично, посидим вместе.",
		"LEIA": "Лея: Давай! Я приду.",
		"TOFFI": "Тоффи: Ага, до встречи!",
		"ONI": "Они: С удовольствием.",
	}
	$Interface/SaveNotice.text = replies[friend]
	return true


func _cafe_plan() -> Dictionary:
	var result: Dictionary = {}
	var ids := _friend_ids()
	for id in ids:
		var body := entities.get_entity(id) as EntityBody
		if not _friend_available(body):
			return {}
		for point in CAFE_SEATS:
			if not _friend_safe(body, point, 0.0, ids):
				continue
			var occupied := false
			for other_id in result:
				var other := entities.get_entity(other_id) as EntityBody
				var other_point: Vector2 = result[other_id]
				if other_point.distance_to(point) < other.foot_radius() + body.foot_radius():
					occupied = true
			if not occupied:
				result[id] = point
				break
		if not result.has(id):
			return {}
	return result


func _place_friend(body: EntityBody, point: Vector2, height: float) -> void:
	body.position = point
	body.motion.reset_on_surface(point, height)
	body.location_id = _entity_location(point)
	body.autonomous_destination = Vector2.INF
	body.music_interest = Vector2.INF
	body.profile_interest = Vector2.INF
	body.profile_interest_gap = 0.0
	body.velocity = Vector2.ZERO
	body._sync_projection()


func _cafe_near() -> bool:
	return observation_fixture and _entity_location(actor.position) == City.CAFE_ID and actor.motion.grounded and not actor.is_attached() and _within_reach(CAFE_TALK)


func _cafe_action() -> String:
	if not _cafe_near():
		return ""
	match evening_stage:
		0: return "Предложить встретиться вечером" if social.can_gather() else ""
		1: return "Друзья собираются"
		2: return "Посидеть вместе"
		3: return "Продолжить вечер"
	return ""


func begin_cafe_evening() -> bool:
	if evening_stage != 0 or not _cafe_near() or not social.can_gather() or _cafe_plan().size() != 6:
		return false
	evening_stage = 1
	_evening_delay = 1.8
	world_clock.set_time_of_day(WorldClock.EVENING_MINUTE + 30)
	_show_evening_panel()
	return true


func _tick_cafe(delta: float) -> void:
	if not observation_fixture:
		return
	if evening_stage == 1:
		_evening_delay -= delta
		if _evening_delay > 0.0:
			return
		var plan := _cafe_plan()
		if plan.size() != 6:
			evening_stage = 0
			social.legacy_evening = false
			_evening_panel.hide()
			$Interface/SaveNotice.text = "Пока не все могут прийти. Попробуй позже."
			return
		for id in plan:
			var body := entities.get_entity(id) as EntityBody
			evening_origins[id] = [body.position.x, body.position.y, body.motion.elevation]
			_place_friend(body, plan[id], 0.0)
		evening_stage = 2
		_evening_panel.hide()
	elif evening_stage == 4:
		for id in evening_origins.keys():
			var body := entities.get_entity(id) as EntityBody
			var origin: Array = evening_origins[id]
			var point := Vector2(origin[0], origin[1])
			if _friend_available(body) and _friend_safe(body, point, float(origin[2])):
				_place_friend(body, point, float(origin[2]))
				evening_origins.erase(id)


func finish_cafe_evening() -> bool:
	if evening_stage != 2 or not _cafe_near():
		return false
	for id in _friend_ids():
		var body := entities.get_entity(id) as EntityBody
		if body == null or _entity_location(body.position) != City.CAFE_ID:
			return false
	evening_stage = 3
	_show_evening_panel()
	return true


func _finish_ordinary_credits() -> void:
	if evening_stage == 3:
		evening_stage = 4
		_show_evening_panel()


func ordinary_finale_voice() -> String:
	# The same request plays in either order; after merging it is remembered
	# rather than a new unfinished call. No discovery, quest or access change.
	var line := "На мгновение всё замирает.\n\n…Луна… Помоги мне…\n\nГолос исчезает."
	if meta_merged.is_valid() and meta_merged.call():
		line += "\n\nЛуна узнаёт отголосок знакомого голоса."
	return line


func _show_evening_panel() -> void:
	for child in _evening_panel.get_children():
		_evening_panel.remove_child(child)
		child.queue_free()
	var box := VBoxContainer.new()
	_evening_panel.add_child(box)
	var label := Label.new()
	label.custom_minimum_size.x = 420.0
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(label)
	var button := Button.new()
	box.add_child(button)
	match evening_stage:
		0:
			label.text = "Давно мы все вместе не собирались. Может, сегодня?"
			button.text = "Начать вечер"
			button.pressed.connect(func(): begin_cafe_evening())
			var later := Button.new()
			later.text = "Позже"
			later.pressed.connect(_evening_panel.hide)
			box.add_child(later)
		1:
			label.text = "Лиловеет небо. Друзья собираются в кафе…"
			button.hide()
		2:
			label.text = "Юки, Ори, Мия, Лея, Тоффи, Они и Луна.\n\n— Завтра опять куда-нибудь?\n— Ага. Но сейчас давайте посидим."
			button.text = "Завершить вечер"
			button.pressed.connect(func(): finish_cafe_evening())
		3:
			label.text = ordinary_finale_voice()
			button.text = "Далее"
			button.pressed.connect(_finish_ordinary_credits)
		4:
			label.text = "LUNA: Dev Mode\n\nОбычная история Этернии\n\nПутешествие продолжается."
			button.text = "Продолжить игру"
			button.pressed.connect(_evening_panel.hide)
	_evening_panel.show()
	apply_player_input(Vector2.ZERO)


func _evening_snapshot() -> Dictionary:
	return {"turtle_seen": leia_turtle_seen, "leia_free": leia_free, "tamagotchi": tamagotchi_owned, "stage": evening_stage, "origins": evening_origins.duplicate(true)}


func _valid_evening(data: Variant) -> bool:
	if not data is Dictionary:
		return false
	for key in ["turtle_seen", "leia_free", "tamagotchi"]:
		if not data.get(key) is bool:
			return false
	if data["tamagotchi"] and not data["leia_free"]:
		return false
	var raw_stage: Variant = data.get("stage")
	# JSON numbers are floats; validate the value before canonicalizing to an int.
	if typeof(raw_stage) not in [TYPE_INT, TYPE_FLOAT] or float(raw_stage) not in [0.0, 1.0, 2.0, 3.0, 4.0]:
		return false
	var stage := int(raw_stage)
	var origins: Variant = data.get("origins")
	if not origins is Dictionary or origins.size() > 6 or (stage < 2 and not origins.is_empty()) or (stage in [2, 3] and origins.size() != 6):
		return false
	for id in origins:
		if id not in _friend_ids() or not origins[id] is Array or origins[id].size() != 3:
			return false
		for value in origins[id]:
			if typeof(value) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(value)) or absf(float(value)) > 10000.0:
				return false
	return true






func _setup_anomalies() -> void:
	for definition in Anomaly.DEFINITIONS:
		var body := spawn_entity(definition, definition["point"], 0.0)
		if body == null:
			push_error("Could not place anomalous resident " + definition["id"])
			continue
		body.set_parameter("size", definition["size"])
		body.set_parameter("speed", definition["speed"])
		body.set_parameter("color", Color(definition["color"]))
		body.set_parameter("behavior_mode", "IDLE")
	for entry in make_snapshot()["entities"]:
		if Anomaly.DEFINITIONS.any(func(definition): return definition["id"] == entry["id"]):
			_initial_anomaly_states.append(entry.duplicate(true))


func _anomaly_available(body: EntityBody, area: Rect2) -> bool:
	return body != null and body.get_parameter("alive") and body.get_parameter("ai_enabled") and body.get_parameter("control_source") == "NONE" and body.get_parameter("behavior_mode") in ["IDLE", "CHASE"] and not body.is_attached() and not body.has_passenger() and body.motion.grounded and area.has_point(body.position) and body.location_id == Edge.ID


func _anomaly_move(body: EntityBody, point: Vector2, area: Rect2) -> bool:
	if not area.has_point(point) or _entity_location(point) != Edge.ID or not _friend_safe(body, point, body.motion.elevation):
		return false
	body.position = point
	body.motion.reset_on_surface(point, body.motion.elevation)
	body.direction = Vector2.ZERO
	body.velocity = Vector2.ZERO
	body._impulse_velocity = Vector2.ZERO
	body._sync_projection()
	return true


func _tick_anomalies(delta: float) -> void:
	if not observation_fixture:
		return
	anomalies.fox_echo_time = maxf(0.0, anomalies.fox_echo_time - delta)
	var fox := entities.get_entity(Anomaly.FOX) as EntityBody
	if _anomaly_available(fox, Anomaly.FOX_BOUNDS):
		var hostile: bool = fox.get_parameter("luna_relation") == "HOSTILE"
		var target: Vector2 = Anomaly.FOX_ROUTE[anomalies.fox_index]
		if hostile and Anomaly.FOX_BOUNDS.has_point(actor.position):
			var away: Vector2 = (fox.position - actor.position).normalized()
			if away.is_zero_approx():
				away = Vector2.RIGHT
			target = actor.position + away * 42.0
			if not Anomaly.FOX_BOUNDS.has_point(target):
				target = Anomaly.FOX_ROUTE[anomalies.fox_index]
		if fox.position.distance_to(target) <= 6.0:
			anomalies.fox_index = (anomalies.fox_index + 1) % Anomaly.FOX_ROUTE.size()
			target = Anomaly.FOX_ROUTE[anomalies.fox_index]
		if anomalies.blink:
			fox.autonomous_destination = Vector2.INF
			anomalies.fox_elapsed = minf(1.6, anomalies.fox_elapsed + delta)
			if anomalies.fox_elapsed >= 1.6:
				var prior: Vector2 = fox.position
				if _anomaly_move(fox, target, Anomaly.FOX_BOUNDS):
					anomalies.fox_echo = prior
					anomalies.fox_echo_time = 0.7
				anomalies.fox_index = (anomalies.fox_index + 1) % Anomaly.FOX_ROUTE.size()
				anomalies.fox_elapsed = 0.0
		else:
			fox.autonomous_destination = target if _friend_safe(fox, target, fox.motion.elevation) else Vector2.INF
	elif fox != null:
		fox.autonomous_destination = Vector2.INF
	var cat := entities.get_entity(Anomaly.CAT) as EntityBody
	if _anomaly_available(cat, Anomaly.CAT_BOUNDS):
		var target: Vector2 = Anomaly.CAT_ROUTE[anomalies.cat_index]
		if cat.position.distance_to(target) <= 7.0:
			anomalies.cat_index = (anomalies.cat_index + 1) % Anomaly.CAT_ROUTE.size()
			target = Anomaly.CAT_ROUTE[anomalies.cat_index]
		cat.autonomous_destination = target
		anomalies.cat_elapsed += delta
		if anomalies.cat_elapsed >= 0.5:
			anomalies.cat_elapsed = 0.0
			anomalies.cat_history.append(cat.position)
			var capacity := anomalies.cat_delay * 2 + 1
			if anomalies.cat_history.size() >= capacity:
				var prior: Vector2 = anomalies.cat_history[0]
				if _anomaly_move(cat, prior, Anomaly.CAT_BOUNDS):
					anomalies.cat_history.clear()
				else:
					anomalies.cat_history.pop_front()
	else:
		anomalies.cat_history.clear()
		if cat != null:
			cat.autonomous_destination = Vector2.INF
	var rabbit := entities.get_entity(Anomaly.RABBIT) as EntityBody
	if _anomaly_available(rabbit, Anomaly.RABBIT_BOUNDS):
		var target: Vector2 = Anomaly.RABBIT_ROUTE[anomalies.rabbit_index]
		if rabbit.position.distance_to(target) <= 7.0:
			anomalies.rabbit_index = (anomalies.rabbit_index + 1) % Anomaly.RABBIT_ROUTE.size()
			target = Anomaly.RABBIT_ROUTE[anomalies.rabbit_index]
		rabbit.autonomous_destination = target
		anomalies.rabbit_elapsed += delta
		if anomalies.rabbit_elapsed >= 0.35:
			anomalies.rabbit_elapsed = 0.0
			anomalies.rabbit_echo = rabbit.position
	else:
		anomalies.rabbit_echo = Vector2.INF
		if rabbit != null:
			rabbit.autonomous_destination = Vector2.INF
	if Edge.D2.merge(Edge.D3).grow(400.0).has_point(actor.position):
		queue_redraw()


func _edit_anomaly(target_id: String, key: String) -> bool:
	# Recheck existing wand authorization on invocation, including reach.
	if super.get_wand_editor_tabs(target_id).is_empty():
		return false
	var body := entities.get_entity(target_id) as EntityBody
	if body == null:
		return false
	if target_id == Anomaly.FOX:
		if key == "BLINK":
			anomalies.blink = not anomalies.blink
			return true
		if key == "NOTICE":
			var hostile: bool = body.get_parameter("luna_relation") != "HOSTILE"
			if not request_wand_parameter_edit(target_id, "size", 1.5 if hostile else 0.85):
				return false
			return request_wand_parameter_edit(target_id, "luna_relation", "HOSTILE" if hostile else "NEUTRAL")
	if target_id == Anomaly.CAT and key == "PAST":
		var next := (Anomaly.CAT_DELAYS.find(anomalies.cat_delay) + 1) % Anomaly.CAT_DELAYS.size()
		anomalies.cat_delay = Anomaly.CAT_DELAYS[next]
		anomalies.cat_history.clear()
		return true
	return false


func _draw_anomalies() -> void:
	if anomalies.fox_echo_time > 0.0 and anomalies.fox_echo.is_finite():
		draw_circle(anomalies.fox_echo - Vector2(0, 12), 9.0, Color(0.67, 0.53, 0.95, anomalies.fox_echo_time * 0.7))
	if anomalies.rabbit_echo.is_finite():
		draw_circle(anomalies.rabbit_echo - Vector2(0, 10), 7.0, Color(0.58, 0.81, 0.98, 0.28))


func _tick_local_time(delta: float) -> void:
	if not observation_fixture or not edge.time_owned:
		return
	if _forward_remaining > 0.0:
		_forward_remaining = maxf(0.0, _forward_remaining - delta)
		if _forward_remaining <= 0.0:
			_stop_time_forward()
	var address := _entity_location(actor.position)
	if address != _time_address:
		_time_address = address
		_time_history.reset(make_snapshot())
	elif _time_history.tick(delta):
		_time_history.record(make_snapshot())


func rewind_local_time(seconds: float = 5.0) -> bool:
	if not edge.time_owned or not (actor as EntityBody).accepts_player_input() or is_instance_valid(_debug_editor) or _forward_remaining > 0.0 or actor.is_attached() or actor.has_passenger() or _time_address != _entity_location(actor.position):
		return false
	var past := _time_history.preview(seconds)
	if past.is_empty():
		return false
	var candidate := make_snapshot()
	var previous: Dictionary = past["world"]
	var local := {}
	for entry in previous["entities"]:
		if entry["location_id"] == _time_address:
			local[entry["id"]] = entry
	var current_count := 0
	for index in candidate["entities"].size():
		var entry: Dictionary = candidate["entities"][index]
		if entry["location_id"] != _time_address:
			continue
		current_count += 1
		var old: Dictionary = local.get(entry["id"], {})
		# A body or finite module that crossed a boundary is never recreated.
		if old.is_empty() or old["category"] != entry["category"] or old.get("components", {}) != entry.get("components", {}) or old["attachment"] != entry["attachment"] or not entry["attachment"]["carrier_id"].is_empty():
			return false
		candidate["entities"][index] = old.duplicate(true)
	if current_count != local.size() or not local.has(ENTITY_ID):
		return false
	if _time_address == Edge.SERVICE:
		candidate["edge"]["elapsed"] = previous["edge"]["elapsed"]
	# Keep discoveries, artifacts, world clock, foreign bodies and profile journal.
	if not apply_snapshot(candidate):
		return false
	_time_address = _entity_location(actor.position)
	_time_history.commit_rewind(float(past["time"]))
	_time_history.reset(make_snapshot())
	return true


func start_time_forward() -> bool:
	if not edge.time_owned or _forward_remaining > 0.0 or not (actor as EntityBody).accepts_player_input() or is_instance_valid(_debug_editor) or actor.is_attached() or actor.has_passenger():
		return false
	_forward_behavior = actor.get_parameter("behavior_mode")
	if not actor.set_parameter("behavior_mode", "WANDER"):
		return false
	actor.set_parameter("control_source", "NONE")
	actor.set_parameter("ai_enabled", true)
	_forward_remaining = 6.0
	return true


func _stop_time_forward() -> void:
	if not _forward_behavior.is_empty():
		actor.set_parameter("behavior_mode", _forward_behavior)
		actor.set_parameter("control_source", "PLAYER")
		actor.set_parameter("ai_enabled", false)
	_forward_remaining = 0.0
	_forward_behavior = ""


func _tick_edge(delta: float) -> void:
	if not observation_fixture:
		return
	var was_intact := edge.elapsed < Edge.INTACT_SECONDS
	edge.elapsed = fposmod(edge.elapsed + world_clock.sim_delta(delta), Edge.CYCLE_SECONDS)
	var intact := edge.elapsed < Edge.INTACT_SECONDS
	if intact and not _surfaces.has(Edge.CYCLE_SPAN):
		_surfaces.append(Edge.CYCLE_SPAN)
	elif not intact:
		_surfaces.erase(Edge.CYCLE_SPAN)
	if was_intact != intact:
		queue_redraw()
	if not ghost_offer.is_empty() and (world_clock.phase() != WorldClock.Phase.NIGHT or actor.position.distance_to(_ghost_point()) > 180.0):
		ghost_offer = ""
		queue_redraw()


func _ghost_point() -> Vector2:
	if ghost_offer == Meadows.LOCATION_ID:
		return City.MEADOWS_STATION + Vector2(42, 0)
	if ghost_offer == City.CITY_ID:
		return City.BOARD + Vector2(42, 0)
	return Vector2.INF


func _ghost_action() -> bool:
	return observation_fixture and ghost_ride_requested.is_valid() and not ghost_offer.is_empty() and world_clock.phase() == WorldClock.Phase.NIGHT and actor.motion.grounded and not actor.is_attached() and actor.position.distance_to(_ghost_point()) <= 20.0


func _edge_action() -> String:
	if not observation_fixture or not actor.motion.grounded or actor.is_attached():
		return ""
	var address := _entity_location(actor.position)
	if address == Edge.ID and _within_reach(Edge.RETURN):
		return "Вернуться на побережье"
	if address == Edge.ID and _oni_edge_near():
		return "Поговорить с Они"
	if address == Edge.ID and _within_reach(Edge.ONI_RECORD):
		return "Рассмотреть рисунок"
	if address == Edge.REFUGE and _within_reach(Edge.NOTE):
		return "Прочесть личную запись"
	if address == Edge.SERVICE and _within_reach(Edge.DESK) and Edge.D4_DESK.has_point(actor.position) and not edge.time_owned:
		return "Взять Кнопку времени"
	if Edge.D8.has_point(actor.position):
		if actor.position.distance_to(Edge.PORTAL_A) <= 24.0 or actor.position.distance_to(Edge.PORTAL_B) <= 24.0:
			return "Пройти через стационарный портал"
		if not edge.portal_owned and _within_reach(Vector2(3460, 1445)):
			return "Взять Портал-ган"
	if edge.portal_owned and edge.portal_a.size() == 2 and edge.portal_b.size() == 2 and (actor.position.distance_to(Vector2(edge.portal_a[0], edge.portal_a[1])) <= 22.0 or actor.position.distance_to(Vector2(edge.portal_b[0], edge.portal_b[1])) <= 22.0):
		return "Пройти через переносной портал"
	return ""


func _portal_transfer(destination: Vector2, turn: float) -> bool:
	var address := _entity_location(destination)
	if not _ordinary_arrival_is_safe(address, destination):
		return false
	var planar: Vector2 = actor._impulse_velocity.rotated(turn)
	var drive: Vector2 = actor.direction.rotated(turn)
	_move_home_travelers(destination, address)
	actor._impulse_velocity = planar
	actor.direction = drive
	return true


func _interact_edge() -> bool:
	match _edge_action():
		"Вернуться на побережье":
			if not _ordinary_arrival_is_safe(Coast.LOCATION_ID, Edge.COAST_RETURN):
				return false
			_move_home_travelers(Edge.COAST_RETURN, Coast.LOCATION_ID)
			return true
		"Поговорить с Они":
			if not _oni_edge_near():
				return false
			$Interface/SaveNotice.text = "Они: Я всё пытаюсь понять, почему здесь линии не сходятся. Мне казалось, ты уже была здесь… Ты раньше немного иначе выглядела."
			return true
		"Рассмотреть рисунок":
			$Interface/SaveNotice.text = "Несколько линий сходятся к пустому месту. На полях — зачёркнутые варианты и вопросительный знак."
			return true
		"Прочесть личную запись":
			$Interface/SaveNotice.text = "На листе прямоугольник окна (WINDOWED). След шагов продолжается за его границей; рядом незаконченный рисунок GAME_FRAME и рабочего стола."
			return true
		"Взять Кнопку времени":
			edge.time_owned = true
			queue_redraw()
			$Interface/SaveNotice.text = "Кнопка времени · F8: назад / F12: вперёд"
			return true
		"Взять Портал-ган":
			edge.portal_owned = true
			queue_redraw()
			$Interface/SaveNotice.text = "Портал-ган · F10 / F11: установить концы на устойчивой поверхности"
			return true
		"Пройти через стационарный портал":
			return _portal_transfer(Edge.PORTAL_B_EXIT, PI / 2.0) if actor.position.distance_to(Edge.PORTAL_A) <= 24.0 else _portal_transfer(Edge.PORTAL_A_EXIT, -PI / 2.0)
		"Пройти через переносной портал":
			var a := Vector2(edge.portal_a[0], edge.portal_a[1])
			var b := Vector2(edge.portal_b[0], edge.portal_b[1])
			return _portal_transfer(b, 0.0) if actor.position.distance_to(a) <= 22.0 else _portal_transfer(a, 0.0)
	return false


func place_portal(which: int) -> bool:
	if not edge.portal_owned or which not in [0, 1] or not (actor as EntityBody).accepts_player_input() or is_instance_valid(_debug_editor) or actor.is_attached() or not actor.motion.grounded or not is_zero_approx(actor.motion.elevation):
		return false
	var point: Vector2 = actor.position
	if not can_return_traveler(point, 0.0) or not actor._is_dry(point, 0.0):
		return false
	var other: Array = edge.portal_b if which == 0 else edge.portal_a
	if other.size() == 2 and point.distance_to(Vector2(other[0], other[1])) < 64.0:
		return false
	if which == 0:
		edge.portal_a = [point.x, point.y]
	else:
		edge.portal_b = [point.x, point.y]
	queue_redraw()
	return true


func _valid_edge_anchor(anchor: Array) -> bool:
	if anchor.is_empty():
		return true
	var point := Vector2(anchor[0], anchor[1])
	return actor.motion._has_support(point, 0.0, _decks, true) and actor.fits_walls_at(point, 0.0, actor.foot_radius()) and actor._is_dry(point, 0.0)


func _setup_highland() -> void:
	var oracle := spawn_entity({"id": Mountain.ORACLE_ID, "category": "oracle", "label": "Оракул", "material": "FABRIC"}, Mountain.ORACLE_POINT, 18.0)
	var ray := spawn_entity({"id": Mountain.RAY_ID, "category": "ray", "label": "Свободный скат", "material": "FABRIC"}, Mountain.RAY_POINT, 0.0)
	if oracle == null or ray == null:
		push_error("Could not place mountain residents")
		return
	oracle.set_parameter("behavior_mode", "IDLE")
	ray.set_parameter("behavior_mode", "IDLE")
	ray.set_parameter("size", 1.35)
	ray.set_parameter("rideable", true)
	ray.set_parameter("mass", 1.2)
	if ecology_fixture:
		ray.record.set_component("ABILITY_SET", {"instances": {Mountain.FLY_INSTANCE: {"ability_id": "FLY", "enabled": true, "protected": false}}})
	else:
		ray.flight_enabled = true
	for state in make_snapshot()["entities"]:
		if state["id"] in [Mountain.ORACLE_ID, Mountain.RAY_ID]:
			_initial_highland_states.append(state.duplicate(true))


func _highland_action() -> String:
	if not observation_fixture or not actor.motion.grounded or actor.is_attached():
		return ""
	if not highland.camera_owned and Mountain.TREE_POCKET.has_point(actor.position) and _within_reach(Mountain.CAMERA_POINT):
		return "Взять Камеру"
	if not highland.compass_owned and Mountain.H1.has_point(actor.position) and _within_reach(Mountain.COMPASS):
		return "Взять Гравитационный компас"
	var oracle := entities.get_entity(Mountain.ORACLE_ID) as EntityBody
	if oracle != null and oracle.get_parameter("alive") and oracle.location_id == _entity_location(actor.position) and _within_reach(oracle.position, oracle.motion.elevation):
		return "Поговорить с Оракулом"
	if Mountain.H4.has_point(actor.position) and _within_reach(Mountain.H4_NOTE):
		return "Рассмотреть старые рисунки"
	return ""


func _interact_highland() -> bool:
	match _highland_action():
		"Взять Камеру":
			highland.camera_owned = true
			$Interface/SaveNotice.text = "Камера · F4: следовать за Луной / оставить кадр"
			queue_redraw()
			return true
		"Взять Гравитационный компас":
			highland.compass_owned = true
			$Interface/SaveNotice.text = "Компас · F6: изменить силу гравитации"
			queue_redraw()
			return true
		"Поговорить с Оракулом":
			$Interface/SaveNotice.text = "Оракул: Заметила, как лёгкие вещи подхватывает ветер? Тяжёлые иногда даже не шелохнутся."
			return true
		"Рассмотреть старые рисунки":
			$Interface/SaveNotice.text = "На листе три рисунка: палочка у разрыва контура, палочка вдали, две перекрывающиеся области."
			return true
	return false


func cycle_compass() -> bool:
	if not highland.compass_owned or not (actor as EntityBody).accepts_player_input() or is_instance_valid(_debug_editor):
		return false
	highland.gravity_index = (highland.gravity_index + 1) % Mountain.STRENGTHS.size()
	_sync_highland_forces()
	return true


func _setup_profile_panel() -> void:
	_profile_panel = HeroProfilePanel.new()
	_profile_panel.position = Vector2(40, 85)
	$Interface.add_child(_profile_panel)
	_profile_panel.hide()


func _profile_edit_allowed() -> bool:
	if not observation_fixture or not visible or not $Interface.visible or not is_instance_valid(actor) or actor.entity_id != ENTITY_ID or not actor.accepts_player_input():
		return false
	if access.wand_mode != AccessState.DEVELOPER or wand_pair.held.is_empty() or not wand_pair.active().carried or not actor.motion.grounded or not is_zero_approx(float(actor.motion.elevation)) or actor.is_attached() or actor.has_passenger() or is_instance_valid(_debug_editor):
		return false
	return HeroProfile.within_projected_control(actor, _camera, $Interface/ProfilePortrait, 24.0)


func _completed_profile_branches() -> Dictionary:
	return HeroProfile.completed_branches(yuki.ownership, flask_state, ori.ownership, tamagotchi_owned, antimemetic.stage, social.oni_profile_unlocked())


func request_profile_change(profile_id: String) -> bool:
	if not hero_profile.choose(profile_id, _completed_profile_branches(), _profile_edit_allowed()):
		return false
	$Interface/ProfilePortrait.text = HeroProfile.NAMES[hero_profile.active]
	_sync_antimemetic_visibility()
	_tick_profile_attraction()
	queue_redraw()
	return true


func _open_profile_panel() -> bool:
	if not _profile_edit_allowed() or not is_instance_valid(_profile_panel):
		return false
	_profile_panel.configure(hero_profile.available(_completed_profile_branches()), hero_profile.active, request_profile_change)
	apply_player_input(Vector2.ZERO)
	return true


func _setup_window_frame() -> void:
	_window_frame = WindowFrame.new()
	_window_frame.physics_tick = _tick_window_frame
	var layer := CanvasLayer.new()
	layer.layer = 1
	add_child(layer)
	layer.add_child(_window_frame)
	_frame_panel = PanelContainer.new()
	_frame_panel.position = Vector2(430, 340)
	_frame_panel.custom_minimum_size = Vector2(270, 56)
	_frame_switch = CheckButton.new()
	_frame_switch.text = "GAME_FRAME"
	_frame_switch.button_pressed = true
	_frame_switch.toggled.connect(_on_frame_switch)
	_frame_panel.add_child(_frame_switch)
	$Interface.add_child(_frame_panel)
	_frame_panel.hide()


func set_game_mode(mode: String) -> bool:
	if mode not in ["FULLSCREEN", "WINDOWED"] or not (actor as EntityBody).accepts_player_input():
		return false
	game_mode = mode
	_reset_window_frame()
	_update_window_visual()
	return true


func _reset_window_frame() -> void:
	game_frame_solid = true
	_frame_previous = Vector2.INF
	if is_instance_valid(_frame_panel):
		_frame_panel.hide()


func _update_window_visual() -> void:
	if is_instance_valid(_window_frame):
		_window_frame.active = game_mode == "WINDOWED"
		_window_frame.solid = game_frame_solid
		_window_frame.queue_redraw()


func _frame_world_bounds() -> Rect2:
	_camera.force_update_scroll()
	var extent := WindowFrame.logical_size(get_viewport().get_visible_rect().size) / _camera.zoom
	var center := highland.camera_lock if highland.camera_mode == "LOCKED" else _camera.position
	return Rect2(center - extent * (Vector2.ONE * 0.5 - WindowFrame.INSET), extent * (Vector2.ONE - WindowFrame.INSET * 2.0))


func _frame_edit_allowed() -> bool:
	if not desktop_requested.is_valid() or game_mode != "WINDOWED" or highland.camera_mode != "LOCKED" or not highland.camera_owned or access.wand_mode != AccessState.DEVELOPER or not actor.motion.grounded or actor.is_attached() or actor.has_passenger() or not (actor as EntityBody).accepts_player_input() or is_instance_valid(_debug_editor):
		return false
	var bounds := _frame_world_bounds()
	var point: Vector2 = actor.position - Vector2(0, actor.motion.elevation)
	return bounds.grow(2.0).has_point(point) and not bounds.grow(-actor.foot_radius() - 35.0).has_point(point)


func set_game_frame_solid(value: bool) -> bool:
	if not _frame_edit_allowed():
		return false
	game_frame_solid = value
	_update_window_visual()
	return true


func _on_frame_switch(value: bool) -> void:
	if set_game_frame_solid(value):
		_frame_panel.hide()
	else:
		_frame_switch.set_pressed_no_signal(game_frame_solid)


func _tick_window_frame() -> bool:
	_update_window_visual()
	if game_mode != "WINDOWED" or highland.camera_mode != "LOCKED" or not highland.camera_owned:
		_frame_previous = Vector2.INF
		game_frame_solid = true
		return false
	if access.wand_mode != AccessState.DEVELOPER:
		game_frame_solid = true
	var bounds := _frame_world_bounds()
	var current: Vector2 = actor.position - Vector2(0, actor.motion.elevation)
	var previous := _frame_previous
	_frame_previous = current
	if previous == Vector2.INF or not bounds.has_point(previous) or previous.distance_to(current) > 64.0 or not actor.motion.grounded or actor.is_attached() or actor.has_passenger() or not (actor as EntityBody).accepts_player_input():
		return false
	if bounds.has_point(current):
		return false
	var inside := current.clamp(bounds.position + Vector2.ONE, bounds.end - Vector2.ONE)
	var safe := inside + Vector2(0, actor.motion.elevation)
	if not can_return_traveler(safe, actor.motion.elevation):
		# A border crossing cannot replace an existing safe return anchor with an unsafe one.
		safe = previous + Vector2(0, actor.motion.elevation)
		if not can_return_traveler(safe, actor.motion.elevation):
			return false
		inside = previous
	actor.position = safe
	actor.motion.reset_on_surface(safe, actor.motion.elevation)
	actor.location_id = _entity_location(safe)
	actor._sync_projection()
	_frame_previous = inside
	if not game_frame_solid and access.wand_mode == AccessState.DEVELOPER and desktop_requested.is_valid():
		_frame_crossing = true
		var crossed: bool = desktop_requested.call()
		_frame_crossing = false
		if crossed:
			_reset_window_frame()
			return true
	actor._impulse_velocity = Vector2.ZERO
	actor.velocity = Vector2.ZERO
	return false


func toggle_camera_lock() -> bool:
	if not highland.camera_owned or is_instance_valid(_debug_editor) or not (actor as EntityBody).accepts_player_input():
		return false
	if highland.camera_mode == "FOLLOW":
		_update_local_camera()
		_camera.reset_smoothing()
		_camera.force_update_scroll()
		highland.camera_lock = _camera.position
		highland.camera_mode = "LOCKED"
	else:
		highland.camera_mode = "FOLLOW"
	_reset_window_frame()
	_update_local_camera()
	_camera.reset_smoothing()
	_sync_mountain_bridge()
	return true


func return_to_luna() -> bool:
	_stop_time_forward()
	if not super.return_to_luna():
		return false
	highland.camera_mode = "FOLLOW"
	_reset_window_frame()
	_update_local_camera()
	_camera.reset_smoothing()
	_sync_mountain_bridge()
	return true


func _sync_highland_forces() -> void:
	if not observation_fixture:
		return
	for id in entities.list_ids():
		var body := entities.get_entity(id) as EntityBody
		if body == null:
			continue
		body.environmental_wind = Mountain.wind_at(body.position, body.motion.elevation)
		body.world_gravity_multiplier = float(Mountain.STRENGTHS[highland.gravity_index]) if highland.compass_owned else 1.0


func _sync_mountain_bridge() -> void:
	if not observation_fixture:
		return
	_camera.force_update_scroll()
	var extent := _camera.get_viewport_rect().size / _camera.zoom
	var view := Rect2(_camera.get_screen_center_position() - extent * 0.5, extent)
	for surface in [Mountain.CAMERA_BRIDGE, Edge.R07, Edge.BRIDGE]:
		var bounds: Rect2 = surface["bounds"]
		var projected := Rect2(bounds.position - Vector2(0, float(surface["height"])), bounds.size)
		var solid := Solidity.solid_for(Solidity.WHEN_UNOBSERVED, Solidity.CAMERA, {"player_camera": view.intersects(projected)})
		if solid and not _surfaces.has(surface):
			_surfaces.append(surface)
		elif not solid:
			_surfaces.erase(surface)


func _mountain_music_response() -> bool:
	if not observation_fixture or actor.position.distance_to(Mountain.M07_SOURCE) > 160.0 or Mountain.SKY != _entity_location(actor.position) or not is_instance_valid(_am_audio):
		return false
	_mountain_echo = 3.0
	_am_audio.position = Mountain.M07_SOURCE
	_am_audio.stream = Music.tone("U")
	_am_audio.play()
	queue_redraw()
	return true


func _mountain_anchor_pull() -> bool:
	if Mountain.SKY != _entity_location(actor.position):
		return false
	var point := Vector2(Mountain.ANCHOR.x, Mountain.ANCHOR.y)
	var distance: float = actor.position.distance_to(point)
	if distance > 190.0 or distance < 24.0 or not _am_line_clear(point):
		return false
	return actor.apply_impulse((point - actor.position).normalized() * 160.0, 215.0)


func _setup_antimemetic() -> void:
	for definition in AM.DEFINITIONS:
		var body := spawn_entity(definition, definition["point"], 0.0)
		if body == null:
			push_error("Could not place permanent L1 entity " + definition["id"])
			continue
		body.set_parameter("size", definition["size"])
		body.set_parameter("speed", definition["speed"])
		body.set_parameter("behavior_mode", "IDLE" if definition["id"] == AM.GIANT else "WANDER")
		body.set_parameter("color", Color("87bfe8") if definition["id"] == AM.GIANT else Color("f49fc9"))
		body.hide()
	for state in make_snapshot()["entities"]:
		if AM.DEFINITIONS.any(func(definition): return definition["id"] == state["id"]):
			_initial_am_states.append(state.duplicate(true))
	_am_audio = AudioStreamPlayer2D.new()
	_am_audio.max_distance = 400.0
	_am_audio.volume_db = -10.0
	add_child(_am_audio)
	_am_stomp = AM.footfall()
	_connect_bridge_body()


func _am_is_hidden(body: EntityBody) -> bool:
	return body != null and AM.SPECIES.has(body.record.category)


func _am_line_clear(point: Vector2) -> bool:
	# Same physical authored walls as movement; avoid a reveal through room walls.
	var origin: Vector2 = actor.position
	for wall in _walls:
		if actor.motion.elevation >= float(wall["height"]):
			continue
		var bounds: Rect2 = wall["bounds"]
		if bounds.has_point(point):
			continue # A monument's own face is the observed surface.
		var corners := [bounds.position, Vector2(bounds.end.x, bounds.position.y), bounds.end, Vector2(bounds.position.x, bounds.end.y)]
		for index in range(4):
			if Geometry2D.segment_intersects_segment(origin, point, corners[index], corners[(index + 1) % 4]) != null:
				return false
	return true


func _am_revealed(body: EntityBody) -> bool:
	return ((antimemetic.stage > 0 and antimemetic.active) or hero_profile.sees_hidden_creatures()) and body != null and body.get_parameter("alive") and body.location_id == _entity_location(actor.position) and actor.position.distance_to(body.position) <= AM.REVEAL_RANGE and _am_line_clear(body.position)


func _am_gaze(body: EntityBody) -> bool:
	return body != null and body.location_id == _entity_location(actor.position) and bool(crystal_observer.evaluate(actor, null, body.global_position)["luna_eyes"]) and _am_line_clear(body.position)


func _sync_antimemetic_visibility(record_observations: bool = false) -> void:
	if not observation_fixture:
		return
	for definition in AM.DEFINITIONS:
		var body := entities.get_entity(definition["id"]) as EntityBody
		if body == null:
			continue
		body.visible = _am_revealed(body)
		if record_observations and body.visible and _am_gaze(body):
			antimemetic.observe(body.record.category)
			if body.entity_id == AM.GIANT and (City.HIDDEN_STREET.has_point(actor.position) or AM.NICHE.has_point(actor.position)):
				antimemetic.seen_giant = true


func toggle_lantern() -> bool:
	if antimemetic.stage == 0 or not observation_fixture or not (actor as EntityBody).accepts_player_input() or is_instance_valid(_debug_editor):
		return false
	antimemetic.active = not antimemetic.active
	_sync_antimemetic_visibility()
	queue_redraw()
	return true


func _schedule_available(body: EntityBody) -> bool:
	return _friend_available(body) and body.get_parameter("behavior_mode") == "IDLE" and body.get_parameter("control_source") == "NONE"


func _friend_threshold(body: EntityBody, source: Vector2, destination: Vector2) -> bool:
	if body.position.distance_to(source) >= 8.0 or not _friend_safe(body, destination, 0.0):
		return false
	_place_friend(body, destination, 0.0)
	body.direction = Vector2.ZERO
	return true


func _tick_city_friend_schedules() -> void:
	if not observation_fixture:
		return
	var evening := world_clock.phase() in [WorldClock.Phase.EVENING, WorldClock.Phase.NIGHT]
	for id in [City.YUKI, City.ORI]:
		if _friend_at_cafe(id) or (id == City.ORI and city_tools.ori_stage in [1, 2] and ori.ownership == 1):
			continue
		var body := entities.get_entity(id) as EntityBody
		if not _schedule_available(body):
			if body != null:
				body.autonomous_destination = Vector2.INF
			continue
		var room: Rect2 = City.WORKSHOP if id == City.YUKI else City.SHOP
		var inside: Array = FriendRoutes.YUKI_INSIDE if id == City.YUKI else FriendRoutes.ORI_INSIDE
		var outside: Array = FriendRoutes.YUKI_OUTSIDE if id == City.YUKI else FriendRoutes.ORI_OUTSIDE
		if room.has_point(body.position):
			if evening and _friend_threshold(body, inside[-1], outside[0]):
				continue
			body.autonomous_destination = FriendRoutes.next_point(body.position, inside, evening)
		elif _entity_location(body.position) == City.CITY_ID:
			if not evening and _friend_threshold(body, outside[0], inside[-1]):
				continue
			body.autonomous_destination = FriendRoutes.next_point(body.position, outside, evening)
		else:
			body.autonomous_destination = Vector2.INF


func _tick_toffi_route() -> void:
	var toffi := entities.get_entity(City.TOFFI) as EntityBody
	if toffi == null or _friend_at_cafe(City.TOFFI):
		return
	if not _schedule_available(toffi):
		toffi.autonomous_destination = Vector2.INF
		return
	var secret_visit := City.HIDDEN_STREET.has_point(actor.position) or AM.NICHE.has_point(actor.position)
	var meadow_time := FriendRoutes.toffi_meadow_time(world_clock.minute_of_day()) and not secret_visit
	var point := toffi.position
	# A secret approach never completes an ordinary meeting. The same Toffi
	# travels from the meadows, or exits Ori's shop, to the optional street.
	if _entity_location(point) == Meadows.LOCATION_ID:
		if meadow_time:
			var joy := entities.get_entity(AM.JOY) as EntityBody
			if point.distance_to(FriendRoutes.TOFFI_MEADOW) < 75.0 and joy != null and joy.get_parameter("alive") and Meadows.M2.has_point(joy.position):
				var play_point := (joy.position + Vector2(36, 0)).clamp(Meadows.M2.position + Vector2(20, 20), Meadows.M2.end - Vector2(20, 20))
				toffi.autonomous_destination = play_point if point.distance_to(play_point) > 8.0 else Vector2.INF
			else:
				toffi.autonomous_destination = FriendRoutes.next_point(point, FriendRoutes.MEADOW_PATH, false)
		elif not _friend_threshold(toffi, FriendRoutes.MEADOW_GATE, FriendRoutes.CITY_GATE):
			toffi.autonomous_destination = FriendRoutes.next_point(point, FriendRoutes.MEADOW_PATH, true)
		return
	if City.SHOP.has_point(point):
		if not meadow_time and not secret_visit:
			toffi.autonomous_destination = FriendRoutes.next_point(point, FriendRoutes.SHOP_PATH, true)
		elif not _friend_threshold(toffi, FriendRoutes.SHOP_INSIDE, FriendRoutes.SHOP_GATE):
			toffi.autonomous_destination = FriendRoutes.next_point(point, FriendRoutes.SHOP_PATH, false)
		return
	if _entity_location(point) != City.CITY_ID:
		toffi.autonomous_destination = Vector2.INF
		return
	# The secret branch rejoins the public plaza before leaving for another site.
	if point.y < 470.0 and point.x >= 5030.0:
		toffi.autonomous_destination = FriendRoutes.next_point(point, FriendRoutes.SECRET_PATH, secret_visit)
		return
	if secret_visit:
		if point.distance_to(FriendRoutes.PLAZA_TURN) < 8.0:
			toffi.autonomous_destination = FriendRoutes.SECRET_PATH[1]
		elif point.y >= 480.0 and point.x >= 5130.0:
			toffi.autonomous_destination = FriendRoutes.PLAZA_TURN
		else:
			toffi.autonomous_destination = FriendRoutes.next_point(point, FriendRoutes.CITY_PATH, true)
		return
	if meadow_time:
		if not _friend_threshold(toffi, FriendRoutes.CITY_GATE, FriendRoutes.MEADOW_GATE):
			toffi.autonomous_destination = FriendRoutes.next_point(point, FriendRoutes.CITY_PATH, false)
	elif not _friend_threshold(toffi, FriendRoutes.SHOP_GATE, FriendRoutes.SHOP_INSIDE):
		toffi.autonomous_destination = FriendRoutes.next_point(point, FriendRoutes.CITY_PATH, true)


func _toffi_secret_action() -> String:
	if not observation_fixture or not actor.motion.grounded or actor.is_attached() or not AM.NICHE.has_point(actor.position):
		return ""
	var toffi := entities.get_entity(City.TOFFI) as EntityBody
	var giant := entities.get_entity(AM.GIANT) as EntityBody
	if not _friend_available(toffi) or giant == null or not AM.NICHE.has_point(toffi.position) or not _within_reach(toffi.position, toffi.motion.elevation):
		return ""
	if antimemetic.stage == 0:
		return "Взять Фонарь у Тоффи"
	if antimemetic.stage == 1 and antimemetic.seen_giant and actor.position.distance_to(giant.position) >= 115.0 and not _am_gaze(giant):
		return "Вернуться к Тоффи"
	return ""


func _interact_toffi_secret() -> bool:
	match _toffi_secret_action():
		"Взять Фонарь у Тоффи":
			antimemetic.stage = 1
			antimemetic.active = true
			_sync_antimemetic_visibility()
			$Interface/SaveNotice.text = "Тоффи: Сюда! Только не стой посреди дороги!"
			return true
		"Вернуться к Тоффи":
			antimemetic.stage = 2
			$Interface/SaveNotice.text = "Тоффи: Они же никуда не исчезали. Ты просто забывала, на что смотрела. Получено: Фонарь."
			return true
	return false


func _tick_antimemetic(delta: float) -> void:
	if not observation_fixture:
		return
	_tick_toffi_route()
	var giant := entities.get_entity(AM.GIANT) as EntityBody
	if giant != null and giant.get_parameter("ai_enabled") and giant.get_parameter("behavior_mode") == "IDLE" and not giant.is_attached() and not giant.has_passenger():
		# The personal gaze is a stimulus even before the player can perceive the body.
		if (City.HIDDEN_STREET.has_point(actor.position) or AM.NICHE.has_point(actor.position)) and _am_gaze(giant):
			var point: Vector2 = actor.position.clamp(AM.GIANT_RANGE.position + Vector2(6, 6), AM.GIANT_RANGE.end - Vector2(6, 6))
			giant.autonomous_destination = point if giant.position.distance_to(point) > 5.0 else Vector2.INF
		else:
			giant.autonomous_destination = AM.DEFINITIONS[0]["point"] if giant.position.distance_to(AM.DEFINITIONS[0]["point"]) > 8.0 else Vector2.INF
	elif giant != null:
		giant.autonomous_destination = Vector2.INF
	var joy := entities.get_entity(AM.JOY) as EntityBody
	var fox := entities.get_entity(Meadows.FOX_ID) as EntityBody
	if joy != null:
		joy.autonomous_destination = Vector2.INF
		if fox != null and joy.get_parameter("ai_enabled") and joy.get_parameter("behavior_mode") == "WANDER" and Meadows.M2.has_point(fox.position) and Meadows.M2.has_point(joy.position) and joy.position.distance_to(fox.position) > 40.0 and joy.position.distance_to(fox.position) < 130.0:
			joy.autonomous_destination = fox.position + Vector2(26, 0)
	_sync_antimemetic_visibility(true)
	var redraw := antimemetic.visit(AM.MONUMENT_ZONE.has_point(actor.position))
	_am_echo_remaining = maxf(0.0, _am_echo_remaining - delta)
	for definition in AM.DEFINITIONS:
		var body := entities.get_entity(definition["id"]) as EntityBody
		if body == null or body.location_id != _entity_location(actor.position) or body.position.distance_to(actor.position) > 330.0:
			continue
		var tracks: Array = _am_tracks.get(body.entity_id, [])
		if tracks.is_empty() or body.position.distance_to(tracks[-1]) > (22.0 if body.entity_id == AM.GIANT else 17.0):
			if not tracks.is_empty() and body.entity_id == AM.GIANT and is_instance_valid(_am_audio):
				_am_audio.position = body.position
				_am_audio.stream = _am_stomp
				_am_audio.play()
			tracks.append(body.position)
			if tracks.size() > 4:
				tracks.pop_front()
			_am_tracks[body.entity_id] = tracks
		redraw = true
	if redraw or _am_echo_remaining > 0.0:
		queue_redraw()


func _monument_visible() -> bool:
	return observation_fixture and antimemetic.stage > 0 and antimemetic.active and _entity_location(actor.position) == ForestBank.LOCATION_ID and actor.position.distance_to(AM.MONUMENT_POINT) <= AM.REVEAL_RANGE and _am_line_clear(AM.MONUMENT_POINT)


func monument_read() -> String:
	if not _monument_visible() or not prism_active or not crystal_observer.luna_eyes_open or not _within_reach(AM.MONUMENT_POINT):
		return ""
	return Runes.encode(AM.COMMANDS[antimemetic.monument_index])


func _am_music_response() -> bool:
	var nearest: EntityBody
	var distance := 175.0
	for id in [AM.JOY, AM.CURIOUS]:
		var body := entities.get_entity(id) as EntityBody
		if body == null or not body.get_parameter("alive") or body.location_id != _entity_location(actor.position) or not _am_line_clear(body.position):
			continue
		var gap: float = body.position.distance_to(actor.position)
		if gap < distance:
			distance = gap
			nearest = body
	if nearest == null or not is_instance_valid(_am_audio):
		return false
	_am_echo_id = nearest.entity_id
	_am_echo_remaining = 3.0
	_am_audio.position = nearest.position
	_am_audio.stream = Music.tone("L")
	_am_audio.play()
	queue_redraw()
	return true


func _draw_antimemetic() -> void:
	for id in _am_tracks:
		var body := entities.get_entity(id) as EntityBody
		if body == null or body.location_id != _entity_location(actor.position):
			continue
		for point in _am_tracks[id]:
			draw_circle(point, 7.0 if id == AM.GIANT else 3.0, Color(0.31, 0.30, 0.40, 0.55))
	if _am_echo_remaining > 0.0:
		var body := entities.get_entity(_am_echo_id) as EntityBody
		if body != null and body.location_id == _entity_location(actor.position):
			draw_arc(body.position, 18.0 + (3.0 - _am_echo_remaining) * 7.0, 0.0, TAU, 24, Color(0.72, 0.82, 0.88, _am_echo_remaining / 3.0), 1.0)
	if _monument_visible():
		var bounds: Rect2 = AM.MONUMENT["bounds"]
		draw_rect(Rect2(bounds.position - Vector2(0, 58), bounds.size + Vector2(0, 58)), Color("606678"))
		draw_rect(Rect2(bounds.position - Vector2(-5, 53), Vector2(22, 42)), Color("8795a0"), false, 2.0)
		draw_circle(bounds.position + Vector2(6, -25), 3.0, Color("c7e5d6"))
		var reading := monument_read()
		if not reading.is_empty():
			Runes.draw_encoded(self, reading, AM.MONUMENT_POINT + Vector2(-75, -65), Color("f4d99d"), 0.85)
	draw_string(ThemeDB.fallback_font, Vector2(2110, 93), "↑ ↓ → ↓ ← ↑", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("c8c2d2"))


func _spawn_city() -> void:
	_c6_facade = City.create_c6_facade()
	add_child(_c6_facade)
	_sync_c6_facade()
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


func _sync_c6_facade() -> void:
	if is_instance_valid(_c6_facade) and is_instance_valid(actor):
		_c6_facade.visible = not City.c6_behind_facade(actor.position, actor.motion.elevation)


func _tick_city() -> void:
	if not observation_fixture:
		return
	_sync_c6_facade()
	if not luna_door_session.is_empty() and not _door_session_is_live():
		luna_door_session.clear()
		queue_redraw()
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
			if door["id"] == "room" and _door_session_is_live():
				var back := _door_return_point()
				if not back.is_empty():
					return back
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


func _toffi_shop_chat() -> bool:
	if not observation_fixture or not actor.motion.grounded or actor.is_attached() or not City.SHOP.has_point(actor.position):
		return false
	var toffi := entities.get_entity(City.TOFFI) as EntityBody
	var ori_body := entities.get_entity(City.ORI) as EntityBody
	return _friend_available(toffi) and _friend_available(ori_body) and City.SHOP.has_point(toffi.position) and City.SHOP.has_point(ori_body.position) and toffi.position.distance_to(ori_body.position) < 100.0 and _within_reach(toffi.position, toffi.motion.elevation)


func _city_friend_action() -> String:
	if not observation_fixture or not actor.motion.grounded or actor.is_attached():
		return ""
	var yuki_body := entities.get_entity(City.YUKI) as EntityBody
	if yuki_body != null and City.WORKSHOP.has_point(actor.position) and City.WORKSHOP.has_point(yuki_body.position) \
			and yuki_body.get_parameter("alive") and _within_reach(yuki_body.position, yuki_body.motion.elevation) and city_bench_observed and city_bench_active:
		return "Обсудить скамейку с Юки"
	return ""


func _city_friend_interact(action: String) -> bool:
	if action != _city_friend_action():
		return false
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
	if _friend_at_cafe(Visits.ONI_ID):
		return
	var oni := entities.get_entity(Visits.ONI_ID) as EntityBody
	if not _schedule_available(oni):
		if oni != null:
			oni.autonomous_destination = Vector2.INF
		return
	var daytime := world_clock.phase() in [WorldClock.Phase.DAY, WorldClock.Phase.EVENING]
	var destination := Visits.destination_index(world_clock.minute_of_day(), daytime)
	var wants_refuge := _oni_wants_refuge()
	if oni_route_index >= Visits.W8_FIRST_INDEX:
		_tick_oni_refuge(oni, wants_refuge)
		return
	if wants_refuge:
		destination = Visits.W8_JUNCTION
	# If a camera-dependent span vanishes, actual physics owns recovery.
	# Reconcile a recovered body with its own shore, never snap it to the target.
	if oni_route_index in [Visits.BRIDGE_WEST_INDEX, Visits.BRIDGE_EAST_INDEX] and not _surfaces.has(Edge.R07):
		if Coast.CAPE.has_point(oni.position):
			oni_route_index = Visits.BRIDGE_WEST_INDEX
		elif Edge.D0.has_point(oni.position):
			oni_route_index = Visits.BRIDGE_EAST_INDEX
		else:
			oni.autonomous_destination = Vector2.INF
			return
	var target: Vector2 = Visits.ROUTE[oni_route_index]
	if oni.position.distance_to(target) < 5.0:
		if destination == oni_route_index:
			if wants_refuge and oni_route_index == Visits.W8_JUNCTION:
				oni_route_index = Visits.W8_FIRST_INDEX
				oni.autonomous_destination = Visits.ROUTE[oni_route_index]
			else:
				oni.autonomous_destination = Vector2.INF
			return
		var next := oni_route_index + (1 if destination > oni_route_index else -1)
		if mini(next, oni_route_index) == Visits.BRIDGE_WEST_INDEX and not _surfaces.has(Edge.R07):
			oni.autonomous_destination = Vector2.INF
			return
		oni_route_index = next
		target = Visits.ROUTE[oni_route_index]
	oni.autonomous_destination = target


func _oni_wants_refuge() -> bool:
	# She can investigate independently, and an already-open passage permits
	# the visit without making the player wait for a specific hour.
	return Visits.private_refuge_period(world_clock.minute_of_day()) or (
		_w8_open and _entity_location(actor.position) in [W8.PASSAGE, W8.REFUGE])


func _tick_oni_refuge(oni: EntityBody, wants_refuge: bool) -> void:
	# The same physical NPC walks the existing dry geometry. Only the real
	# W8 doorway permits a threshold transfer, under the same return rule as Luna.
	if not _w8_open and oni_route_index in [Visits.W8_NEAR_INDEX, Visits.W8_FAR_INDEX]:
		if oni.position.y < W8.SEAM["bounds"].position.y:
			oni_route_index = Visits.W8_NEAR_INDEX
		elif W8.LANDING.has_point(oni.position):
			oni.autonomous_destination = Vector2.INF
			return
		else:
			# If a support disappears underfoot, the ordinary motion system
			# handles falling and recovery; do not move across the closed seam.
			oni.autonomous_destination = Vector2.INF
			return
	var target: Vector2 = Visits.ROUTE[oni_route_index]
	if oni.position.distance_to(target) >= 5.0:
		oni.autonomous_destination = target
		return
	if wants_refuge:
		if oni_route_index == Visits.W8_STUDY_INDEX:
			oni.autonomous_destination = Vector2.INF
			return
		if oni_route_index == Visits.W8_NEAR_INDEX and not _w8_open:
			oni.autonomous_destination = Vector2.INF
			return
		if oni_route_index == Visits.W8_FAR_INDEX:
			oni.autonomous_destination = Vector2.INF
			if _w8_open and _friend_threshold(oni, W8.FAR, Visits.ROUTE[Visits.W8_ROOM_ENTRY_INDEX]):
				oni_route_index = Visits.W8_ROOM_ENTRY_INDEX
			return
		oni_route_index += 1
	else:
		if oni_route_index == Visits.W8_ROOM_ENTRY_INDEX:
			oni.autonomous_destination = Vector2.INF
			var shore := W8.FAR if _w8_open else W8.NEAR
			if _friend_threshold(oni, Visits.ROUTE[Visits.W8_ROOM_ENTRY_INDEX], shore):
				oni_route_index = Visits.W8_FAR_INDEX if _w8_open else Visits.W8_NEAR_INDEX
			return
		if oni_route_index == Visits.W8_FIRST_INDEX:
			oni_route_index = Visits.W8_JUNCTION
		else:
			oni_route_index -= 1
	oni.autonomous_destination = Visits.ROUTE[oni_route_index]


func _oni_w8_near() -> bool:
	if not observation_fixture or _friend_at_cafe(Visits.ONI_ID) or _entity_location(actor.position) != W8.REFUGE:
		return false
	var oni := entities.get_entity(Visits.ONI_ID) as EntityBody
	return _friend_available(oni) and _entity_location(oni.position) == W8.REFUGE and _within_reach(oni.position, oni.motion.elevation)


func _oni_edge_near() -> bool:
	if not observation_fixture or _friend_at_cafe(Visits.ONI_ID):
		return false
	var oni := entities.get_entity(Visits.ONI_ID) as EntityBody
	return _friend_available(oni) and _entity_location(oni.position) == Edge.ID and oni.position.distance_to(Visits.EDGE_SPOT) < 12.0 and _within_reach(oni.position, oni.motion.elevation)


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
		and SecretFinds.can_reach(actor.position, actor.motion.elevation, SecretFinds.FLUTE_POINT, SecretFinds.FLUTE_HEIGHT)


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
			if world_clock.phase() == WorldClock.Phase.NIGHT and ghost_ride_requested.is_valid() and not _city_station_destination().is_empty():
				ghost_offer = _entity_location(actor.position)
				queue_redraw()
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
		"M07":
			return _mountain_music_response()
		"M09":
			return _am_music_response()
		"M06":
			for point in [CoastExtra.HIGH_VIEW, Vector2(2410, 818), Vector2(2430, 818)]:
				if _ordinary_arrival_is_safe(Coast.LOCATION_ID, point, 18.0):
					_move_home_travelers(point, Coast.LOCATION_ID, 18.0)
					return true
	return false


func _tick_profile_attraction() -> void:
	# Attraction is sensed locally and cannot replace authored destinations,
	# forced behavior, rider input, vital swimming, or explicit AI disable.
	# Body size is used only for safe personal distance, never eligibility.
	var enabled: bool = observation_fixture and visible and hero_profile.attracts_animals() and is_instance_valid(actor) and actor.get_parameter("alive") == true
	var location := _entity_location(actor.position) if enabled else ""
	for id in entities.list_ids():
		var body := entities.get_entity(id) as EntityBody
		body.profile_interest = Vector2.INF
		body.profile_interest_gap = 0.0
		if not enabled or body == actor or id == TAMAGOTCHI_PET or body.record.category not in HeroProfile.ANIMALS:
			continue
		if not body.get_parameter("alive") or not body.get_parameter("ai_enabled") or not body.visible or body.is_attached() or body.has_passenger() or body.get_parameter("control_source") != "NONE" or body.autonomous_destination.is_finite():
			continue
		if body.get_parameter("behavior_mode") not in ["AUTO", "WANDER", "IDLE"] or body.location_id != location:
			continue
		var gap := body.foot_radius() + actor.foot_radius() + 12.0
		var range_px := maxf(80.0, float(body.get_parameter("sense_range")) * 80.0)
		if body.position.distance_to(actor.position) > range_px + gap or absf(body.motion.elevation - actor.motion.elevation) > 48.0:
			continue
		body.profile_interest = actor.position
		body.profile_interest_gap = gap


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


func _tick_shell_collection() -> void:
	if not observation_fixture or shell_collection_ready or not ShellCollection.COVE.has_point(actor.position):
		return
	# Materialize the optional local population once, atomically. Until the
	# cove is visited, distant shell bodies do not add simulation cost.
	var added: Array[String] = []
	var octopus := spawn_entity({"id": ShellCollection.OCTOPUS, "category": "octopus", "label": "Осьминог", "material": "FABRIC"}, ShellCollection.OCTOPUS_POINT, 0.0)
	if octopus == null:
		return
	added.append(ShellCollection.OCTOPUS)
	octopus.set_parameter("behavior_mode", "IDLE")
	for index in range(1, ShellCollection.REQUIRED + 1):
		var identity := ShellCollection.natural_id(index)
		var shell := spawn_entity({"id": identity, "category": "prop", "label": ShellCollection.LABEL, "material": "STONE"}, ShellCollection.shell_point(index), 0.0)
		if shell == null:
			for created in added:
				var body := entities.get_entity(created) as EntityBody
				entities.unregister_entity(created)
				body.free()
			return
		added.append(identity)
		shell.set_parameter("size", 0.5)
		shell.set_parameter("mass", 0.25)
		shell.set_parameter("pickable", true)
	shell_collection_ready = true


func _octopus_action() -> bool:
	if not observation_fixture or not shell_collection_ready or not actor.motion.grounded or actor.is_attached():
		return false
	var octopus := entities.get_entity(ShellCollection.OCTOPUS) as EntityBody
	return octopus != null and octopus.get_parameter("alive") and _entity_location(actor.position) == octopus.location_id and _within_reach(octopus.position, octopus.motion.elevation)


func _talk_octopus() -> bool:
	if not _octopus_action():
		return false
	if shell_collection_delivered:
		$Interface/SaveNotice.text = "Осьминог: Тридцать одинаковых! Как ты это сделала?"
	elif ShellCollection.identical_count(entities) >= ShellCollection.REQUIRED:
		shell_collection_delivered = true
		$Interface/SaveNotice.text = "Осьминог: Все тридцать? И совершенно одинаковые?!"
	else:
		$Interface/SaveNotice.text = "Осьминог: Принеси тридцать одинаковых ракушек и положи их сюда."
	return true


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


func _can_borrow_flask() -> bool:
	var mia := entities.get_entity(Life.MIA_ID) as EntityBody
	return flask_state == 0 and mia_experienced and _at_alchemy_station() and _friend_available(mia) and _within_reach(mia.position, mia.motion.elevation)


func _borrow_flask() -> bool:
	if not _can_borrow_flask():
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
	if not observation_fixture or _friend_at_cafe(Life.MIA_ID):
		return
	var mia := entities.get_entity(Life.MIA_ID) as EntityBody
	if not _schedule_available(mia):
		if mia != null:
			mia.autonomous_destination = Vector2.INF
		return
	if flask_state != 1:
		var daily_path := [Life.MIA_START] + Life.MIA_ROUTE
		mia.autonomous_destination = FriendRoutes.next_point(mia.position, daily_path, world_clock.phase() in [WorldClock.Phase.EVENING, WorldClock.Phase.NIGHT])
		return
	if mia_route_step >= Life.MIA_ROUTE.size():
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
		_alchemy_panel.configure_access(false, flask_state > 0, _can_borrow_flask())
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


func _spawn_quiet_meadow_fauna() -> void:
	for identity in Meadows.QUIET_FAUNA:
		var definition: Dictionary = Meadows.QUIET_FAUNA[identity]
		var body := spawn_entity({"id": identity, "category": definition["category"],
			"label": definition["label"], "material": "FABRIC"}, definition["point"], 0.0)
		if body == null:
			push_error("Could not place meadow resident " + identity)
			continue
		body.set_parameter("size", definition["size"])
		body.set_parameter("speed", definition["speed"])
		body.set_parameter("behavior_mode", "WANDER")
	for entry in make_snapshot()["entities"]:
		if Meadows.QUIET_FAUNA.has(entry["id"]):
			_initial_quiet_states.append(entry.duplicate(true))


func _setup_f2_food() -> void:
	var fairy := spawn_entity({"id": FairyBranch.RESIDENT, "category": "fairy", "label": "Фея", "material": "FABRIC"}, FairyBranch.RESIDENT_POINT, 0.0)
	if fairy != null:
		fairy.set_parameter("size", 0.5)
		fairy.set_parameter("speed", 0.5)
		fairy.set_parameter("behavior_mode", "IDLE")
	else:
		push_error("Could not spawn the F2 resident")
	var snack := spawn_entity({"id": CAFE_SNACK, "category": "food", "label": "Тарелка с пончиками", "material": "FABRIC"}, Vector2(5605, 320), 0.0)
	if snack != null:
		snack.set_parameter("size", 0.5)
		snack.set_parameter("mass", 0.2)
		snack.set_parameter("pickable", true)
		snack.set_parameter("portions", 2)
	else:
		push_error("Could not spawn cafe food")
	for entry in make_snapshot()["entities"]:
		if entry["id"] in [FairyBranch.RESIDENT, CAFE_SNACK]:
			_initial_f2_food_states.append(entry.duplicate(true))


func _fairy_door_action() -> String:
	if not observation_fixture or not actor.motion.grounded or actor.is_attached() or actor.has_passenger():
		return ""
	if FairyBranch.ROOM.has_point(actor.position) and actor.position.distance_to(FairyBranch.INSIDE) <= 20.0:
		return "Выйти на ветвь"
	if FairyBranch.can_enter(actor.position, actor.motion.elevation, actor.body_size):
		return "Войти в домик феи"
	return ""


func _use_fairy_door() -> bool:
	var action := _fairy_door_action()
	if action == "Войти в домик феи" and _ordinary_arrival_is_safe(FairyBranch.ID, FairyBranch.INSIDE):
		_move_home_travelers(FairyBranch.INSIDE, FairyBranch.ID)
		return true
	if action == "Выйти на ветвь" and _ordinary_arrival_is_safe(ForestBank.LOCATION_ID, FairyBranch.DOOR, FairyBranch.HEIGHT):
		_move_home_travelers(FairyBranch.DOOR, ForestBank.LOCATION_ID, FairyBranch.HEIGHT)
		return true
	return false


func _nearby_food() -> EntityBody:
	if not observation_fixture or not actor.motion.grounded or actor.is_attached():
		return null
	var closest: EntityBody
	var distance := INF
	for identity in entities.list_ids():
		var target := entities.get_entity(identity) as EntityBody
		if target.record.category != "food" or not target.get_parameter("edible") or int(target.get_parameter("portions")) <= 0:
			continue
		if target.location_id != _entity_location(actor.position) or (target.is_attached() and not (actor.has_passenger() and actor._rider == target)):
			continue
		var gap := Vector3(target.position.x - actor.position.x, target.position.y - actor.position.y, target.motion.elevation - actor.motion.elevation).length()
		if gap <= 36.0 and gap < distance:
			closest = target
			distance = gap
	return closest


func _eat_nearby_food() -> bool:
	var food := _nearby_food()
	if food == null or not food.set_parameter("portions", int(food.get_parameter("portions")) - 1):
		return false
	$Interface/SaveNotice.text = "Съедена порция. Осталось: %d" % int(food.get_parameter("portions"))
	return true


func _ordinary_copy_source(target: EntityBody) -> bool:
	if target == null or target.record.category not in ["prop", "food"] or target.is_attached() or target.has_passenger() or not target.motion.grounded:
		return false
	# Explicit ordinary source set: no artifact, structural puzzle prop, NPC,
	# finite ability or special machine is silently made replicable.
	return target.entity_id in [City.CRATE, City.BREAD, CAFE_SNACK, LAKE_STONE_ID] or target.entity_id.begins_with(WAND_COPY_PREFIX) or ShellCollection.is_shell(target.entity_id)


func request_wand_copy(target_id: String) -> String:
	if not observation_fixture or not (actor as EntityBody).accepts_player_input():
		return ""
	var source := _wand_target(target_id)
	if not _ordinary_copy_source(source) or not wand_policy.authorize(actor, source, _entity_location(actor.position), projection, access, parameters, "mass"):
		return ""
	if Vector3(actor.position.x - source.position.x, actor.position.y - source.position.y, actor.motion.elevation - source.motion.elevation).length() > WandPolicy.REACH_PX:
		return ""
	var identity := ""
	var shell_source := ShellCollection.is_shell(source.entity_id)
	for index in range(1, WAND_COPY_LIMIT + 1):
		if entities.get_entity(WAND_COPY_PREFIX + str(index)) == null and entities.get_entity(ShellCollection.COPY_PREFIX + str(index)) == null:
			identity = (ShellCollection.COPY_PREFIX if shell_source else WAND_COPY_PREFIX) + str(index)
			break
	if identity.is_empty():
		return ""
	var offsets: Array = ShellCollection.offsets() if shell_source else [Vector2(42, 0), Vector2(-42, 0), Vector2(0, 42), Vector2(0, -42), Vector2(42, 42), Vector2(-42, 42), Vector2(42, -42), Vector2(-42, -42)]
	for offset in offsets:
		var point: Vector2 = source.position + offset
		if _entity_location(point) != _entity_location(source.position):
			continue
		var copy := spawn_entity({"id": identity, "category": source.record.category, "label": source.record.display_name, "material": source.get_parameter("material")}, point, source.motion.elevation)
		if copy == null:
			continue
		var ok := true
		for field in ["size", "mass", "bounciness", "gravity_scale", "speed", "color", "pickable"]:
			if not copy.set_parameter(field, source.get_parameter(field)):
				ok = false
				break
		if ok and source.record.category == "food":
			ok = copy.set_parameter("edible", source.get_parameter("edible")) and copy.set_parameter("portions", source.get_parameter("portions"))
		if not ok:
			entities.unregister_entity(identity)
			copy.free()
			continue
		# No component/ability bank, unique artifact, script or control lease is copied.
		return identity
	return ""


func _spawn_quiet_region_fauna() -> void:
	for identity in QuietRegions.FAUNA:
		var definition: Dictionary = QuietRegions.FAUNA[identity]
		var body := spawn_entity({"id": identity, "category": definition["category"],
			"label": definition["label"], "material": "FABRIC"}, definition["point"], 0.0)
		if body == null:
			push_error("Could not place quiet region resident " + identity)
			continue
		body.set_parameter("size", definition["size"])
		body.set_parameter("speed", definition["speed"])
		body.set_parameter("behavior_mode", "WANDER")
	for entry in make_snapshot()["entities"]:
		if QuietRegions.FAUNA.has(entry["id"]):
			_initial_quiet_region_states.append(entry.duplicate(true))


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
	if species_id not in ["FOX", "CAT"]:
		return false
	var definition := CONSOLE_FOX.duplicate() if species_id == "FOX" else {"category": "cat", "label": "Котик", "material": "FABRIC"}
	for index in _entity_limit():
		var identity := "FOREST_CONSOLE_%s_%02d" % [species_id, index]
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
	if item == null or not item.is_carried() or item.record.category != "prop" or item.entity_id in [ECOLOGY_CATALOG, LunaDoor.ID]:
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
			or source.entity_id == LunaDoor.ID or source.entity_id.begins_with(LAKE_PROP_PREFIX) or source.is_attached() or not _lake_wet(source):
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
	if observation_fixture and identity == LunaDoor.ID and category == "prop":
		return LunaDoor.new()
	if observation_fixture and QuietRegions.FAUNA.has(identity) and category == QuietRegions.FAUNA[identity]["category"]:
		var region_resident := Fauna.new()
		region_resident.birth_point = QuietRegions.FAUNA[identity]["point"]
		region_resident.respawned.connect(fauna_respawned.emit)
		return region_resident
	if Meadows.QUIET_FAUNA.has(identity) and category == Meadows.QUIET_FAUNA[identity]["category"]:
		var resident := Fauna.new()
		resident.birth_point = Meadows.QUIET_FAUNA[identity]["point"]
		resident.respawned.connect(fauna_respawned.emit)
		return resident
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
	if is_instance_valid(_window_frame):
		_window_frame.visible = active
	if not active:
		_reset_window_frame()
		if is_instance_valid(_profile_panel):
			_profile_panel.hide()
	if not active and ancient_console != null:
		ancient_console.close()
	if not active and is_instance_valid(_yuki_panel):
		_yuki_panel.hide()
	if not active and is_instance_valid(_ori_panel):
		_ori_panel.hide()
	if not active and is_instance_valid(_city_tool_panel):
		_city_tool_panel.hide()
	if not active and is_instance_valid(_evening_panel):
		_evening_panel.hide()
	if not active and is_instance_valid(_tamagotchi_panel):
		_tamagotchi_panel.hide()
	process_mode = Node.PROCESS_MODE_PAUSABLE if active else Node.PROCESS_MODE_DISABLED
	visible = active
	$Interface.visible = active
	_camera.enabled = active
	if not active:
		for body in actor.map_travelers():
			body.environmental_wind = Vector3.ZERO
			body.world_gravity_multiplier = 1.0
	if active:
		_update_local_camera()
		_camera.make_current()
		_camera.reset_smoothing()


func can_return_traveler(point: Vector2, height: float) -> bool:
	return actor.motion._has_support(point, height, _decks, true) \
		and ElevationBody.clears_walls(point, height, actor.foot_radius(), _walls)


# Only implemented ordinary locations have authored landing candidates.
# No address catalogue is exposed to the player, and a Feature ID is not a destination.
func _ordinary_arrival_points(address: String) -> Array[Vector2]:
	match address:
		Edge.ID:
			if observation_fixture:
				return [Edge.ENTRY, Edge.FALL_ENTRY]
		Mountain.MOUNTAIN:
			if observation_fixture:
				return [Mountain.ENTRY, Vector2(1590, 1460)]
		Mountain.UPDRAFT:
			if observation_fixture:
				return [Vector2(1500, 1600)]
		Mountain.SKY:
			if observation_fixture:
				return [Vector2(1840, 1780)]
		Mountain.ORACLE:
			if observation_fixture:
				return [Vector2(2050, 1660)]
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
	var giant := entities.get_entity(AM.GIANT) as EntityBody
	if giant != null:
		giant.collision_layer = EntityBody.BODY_OBSTACLE_LAYER
	(actor as EntityBody).secondary_step_obstacle = giant


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
	_sync_w8()
	if not is_instance_valid(_debug_editor):
		world_clock.advance(delta)
		donut_refill = maxf(0.0, donut_refill - delta)
		_ice_duration.tick(delta)
		_alchemy_glow.tick(delta)
		_tick_bubble(world_clock.sim_delta(delta))
		_tick_duplicate(world_clock.sim_delta(delta))
		_tick_lake(world_clock.sim_delta(delta))
		_tick_shell_collection()
		_lab_ice.tick(world_clock.sim_delta(delta))
		_tick_mia()
		_tick_oni()
		_tick_city()
		_tick_yuki(world_clock.sim_delta(delta))
		_tick_ori()
		_tick_ori_helper()
		_tick_city_friend_schedules()
		_tick_leia()
		_sync_leia_pose()
		_tick_antimemetic(world_clock.sim_delta(delta))
		_sync_highland_forces()
		_tick_edge(delta)
		_tick_anomalies(world_clock.sim_delta(delta))
		_tick_local_time(delta)
		if _mountain_echo > 0.0:
			_mountain_echo = maxf(0.0, _mountain_echo - delta)
			queue_redraw()
		_tick_cafe(delta)
		_observe_city_tools()
		_tick_stamps(world_clock.sim_delta(delta))
		_tick_music(world_clock.sim_delta(delta))
		_tick_profile_attraction()
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
	_sync_mountain_bridge()
	var find_visibility := Vector2i(
		int(actor.motion.elevation >= SecretFinds.GRAVITY_HEIGHT and actor.position.distance_to(SecretFinds.GRAVITY_POINT) < 75.0),
		int(actor.motion.elevation >= SecretFinds.FLUTE_HEIGHT and actor.position.distance_to(SecretFinds.FLUTE_POINT) < 75.0))
	if find_visibility != _secret_find_visibility:
		_secret_find_visibility = find_visibility
		queue_redraw()
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
	if tamagotchi_owned:
		_status.text += "  ·  Z: Тамагочи"
	if antimemetic.stage > 0:
		_status.text += "  ·  F3: Фонарь" + (" ✓" if antimemetic.active else "")
	_status.text += "  ·  F1: " + game_mode
	if highland.camera_owned:
		_status.text += "  ·  F4: " + highland.camera_mode
	if highland.compass_owned:
		_status.text += "  ·  F6: g ×%.2f" % Mountain.STRENGTHS[highland.gravity_index]
	if restriction_text.is_valid():
		_status.text += restriction_text.call()
	var action := _nearby_action()
	_prompt.text = "" if action.is_empty() or is_instance_valid(_debug_editor) \
		or (ancient_console != null and ancient_console.is_open()) else "E  " + action


func _update_local_camera() -> void:
	_sync_c6_facade()
	if highland.camera_owned and highland.camera_mode == "LOCKED":
		_camera.position = highland.camera_lock
		return
	if observation_fixture:
		for room in [City.CAFE, City.ROOM, City.WORKSHOP, City.SHOP, RuneRoom.KEY_ROOM, FairyBranch.ROOM]:
			if room.has_point(actor.position):
				_camera.position = room.get_center()
				_camera.zoom = Vector2(2.25, 2.25)
				return
	_camera.position = actor.position
	_camera.zoom = Vector2(1.25, 1.25)


func _apply_keyboard_input() -> void:
	if is_instance_valid(_profile_panel) and _profile_panel.visible:
		if not _profile_edit_allowed():
			_profile_panel.hide()
		apply_player_input(Vector2.ZERO)
		return
	if is_instance_valid(_frame_panel) and _frame_panel.visible:
		apply_player_input(Vector2.ZERO)
		return
	if is_instance_valid(_tamagotchi_panel) and _tamagotchi_panel.visible:
		apply_player_input(Vector2.ZERO)
		return
	if is_instance_valid(_evening_panel) and _evening_panel.visible:
		apply_player_input(Vector2.ZERO)
		return
	if is_instance_valid(_city_tool_panel) and _city_tool_panel.visible:
		apply_player_input(Vector2.ZERO)
		return
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
	var w8_action := _w8_action()
	if not w8_action.is_empty():
		return w8_action
	var fairy_door := _fairy_door_action()
	if not fairy_door.is_empty():
		return fairy_door
	if _ghost_action():
		return "Сесть на призрачного ската"
	var edge_action := _edge_action()
	if not edge_action.is_empty():
		return edge_action
	var city_door := _city_door_action()
	if not city_door.is_empty():
		return city_door["label"]
	if _can_use_placed_luna_door():
		return "Пройти через Дверь Луны"
	if _octopus_action():
		return "Поговорить с осьминогом"
	if _nearby_food() != null:
		return "Съесть порцию"
	var station := _city_station_destination()
	if not station.is_empty():
		return "Рейс в Люму" if station == City.CITY_ID else "Рейс на Большие луга"
	if not _ordinary_friend_target().is_empty():
		return "Поговорить"
	if not _friend_invitation_target().is_empty():
		return "Пригласить в кафе"
	var friend_action := _city_friend_action()
	if not friend_action.is_empty():
		return friend_action
	var yuki_action := _yuki_action()
	if not yuki_action.is_empty():
		return yuki_action
	var ori_action := _ori_action()
	if not ori_action.is_empty():
		return ori_action
	if _toffi_shop_chat():
		return "Послушать разговор"
	var highland_action := _highland_action()
	if not highland_action.is_empty():
		return highland_action
	var toffi_action := _toffi_secret_action()
	if not toffi_action.is_empty():
		return toffi_action
	var leia_action := _leia_action()
	if not leia_action.is_empty():
		return leia_action
	var cafe_action := _cafe_action()
	if not cafe_action.is_empty():
		return cafe_action
	var tool := _city_tool_action()
	if not tool.is_empty():
		return "Взять " + TOOL_NAMES[tool]
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
	if _near_city_resident():
		return "Поговорить с прохожим"
	if _near_ori_customer():
		return "Поговорить с посетителем"
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
	if not _w8_action().is_empty():
		return _interact_w8()
	if _ghost_action():
		return ghost_ride_requested.call()
	if not _edge_action().is_empty():
		return _interact_edge()
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
	if _can_use_placed_luna_door():
		return use_luna_door()
	var station := _city_station_destination()
	if not station.is_empty():
		return public_ride_requested.call(station)
	if _meet_ordinary_friend():
		return true
	if _invite_nearby_friend():
		return true
	var friend_action := _city_friend_action()
	if not friend_action.is_empty():
		return _city_friend_interact(friend_action)
	if not _yuki_action().is_empty():
		return _interact_yuki()
	if not _ori_action().is_empty():
		return _interact_ori()
	if _toffi_shop_chat():
		$Interface/SaveNotice.text = "Ори: А если у ската будут маленькие лапки? Тоффи: Тогда пусть сам выбирает, ходить ему или летать."
		return true
	if _interact_highland():
		return true
	if _interact_toffi_secret():
		return true
	if _interact_leia():
		return true
	if not _cafe_action().is_empty():
		_show_evening_panel()
		return true
	var city_tool := _city_tool_action()
	if not city_tool.is_empty():
		return _take_city_tool(city_tool)
	match _nearby_action():
		"Войти в домик феи", "Выйти на ветвь":
			return _use_fairy_door()
		"Съесть порцию":
			return _eat_nearby_food()
		"Поговорить с осьминогом":
			return _talk_octopus()
		"Пройти через Дверь Луны":
			return use_luna_door()
		"Нырнуть в тоннель":
			return _use_tunnel(Tunnel.WEST_EXIT, Tunnel.LOCATION_ID)
		"Нырнуть в обратный тоннель":
			return _use_tunnel(Tunnel.EAST_EXIT, Tunnel.LOCATION_ID)
		"К тихому озеру":
			return _use_tunnel(Tunnel.W1_RETURN, Valley.LOCATION_ID)
		"К Озеру Дубликатов":
			for landing in Lake.TUNNEL_ARRIVALS:
				if _use_tunnel(landing, Lake.LOCATION_ID):
					return true
			return false
		"Взять Песочные часы":
			return _take_hourglass()
		"Поговорить с Мией":
			return _gift_flask()
		"Взять свирель":
			return _take_flute()
		"Посмотреть вместе с Они":
			return _observe_with_oni()
		"Алхимическая установка":
			_alchemy_panel.configure_access(false, flask_state > 0, _can_borrow_flask())
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
		"Поговорить с прохожим":
			if not _near_city_resident():
				return false
			$Interface/SaveNotice.text = _city_resident_line()
			return true
		"Поговорить с посетителем":
			if not _near_ori_customer():
				return false
			$Interface/SaveNotice.text = _ori_customer_line()
			return true
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


func drop_held_wand() -> bool:
	if not observation_fixture or not (actor as EntityBody).accepts_player_input() or is_instance_valid(_debug_editor) or actor.is_attached() or not actor.motion.grounded or not is_zero_approx(actor.motion.elevation):
		return false
	# Dropping on a conditional span would remove its own source of support.
	if not can_return_traveler(actor.position, 0.0) or not actor._is_dry(actor.position, 0.0):
		return false
	if not wand_pair.drop_held(actor.position, _entity_location(actor.position)):
		return false
	_wand_hold = 0.0
	_sync_w8()
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
	if is_instance_valid(_profile_panel) and _profile_panel.visible:
		if event.keycode in [KEY_ESCAPE, KEY_TAB]:
			_profile_panel.hide()
		get_viewport().set_input_as_handled()
		return
	if is_instance_valid(_tamagotchi_panel) and _tamagotchi_panel.visible:
		if event.keycode == KEY_ESCAPE:
			_tamagotchi_panel.hide()
		get_viewport().set_input_as_handled()
		return
	if is_instance_valid(_evening_panel) and _evening_panel.visible:
		if event.keycode == KEY_ESCAPE and evening_stage != 1:
			_evening_panel.hide()
		get_viewport().set_input_as_handled()
		return
	if is_instance_valid(_city_tool_panel) and _city_tool_panel.visible:
		if event.keycode == KEY_ESCAPE:
			_city_tool_panel.hide()
		get_viewport().set_input_as_handled()
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
	if is_instance_valid(_frame_panel) and _frame_panel.visible:
		if event.keycode == KEY_ESCAPE:
			_frame_panel.hide()
		get_viewport().set_input_as_handled()
		return
	match event.keycode:
		KEY_F1:
			if set_game_mode("WINDOWED" if game_mode == "FULLSCREEN" else "FULLSCREEN"):
				get_viewport().set_input_as_handled()
		KEY_O:
			if use_luna_door():
				get_viewport().set_input_as_handled()
		KEY_I:
			if close_luna_door():
				get_viewport().set_input_as_handled()
		KEY_B:
			if _show_city_tool("BESTIARY"):
				get_viewport().set_input_as_handled()
		KEY_V:
			if _show_city_tool("PIXEL_GLOBE"):
				get_viewport().set_input_as_handled()
		KEY_N:
			if _show_city_tool("REALITY_STAMP"):
				get_viewport().set_input_as_handled()
		KEY_T:
			if _stamp_nearest():
				get_viewport().set_input_as_handled()
		KEY_U:
			if gravity_pull():
				get_viewport().set_input_as_handled()
		KEY_Z:
			if _open_tamagotchi():
				get_viewport().set_input_as_handled()
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
		KEY_F12:
			if start_time_forward():
				get_viewport().set_input_as_handled()
		KEY_F8:
			if rewind_local_time():
				get_viewport().set_input_as_handled()
		KEY_F10:
			if place_portal(0):
				get_viewport().set_input_as_handled()
		KEY_F11:
			if place_portal(1):
				get_viewport().set_input_as_handled()
		KEY_F4:
			if toggle_camera_lock():
				get_viewport().set_input_as_handled()
		KEY_F6:
			if cycle_compass():
				get_viewport().set_input_as_handled()
		KEY_F3:
			if toggle_lantern():
				get_viewport().set_input_as_handled()
		KEY_F2:
			if observation_fixture and not is_instance_valid(_debug_editor):
				set_luna_eyes(not crystal_observer.luna_eyes_open)
				get_viewport().set_input_as_handled()
		KEY_E:
			if interact():
				get_viewport().set_input_as_handled()
			elif not is_instance_valid(_debug_editor):
				if _active_city_tool == "tamagotchi" and tamagotchi_owned:
					if toggle_tamagotchi():
						get_viewport().set_input_as_handled()
				elif _active_city_tool == "ori" and ori.ownership > 0:
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
			if get_wand_editor_tabs(Administrator.ID).is_empty() and _open_profile_panel():
				get_viewport().set_input_as_handled()
				return
			if _frame_edit_allowed():
				_frame_switch.set_pressed_no_signal(game_frame_solid)
				_frame_panel.show()
				_frame_switch.grab_focus()
				get_viewport().set_input_as_handled()
				return
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
			if exchange_nearby_wand() or drop_held_wand():
				get_viewport().set_input_as_handled()
		KEY_ENTER:
			if not is_instance_valid(_debug_editor):
				if _active_city_tool == "tamagotchi" and _open_tamagotchi():
					get_viewport().set_input_as_handled()
				elif ori.ownership > 0 and (_near_ori() or _active_city_tool == "ori") and _open_ori():
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
	return null if (target is Fauna and not target.visible) or (_am_is_hidden(target) and not _am_revealed(target)) else target


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
	if not tabs.is_empty() and target_id == Anomaly.FOX:
		var fox := entities.get_entity(target_id) as EntityBody
		tabs["Разум"].append({"id": "GLITCH_WHERE", "label": "ГДЕ ОНА СЕЙЧАС?", "kind": "action", "value": "НЕ ЗДЕСЬ" if anomalies.blink else "ЗДЕСЬ", "action": func(): return _edit_anomaly(target_id, "BLINK")})
		tabs["Разум"].append({"id": "GLITCH_NOTICE", "label": "ОНО ТЕБЯ ЗАМЕТИЛО", "kind": "action", "value": str(fox.get_parameter("luna_relation") == "HOSTILE"), "action": func(): return _edit_anomaly(target_id, "NOTICE")})
	if not tabs.is_empty() and target_id == Anomaly.CAT:
		tabs["Разум"].append({"id": "RETURN_PAST", "label": "КОГДА ОН БЫЛ ЗДЕСЬ?", "kind": "action", "value": "%d с" % anomalies.cat_delay, "action": func(): return _edit_anomaly(target_id, "PAST")})
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
	if not tabs.is_empty() and _bank_open():
		var target := entities.get_entity(target_id) as EntityBody
		if _can_extract_ori(target):
			var installed: Dictionary = target.record.get_component("ABILITY_SET").get("instances", {})
			for module_id in ORI_MODULES:
				if installed.has(module_id):
					var id: String = module_id
					if not tabs.has("Способности"):
						tabs["Способности"] = []
					tabs["Способности"].append({"id": id, "label": ORI_MODULES[id], "kind": "action", "value": "В банк", "action": func(): return request_extract_ori(target_id, id)})
	if not tabs.is_empty() and _ordinary_copy_source(_wand_target(target_id)):
		tabs["Общее"].append({"id": "COPY", "label": "Copy", "kind": "action", "value": "Copy", "footer": true, "repeatable": true, "action": func(): return not request_wand_copy(target_id).is_empty()})
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
	data["game_mode"] = game_mode
	data["hero_profile"] = hero_profile.active
	# FORWARD is a transient autonomy lease. Disk/recovery saves preserve the
	# physical result but return the player to ordinary input on restoration.
	if not _forward_behavior.is_empty():
		for entry in data["entities"]:
			if entry["id"] == ENTITY_ID:
				entry["control"] = {"ai_enabled": false, "control_source": "PLAYER"}
				entry["editor"]["behavior_mode"] = _forward_behavior
	if observation_fixture:
		data["observation_layout"] = 1
	if ecology_fixture:
		data["ecology_layout"] = 1
		for entry in data["entities"]:
			entry["components"] = entities.get_entity(entry["id"]).record.get_components()
		if observation_fixture:
			data["tamagotchi_recalled"] = not _recalled_pet.is_empty()
			if not _recalled_pet.is_empty():
				data["entities"].append(_recalled_pet.duplicate(true))
	data["island"] = {
		"access": access.snapshot(), "projection": wand_pair.original.snapshot(), "has_donut": has_donut,
		"donut_refill": donut_refill, "retreat_step": retreat_step,
	}
	data["meadows"] = {"ice_remaining": ice_remaining, "layout_version": 2}
	data["quiet_meadow_layout"] = 1
	if observation_fixture:
		data["quiet_regions_layout"] = 2
		data["f2_food_layout"] = 1
		data["shell_collection"] = {"ready": shell_collection_ready, "delivered": shell_collection_delivered}
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
		data["luna_door_layout"] = LunaDoor.LAYOUT_VERSION
		data["yuki_layout"] = 1
		data["yuki"] = yuki.snapshot()
		data["city_tools"] = city_tools.snapshot()
		data["luna_door_session"] = luna_door_session.duplicate(true) if _door_session_is_live() else {}
		if ecology_fixture:
			data["ori_layout"] = 1
			data["ori"] = ori.snapshot()
		data["city_bench_active"] = city_bench_active
		data["city_bench_step"] = city_bench_step
		data["city_bench_observed"] = city_bench_observed
		data["city_ray_settled"] = city_ray_settled
		data["friend_layout"] = 1
		data["social"] = social.snapshot()
		data["friend_extra_layout"] = 1
		data["evening"] = _evening_snapshot()
		data["am_layout"] = 1
		data["antimemetic"] = antimemetic.snapshot()
		data["highland_layout"] = 1
		data["highland"] = highland.snapshot()
		data["edge"] = edge.snapshot()
		data["anomaly_layout"] = 1
		data["anomalies"] = anomalies.snapshot()
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
	var next_game_mode: Variant = data.get("game_mode", "FULLSCREEN")
	if next_game_mode not in ["FULLSCREEN", "WINDOWED"]:
		return false
	var schema: Variant = data.get("address_schema", 0)
	if typeof(schema) not in [TYPE_INT, TYPE_FLOAT] or float(schema) not in [0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 17.0, 18.0, 19.0, float(ADDRESS_SCHEMA)]:
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
	var next_tools := CityTools.new()
	if not next_tools.restore(data.get("city_tools", next_tools.snapshot())):
		return false
	var saved_door: Variant = data.get("luna_door_session", {})
	if not saved_door is Dictionary:
		return false
	var next_door := _door_source(saved_door)
	if not saved_door.is_empty() and (next_door.is_empty() or "LUNA_ROOM_DOOR" not in next_tools.owned):
		return false
	var next_ori := OriCatalog.new()
	if not next_ori.restore(data.get("ori", next_ori.snapshot())):
		return false
	var next_yuki := YukiProgram.new()
	if not next_yuki.restore(data.get("yuki", next_yuki.snapshot())):
		return false
	var next_evening: Variant = data.get("evening", {"turtle_seen": false, "leia_free": false, "tamagotchi": false, "stage": 0, "origins": {}})
	if not _valid_evening(next_evening):
		return false
	var next_recalled: Variant = data.get("tamagotchi_recalled", false)
	if not next_recalled is bool:
		return false
	var pet_count := 0
	for entry in states:
		if not entry is Dictionary:
			continue
		if entry.get("id") == TAMAGOTCHI_PET:
			pet_count += 1
			if not observation_fixture or not ecology_fixture or not next_evening["tamagotchi"] or not TAMAGOTCHI_FORMS.has(entry.get("category")):
				return false
			if next_recalled:
				var attachment: Variant = entry.get("attachment")
				if not attachment is Dictionary or attachment.get("carrier_id") != "" or entry.get("position") != [SPAWN.x, SPAWN.y]:
					return false
		if next_recalled and entry.get("attachment") is Dictionary and entry["attachment"].get("carrier_id") == TAMAGOTCHI_PET:
			return false
	if pet_count > 1 or (next_recalled and (pet_count != 1 or next_tools.stamped.has(TAMAGOTCHI_PET) or next_yuki.rules.any(func(rule): return rule["host"] == TAMAGOTCHI_PET))):
		return false
	var next_anomalies := Anomaly.new()
	if not next_anomalies.restore(data.get("anomalies", next_anomalies.snapshot())):
		return false
	var next_edge := EdgeState.new()
	if not next_edge.restore(data.get("edge", next_edge.snapshot())) or not _valid_edge_anchor(next_edge.portal_a) or not _valid_edge_anchor(next_edge.portal_b):
		return false
	var next_highland := Highland.new()
	if not next_highland.restore(data.get("highland", next_highland.snapshot())):
		return false
	if not observation_fixture and (next_highland.camera_owned or next_highland.compass_owned):
		return false
	var next_am := AM.new()
	if not next_am.restore(data.get("antimemetic", next_am.snapshot())):
		return false
	if not observation_fixture and next_am.stage != 0:
		return false
	var next_social := Social.new()
	var next_oni: Variant = data.get("oni_route_index", 0)
	var next_flute: Variant = data.get("flute_owned", false)
	var next_prism: Variant = data.get("prism_active", false)
	var next_music_scale: Variant = data.get("music_scale", 0.0)
	var next_attraction := ActiveDuration.new(ATTRACTION_SECONDS)
	if data.has("social") and not next_social.restore(data["social"], next_evening["stage"] > 0):
		return false
	if not next_flute is bool or not next_prism is bool or (next_prism and not next_social.prism_owned) \
			or typeof(next_oni) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(next_oni)) \
			or float(next_oni) != floorf(float(next_oni)) or int(next_oni) < 0 or int(next_oni) >= Visits.ROUTE.size() \
			or typeof(next_music_scale) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(next_music_scale)) \
			or (float(next_music_scale) != 0.0 and (not next_flute or float(next_music_scale) < 0.5 or float(next_music_scale) > 2.0)) \
			or not next_attraction.restore(data.get("music_attraction", 0.0)) or (not next_flute and next_attraction.remaining > 0.0):
		return false
	# C6 is an independent discovery, not an ordinary friendship requirement.
	if (next_evening["stage"] > 0 and not next_social.can_restore_evening()) or (next_evening["tamagotchi"] and not next_social.meetings.has("LEIA")):
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
	var next_hero_profile := HeroProfile.new()
	var completed := HeroProfile.completed_branches(next_yuki.ownership, int(next_flask), next_ori.ownership, next_evening["tamagotchi"], next_am.stage, next_social.oni_profile_unlocked())
	if not next_hero_profile.restore(data.get("hero_profile", HeroProfile.LUNA), completed):
		return false
	if not observation_fixture and next_hero_profile.active != HeroProfile.LUNA:
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
	var next_shell_collection: Variant = data.get("shell_collection", {"ready": false, "delivered": false})
	if not next_shell_collection is Dictionary or next_shell_collection.size() != 2 or not next_shell_collection.get("ready") is bool or not next_shell_collection.get("delivered") is bool or (next_shell_collection["delivered"] and not next_shell_collection["ready"]):
		return false
	if observation_fixture:
		var shell_ids := {}
		for entry in states:
			if not entry is Dictionary:
				return false
			var identity: Variant = entry.get("id")
			if not identity is String:
				return false
			if identity == ShellCollection.OCTOPUS or identity.begins_with(ShellCollection.NATURAL_PREFIX) or identity.begins_with(ShellCollection.COPY_PREFIX):
				if not next_shell_collection["ready"] or shell_ids.has(identity):
					return false
				if identity == ShellCollection.OCTOPUS:
					if entry.get("category") != "octopus":
						return false
				elif not ShellCollection.is_shell(identity) or entry.get("category") != "prop":
					return false
				shell_ids[identity] = true
		if next_shell_collection["ready"]:
			if not shell_ids.has(ShellCollection.OCTOPUS):
				return false
			for index in range(1, ShellCollection.REQUIRED + 1):
				if not shell_ids.has(ShellCollection.natural_id(index)):
					return false
		for index in range(1, WAND_COPY_LIMIT + 1):
			if shell_ids.has(ShellCollection.COPY_PREFIX + str(index)) and states.any(func(entry): return entry.get("id") == WAND_COPY_PREFIX + str(index)):
				return false
	if float(layout) == 1.0:
		candidate = data.duplicate(true)
		for entry in _initial_meadow_states:
			if not data.has("meadows") or entry["id"] == Meadows.PLANK_ID:
				candidate["entities"].append(entry)
	# Add only missing authored individuals to legacy profiles, preserving any
	# existing state; never regenerate on a current-format load.
	if not candidate.has("quiet_meadow_layout"):
		if _initial_quiet_states.size() != Meadows.QUIET_FAUNA.size():
			return false
		candidate = candidate.duplicate(true)
		for entry in _initial_quiet_states:
			if not candidate["entities"].any(func(saved): return saved.get("id") == entry["id"]):
				candidate["entities"].append(entry.duplicate(true))
	elif candidate["quiet_meadow_layout"] != 1:
		return false
	if observation_fixture:
		var quiet_version: Variant = candidate.get("quiet_regions_layout", 0)
		if typeof(quiet_version) not in [TYPE_FLOAT, TYPE_INT] or float(quiet_version) not in [0.0, 1.0, 2.0]:
			return false
		if int(quiet_version) < 2:
			if _initial_quiet_region_states.size() != QuietRegions.FAUNA.size():
				return false
			candidate = candidate.duplicate(true)
			for entry in _initial_quiet_region_states:
				if int(quiet_version) == 1 and entry["id"] not in QuietRegions.V2_FAUNA_IDS:
					continue
				if not candidate["entities"].any(func(saved): return saved.get("id") == entry["id"]):
					candidate["entities"].append(entry.duplicate(true))
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
		var f2_version: Variant = candidate.get("f2_food_layout", 0)
		if typeof(f2_version) not in [TYPE_FLOAT, TYPE_INT] or float(f2_version) not in [0.0, 1.0]:
			return false
		if int(f2_version) == 0:
			if _initial_f2_food_states.size() != 2:
				return false
			candidate = candidate.duplicate(true)
			for initial in _initial_f2_food_states:
				if not candidate["entities"].any(func(entry): return entry.get("id") == initial["id"]):
					candidate["entities"].append(initial.duplicate(true))
		var door_version: Variant = candidate.get("luna_door_layout", 0)
		if typeof(door_version) not in [TYPE_FLOAT, TYPE_INT] or float(door_version) not in [0.0, float(LunaDoor.LAYOUT_VERSION)]:
			return false
		if int(door_version) == 0:
			if candidate["entities"].any(func(entry): return entry.get("id") == LunaDoor.ID):
				return false
			var original := LunaDoor.migrate_legacy(_initial_luna_door, next_tools.owned.has(LunaDoor.TOOL_KEY), next_door)
			if original.is_empty():
				return false
			candidate = candidate.duplicate(true)
			candidate["entities"].append(original)
		else:
			if not candidate["entities"].any(func(entry): return entry.get("id") == LunaDoor.ID and entry.get("category") == "prop"):
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
		if cats > _entity_limit() or cats > next_yuki.spawn_serial:
			return false
		if not candidate["entities"].any(func(entry): return entry.get("id") == PASSERBY):
			if candidate.has("city_tools") or _initial_passerby.is_empty():
				return false
			candidate = candidate.duplicate(true)
			candidate["entities"].append(_initial_passerby.duplicate(true))
		for entry in candidate["entities"]:
			if entry.get("id") == PASSERBY and entry.get("category") != ("mouse" if next_tools.mouse_size > 0.0 else "resident"):
				return false
		for id in next_tools.cat_sizes:
			if not candidate["entities"].any(func(entry): return entry.get("id") == id and entry.get("category") == "cat"):
				return false
		for id in next_tools.stamped:
			if "REALITY_STAMP" not in next_tools.owned or not candidate["entities"].any(func(entry): return entry.get("id") == id and entry.get("category") in OriCatalog.FORMS):
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
		if not next_ori.order_id.is_empty() and not candidate["entities"].any(func(entry): return entry.get("id") == next_ori.order_id and entry.get("category") in OriCatalog.FORMS):
			return false
	if observation_fixture:
		if not candidate.has("friend_extra_layout"):
			if _initial_friend_extra.size() != FRIEND_EXTRA.size():
				return false
			candidate = candidate.duplicate(true)
			for initial in _initial_friend_extra:
				if not candidate["entities"].any(func(entry): return entry.get("id") == initial["id"]):
					candidate["entities"].append(initial.duplicate(true))
		elif candidate["friend_extra_layout"] != 1:
			return false
	if observation_fixture:
		if not candidate.has("am_layout"):
			if _initial_am_states.size() != AM.DEFINITIONS.size():
				return false
			candidate = candidate.duplicate(true)
			for initial in _initial_am_states:
				if not candidate["entities"].any(func(entry): return entry.get("id") == initial["id"]):
					candidate["entities"].append(initial.duplicate(true))
		elif candidate["am_layout"] != 1:
			return false
	if observation_fixture:
		if not candidate.has("highland_layout"):
			if _initial_highland_states.size() != 2:
				return false
			candidate = candidate.duplicate(true)
			for initial in _initial_highland_states:
				if not candidate["entities"].any(func(entry): return entry.get("id") == initial["id"]):
					candidate["entities"].append(initial.duplicate(true))
		elif candidate["highland_layout"] != 1:
			return false
	if observation_fixture:
		if not candidate.has("anomaly_layout"):
			if _initial_anomaly_states.size() != Anomaly.DEFINITIONS.size():
				return false
			candidate = candidate.duplicate(true)
			for initial in _initial_anomaly_states:
				if not candidate["entities"].any(func(entry): return entry.get("id") == initial["id"]):
					candidate["entities"].append(initial.duplicate(true))
		elif candidate["anomaly_layout"] != 1:
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
	var previous_w8_open := _w8_open
	var previous_w8_wall := _walls.has(W8.SEAM)
	if observation_fixture:
		var saved_point := Vector2.INF
		for entry in candidate["entities"]:
			if entry is Dictionary and entry.get("id") == ENTITY_ID:
				var raw: Variant = entry.get("position")
				if raw is Array and raw.size() == 2 and typeof(raw[0]) in [TYPE_INT, TYPE_FLOAT] and typeof(raw[1]) in [TYPE_INT, TYPE_FLOAT]:
					saved_point = Vector2(float(raw[0]), float(raw[1]))
		if not saved_point.is_finite():
			return false
		_set_w8_open(pair.outside_all_on_plane(saved_point))
	var previous_bridge := _surfaces.has(Crystal.BRIDGE)
	var previous_coast_bridge := _surfaces.has(CoastExtra.BRIDGE)
	var previous_edge_surfaces: Array[Dictionary] = []
	if observation_fixture:
		for surface in [Edge.R07, Edge.BRIDGE, Edge.CYCLE_SPAN]:
			if _surfaces.has(surface):
				previous_edge_surfaces.append(surface)
			else:
				_surfaces.append(surface)
	var previous_mountain_bridge := _surfaces.has(Mountain.CAMERA_BRIDGE)
	if observation_fixture and not previous_mountain_bridge:
		_surfaces.append(Mountain.CAMERA_BRIDGE)
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
			_set_w8_open(previous_w8_open)
			if not previous_w8_wall:
				_walls.erase(W8.SEAM)
				_w8_wall.collision_layer = 0
			_set_crystal_door(previous_door)
			if not previous_bridge:
				_surfaces.erase(Crystal.BRIDGE)
			if not previous_coast_bridge:
				_surfaces.erase(CoastExtra.BRIDGE)
			if not previous_mountain_bridge:
				_surfaces.erase(Mountain.CAMERA_BRIDGE)
			for surface in [Edge.R07, Edge.BRIDGE, Edge.CYCLE_SPAN]:
				if not previous_edge_surfaces.has(surface):
					_surfaces.erase(surface)
		return false
	shell_collection_ready = next_shell_collection["ready"]
	shell_collection_delivered = next_shell_collection["delivered"]
	game_mode = next_game_mode
	_reset_window_frame()
	_update_window_visual()
	city_tools = next_tools
	luna_door_session = next_door
	_tick_stamps(0.0)
	if is_instance_valid(_city_tool_panel):
		_city_tool_panel.hide()
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
	hero_profile = next_hero_profile
	$Interface/ProfilePortrait.text = HeroProfile.NAMES[hero_profile.active]
	if is_instance_valid(_profile_panel):
		_profile_panel.hide()
	antimemetic = next_am
	highland = next_highland
	edge = next_edge
	anomalies = next_anomalies
	_forward_remaining = 0.0
	_forward_behavior = ""
	_time_address = ""
	ghost_offer = ""
	_tick_edge(0.0)
	_mountain_echo = 0.0
	_sync_highland_forces()
	_update_local_camera()
	_camera.reset_smoothing()
	_sync_mountain_bridge()
	_am_tracks.clear()
	_am_echo_id = ""
	_am_echo_remaining = 0.0
	if is_instance_valid(_am_audio):
		_am_audio.stop()
	_sync_antimemetic_visibility()
	leia_turtle_seen = next_evening["turtle_seen"]
	leia_free = next_evening["leia_free"]
	tamagotchi_owned = next_evening["tamagotchi"]
	_recalled_pet.clear()
	if next_recalled:
		var recalled := entities.get_entity(TAMAGOTCHI_PET) as EntityBody
		for entry in candidate["entities"]:
			if entry["id"] == TAMAGOTCHI_PET:
				_recalled_pet = entry.duplicate(true)
				break
		entities.unregister_entity(TAMAGOTCHI_PET)
		recalled.free()
	if is_instance_valid(_tamagotchi_panel):
		_tamagotchi_panel.hide()
	evening_stage = int(next_evening["stage"])
	evening_origins = next_evening["origins"].duplicate(true)
	_sync_leia_pose()
	_evening_delay = 1.8
	if is_instance_valid(_evening_panel):
		_evening_panel.hide()
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
	_sync_w8()
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
	if observation_fixture and previous_schema >= 16 and previous_schema <= 18:
		var old_highland: Variant = result.get("highland")
		if old_highland is Dictionary:
			_shift_legacy_refuge_xy(old_highland.get("camera_lock"))
		var old_edge: Variant = result.get("edge")
		if old_edge is Dictionary:
			_shift_legacy_refuge_xy(old_edge.get("portal_a"))
			_shift_legacy_refuge_xy(old_edge.get("portal_b"))
		var old_evening: Variant = result.get("evening")
		if old_evening is Dictionary and old_evening.get("origins") is Dictionary:
			for origin in old_evening["origins"].values():
				_shift_legacy_refuge_xy(origin)
	result["address_schema"] = ADDRESS_SCHEMA
	return result


func _shift_legacy_refuge_xy(raw: Variant) -> bool:
	if not raw is Array or raw.size() not in [2, 3]:
		return false
	for value in raw:
		if typeof(value) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(value)):
			return false
	var point := Vector2(float(raw[0]), float(raw[1]))
	if not Edge.legacy_refuge_point(point):
		return false
	raw[0] = point.x + Edge.REFUGE_OFFSET.x
	raw[1] = point.y + Edge.REFUGE_OFFSET.y
	return true


func _migrate_address_entry(entry: Dictionary, is_field: bool, previous_schema: int) -> void:
	var stored: Variant = entry.get("location_id")
	if not stored is String:
		return
	var canonical: String = Lake.LOCATION_ID if stored == Lake.LEGACY_LOCATION_ID else stored
	if observation_fixture and previous_schema >= 16 and previous_schema <= 18 and not is_field and entry.get("motion") is Dictionary:
		_shift_legacy_refuge_xy(entry["motion"].get("anchor"))
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
	if observation_fixture and previous_schema >= 16 and previous_schema <= 18 and canonical == Edge.address_v18(point) and _shift_legacy_refuge_xy(raw):
		entry["location_id"] = _entity_location(point + Edge.REFUGE_OFFSET)
		return
	# Schema 14 accidentally overlaid the existing Mia cave. Relocate only
	# records explicitly assigned to the old mountain addresses, not old valley records.
	if previous_schema == 14 and canonical in Mountain.ADDRESSES and Mountain.old_mountain_point(point):
		entry["position"] = [point.x, point.y + Mountain.OLD_OFFSET.y]
		if not is_field and entry.get("motion") is Dictionary:
			var anchor: Variant = entry["motion"].get("anchor")
			if anchor is Array and anchor.size() == 3 and typeof(anchor[0]) in [TYPE_INT, TYPE_FLOAT] and typeof(anchor[1]) in [TYPE_INT, TYPE_FLOAT] and Mountain.old_mountain_point(Vector2(float(anchor[0]), float(anchor[1]))):
				anchor[1] = float(anchor[1]) + Mountain.OLD_OFFSET.y
		entry["location_id"] = _entity_location(point + Mountain.OLD_OFFSET)
		return
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
	elif previous_schema == 12:
		previous_location = _entity_location_v12(point)
	elif previous_schema == 13:
		previous_location = _entity_location_v13(point)
	elif previous_schema == 14:
		previous_location = _entity_location_v13(point)
	elif previous_schema == 15:
		previous_location = _entity_location_v15(point)
	elif previous_schema == 16:
		previous_location = _entity_location_v16(point)
	elif previous_schema == 17:
		previous_location = _entity_location_v17(point)
	elif previous_schema == 18:
		previous_location = _entity_location_v18(point)
	elif previous_schema == 19:
		previous_location = _entity_location_v19(point)
	if canonical == previous_location:
		entry["location_id"] = _entity_location(point)


func _build_saved_entity(state: Variant, version: int) -> EntityBody:
	var body := super._build_saved_entity(state, version)
	# Preserve the original stable ID, position, ownership and editable state.
	if body != null and body.entity_id == Meadows.PLANK_ID and body.record.display_name == "Доска":
		body.record.display_name = "Упавшая ветвь"
	if body != null and not ecology_fixture and body.entity_id == Mountain.RAY_ID:
		body.flight_enabled = true
	if body != null and ecology_fixture and not body.record.set_components(state.get("components", {})):
		body.free()
		return null
	return body


func _validate_saved_entities(candidates: Dictionary) -> bool:
	for identity in Meadows.QUIET_FAUNA:
		var resident: EntityBody = candidates.get(identity)
		if not resident is Fauna or resident.record.category != Meadows.QUIET_FAUNA[identity]["category"]:
			return false
	if observation_fixture:
		for identity in QuietRegions.FAUNA:
			var region_resident: EntityBody = candidates.get(identity)
			if not region_resident is Fauna or region_resident.record.category != QuietRegions.FAUNA[identity]["category"]:
				return false
		for definition in Anomaly.DEFINITIONS:
			var anomalous: EntityBody = candidates.get(definition["id"])
			if anomalous == null or anomalous.record.category != definition["category"]:
				return false
		for id in [Mountain.ORACLE_ID, Mountain.RAY_ID]:
			var highland_resident: EntityBody = candidates.get(id)
			if highland_resident == null or highland_resident.record.category != ("oracle" if id == Mountain.ORACLE_ID else "ray"):
				return false
		for definition in AM.DEFINITIONS:
			var hidden: EntityBody = candidates.get(definition["id"])
			if hidden == null or hidden.record.category != definition["category"]:
				return false
		for definition in FRIEND_EXTRA:
			var friend_body: EntityBody = candidates.get(definition["id"])
			if friend_body == null or friend_body.record.category != definition["category"]:
				return false
		var passerby: EntityBody = candidates.get(PASSERBY)
		if passerby == null or passerby.record.category not in ["resident", "mouse"]:
			return false
		var machine: EntityBody = candidates.get(YUKI_FRIDGE)
		if machine == null or machine.record.category != "fridge":
			return false
		for definition in City.DEFINITIONS:
			var resident: EntityBody = candidates.get(definition["id"])
			if resident == null:
				return false
			if definition["id"] == City.CAT:
				if resident.record.category not in OriCatalog.FORMS:
					return false
			elif resident.record.category != definition["category"]:
				return false
		var fairy: EntityBody = candidates.get(FairyBranch.RESIDENT)
		var snack: EntityBody = candidates.get(CAFE_SNACK)
		if fairy == null or fairy.record.category != "fairy" or snack == null or snack.record.category != "food":
			return false
		for identity in candidates:
			if identity.begins_with(WAND_COPY_PREFIX):
				var suffix: String = identity.trim_prefix(WAND_COPY_PREFIX)
				if not suffix.is_valid_int() or int(suffix) < 1 or int(suffix) > WAND_COPY_LIMIT or candidates[identity].record.category not in ["prop", "food"]:
					return false
		var original: EntityBody = candidates.get(LunaDoor.ID)
		if not original is LunaDoor or original.record.category != "prop":
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
		if wall["bounds"] not in [ForestBank.REST_SPOT, AncientConsole.CONSOLE_BODY, AM.MONUMENT["bounds"], Mountain.ANCHOR_WALL["bounds"]]:
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
		W8.draw_on(self, _w8_open, hero_profile.sees_underside(crystal_observer.luna_eyes_open))
		CoastExtra.draw_on(self)
		Lake.draw_shallow_on(self)
		Coast.draw_on(self, coast_house_phase, world_clock.phase(), Coast.tide_height(world_clock.minute_of_day()))
		Life.draw_on(self, Coast.tide_height(world_clock.minute_of_day()) * 8.0 / 30.0, hourglass_owned, flask_state, _lab_ice.remaining > 0.0)
		ShellCollection.draw_on(self)
		Visits.draw_on(self, flute_owned, prism_active)
		SecretFinds.draw_on(self, actor.position, actor.motion.elevation, "GRAVITY_GUN" in city_tools.owned, flute_owned)
		FairyBranch.draw_on(self)
		RuneRoom.draw_on(self)
		City.draw_on(self)
		_draw_antimemetic()
		Mountain.draw_on(self, highland.compass_owned, highland.camera_owned, actor.position, prism_active, _mountain_echo)
		Edge.draw_on(self, edge.elapsed, edge.time_owned, edge.portal_owned)
		_draw_anomalies()
		for endpoint in [edge.portal_a, edge.portal_b]:
			if endpoint.size() == 2:
				draw_arc(Vector2(endpoint[0], endpoint[1]) - Vector2(0, 15), 18.0, 0, TAU, 32, Color("dfa5f7"), 3.0)
		if not ghost_offer.is_empty():
			var p := _ghost_point()
			draw_colored_polygon(PackedVector2Array([p + Vector2(-25, -7), p + Vector2(0, -22), p + Vector2(25, -7), p + Vector2(0, 8)]), Color(0.68, 0.87, 0.98, 0.72))
		if not luna_door_session.is_empty():
			var source := Vector2(float(luna_door_session["x"]), float(luna_door_session["y"]))
			draw_rect(Rect2(source + Vector2(-14, -38), Vector2(28, 38)), Color("f2cfff"), false, 3.0)
		for key in TOOL_POINTS:
			if key not in city_tools.owned and key != "GRAVITY_GUN":
				var point: Vector2 = TOOL_POINTS[key]
				draw_circle(point, 9.0, Color("f4d6a4"))
				draw_string(font, point + Vector2(-30, -13), TOOL_NAMES[key])
	for field in [wand_pair.original, wand_pair.duplicate]:
		if field != null and not field.carried:
			var point: Vector2 = field.ground_position
			draw_line(point + Vector2(-11, 7), point + Vector2(11, -7), Color("ead1ff"), 5.0)
			draw_circle(point + Vector2(11, -7), 4.0, Color("ffd98d"))
