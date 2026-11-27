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
	# Optional visitor interaction works without a loan or a creation.
	var visitor = home.entities.get_entity(Island.ORI_CUSTOMER)
	_place(home, visitor.position + Vector2(25, 0))
	var social_before: Dictionary = home.social.snapshot()
	var ori_before: Dictionary = home.ori.snapshot()
	assert(home._near_ori_customer() and home._nearby_action() == "Поговорить с посетителем")
	assert(home.interact() and home.get_node("Interface/SaveNotice").text.contains("просто посмотреть"))
	assert(home.social.snapshot() == social_before and home.ori.snapshot() == ori_before)
	_place(home, Vector2(510, 535))
	assert(not home._near_ori_customer())
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
	# Observe the genuine creature in its current physical room, without
	# granting a friend meeting or changing the module bank.
	assert(created.position.distance_to(customer.position) <= 100.0)
	_place(home, customer.position + Vector2(25, 0))
	var visitor_social: Dictionary = home.social.snapshot()
	var visitor_bank: Dictionary = home.actor.record.get_component("ABILITY_BANK").duplicate(true)
	assert(home.interact() and home.get_node("Interface/SaveNotice").text.contains("ночник"))
	assert(home.social.snapshot() == visitor_social and home.actor.record.get_component("ABILITY_BANK") == visitor_bank)
	_place(home, customer.position + Vector2(-42, 0))
	# Keep the same real cat; arrange only its test position.
	created.position = customer.position + Vector2(-30, 0)
	created.motion.reset_on_surface(created.position, 0.0)
	created.location_id = home._entity_location(created.position)
	assert(home.ori.order_id.is_empty())
	assert(customer.set_parameter("ai_enabled", false))
	home._tick_ori()
	assert(home.ori.order_id.is_empty() and home.social.snapshot() == visitor_social)
	assert(not home._near_ori_customer())
	assert(customer.set_parameter("ai_enabled", true))
	created.motion.reset_on_surface(created.position, 60.0)
	home._tick_ori()
	assert(home.ori.order_id.is_empty())
	created.motion.reset_on_surface(created.position, 0.0)
	home._tick_ori()
	assert(home.ori.order_id == first)
	# Optional encounter is stable and does not duplicate the creature.
	home._tick_ori()
	assert(home.ori.order_id == first and home.entities.get_entity(first) == created)
	_place(home, Vector2(5990, 650))
	var second: String = home.catalog_repeat()
	assert(not second.is_empty())
	assert(not home.entities.get_entity(second).has_active_ability("GLOW"))
	assert(home.ability_bank.amount(home.ENTITY_ID, "GLOW") == 0)
	var saved: Dictionary = home.make_snapshot()
	assert(home.apply_snapshot(saved))
	assert(home.ori.ownership == 1 and home.ori.serial == 2 and home.ori.order_id == first)
	assert(home.entities.get_entity(first).has_active_ability("GLOW"))
	assert(not home.entities.get_entity(second).has_active_ability("GLOW"))
	# Two creations suffice; no specific order, flight demonstration or extra module.
	var current_ori = home.entities.get_entity(Island.City.ORI)
	_place(home, current_ori.position + Vector2(0, 30))
	assert(home._interact_ori() and home.ori.ownership == 2)
	# The old six-creation narrative ceiling is gone; shared capacity still applies.
	for point in [Vector2(1260, 75), Vector2(1300, 960), Vector2(1910, 740), Vector2(1860, -300), Vector2(2290, 1010)]:
		_place(home, point)
		assert(not home.catalog_create({"form": "cat", "size": 0.6, "relation": "NEUTRAL", "ability": ""}).is_empty())
	assert(home.ori.serial == 7 and home.apply_snapshot(home.make_snapshot()))
	assert(home.ori.ownership == 2 and home.ori.serial == 7)
	game.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PROFILE))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PROFILE + ".bak"))
	print("M3.118–122: Ori loan, discovered forms, finite glow, repeated templates and persistence")
	quit()
