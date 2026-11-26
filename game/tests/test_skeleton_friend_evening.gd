extends SceneTree
const Scene = preload("res://scenes/skeleton/adventure.tscn")
const Island = preload("res://scripts/skeleton/start_island.gd")

func _initialize() -> void:
	call_deferred("_run")

func _place(body: Node, point: Vector2) -> void:
	body.position = point
	body.motion.reset_on_surface(point, 0.0)

func _run() -> void:
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
	_place(turtle, Island.LEIA_SEAT)
	home._tick_leia()
	assert(home.leia_turtle_seen)
	assert(home._interact_leia())
	assert(home.social.meetings.has("LEIA") and not home.tamagotchi_owned)
	_place(home.actor, Island.CAFE_TALK)
	assert(not home.begin_cafe_evening())
	home.social.complete("YUKI")
	home.social.complete("TOFFI")
	assert(home.social.can_gather())
	var same = home.entities.get_entity(Island.City.YUKI)
	same.set_parameter("speed", 1.1)
	assert(home.begin_cafe_evening())
	home._tick_cafe(2.0)
	assert(home.evening_stage == 2)
	assert(home.entities.get_entity(Island.City.YUKI) == same)
	assert(is_equal_approx(float(same.get_parameter("speed")), 1.1))
	assert(home.apply_snapshot(JSON.parse_string(JSON.stringify(home.make_snapshot()))))
	assert(home.evening_stage == 2 and home.evening_origins.size() == 6)
	assert(home.finish_cafe_evening())
	home._finish_ordinary_credits()
	assert(home.evening_stage == 4 and not home.begin_cafe_evening())
	home._tick_cafe(0.1)
	assert(home.apply_snapshot(JSON.parse_string(JSON.stringify(home.make_snapshot()))))
	game.queue_free()
	await process_frame
	print("M3.136–143: Leia meeting, voluntary cafe, stable IDs and saved finale")
	quit()
