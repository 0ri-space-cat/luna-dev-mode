extends SceneTree
const Scene = preload("res://scenes/skeleton/adventure.tscn")
const Island = preload("res://scripts/skeleton/start_island.gd")
const Outer = preload("res://scripts/skeleton/outer_routes_fixture.gd")
const Edge = preload("res://scripts/skeleton/forgotten_edge_layout.gd")
const City = preload("res://scripts/skeleton/luma_city_layout.gd")


func _initialize() -> void:
	call_deferred("_run")


func _place(home, point: Vector2) -> void:
	home.actor.position = point
	home.actor.motion.reset_on_surface(point, 0.0)
	home.actor.location_id = home._entity_location(point)
	home.actor.direction = Vector2.ZERO


func _run() -> void:
	var game = Scene.instantiate()
	game.profile_path = "user://luna_edge_test_%d.json" % OS.get_process_id()
	game.get_node("Home").keyboard = false
	root.add_child(game)
	await physics_frame
	var home = game.home
	var player = home.actor
	assert(Edge.ID not in home._ordinary_public_addresses())
	assert(home._entity_location(Edge.FALL_ENTRY) == Edge.ID)
	# The already implemented public frame break is now connected to L4.
	_place(home, City.MEADOWS_STATION)
	assert(home.interact() and game._away)
	assert(game.outer.current_address == Outer.BUFFER)
	var guest = game.outer
	guest.actor.position.y = Outer.FRAME.position.y - 2.0
	guest._tick_frame(Outer.OUTWARD_SECONDS, Vector2.UP)
	assert(guest.cracking)
	guest._tick_frame(Outer.CRACK_SECONDS, Vector2.ZERO)
	assert(guest.current_address == Outer.SUBSPACE)
	guest.actor.motion.reset_on_surface(guest.actor.position, 0.0)
	guest._physics_process(0.0)
	assert(not game._away and home.actor == player and player.location_id == Edge.ID)
	# Ordinary exit, independently of any artifact.
	_place(home, Edge.RETURN)
	assert(home.interact() and player.location_id == Island.Coast.LOCATION_ID)
	# R08 known address accepts the real edge; no public route catalogue entry.
	_place(home, Island.AncientConsole.RETURN_POINT)
	home.access.set_wand_mode("PLAYFUL")
	assert(home.teleport_known_location(Edge.ID))
	assert(player.position.distance_to(Edge.ENTRY) < 1.0)
	# Camera observation and personal gaze remain different.
	_place(home, Edge.REFUGE_APPROACH.get_center())
	home._update_local_camera()
	home._camera.reset_smoothing()
	home._sync_mountain_bridge()
	assert(not home._surfaces.has(Edge.BRIDGE))
	home.set_luna_eyes(false)
	home._sync_mountain_bridge()
	assert(not home._surfaces.has(Edge.BRIDGE))
	home.highland.camera_owned = true
	home.highland.camera_mode = "LOCKED"
	home.highland.camera_lock = Vector2(900, 350)
	home._update_local_camera()
	home._camera.reset_smoothing()
	home._sync_mountain_bridge()
	assert(home._surfaces.has(Edge.BRIDGE) and home._surfaces.has(Edge.R07))
	# The permanent clue exists without Oni, prism, cafe or the main refuge.
	_place(home, Edge.ONI_RECORD)
	assert(home._edge_action() == "Рассмотреть рисунок" and home.interact())
	assert(not home.get_node("Interface/SaveNotice").text.contains("META_WHITE_VOID"))
	var oni = home.entities.get_entity(Island.Visits.ONI_ID)
	# Seed at her ordinary cape stop; the extension must be walked.
	home._place_friend(oni, Island.Visits.CAPE, 0.0)
	home.oni_route_index = Island.Visits.CAPE_INDEX
	assert(oni.set_parameter("speed", 2.5))
	assert(home.world_clock.set_time_of_day(23 * 60))
	assert(await _reach(oni, Island.Visits.EDGE_SPOT, 540), "Oni edge arrival %s index %s" % [oni.position, home.oni_route_index])
	assert(home.entities.get_entity(Island.Visits.ONI_ID) == oni and oni.location_id == Edge.ID)
	_place(home, Island.Visits.EDGE_SPOT + Vector2(0, 28))
	assert(home._edge_action() == "Поговорить с Они" and home.interact())
	assert(not home.social.prism_owned and home.social.meetings.is_empty())
	assert(home.apply_snapshot(JSON.parse_string(JSON.stringify(home.make_snapshot()))))
	oni = home.entities.get_entity(Island.Visits.ONI_ID)
	assert(oni.location_id == Edge.ID and home._oni_edge_near())
	# A daytime return follows the same physical span and leaves the drawing.
	assert(home.world_clock.set_time_of_day(12 * 60))
	assert(await _reach(oni, Island.Visits.CAPE, 540), "Oni cape return %s index %s" % [oni.position, home.oni_route_index])
	_place(home, Edge.ONI_RECORD)
	assert(home._edge_action() == "Рассмотреть рисунок" and home.interact())
	player = home.actor
	# Local collapse never resets previously collected items.
	home.edge.elapsed = Edge.INTACT_SECONDS - 0.1
	home._tick_edge(0.2)
	assert(not home._surfaces.has(Edge.CYCLE_SPAN))
	_place(home, Edge.DESK)
	assert(home.interact() and home.edge.time_owned)
	home.edge.elapsed = Edge.CYCLE_SECONDS - 0.1
	home._tick_edge(0.2)
	assert(home.edge.time_owned and home._surfaces.has(Edge.CYCLE_SPAN))
	# One portable original and two saved anchors; stationary portal rotates impulse.
	_place(home, Edge.PORTAL_A)
	player._impulse_velocity = Vector2(12, 0)
	assert(home.interact() and player.position.distance_to(Edge.PORTAL_B_EXIT) < 1.0)
	assert(player._impulse_velocity.distance_to(Vector2(0, 12)) < 0.1)
	_place(home, Vector2(3460, 1445))
	assert(home.interact() and home.edge.portal_owned)
	_place(home, Edge.ENTRY)
	assert(home.place_portal(0))
	_place(home, Edge.FALL_ENTRY)
	assert(home.place_portal(1))
	assert(home.interact() and player.position.distance_to(Edge.ENTRY) < 1.0)
	var snapshot: Dictionary = JSON.parse_string(JSON.stringify(home.make_snapshot()))
	assert(home.apply_snapshot(snapshot) and home.edge.portal_owned and home.edge.time_owned)
	player = home.actor
	# P04 is voluntary, separate from P01 and administrative exile.
	_place(home, City.MEADOWS_STATION)
	home.world_clock.set_time_of_day(home.WorldClock.NIGHT_MINUTE)
	home.flute_owned = true
	assert(home.perform_music("URULDR") and not game._away)
	_place(home, home._ghost_point())
	assert(home.interact() and game._away and game.outer.current_address == Outer.BLACK_VOID)
	assert(game.outer.actor == player and game.outer.hosted_entry == Outer.GHOST_ENTRY)
	assert(game.save_game())
	assert(game.outer.apply_snapshot(game.outer.make_snapshot()))
	assert(game._return_to_home() and not game._away and home.actor == player)
	game.queue_free()
	await process_frame
	print("M3.174–185: edge, P01, independent P04, camera spans, cycle and portal identity")
	quit()


func _reach(body: Node, point: Vector2, ticks: int) -> bool:
	for tick in ticks:
		if body.motion.grounded and body.position.distance_to(point) < 4.0:
			return true
		await physics_frame
	return false
