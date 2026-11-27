extends SceneTree
const Scene = preload("res://scenes/skeleton/adventure.tscn")
const Island = preload("res://scripts/skeleton/start_island.gd")
const Social = preload("res://scripts/runtime2d/friend_progress_2d.gd")

func _initialize() -> void:
	call_deferred("_run")

func _place(body: Node, point: Vector2) -> void:
	body.position = point
	body.motion.reset_on_surface(point, 0.0)

func _run() -> void:
	_check_social_migration()
	var game = Scene.instantiate()
	game.profile_path = "user://luna_friend_evening_regression.json"
	game.get_node("Home").keyboard = false
	root.add_child(game)
	await physics_frame
	var home = game.home
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
	assert(home.interact() and home.social.oni_sites == ["W1"])
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
	home._finish_ordinary_credits()
	assert(home.evening_stage == 4 and not home.begin_cafe_evening())
	home._tick_cafe(0.1)
	assert(home.apply_snapshot(JSON.parse_string(JSON.stringify(home.make_snapshot()))))
	game.queue_free()
	await process_frame
	print("M3.136–143: Leia meeting, voluntary cafe, stable IDs and saved finale")
	quit()

func _check_social_migration() -> void:
	var progress := Social.new()
	var old := {"meetings": ["YUKI", "LEIA", "TOFFI"], "oni_sites": [], "prism_owned": false}
	assert(progress.restore(old))
	assert(progress.meetings.size() == 3 and progress.invitations.is_empty())
	assert(not progress.can_gather() and not progress.can_restore_evening())
	assert(not progress.invite("ORI"))
	assert(progress.invite("YUKI") and not progress.invite("YUKI"))
	var saved := progress.snapshot()
	var copy := Social.new()
	assert(copy.restore(JSON.parse_string(JSON.stringify(saved))))
	assert(copy.invitations == progress.invitations)
	var invalid := saved.duplicate(true)
	invalid["invitations"] = ["ORI"]
	assert(not copy.restore(invalid) and copy.invitations == progress.invitations)
	assert(copy.restore(old, true))
	assert(copy.can_restore_evening() and not copy.can_gather() and copy.invitations.is_empty())
	assert(copy.restore(copy.snapshot(), true))
	assert(not copy.restore(copy.snapshot(), false))
