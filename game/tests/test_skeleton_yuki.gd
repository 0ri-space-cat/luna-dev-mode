extends SceneTree
const Scene = preload("res://scenes/skeleton/adventure.tscn")
const Island = preload("res://scripts/skeleton/start_island.gd")
const Program = preload("res://scripts/runtime2d/yuki_program_2d.gd")
const PROFILE := "user://luna_yuki_regression.json"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PROFILE))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PROFILE + ".bak"))
	var game = Scene.instantiate()
	game.profile_path = PROFILE
	game.get_node("Home").keyboard = false
	root.add_child(game)
	await physics_frame
	var home = game.home
	var friend_body = home.entities.get_entity(Island.City.YUKI)
	home.actor.position = friend_body.position + Vector2(-30, 0)
	home.actor.motion.reset_on_surface(home.actor.position, 0.0)
	assert(home._interact_yuki() and home.yuki.ownership == 1)
	assert(not home.install_yuki_rule(Island.City.YUKI, "EVERY 1 SET SELF SPEED 0"))
	var fridge = home.entities.get_entity(Island.YUKI_FRIDGE)
	home.actor.position = fridge.position + Vector2(0, 30)
	home.actor.motion.reset_on_surface(home.actor.position, 0.0)
	assert(home.install_yuki_rule(Island.YUKI_FRIDGE, "EVERY 60 SPAWN CAT"))
	assert(home.install_yuki_rule(Island.YUKI_FRIDGE, "EVERY 1 SET SELF IS_ALIVE ON"))
	assert(not home.install_yuki_rule("", "EVERY 1 SET SELF SPEED 2"))
	home._tick_yuki(60.0)
	assert(fridge.get_parameter("alive"))
	var cat = home.entities.get_entity(Island.YUKI_CAT_PREFIX + "1")
	assert(cat != null and cat.record.category == "cat")
	home.actor.position = cat.position + Vector2(-30, 0)
	home.actor.motion.reset_on_surface(home.actor.position, 0.0)
	home._tick_yuki(0.0)
	assert(home.yuki.observed)
	# A deliberate individual edit protects this cat from mass cleanup.
	assert(cat.set_parameter("luna_relation", "FRIEND"))
	# Return with the rule still active: the optional gift never requires cleanup.
	home.actor.position = friend_body.position + Vector2(-30, 0)
	home.actor.motion.reset_on_surface(home.actor.position, 0.0)
	assert(home.yuki.has_active_cat_rule())
	assert(home._interact_yuki() and home.yuki.ownership == 2)
	assert(home.yuki.has_active_cat_rule())
	assert(home.set_yuki_running(false))
	home._tick_yuki(120.0)
	assert(home.yuki.spawn_serial == 1)
	assert("YUKI" in home.social.meetings)
	var saved: Dictionary = home.make_snapshot()
	var invalid: Dictionary = saved.duplicate(true)
	invalid["yuki"]["rules"][0]["period"] = -1
	assert(not home.apply_snapshot(invalid))
	assert(home.apply_snapshot(saved))
	assert(home.yuki.ownership == 2 and not home.yuki.running and home.yuki.rules.size() == 2)
	assert(home.entities.get_entity(Island.YUKI_CAT_PREFIX + "1") != null)
	game.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PROFILE))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PROFILE + ".bak"))
	print("M3.110–117: Yuki loan, independent rules, physical effects, cat spawn, stop, gift and saved state")
	quit()
