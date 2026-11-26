extends SceneTree
const Scene = preload("res://scenes/skeleton/adventure.tscn")
const Island = preload("res://scripts/skeleton/start_island.gd")
const PROFILE := "user://luna_ori_regression.json"


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
	var cat = home.entities.get_entity(Island.City.CAT)
	_place(home, cat.position + Vector2(-30, 0))
	home._tick_ori()
	assert("cat" in home.ori.known)
	var ori_body = home.entities.get_entity(Island.City.ORI)
	_place(home, ori_body.position + Vector2(-30, 0))
	assert(home._interact_ori() and home.ori.ownership == 1)
	# Actual ordinary wand upgrade at the original rift.
	_place(home, Island.RIFT_SPOT + Vector2(0, -44))
	assert(home.interact())
	var donor = home.entities.get_entity(Island.ORI_GLOW_DONOR)
	_place(home, donor.position + Vector2(30, 0))
	assert(donor.has_active_ability("GLOW"))
	assert(home.request_extract_ori(Island.ORI_GLOW_DONOR, Island.ORI_GLOW_INSTANCE))
	assert(not donor.has_active_ability("GLOW"))
	var customer = home.entities.get_entity(Island.ORI_CUSTOMER)
	_place(home, customer.position + Vector2(-42, 0))
	var template := {"form": "cat", "size": 0.6, "relation": "FRIEND", "ability": "GLOW"}
	var first: String = home.catalog_create(template)
	assert(not first.is_empty())
	var created = home.entities.get_entity(first)
	assert(created.has_active_ability("GLOW"))
	home._tick_ori()
	_place(home, Vector2(5990, 650))
	var second: String = home.catalog_repeat()
	assert(not second.is_empty())
	assert(not home.entities.get_entity(second).has_active_ability("GLOW"))
	assert(home.ability_bank.amount(home.ENTITY_ID, "GLOW") == 0)
	var saved: Dictionary = home.make_snapshot()
	assert(home.apply_snapshot(saved))
	assert(home.ori.ownership == 1 and home.ori.serial == 2)
	assert(home.entities.get_entity(first).has_active_ability("GLOW"))
	assert(not home.entities.get_entity(second).has_active_ability("GLOW"))
	game.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PROFILE))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PROFILE + ".bak"))
	print("M3.118–122: Ori loan, discovered forms, finite glow, repeated templates and persistence")
	quit()
