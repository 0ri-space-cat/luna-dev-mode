extends SceneTree

const Scene = preload("res://scenes/skeleton/adventure.tscn")
const Island = preload("res://scripts/skeleton/start_island.gd")
const Profile = preload("res://scripts/runtime2d/consumable_profile_2d.gd")
const CREATURES := ["M_QUIET_FOX_N", "M_QUIET_TURTLE_N", "M_QUIET_FOX_S", "M_QUIET_TURTLE_S"]

var path := "user://luna_electro_test_%d.json" % OS.get_process_id()
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
	home.mia_experienced = true
	home.flask_state = 1
	home._alchemy_panel._select(true, "Electro")
	home._alchemy_panel._mix()
	assert(home._alchemy_panel._effect == "ALC-R07")
	assert(not home._alchemy_panel._fill.disabled)
	home._alchemy_panel.fill_effect.emit(home._alchemy_panel._effect)
	assert(home._flask_program() == [{"id": "ELECTRO", "value": 8}])
	assert(await _power_device())
	assert(await _save_charge_and_walk_into_water())
	assert(await _throw_into_water())
	game.queue_free()
	await process_frame
	for file in [path, path + ".bak", path + ".next"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(file))
	print("Electro: inactive C4 device, four unique targets, real water contact, saved single entry shock and neutralization passed")
	quit()


func _power_device() -> bool:
	var fridge := home.entities.get_entity(Island.YUKI_FRIDGE) as Island.EntityBody
	assert(fridge != null and not fridge.get_parameter("alive"))
	home.yuki.running = false
	var origin := fridge.position - Vector2(75, 0)
	home._move_home_travelers(origin, home._entity_location(origin))
	assert(home._throw_flask(fridge.position) and await _finish_throw())
	assert(fridge.get_parameter("alive") and fridge.get_parameter("health") == 100)
	var yuki := home.entities.get_entity(Island.City.YUKI) as Island.EntityBody
	assert(not home._apply_consumable(Profile.RECIPES["ALC-R07"], yuki))
	assert(yuki.get_parameter("health") == 100 and not home.yuki.running)
	return true


func _save_charge_and_walk_into_water() -> bool:
	home._move_home_travelers(Vector2(370, 470), Island.ISLAND_ID)
	for index in CREATURES.size():
		var body = home.get_natural_fauna(CREATURES[index])
		home._place_friend(body, Vector2(430 + 50 * index, 470), 0.0)
		body.set_parameter("ai_enabled", false)
	assert(home.drink_flask() and home.actor.get_parameter("health") == 92)
	for index in CREATURES.size():
		var body = home.get_natural_fauna(CREATURES[index])
		assert(body.get_parameter("health") == 94 + index * 2)
	assert(home.get_natural_fauna(CREATURES[3]).electric_charge.is_empty())
	assert(home.electro._segments.size() == 3)
	assert(not home.electro._clear_path(Vector3(708, 375, 12), Vector3(708, 312, 12)))
	assert(home.electro._clear_path(Vector3(708, 375, 103), Vector3(708, 312, 103)))

	assert(game.save_game() and game.load_game())
	assert(home.actor.electric_charge["armed"] and home.actor.electric_charge["entry_damage"] == 24)
	assert(home.entities.get_entity(Island.YUKI_FRIDGE).get_parameter("alive"))
	var entry := Vector2(1937, 879)
	home._move_home_travelers(entry, home._entity_location(entry))
	home.apply_player_input(Vector2.LEFT)
	for frame in 70:
		await physics_frame
		if home.actor.get_parameter("health") == 68:
			break
	home.apply_player_input(Vector2.ZERO)
	assert(home.actor._current_water() != null)
	assert(home.actor.get_parameter("health") == 68 and home.actor.electric_charge["entry_damage"] == 0)
	for frame in 20:
		await physics_frame
	assert(home.actor.get_parameter("health") == 68)
	home._move_home_travelers(entry, home._entity_location(entry))
	await physics_frame
	assert(home.actor.electric_charge["entry_damage"] == 0 and not home.actor.electric_charge["armed"])
	assert(home._apply_consumable(Profile.RECIPES["ALC-R09"], home.actor))
	assert(home.actor.electric_charge.is_empty())
	return true


func _throw_into_water() -> bool:
	var first = home.get_natural_fauna(CREATURES[0])
	var second = home.get_natural_fauna(CREATURES[1])
	assert(home._apply_consumable(Profile.RECIPES["ALC-R09"], first))
	assert(home._apply_consumable(Profile.RECIPES["ALC-R09"], second))
	home._place_friend(first, Vector2(1884, 861), -4.0)
	home._place_friend(second, Vector2(1875, 838), -4.0)
	assert(first._current_water() != null and first._current_water() == second._current_water())
	var shore := Vector2(2040, 900)
	home._move_home_travelers(shore, home._entity_location(shore))
	assert(home._throw_flask(Vector2(1870, 900)) and await _finish_throw())
	assert(first.get_parameter("health") == 78 and second.get_parameter("health") == 84,
		"wet targets: %s and %s" % [first.get_parameter("health"), second.get_parameter("health")])
	assert(first.electric_charge["remaining"] > 8.0 and not first.electric_charge["armed"])
	assert(second.electric_charge["remaining"] > 8.0 and not second.electric_charge["armed"])
	assert(home.actor.get_parameter("health") == 68)
	return true


func _finish_throw() -> bool:
	for frame in 145:
		await physics_frame
		if not is_instance_valid(home._flask_portion):
			return true
	return false
