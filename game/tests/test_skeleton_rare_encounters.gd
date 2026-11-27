extends SceneTree
const Scene = preload("res://scenes/skeleton/adventure.tscn")
const Director = preload("res://scripts/runtime2d/rare_encounter_director_2d.gd")
const Journal = preload("res://scripts/runtime2d/system_incident_journal_2d.gd")
const Store = preload("res://scripts/runtime2d/save_store_2d.gd")
const Island = preload("res://scripts/skeleton/start_island.gd")
var path := "user://luna_rare_encounters_%d.json" % OS.get_process_id()


func _initialize() -> void:
	call_deferred("_run")


func _check_budget() -> void:
	var director := Director.new()
	assert(not director.consider(600.0, false, 100.0, Director.REFLECTION, 0.0))
	assert(not director.consider(600.1, true, 100.0, Director.REFLECTION, 0.0))
	assert(not director.consider(1200.0, true, 100.0, Director.REFLECTION, 0.9))
	assert(director.consider(1800.0, true, 100.0, Director.REFLECTION, 0.0))
	assert(director.active == Director.REFLECTION and director.consumed == [Director.REFLECTION])
	director.clear_active()
	assert(not director.consider(2400.0, true, 100.0, Director.HAND, 0.0))
	assert(not director.consider(4500.0, true, 100.0, Director.REFLECTION, 0.0))
	assert(director.consider(5100.0, true, 100.0, Director.HAND, 0.0))
	var copy := Director.new()
	assert(copy.restore(JSON.parse_string(JSON.stringify(director.snapshot())), 5100.0, true))
	assert(copy.active.is_empty() and copy.consumed == director.consumed)
	assert(not copy.restore(director.snapshot(), 5100.0, false))
	var bad := director.snapshot()
	bad["consumed"] = [Director.REFLECTION, Director.REFLECTION]
	assert(not copy.restore(bad, 5100.0, true))
	assert(copy.consumed == director.consumed)
	assert(Director.chance(false, 100.0, Director.REFLECTION) == 0.0)
	assert(Director.chance(true, 100.0, Director.REFLECTION) <= 0.08)
	assert(Director.chance(true, 100.0, Director.HAND) < 0.01)
	# 48 hours of maximum-pressure windows, forced successful samples:
	# even then only the two implemented one-shot events can appear.
	var long_run := Director.new()
	for index in range(1, 289):
		long_run.consider(index * 600.0, true, 100.0, Director.REFLECTION if index % 2 else Director.HAND, 0.0)
		long_run.clear_active()
	assert(long_run.consumed.size() == 2)


func _run() -> void:
	_check_budget()
	var game = Scene.instantiate()
	game.profile_path = path
	game.get_node("Home").keyboard = false
	root.add_child(game)
	await physics_frame
	var home = game.home
	# Actual recovery accepts and acknowledges a real overflow before any roll.
	assert(game.demonstrate_overload())
	assert(not game._has_confirmed_overload(game.journal))
	game._finish_recovery()
	assert(game._has_confirmed_overload(game.journal) and game.journal.instability > 0.0)
	home.actor.position = Vector2(2059, 420)
	home.actor.motion.reset_on_surface(home.actor.position, 0.0)
	home.actor.location_id = home._entity_location(home.actor.position)
	home._update_local_camera()
	home._camera.reset_smoothing()
	home._camera.force_update_scroll()
	assert(home.rare_candidate().get("id") == Director.REFLECTION, "Reflection must be available from the real west bank")
	var social_before: Dictionary = home.social.snapshot()
	var before_count: int = home.entities.list_ids().size()
	game.journal.advance(Director.WINDOW_SECONDS)
	game._tick_rare_encounters(0.0)
	assert(game.rare_encounters.active == Director.REFLECTION and home.rare_kind == Director.REFLECTION)
	assert(home.social.snapshot() == social_before and home.entities.list_ids().size() == before_count)
	var saved: Dictionary = Store.new().read_snapshot(path)
	assert(saved["rare_encounters"]["consumed"] == [Director.REFLECTION])
	assert(not game.white_discovered and not game.meta.merged)
	var state: Dictionary = home.make_snapshot()
	assert(game.apply_local_rollback(state))
	assert(home.rare_kind.is_empty() and game.rare_encounters.active.is_empty())
	assert(game.rare_encounters.consumed == [Director.REFLECTION])
	game.queue_free()
	await process_frame
	game = Scene.instantiate()
	game.profile_path = path
	game.get_node("Home").keyboard = false
	root.add_child(game)
	await physics_frame
	assert(game._profile_valid and game.rare_encounters.consumed == [Director.REFLECTION] and game.home.rare_kind.is_empty())
	assert(not game.white_discovered)
	game.queue_free()
	await process_frame
	for file in [path, path + ".bak"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(file))
	print("Rare encounters: real overload, bounded windows, one-shots, persistent budget and safe rollback")
	quit()
