extends SceneTree

const Scene = preload("res://scenes/skeleton/adventure.tscn")
const Island = preload("res://scripts/skeleton/start_island.gd")
const City = preload("res://scripts/skeleton/luma_city_layout.gd")
const Outer = preload("res://scripts/skeleton/outer_routes_fixture.gd")
const PROFILE := "user://luna_city_regression.json"


func _initialize() -> void:
	call_deferred("_run")


func _place(home: Node, point: Vector2, height: float = 0.0) -> void:
	home.actor.position = point
	home.actor.motion.reset_on_surface(point, height)
	home.actor.direction = Vector2.ZERO
	home.actor.location_id = home._entity_location(point)


func _run() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PROFILE))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PROFILE + ".bak"))
	var game = Scene.instantiate()
	game.profile_path = PROFILE
	game.get_node("Home").keyboard = false
	root.add_child(game)
	await physics_frame
	var home = game.home
	var player = home.actor
	_place(home, City.MEADOWS_STATION)
	assert(home.interact() and game._away)
	assert(game.outer.current_address == Outer.BUFFER and game.outer.actor == player)
	assert(game.outer.ride_destination == Outer.LUMA)
	assert(game.save_game())
	var guest: Dictionary = game.outer.make_snapshot()
	assert(game.outer.apply_snapshot(guest))
	assert(game.outer._finish_buffer())
	assert(not game._away and home.actor == player and player.location_id == City.CITY_ID)
	# All regular doors work regardless of gifts, prism, or wand mode.
	for door in City.DOORS:
		_place(home, door["outside"])
		assert(home.interact(), door["name"])
		assert(player.position.distance_to(door["inside"]) < 1.0)
		assert(player.location_id == door["address"])
		assert(home.interact() and player.position.distance_to(door["outside"]) < 1.0)
	var bread = home.entities.get_entity(City.BREAD)
	assert(bread != null and not bread.get_parameter("alive"))
	assert(bread.set_parameter("alive", true))
	_place(home, City.DOORS[0]["outside"])
	assert(home.interact() and player.location_id == City.CAFE_ID)
	var saved: Dictionary = home.make_snapshot()
	assert(home.apply_snapshot(saved))
	player = home.actor
	bread = home.entities.get_entity(City.BREAD)
	assert(bread != null and bread.get_parameter("alive") and player.location_id == City.CAFE_ID)
	assert(home.interact() and player.location_id == City.CITY_ID)
	_place(home, City.BOARD)
	assert(home.interact() and game._away)
	assert(game.outer.ride_destination == Outer.MEADOWS)
	assert(game.outer._finish_buffer() and not game._away)
	assert(home.actor == player and home.actor.location_id == Island.Meadows.LOCATION_ID)
	assert(home.entities.get_entity(City.BREAD).get_parameter("alive"))
	game.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PROFILE))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PROFILE + ".bak"))
	print("M3.105–109: public ride, canonical city, doors and persistent bread passed")
	quit()
