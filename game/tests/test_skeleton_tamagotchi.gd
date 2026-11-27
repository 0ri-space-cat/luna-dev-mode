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
	game.profile_path = "user://luna_tamagotchi_regression.json"
	game.get_node("Home").keyboard = false
	root.add_child(game)
	await physics_frame
	var home = game.home
	var pink := Color("f49fc9")
	assert(not home.tamagotchi_configure("cat", pink, 0.8))
	var leia = home.entities.get_entity(Island.LEIA_ID)
	_place(leia, Island.LEIA_EXIT)
	_place(home.actor, Island.LEIA_EXIT + Vector2(0, 30))
	home._tick_leia()
	assert(home.leia_free and home._interact_leia() and not home.tamagotchi_owned)
	assert(home.leia_free and home._interact_leia() and home.tamagotchi_owned)
	_place(home.actor, Island.SPAWN)
	assert(home.tamagotchi_configure("cat", pink, 0.8))
	var pet = home.entities.get_entity(Island.TAMAGOTCHI_PET)
	assert(pet != null and pet.get_parameter("luna_relation") == "FRIEND" and pet.get_parameter("behavior_mode") == "FOLLOW")
	assert(home.ability_bank.move_instance(home.ENTITY_ID, Island.ORI_GLOW_DONOR, Island.ORI_GLOW_INSTANCE, true))
	assert(home.tamagotchi_install("GLOW"))
	assert(pet.has_active_ability("GLOW") and home.ability_bank.amount(home.ENTITY_ID, "GLOW") == 0)
	assert(home.tamagotchi_configure("fox", pink, 0.7))
	assert(home.entities.get_entity(Island.TAMAGOTCHI_PET) == pet and pet.record.category == "fox" and pet.has_active_ability("GLOW"))
	assert(not home.tamagotchi_install("GLOW"))
	assert(home.apply_snapshot(home.make_snapshot()))
	pet = home.entities.get_entity(Island.TAMAGOTCHI_PET)
	assert(pet != null and pet.record.category == "fox" and pet.has_active_ability("GLOW"))
	assert(home.toggle_tamagotchi())
	assert(home.entities.get_entity(Island.TAMAGOTCHI_PET) == null)
	var dormant: Dictionary = home.make_snapshot()
	assert(dormant["tamagotchi_recalled"])
	assert(dormant["entities"].filter(func(entry): return entry["id"] == Island.TAMAGOTCHI_PET).size() == 1)
	assert(home.apply_snapshot(JSON.parse_string(JSON.stringify(dormant))))
	assert(home.entities.get_entity(Island.TAMAGOTCHI_PET) == null and home.ability_bank.amount(home.ENTITY_ID, "GLOW") == 0)
	var bad: Dictionary = dormant.duplicate(true)
	bad["evening"]["tamagotchi"] = false
	assert(not home.apply_snapshot(bad))
	assert(home.toggle_tamagotchi())
	pet = home.entities.get_entity(Island.TAMAGOTCHI_PET)
	assert(pet != null and pet.record.category == "fox" and pet.has_active_ability("GLOW"))
	assert(pet.get_parameter("color") == pink and is_equal_approx(float(pet.get_parameter("size")), 0.7))
	assert(home.apply_snapshot(home.make_snapshot()))
	game.queue_free()
	await process_frame
	print("M3.144–149: one companion, persistent recall and finite module")
	quit()
