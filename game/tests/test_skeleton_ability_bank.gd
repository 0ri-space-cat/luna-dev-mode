extends SceneTree

const Room = preload("res://scenes/skeleton/ability_fixture.tscn")
const Access = preload("res://scripts/runtime2d/access_state_2d.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene = Room.instantiate()
	scene.keyboard = false
	root.add_child(scene)
	await physics_frame
	var donor = scene.entities.get_entity(scene.TARGET_ID)
	var recipient = scene.entities.get_entity(scene.RECIPIENT_ID)

	assert(donor.can_fly() and not recipient.can_fly())
	assert(not scene.has_bank_access())
	assert(not scene.get_wand_editor_tabs(scene.TARGET_ID).has("Способности"))
	assert(not scene.request_extract(scene.TARGET_ID, scene.INSTANCE_ID))

	_take_artifact(scene, "TAMAGOTCHI")
	assert(scene.get_wand_editor_tabs(scene.TARGET_ID).has("Способности"))
	assert(scene.interact_with_attachment())
	_take_artifact(scene, "REALITY_STAMP")
	assert(scene.has_bank_access())
	assert(scene.access.set_wand_mode(Access.ORDINARY))
	assert(not scene.request_extract(scene.TARGET_ID, scene.INSTANCE_ID))
	assert(scene.access.set_wand_mode(Access.PLAYFUL))
	var tab: Dictionary = scene.get_wand_editor_tabs(scene.TARGET_ID)
	assert(tab["Способности"][0]["id"] == scene.INSTANCE_ID)
	assert(tab["Способности"][0]["action"].call())
	assert(not donor.can_fly() and not recipient.can_fly())
	assert(not scene.request_extract(scene.TARGET_ID, scene.INSTANCE_ID))
	assert(not scene.request_catalog_install(scene.RECIPIENT_ID, scene.INSTANCE_ID))
	assert(scene.interact_with_attachment())
	assert(not scene.has_bank_access())
	assert(scene.bank.amount(scene.ENTITY_ID, "FLY") == 1)

	var banked: Dictionary = JSON.parse_string(JSON.stringify(scene.make_snapshot()))
	assert(scene.apply_snapshot(banked))
	assert(not scene.has_bank_access())
	assert(scene.bank.amount(scene.ENTITY_ID, "FLY") == 1)
	_take_artifact(scene, "ORI_CATALOG")
	assert(scene.get_wand_editor_tabs(scene.TARGET_ID).has("Способности"))
	assert(not scene.request_catalog_install(scene.RECIPIENT_ID, scene.INSTANCE_ID))
	scene.apply_player_input(Vector2.RIGHT)
	for tick in range(25):
		await physics_frame
	scene.apply_player_input(Vector2.ZERO)
	assert(not scene.request_catalog_install(scene.ENTITY_ID, scene.INSTANCE_ID))
	assert(scene.request_catalog_install(scene.RECIPIENT_ID, scene.INSTANCE_ID))
	assert(not scene.request_catalog_install(scene.TARGET_ID, scene.INSTANCE_ID))
	assert(scene.commands.undo())
	assert(scene.bank.amount(scene.ENTITY_ID, "FLY") == 1)
	assert(scene.commands.redo())
	assert(scene.bank.amount(scene.ENTITY_ID, "FLY") == 0)

	var installed: Dictionary = JSON.parse_string(JSON.stringify(scene.make_snapshot()))
	var duplicate := installed.duplicate(true)
	for entry in duplicate["entities"]:
		if entry["id"] == scene.TARGET_ID:
			entry["components"]["ABILITY_SET"] = {"instances": {scene.INSTANCE_ID: scene.MODULE}}
	assert(not scene.apply_snapshot(duplicate))
	assert(scene.apply_snapshot(installed))
	assert(scene.has_bank_access())
	donor = scene.entities.get_entity(scene.TARGET_ID)
	recipient = scene.entities.get_entity(scene.RECIPIENT_ID)
	assert(recipient.record.get_component("ABILITY_SET")["instances"].has(scene.INSTANCE_ID))
	assert(not donor.can_fly() and recipient.can_fly())

	donor.thrust_requested = true
	recipient.thrust_requested = true
	for tick in range(22):
		await physics_frame
	assert(is_equal_approx(donor.motion.elevation, scene.UPPER_HEIGHT))
	assert(recipient.motion.elevation > scene.UPPER_HEIGHT + 10.0)
	print("P9-04: three ownership gates, unique FLY transfer, undo, save and physical lift passed")
	scene.queue_free()
	await process_frame
	quit()


func _take_artifact(scene: Node, id: String) -> void:
	var item = scene.entities.get_entity(id)
	var point: Vector2 = item.position
	scene.actor.position = point
	assert(scene.actor.motion.start_on_safe_support(point, scene.UPPER_HEIGHT, scene._surfaces))
	assert(scene.interact_with_attachment(id))
	assert(scene.has_bank_access())
