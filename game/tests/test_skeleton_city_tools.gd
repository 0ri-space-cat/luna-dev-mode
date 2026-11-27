extends SceneTree
const Scene = preload("res://scenes/skeleton/adventure.tscn")
const Island = preload("res://scripts/skeleton/start_island.gd")
const PROFILE := "user://luna_city_tools_regression.json"


func _initialize() -> void:
	call_deferred("_run")


func _place(home: Node, point: Vector2) -> void:
	home.actor.position = point
	home.actor.motion.reset_on_surface(point, 0.0)
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
	for key in Island.TOOL_POINTS:
		_place(home, Island.TOOL_POINTS[key])
		if key == "GRAVITY_GUN":
			assert(not home._take_city_tool(key))
			home.actor.motion.reset_on_surface(home.actor.position, Island.SecretFinds.GRAVITY_HEIGHT)
		assert(home._take_city_tool(key))
		assert(not home._take_city_tool(key))
	var cat = home.entities.get_entity(Island.City.CAT)
	_place(home, cat.position + Vector2(-30, 0))
	home._observe_city_tools()
	assert("cat" in home.city_tools.seen)
	var crate = home.entities.get_entity(Island.City.CRATE)
	_place(home, crate.position + Vector2(90, 0))
	assert(home.gravity_pull(Island.City.CRATE))
	assert(crate._impulse_velocity.x > 0.0)
	# Real finite source in the common bank; no permanent stamped instance.
	_place(home, Island.RIFT_SPOT + Vector2(0, -44))
	assert(home.interact())
	var donor = home.entities.get_entity(Island.ORI_GLOW_DONOR)
	_place(home, donor.position + Vector2(30, 0))
	assert(home.request_extract_ori(Island.ORI_GLOW_DONOR, Island.ORI_GLOW_INSTANCE))
	_place(home, cat.position + Vector2(-30, 0))
	assert(home.stamp_ability(Island.City.CAT, "GLOW"))
	assert(cat.temporary_ability == "GLOW" and not cat.has_active_ability("GLOW"))
	assert(home.ability_bank.amount(home.ENTITY_ID, "GLOW") == 1)
	var saved: Dictionary = home.make_snapshot()
	assert(home.apply_snapshot(saved))
	cat = home.entities.get_entity(Island.City.CAT)
	assert(cat.temporary_ability == "GLOW")
	home._tick_stamps(8.0)
	assert(cat.temporary_ability.is_empty())
	# An actual physical machine on the plaza changes the same resident.
	var fridge = home.entities.get_entity(Island.YUKI_FRIDGE)
	fridge.position = Vector2(5230, 475)
	fridge.motion.reset_on_surface(fridge.position, 0.0)
	fridge.location_id = Island.City.CITY_ID
	_place(home, fridge.position + Vector2(-30, 0))
	home.yuki.ownership = 1
	assert(home.install_yuki_rule(Island.YUKI_FRIDGE, "EVERY 1 SPAWN CAT"))
	home._tick_yuki(1.0)
	var person = home.entities.get_entity(Island.PASSERBY)
	assert(person.record.category == "mouse")
	assert(home.set_yuki_running(false))
	home._tick_yuki(6.0)
	assert(person.record.category == "resident")
	assert(home.entities.get_entity(Island.YUKI_CAT_PREFIX + "1") == null)
	assert(home.apply_snapshot(home.make_snapshot()))
	# One original physical door. No old tool pickup or remote flag activation.
	var door = home.entities.get_entity(Island.LunaDoor.ID)
	assert(door != null and not door.get_parameter("pickable"))
	assert("LUNA_ROOM_DOOR" not in home.city_tools.owned)
	_place(home, Vector2(5100, 370))
	assert(not home.use_luna_door() and not home._take_city_tool("LUNA_ROOM_DOOR"))
	_place(home, Island.City.DOORS[1]["outside"])
	assert(home.interact() and home.actor.location_id == Island.City.HOME_ID)
	assert(not home.interact_with_attachment(Island.LunaDoor.ID))
	_place(home, door.position + Vector2(0, -26))
	assert(home.request_wand_parameter_edit(Island.LunaDoor.ID, "PICKABLE", true))
	assert(home.interact_with_attachment(Island.LunaDoor.ID) and home.actor._rider == door)
	assert("LUNA_ROOM_DOOR" in home.city_tools.owned)
	assert(home.apply_snapshot(home.make_snapshot()))
	door = home.entities.get_entity(Island.LunaDoor.ID)
	assert(home.actor._rider == door and door.get_parameter("pickable"))
	_place(home, Island.City.DOORS[1]["inside"])
	home.actor._update_rider_position()
	assert(home.interact() and home.actor.location_id == Island.City.CITY_ID)
	assert(home.actor._rider == door)
	assert(home.interact_with_attachment() and not door.is_attached())
	# The ordinary drop releases at hand height; it must land under gravity.
	assert(not door.motion.grounded and not home.use_luna_door())
	for tick in 90:
		if door.motion.grounded:
			break
		await physics_frame
	assert(door.motion.grounded and is_zero_approx(door.motion.elevation), "Door did not settle: %s Z=%s" % [door.position, door.motion.elevation])
	var source: Vector2 = door.position
	assert(not home._copy_lake_prop(door))
	# Move away from the public room threshold: E acts on the placed original.
	_place(home, source + Vector2(30, 0))
	assert(home._nearby_action() == "Пройти через Дверь Луны")
	assert(home.interact() and home.actor.location_id == Island.City.HOME_ID, "Settled original must open the home session")
	assert(home.apply_snapshot(home.make_snapshot()))
	door = home.entities.get_entity(Island.LunaDoor.ID)
	assert(door.position.is_equal_approx(source) and not door.is_attached())
	assert(home.use_luna_door() and home.actor.position.distance_to(source) <= 35.0)
	assert(home.close_luna_door() and home.luna_door_session.is_empty())
	_place(home, Vector2(5100, 370))
	assert(not home.use_luna_door())
	# Legacy owned/session snapshots acquire one physical original without mutating input.
	var legacy: Dictionary = home.make_snapshot()
	legacy.erase("luna_door_layout")
	legacy["entities"] = legacy["entities"].filter(func(entry): return entry["id"] != Island.LunaDoor.ID)
	legacy["luna_door_session"] = {"address": Island.City.CITY_ID, "x": source.x, "y": source.y}
	assert(home.apply_snapshot(legacy))
	assert(not legacy.has("luna_door_layout"))
	door = home.entities.get_entity(Island.LunaDoor.ID)
	assert(door.position.is_equal_approx(source) and door.get_parameter("pickable"))
	assert(home.make_snapshot()["luna_door_layout"] == 1)
	# A current-format missing original is rejected non-destructively.
	var broken: Dictionary = home.make_snapshot()
	broken["entities"] = broken["entities"].filter(func(entry): return entry["id"] != Island.LunaDoor.ID)
	assert(not home.apply_snapshot(broken))
	assert(home.entities.get_entity(Island.LunaDoor.ID) == door)
	game.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PROFILE))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PROFILE + ".bak"))
	print("M3.123–132: city finds, bestiary, real pull, finite temporary stamp, resident transformation, physical unique door and legacy migration")
	quit()
