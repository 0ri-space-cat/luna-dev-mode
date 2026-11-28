extends SceneTree

const Scene = preload("res://scenes/skeleton/adventure.tscn")
const Island = preload("res://scripts/skeleton/start_island.gd")
const Profile = preload("res://scripts/runtime2d/consumable_profile_2d.gd")
const Access = preload("res://scripts/runtime2d/access_state_2d.gd")
var path := "user://luna_consumables_test_%d.json" % OS.get_process_id()
var game: Node
var home: Island


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	Engine.time_scale = 2.0
	game = Scene.instantiate()
	game.profile_path = path
	home = game.get_node("Home") as Island
	home.keyboard = false
	root.add_child(game)
	await physics_frame
	var legacy := home.make_snapshot()
	legacy["f2_food_layout"] = 1
	legacy["entities"] = legacy["entities"].filter(func(entry): return entry["id"] != Island.FAIRY_POLLEN)
	assert(game.apply_local_rollback(legacy))
	var pollen_code := _learn_flight()
	assert(pollen_code == "FLY 18")
	assert(await _edit_and_eat(pollen_code))
	assert(_edit_flask())
	assert(await _throw_portions())
	assert(await _life_recipes())
	game.queue_free()
	await process_frame
	for file in [path, path + ".bak"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(file))
	print("Consumables: learned flight, two-way editor, atomic rejection, borrowing, recipe reset, independent copy, saved effects, physical throws and life recipes passed")
	quit()


func _learn_flight() -> String:
	home._move_home_travelers(Vector2(6353, 272), Island.FairyBranch.ID)
	var pollen = home.entities.get_entity(Island.FAIRY_POLLEN)
	assert(pollen != null and pollen.get_parameter("portions") == 2)
	assert(home.access.set_wand_mode(Access.PLAYFUL))
	home._open_food_program(Island.FAIRY_POLLEN)
	assert(not home._consumable_editor.visible)
	assert(home.access.set_wand_mode(Access.DEVELOPER))
	assert(home.get_wand_editor_tabs(Island.FAIRY_POLLEN)["Общее"].any(func(field): return field["id"] == "CONSUMABLE"))
	home._open_food_program(Island.FAIRY_POLLEN)
	var editor = home._consumable_editor
	assert(editor.visible)
	var learned: String = editor._code.text.get_slice("\n", 2)
	editor.hide()
	return learned


func _edit_and_eat(learned: String) -> bool:
	home._move_home_travelers(Vector2(5622, 329), Island.City.CAFE_ID)
	var snack = home.entities.get_entity(Island.CAFE_SNACK)
	home._open_food_program(Island.CAFE_SNACK)
	var editor = home._consumable_editor
	assert(editor.visible and not editor._code.text.contains("FLY"))
	editor._code.text = " \n\t EDIBLE  true \n PORTIONS\t 2\nHEAL 12\n" + learned + "\n "
	assert(editor._apply_code() and snack.food_effects.size() == 2)
	var fly_row: HBoxContainer = editor._fields.get_child(3)
	assert(fly_row.get_child(0).text == "FLY · SECONDS")
	var duration: SpinBox = fly_row.get_child(1)
	duration.value = 6
	assert(editor._code.text.ends_with("FLY 6") and snack.food_effects[1]["value"] == 6)
	editor._code.text = "EDIBLE false\nPORTIONS 0\nSPAWN CAT"
	assert(not editor._apply_code() and snack.get_parameter("edible") and snack.get_parameter("portions") == 2)
	assert(not Profile.parse("EDIBLE true\nPORTIONS 2\nSWIM 6", true).has("profile"))
	editor._reset_text()
	editor._remove_effect(0)
	assert(editor._code.text.ends_with("FLY 6") and not editor._code.text.contains("HEAL"))
	editor.hide()
	var copied := home.request_wand_copy(Island.CAFE_SNACK)
	assert(not copied.is_empty())
	var copy = home.entities.get_entity(copied)
	assert(copy.food_effects == snack.food_effects and copy.record.get_component("ABILITY_SET").is_empty())
	assert(home._commit_food_program({"edible": true, "portions": 2,
		"effects": [{"id": "HEAL", "value": 12}, {"id": "FLY", "value": 6}]}, Island.CAFE_SNACK))
	assert(copy.food_effects == [{"id": "FLY", "value": 6}])
	assert(home.actor.record.set_parameter("health", 69))
	assert(home.interact() and snack.get_parameter("portions") == 1 and copy.get_parameter("portions") == 2)
	assert(home.actor.get_parameter("health") == 81 and home.actor.can_fly())
	home.actor.thrust_requested = true
	for frame in 32:
		await physics_frame
	assert(home.actor.motion.elevation > 9.0 and home.actor.can_fly())
	home.actor.thrust_requested = false
	assert(game.save_game() and game.load_game())
	assert(home.actor.can_fly() and home.actor.get_parameter("health") == 81)
	assert(home.entities.get_entity(Island.CAFE_SNACK).get_parameter("portions") == 1)
	assert(home.actor.set_parameter("gravity_scale", 0.9))
	for frame in 230:
		await physics_frame
		if not home.actor.can_fly():
			break
	assert(not home.actor.can_fly() and home.actor.get_parameter("gravity_scale") == 0.9)
	assert(home.actor.record.get_component("ABILITY_BANK").is_empty())
	return true


func _edit_flask() -> bool:
	home._move_home_travelers(Vector2(516, 460), Island.ISLAND_ID)
	assert(not home.drink_flask())
	home.mia_experienced = true
	home.flask_state = 1
	home._fill_flask("ALC-R12")
	assert(home.access.set_wand_mode(Access.PLAYFUL))
	assert(not home._can_edit_flask_program() and home.drink_flask() and home.actor.get_parameter("health") == 100)
	assert(home.access.set_wand_mode(Access.DEVELOPER))
	home._open_flask_program()
	var editor = home._consumable_editor
	assert(editor.visible and editor._code.text == "HEAL 25")
	assert(home.actor.record.set_parameter("health", 65))
	editor._code.text = "HEAL 19\nFREEZE_WATER 8"
	assert(editor._apply_code())
	editor.hide()
	assert(not home.drink_flask() and home.actor.get_parameter("health") == 65)
	assert(game.save_game() and game.load_game())
	assert(home.flask_state == 1 and home._flask_program()[0]["value"] == 19)
	home._fill_flask("ALC-R08")
	assert(home.flask_override == null and home._flask_program()[0]["id"] == "GLOW")
	assert(home.drink_flask() and home._alchemy_glow.remaining > 0.0)
	assert(Profile.RECIPES["ALC-R12"] == [{"id": "HEAL", "value": 25}])
	return true


func _throw_portions() -> bool:
	var source := Vector2(370, 445)
	var destination := Vector2(441, 445)
	home._move_home_travelers(source, Island.ISLAND_ID)
	var fox := home.spawn_entity({"id": "TEST_POTION_RECEIVER", "category": "fox",
		"label": "Лисица", "material": "FABRIC"}, destination, 0.0)
	assert(fox != null and fox.set_parameter("ai_enabled", false))
	assert(fox.record.set_parameter("health", 50))
	home._fill_flask("ALC-R12")
	assert(home._commit_flask_program({"effects": [{"id": "HEAL", "value": 16}, {"id": "GLOW", "value": 9}]}))
	assert(home._begin_flask_use())
	home._flask_hold = home.FLASK_AIM_SECONDS
	assert(home._release_flask_use(destination))
	home._fill_flask("ALC-R30")
	assert(game.save_game() and game.load_game())
	assert(is_instance_valid(home._flask_portion) and home._flask_portion.effects[0]["id"] == "HEAL")
	assert(await _wait_for_contact())
	fox = home.entities.get_entity("TEST_POTION_RECEIVER")
	assert(fox.get_parameter("health") == 66 and fox.consumable_glow_remaining > 0.0)
	assert(home._flask_program()[0]["id"] == "NIGHT")
	assert(game.save_game() and game.load_game())
	fox = home.entities.get_entity("TEST_POTION_RECEIVER")
	assert(fox.consumable_glow_remaining > 0.0 and fox.get_parameter("health") == 66)

	home._move_home_travelers(Vector2(708, 365), Island.ISLAND_ID)
	home._fill_flask("ALC-R08")
	home._alchemy_glow.restore(0.0)
	assert(home._throw_flask(Vector2(708, 276)))
	assert(await _wait_for_contact())
	assert(home._alchemy_glow.remaining > 0.0)

	var shore := Vector2(2040, 879)
	home._move_home_travelers(shore, home._entity_location(shore))
	home._fill_flask("ALC-R20")
	assert(home._throw_flask(home.MiaLab.SHALLOW.get_center() + Vector2(0, 9)))
	assert(await _wait_for_contact())
	assert(home._lab_ice.remaining > 0.0 and home._surfaces.has(home.Life.ICE[0]))
	return true


func _wait_for_contact() -> bool:
	for frame in 155:
		await physics_frame
		if not is_instance_valid(home._flask_portion):
			return true
	return false

func _life_recipes() -> bool:
	var source := Vector2(370, 485)
	var destination := Vector2(441, 485)
	home._move_home_travelers(source, Island.ISLAND_ID)
	var identity: String = Island.Meadows.FOX_ID
	var fox = home.get_natural_fauna(identity)
	assert(fox != null)
	home._place_friend(fox, destination, 0.0)
	assert(fox.set_parameter("size", 1.4) and fox.set_parameter("ai_enabled", false))
	assert(fox.record.set_parameter("health", 33))
	assert(not Profile.parse("MORI\nDORMANT 2", false).has("profile"))
	assert(not Profile.parse("EDIBLE true\nPORTIONS 1\nMORI", true).has("profile"))

	home._fill_flask("ALC-R28")
	assert(home._flask_program()[0]["value"] == 60)
	assert(not home.drink_flask() and home.actor.get_parameter("alive"))
	assert(home._commit_flask_program({"effects": [{"id": "DORMANT", "value": 2}]}))
	assert(home._throw_flask(destination) and await _wait_for_contact())
	assert(not fox.get_parameter("alive") and fox.visible and fox.life_suspended_remaining > 0.0)
	assert(game.ecology.episodes.is_empty())
	assert(game.save_game() and game.load_game())
	fox = home.get_natural_fauna(identity)
	assert(fox.visible and fox.position.is_equal_approx(destination) and fox.life_suspended_remaining > 0.0)
	for frame in 140:
		await physics_frame
		if fox.get_parameter("alive"):
			break
	assert(fox.get_parameter("alive") and fox.position.is_equal_approx(destination))
	assert(fox.get_parameter("health") == 100 and fox.death_remaining == 0.0)

	home._fill_flask("ALC-R28")
	assert(home._throw_flask(destination) and await _wait_for_contact())
	assert(not fox.get_parameter("alive") and fox.life_suspended_remaining > 0.0)
	home._fill_flask("ALC-R09")
	assert(home._throw_flask(destination) and await _wait_for_contact())
	assert(fox.get_parameter("alive") and fox.position.is_equal_approx(destination))

	home._fill_flask("ALC-R13")
	assert(not home.drink_flask() and home.actor.get_parameter("alive"))
	assert(fox.record.set_parameter("health", 33))
	assert(home._throw_flask(destination) and await _wait_for_contact())
	assert(not fox.get_parameter("alive") and fox.death_remaining > 0.0 and fox.life_suspended_remaining == 0.0)
	assert(game.ecology.episodes.size() == 1)
	assert(home.request_wand_parameter_edit(identity, "IS_ALIVE", true))
	assert(home.get_natural_fauna(identity) == fox and fox.get_parameter("health") == 100)
	assert(fox.death_remaining == 0.0)

	var fridge = home.entities.get_entity(Island.FRIDGE_ID)
	assert(fridge.set_parameter("alive", true))
	assert(home._apply_consumable(Profile.RECIPES["ALC-R13"], fridge))
	assert(not fridge.get_parameter("alive") and home.entities.get_entity(Island.FRIDGE_ID) == fridge)

	var mirror = home.get_natural_fauna(Island.MIRROR_SNAIL)
	var original: Dictionary = mirror.record.get_components()
	assert(original["ABILITY_SET"]["instances"].has(Island.DUPLICATE_MODULE_ID))
	assert(home._apply_consumable([{"id": "DORMANT", "value": 1}], mirror))
	mirror.tick_life_suspension(1.0)
	assert(mirror.get_parameter("alive") and mirror.record.get_components() == original)
	return true
