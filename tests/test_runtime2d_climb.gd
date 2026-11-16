extends SceneTree
## CLIMB is a physical movement adapter for authored climb passages.
## Vertical animation/height art is intentionally owned by the future map.
const GridNavigation = preload("res://scripts/runtime2d/grid_navigation_2d.gd")
const GAME = preload("res://scenes/runtime2d/sandbox.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var nav = GridNavigation.new()
	var climb_only := {"id":"DEV_CLIMB","kind":"CLIMB_REQUIRED","rect":[-12,-60,24,120]}
	assert(nav.configure(Vector2(512,384), [climb_only]))
	assert(not nav.is_walkable(Vector2.ZERO))
	assert(nav.is_walkable(Vector2.ZERO, false, false, true))
	assert(nav.is_walkable(Vector2.ZERO, true))
	assert(not nav.is_walkable(Vector2.ZERO, false, true, false))
	var ground_route: PackedVector2Array = nav.get_path(Vector2(-120,0), Vector2(120,0))
	var climb_route: PackedVector2Array = nav.get_path(Vector2(-120,0), Vector2(120,0),
		false, false, true)
	assert(not ground_route.is_empty() and not climb_route.is_empty())
	assert(climb_route.size() < ground_route.size())

	# Swimming and climbing are independent. Both together bypass their
	# author-tagged constraints, while walls remain inaccessible to either.
	var combination = GridNavigation.new()
	assert(combination.configure(Vector2(512,384), [
		{"kind":"CLIMB_REQUIRED", "rect":[-60,-120,20,240]},
		{"kind":"SWIM_REQUIRED", "rect":[40,-120,20,240]}
	]))
	assert(not combination.is_walkable(Vector2(-50,0), false, true, false))
	assert(not combination.is_walkable(Vector2(50,0), false, false, true))
	assert(combination.is_walkable(Vector2(-50,0), false, true, true))
	assert(combination.is_walkable(Vector2(50,0), false, true, true))
	var dual: PackedVector2Array = combination.get_path(Vector2(-150,0), Vector2(150,0),
		false, true, true)
	assert(not dual.is_empty())
	var wall = GridNavigation.new()
	assert(wall.configure(Vector2(512,384), [{"kind":"WALL","rect":[-12,-60,24,120]}]))
	assert(not wall.is_walkable(Vector2.ZERO, false, true, true))

	var game = GAME.instantiate()
	root.add_child(game)
	await physics_frame
	var actor = game.world_registry.get_entity("DEV_ENTITY_01")
	assert(actor != null)
	assert(game.set_entity_parameter(actor.record.id, "ai_enabled", false))
	assert(game._live_level.geometry.build_from_description({
		"solids": [climb_only], "zones": []
	}))
	actor.global_position = Vector2(-95,0)
	actor.set_external_drive(Vector2.RIGHT)
	for i in range(35):
		await physics_frame
	assert(actor.global_position.x < -16.0)
	assert(game.set_entity_ability(actor.record.id, "CLIMB", true))
	assert(actor.has_ability("CLIMB"))
	assert(actor.collision_mask & 16 == 0)
	for i in range(45):
		await physics_frame
	assert(actor.global_position.x > 20.0)
	assert(game.set_entity_ability(actor.record.id, "CLIMB", false))
	assert(actor.collision_mask & 16 != 0)
	actor.clear_external_drive()
	var state: Dictionary = game.make_snapshot()
	assert(game.apply_snapshot(state))
	assert(not game.world_registry.get_entity(actor.record.id).has_ability("CLIMB"))
	game.queue_free()
	print("LUNA runtime2d: authored CLIMB, physical access and combined nav profiles passed")
	quit(0)
