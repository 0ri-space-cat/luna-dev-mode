extends SceneTree
const Scene = preload("res://scenes/skeleton/adventure.tscn")
const Island = preload("res://scripts/skeleton/start_island.gd")
const Mountain = preload("res://scripts/skeleton/mountain_layout.gd")
const Social = preload("res://scripts/runtime2d/friend_progress_2d.gd")
const Routes = preload("res://scripts/skeleton/outer_routes_fixture.gd")
const Store = preload("res://scripts/runtime2d/save_store_2d.gd")
var path := "user://luna_friend_evening_%d.json" % OS.get_process_id()

func _initialize() -> void:
	call_deferred("_run")

func _place(body: Node, point: Vector2) -> void:
	body.position = point
	body.motion.reset_on_surface(point, 0.0)

func _run() -> void:
	_check_social_migration()
	_check_profile_gates()
	var game = Scene.instantiate()
	game.profile_path = path
	game.get_node("Home").keyboard = false
	root.add_child(game)
	await physics_frame
	var home = game.home
	await _check_leia_attraction(home)
	var leia = home.entities.get_entity(Island.LEIA_ID)
	var turtle = home.entities.get_entity(Island.LEIA_TURTLE)
	assert(leia != null and turtle != null)
	_place(home.actor, Island.LEIA_START + Vector2(0, 25))
	# First contact needs neither music nor the turtle's staged arrival.
	assert(not home.flute_owned and not home.leia_turtle_seen)
	assert(home.interact())
	_place(turtle, Island.LEIA_SEAT)
	home._tick_leia()
	assert(home.leia_turtle_seen)
	assert(home.interact() and home.social.invitations.has("LEIA"))
	assert(home.social.meetings.has("LEIA") and not home.tamagotchi_owned)
	_place(home.actor, Island.CAFE_TALK)
	assert(not home.begin_cafe_evening())
	# Ordinary physical meetings and invitations must work before any gift.
	for pair in [[Island.City.ORI, "ORI"], [Island.City.YUKI, "YUKI"], [Island.Life.MIA_ID, "MIA"]]:
		var body = home.entities.get_entity(pair[0])
		_place(home.actor, body.position + Vector2(0, 25))
		assert(home._ordinary_friend_target() == pair[1])
		assert(home.interact())
		assert(home._friend_invitation_target() == pair[1])
		assert(home.interact())
		assert(home.social.invitations.has(pair[1]))
	assert(home.yuki.ownership == 0 and home.ori.ownership == 0 and home.flask_state == 0)
	var toffi = home.entities.get_entity(Island.City.TOFFI)
	_place(home.actor, toffi.position + Vector2(0, 30))
	assert(home.interact() and home.social.meetings.has("TOFFI"))
	assert(home.interact() and home.social.invitations.has("TOFFI"))
	_place(home.actor, Island.CAFE_TALK)
	assert(not home.social.can_gather() and not home.begin_cafe_evening())
	var oni = home.entities.get_entity(Island.Visits.ONI_ID)
	_place(oni, Island.Visits.LAKE)
	_place(home.actor, Island.Visits.LAKE + Vector2(-30, 0))
	assert(oni.set_parameter("ai_enabled", false))
	assert(home._oni_site().is_empty() and not home._observe_with_oni())
	assert(oni.set_parameter("ai_enabled", true))
	assert(home.interact() and home.social.oni_sites == ["W1"])
	assert(home.get_node("Interface/SaveNotice").text.contains("башня") or home.get_node("Interface/SaveNotice").text.contains("Башня"))
	var oni_before: Dictionary = home.social.snapshot()
	assert(home._observe_with_oni() and home.social.snapshot() == oni_before)
	assert(home.interact() and home.social.can_gather())
	assert(not home.social.prism_owned and home.antimemetic.stage == 0 and not home.tamagotchi_owned and not home.flute_owned)
	_place(home.actor, Island.CAFE_TALK)
	assert(not home.social.invite("ONI"))
	var same = home.entities.get_entity(Island.City.YUKI)
	same.set_parameter("speed", 1.1)
	assert(home.begin_cafe_evening())
	home._tick_cafe(2.0)
	assert(home.evening_stage == 2)
	assert(home.entities.get_entity(Island.City.YUKI) == same)
	assert(is_equal_approx(float(same.get_parameter("speed")), 1.1))
	assert(home.apply_snapshot(JSON.parse_string(JSON.stringify(home.make_snapshot()))))
	assert(home.evening_stage == 2 and home.evening_origins.size() == 6)
	assert(home.social.invitations.size() == 6)
	assert(home.finish_cafe_evening())
	assert(home.ordinary_finale_voice().contains("Помоги мне") and not home.ordinary_finale_voice().contains("отголосок"))
	assert(not game.white_discovered and not game.meta.merged and not game.meta.pixel_seen)
	home._finish_ordinary_credits()
	assert(home.evening_stage == 4 and not home.begin_cafe_evening())
	home._tick_cafe(0.1)
	assert(home.apply_snapshot(JSON.parse_string(JSON.stringify(home.make_snapshot()))))
	# Cafe-first ordering: actual physical discovery, not a seeded flag.
	assert(not game._visit_white_void())
	_place(home.actor, Island.AncientConsole.RETURN_POINT)
	home.actor.location_id = home._entity_location(home.actor.position)
	assert(home.at_ancient_console() and home.interact())
	home.ancient_console._submit("TELEPORT " + Routes.WHITE_ADDRESS)
	assert(not game._away and not game.white_discovered)
	# Use the actual wand progression, including a physical duplicate.
	# Positions here are fixtures, not a claim that the full route is walked.
	assert(home.access.wand_mode == "ORDINARY")
	_place(home.actor, Island.RIFT_SPOT + Vector2(0, -44))
	home.actor.location_id = home._entity_location(home.actor.position)
	assert(home.interact() and home.access.wand_mode == "PLAYFUL")
	assert(not home.tick_wand_self_hack(3.0, true))
	_place(home.actor, Island.Lake.SHORE)
	home.actor.location_id = home._entity_location(home.actor.position)
	assert(home.wand_pair.duplicate == null and home._nearby_action() == "Коснуться воды палочкой")
	assert(home.interact() and home.wand_pair.duplicate != null)
	assert(home.wand_pair.original.carried and not home.wand_pair.duplicate.carried)
	assert(home.wand_pair.duplicate.ground_location_id == Island.Lake.LOCATION_ID)
	assert(not home.tick_wand_self_hack(2.0, true))
	assert(not home.tick_wand_self_hack(0.0, false))
	assert(not home.tick_wand_self_hack(2.0, true))
	assert(home.access.wand_mode == "PLAYFUL")
	assert(home.tick_wand_self_hack(1.0, true))
	assert(home.access.wand_mode == "DEVELOPER")
	assert(home.evening_stage == 4 and home.social.invitations.size() == 6)
	assert(game.save_game() and game.load_game())
	assert(home.access.wand_mode == "DEVELOPER" and home.wand_pair.duplicate != null)
	assert(home.evening_stage == 4 and not game.white_discovered)
	# Fixture placement at the existing camera pickup; use the real interaction.
	_place(home.actor, Mountain.CAMERA_POINT)
	home.actor.location_id = home._entity_location(home.actor.position)
	assert(home.interact() and home.highland.camera_owned)
	assert(home.set_game_mode("WINDOWED"))
	_place(home.actor, Vector2(510, 535))
	home.actor.location_id = home._entity_location(home.actor.position)
	home.apply_player_input(Vector2.ZERO)
	home._update_local_camera()
	home._camera.reset_smoothing()
	assert(home.toggle_camera_lock())
	await physics_frame
	var traveler = home.actor
	var bounds: Rect2 = home._frame_world_bounds()
	assert(bounds.has_point(traveler.position))
	var edge := Vector2(bounds.position.x + 18.0, traveler.position.y)
	assert(await _walk_home(home, edge))
	assert(home.set_game_frame_solid(false))
	assert(not game._start_desktop_visit())
	home.apply_player_input(Vector2.LEFT)
	for tick in 50:
		await physics_frame
		if game._away:
			break
	assert(game._away and game.outer.current_address == Routes.DESKTOP and game.outer.actor == traveler)
	assert(not game.white_discovered and not game.meta.merged)
	game.outer.keyboard = false
	game.outer.actor.direction = Vector2.RIGHT
	for tick in 240:
		await physics_frame
		if game.outer.current_address == Routes.WHITE_ADDRESS:
			break
	assert(game.outer.current_address == Routes.WHITE_ADDRESS and game.white_discovered and game.outer.actor == traveler)
	assert(not game.outer.pixel_repeat and not game.meta.merged)
	game.outer.actor.direction = Vector2.RIGHT
	for tick in 180:
		await physics_frame
		if game.outer.at_meta_encounter():
			break
	game.outer.actor.direction = Vector2.ZERO
	assert(game.outer.at_meta_encounter())
	assert(game.outer.use_route() and game.outer.use_route() and game.outer.use_route())
	assert(game.meta.merged and game.outer.actor == traveler and not game.meta.pixel_seen)
	assert(game._return_to_home() and home.actor == traveler)
	assert(home.evening_stage == 4 and home.social.invitations.size() == 6)
	assert(not home.begin_cafe_evening() and home.ordinary_finale_voice().contains("отголосок"))
	assert(game.save_game())
	var saved_profile: Dictionary = Store.new().read_snapshot(path)
	assert(saved_profile["meta"]["merged"] and saved_profile["state"]["evening"]["stage"] == 4)
	assert(saved_profile["state"]["island"]["access"]["wand_mode"] == "DEVELOPER")
	game.queue_free()
	await process_frame
	for file in [path, path + ".bak"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(file))
	print("M3.136–143: six invitations, cafe-first finale, stable IDs and preserved cafe after merge")
	quit()

func _check_social_migration() -> void:
	var progress := Social.new()
	var old := {"meetings": ["YUKI", "LEIA", "TOFFI"], "oni_sites": [], "prism_owned": false}
	assert(progress.restore(old))
	assert(progress.meetings.size() == 3 and progress.invitations.is_empty())
	assert(not progress.can_gather() and not progress.can_restore_evening())
	assert(not progress.oni_profile_unlocked())
	assert(progress.complete_oni_deep() and not progress.complete_oni_deep())
	assert(progress.oni_profile_unlocked() and progress.oni_sites.is_empty() and not progress.prism_owned)
	assert(not progress.can_invite("ONI") and not progress.can_gather())
	assert(not progress.invite("ORI"))
	assert(progress.invite("YUKI") and not progress.invite("YUKI"))
	var saved := progress.snapshot()
	var copy := Social.new()
	assert(copy.restore(JSON.parse_string(JSON.stringify(saved))))
	assert(copy.invitations == progress.invitations and copy.oni_profile_unlocked())
	var previous := saved.duplicate(true)
	previous.erase("oni_deep_met")
	assert(copy.restore(previous) and not copy.oni_profile_unlocked())
	assert(copy.restore(saved) and copy.oni_profile_unlocked())
	var bad_deep := saved.duplicate(true)
	bad_deep["oni_deep_met"] = "true"
	assert(not copy.restore(bad_deep) and copy.oni_profile_unlocked())
	var invalid := saved.duplicate(true)
	invalid["invitations"] = ["ORI"]
	assert(not copy.restore(invalid) and copy.invitations == progress.invitations)
	assert(copy.restore(old, true))
	assert(copy.can_restore_evening() and not copy.can_gather() and copy.invitations.is_empty())
	assert(copy.restore(copy.snapshot(), true))
	assert(not copy.restore(copy.snapshot(), false))

func _check_profile_gates() -> void:
	var profile := Island.HeroProfile.new()
	var initial := Island.HeroProfile.completed_branches(0, 0, 0, false, 0, false)
	assert(profile.available(initial) == ["LUNA"])
	var loans := Island.HeroProfile.completed_branches(1, 1, 1, false, 1, false)
	assert(profile.available(loans) == ["LUNA"])
	var done := Island.HeroProfile.completed_branches(2, 2, 2, true, 2, true)
	assert(profile.available(done).size() == 7)
	for id in Island.HeroProfile.ORDER:
		assert(not profile.choose(id, done, false))
		assert(profile.choose(id, done, true))
		assert(profile.sees_hidden_creatures() == (id == "TOFFI"))
		assert(profile.attracts_animals() == (id == "LEIA"))
		assert(profile.sees_underside(false) == (id == "ONI"))
		assert(not profile.sees_underside(true))
	assert(not profile.restore("PROTO", done) and profile.active == "ONI")
	assert(not profile.restore("ONI", loans) and profile.active == "ONI")
	assert(profile.restore("LUNA", initial))

func _check_leia_attraction(home) -> void:
	# Isolate innate stimulus; restore initial state before six-friend route.
	var fox = home.entities.get_entity(Island.Meadows.FOX_ID)
	var player_point: Vector2 = home.actor.position
	var fox_point: Vector2 = fox.position
	var fox_height: float = fox.motion.elevation
	var old_size: float = fox.get_parameter("size")
	var old_ai: bool = fox.get_parameter("ai_enabled")
	var relation: String = fox.get_parameter("luna_relation")
	var mode: String = fox.get_parameter("behavior_mode")
	var old_destination: Vector2 = fox.autonomous_destination
	_place(home.actor, Vector2(410, 420))
	home.actor.location_id = home._entity_location(home.actor.position)
	_place(fox, Vector2(510, 420))
	fox.location_id = home._entity_location(fox.position)
	fox.autonomous_destination = Vector2.INF
	fox.set_parameter("behavior_mode", "WANDER")
	fox.set_parameter("ai_enabled", true)
	home.hero_profile.active = "LEIA"
	for size in [0.5, 2.0]:
		assert(fox.set_parameter("size", size))
		home._tick_profile_attraction()
		assert(fox.profile_interest == home.actor.position and fox.profile_interest_gap > 0.0)
		assert(fox.get_parameter("luna_relation") == relation)
		assert(fox.get_parameter("behavior_mode") == "WANDER")
	assert(fox.set_parameter("size", 0.5))
	home._tick_profile_attraction()
	var before: float = fox.position.distance_to(home.actor.position)
	for tick in 12:
		await physics_frame
	assert(fox.position.distance_to(home.actor.position) < before, "Leia should attract the actual moving fox")
	fox.set_parameter("ai_enabled", false)
	home._tick_profile_attraction()
	assert(not fox.profile_interest.is_finite())
	fox.set_parameter("ai_enabled", old_ai)
	home.hero_profile.active = "LUNA"
	home._tick_profile_attraction()
	assert(not fox.profile_interest.is_finite())
	fox.set_parameter("size", old_size)
	fox.set_parameter("behavior_mode", mode)
	home._place_friend(fox, fox_point, fox_height)
	fox.autonomous_destination = old_destination
	home._place_friend(home.actor, player_point, 0.0)


func _walk_home(home, target: Vector2) -> bool:
	for tick in 240:
		var offset: Vector2 = target - home.actor.position
		if offset.length_squared() < 16.0:
			home.apply_player_input(Vector2.ZERO)
			return true
		home.apply_player_input(offset.normalized())
		await physics_frame
	home.apply_player_input(Vector2.ZERO)
	return false
