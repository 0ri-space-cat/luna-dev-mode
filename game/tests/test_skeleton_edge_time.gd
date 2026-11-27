extends SceneTree
const Scene = preload("res://scenes/skeleton/adventure.tscn")
const Island = preload("res://scripts/skeleton/start_island.gd")
const Anomaly = preload("res://scripts/runtime2d/edge_anomaly_2d.gd")
const Edge = preload("res://scripts/skeleton/forgotten_edge_layout.gd")


func _initialize() -> void:
	call_deferred("_run")


func _place(home, body, point: Vector2) -> void:
	body.position = point
	body.motion.reset_on_surface(point, 0.0)
	body.location_id = home._entity_location(point)


func _run() -> void:
	var game = Scene.instantiate()
	game.profile_path = "user://luna_anomaly_test_%d.json" % OS.get_process_id()
	game.get_node("Home").keyboard = false
	root.add_child(game)
	await physics_frame
	var home = game.home
	var fox = home.entities.get_entity(Anomaly.FOX)
	var cat = home.entities.get_entity(Anomaly.CAT)
	var rabbit = home.entities.get_entity(Anomaly.RABBIT)
	assert(fox != null and cat != null and rabbit != null)
	_place(home, fox, Anomaly.FOX_ROUTE[0])
	home.anomalies.fox_index = 1
	home.anomalies.fox_elapsed = 0.0
	var prior: Vector2 = fox.position
	home._tick_anomalies(1.6)
	assert(fox.position != prior and home.anomalies.fox_echo == prior)
	assert(home.entities.get_entity(Anomaly.FOX) == fox)
	_place(home, cat, Anomaly.CAT_ROUTE[1])
	home.anomalies.cat_delay = 2
	home.anomalies.cat_history.assign([Anomaly.CAT_ROUTE[0], Anomaly.CAT_ROUTE[0], Anomaly.CAT_ROUTE[1], Anomaly.CAT_ROUTE[1]])
	home.anomalies.cat_elapsed = 0.0
	home._tick_anomalies(0.5)
	assert(cat.position == Anomaly.CAT_ROUTE[0])
	var snapshot: Dictionary = JSON.parse_string(JSON.stringify(home.make_snapshot()))
	assert(home.apply_snapshot(snapshot) and home.anomalies.cat_delay == 2)
	assert(home.entities.get_entity(Anomaly.FOX) != null)
	assert(not home.start_time_forward() and not home.rewind_local_time())
	home.edge.time_owned = true
	_place(home, home.actor, Edge.FALL_ENTRY)
	home._tick_local_time(0.1)
	for i in range(8):
		home._tick_local_time(0.25)
	_place(home, home.actor, Edge.FALL_ENTRY + Vector2(45, 0))
	for i in range(4):
		home._tick_local_time(0.25)
	assert(home.rewind_local_time(2.0))
	assert(home.actor.position == Edge.FALL_ENTRY and home.edge.time_owned)
	assert(home.start_time_forward() and not home.actor.accepts_player_input())
	var forward_save: Dictionary = home.make_snapshot()
	assert(home.apply_snapshot(forward_save) and home.actor.accepts_player_input())
	assert(home.start_time_forward())
	home._tick_local_time(6.0)
	assert(home.actor.accepts_player_input())
	game.queue_free()
	await process_frame
	print("M3.186–195: anomalous fauna, local rewind and bounded autonomy")
	quit()
