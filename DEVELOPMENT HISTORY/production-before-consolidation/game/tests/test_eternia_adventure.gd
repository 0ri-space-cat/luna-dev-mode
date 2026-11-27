extends SceneTree
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://eternia/eternia.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var ok: bool = game.current_location_id == "ISLAND"
	for id in game.rooms:
		var room: Dictionary = game.rooms[id]
		ok = ok and not room.has("entities") and not room.has("spots") and not room.has("zones")
		ok = game._enter_location(id) and ok
		ok = ok and game.world_registry.list_ids().size() == 1
		for dest in room.links:
			ok = ok and game.rooms[dest].links.has(id)
	game.toggle_panel()
	ok = ok and game.panel.visible and game.tabs.get_tab_count() > 6
	game.review_room("ISLAND")
	ok = ok and not game.panel.visible and game.current_location_id == "ISLAND"
	print("Geography and empty placement checks: ",ok)
	quit(0 if ok else 1)
