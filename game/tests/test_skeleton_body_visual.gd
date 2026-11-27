extends SceneTree
const Adventure = preload("res://scenes/skeleton/adventure.tscn")
const Island = preload("res://scripts/skeleton/start_island.gd")
const Visual = preload("res://scripts/skeleton/body_visual_2d.gd")
const Calibration = preload("res://scripts/skeleton/p0_calibration_2d.gd")
const PROFILE := "user://luna_body_visual_regression.json"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PROFILE))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PROFILE + ".bak"))
	var game = Adventure.instantiate()
	game.profile_path = PROFILE
	game.get_node("Home").keyboard = false
	root.add_child(game)
	await physics_frame
	var home = game.home
	var actor = home.actor
	var art = actor.body_visual
	assert(is_instance_valid(art) and art.sprite.texture == Visual.LUNA)
	assert(art.sprite.offset == -Visual.FOOT and art.sprite.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST)
	assert(actor._marker.self_modulate.a == 0.0)
	assert(actor._marker.position.y == -actor.motion.elevation)
	var oni = home.entities.get_entity(Island.Visits.ONI_ID)
	assert(oni.body_visual.sprite.texture == Visual.ONI)
	var prop = home.entities.get_entity(Island.FRIDGE_ID)
	assert(not prop.body_visual.sprite.visible and prop._marker.self_modulate.a == 1.0)
	var initial: Vector2 = actor.position
	var radius: float = actor.foot_radius()
	home.apply_player_input(Vector2.RIGHT)
	for tick in range(8):
		await physics_frame
	assert(actor.position.x > initial.x and art.facing == 0 and art.frame > 0)
	assert(art.sprite.region_rect == Visual.atlas_rect(0, art.frame))
	home.apply_player_input(Vector2.ZERO)
	for tick in range(2):
		await physics_frame
	assert(art.frame == 0)
	actor.jump()
	for tick in range(5):
		await physics_frame
	assert(actor.motion.elevation > 0.0 and actor._marker.position.y == -actor.motion.elevation)
	assert(art.sprite.offset == -Visual.FOOT and actor.foot_radius() == radius)
	for tick in range(120):
		await physics_frame
		if actor.motion.grounded:
			break
	assert(actor.motion.grounded)
	var saved: Dictionary = home.make_snapshot()
	art.sprite.scale = Vector2.ONE * 2.0
	assert(home.make_snapshot() == saved)
	assert(home.apply_snapshot(saved))
	assert(home.actor.entity_id == Island.ENTITY_ID)
	assert(home.actor.body_visual.sprite.texture == Visual.LUNA and home.actor.foot_radius() == radius)
	# Presence and enabled state are independent; temporary effects own no modules.
	var modules := {"W": {"ability_id": "WALK", "enabled": false}, "F": {"ability_id": "FLY", "enabled": true}}
	assert(Visual.module_state(modules, "WALK") == Vector2i(1, 0))
	assert(Visual.module_state(modules, "FLY") == Vector2i(1, 1))
	assert(Visual.module_state({}, "FLY") == Vector2i.ZERO)
	assert(Visual.mirrored(4) and not Visual.mirrored(0))
	var fit := Calibration.integer_fit(Vector2i(320, 180), Vector2i(1280, 800))
	assert(fit["scale"] == 4 and fit["rect"] == Rect2i(0, 40, 1280, 720))
	assert(Calibration.integer_fit(Vector2i(640, 360), Vector2i(320, 180)).is_empty())
	assert(Calibration.snap_display(Vector2(2.3, 5.7), 1.0) == Vector2(2, 6))
	game.queue_free()
	await process_frame
	print("DEV body visuals: Adventure, atlas, motion, height, profile and P0 math passed")
	quit()
