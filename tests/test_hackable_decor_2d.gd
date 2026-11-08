extends SceneTree
const Save2D = preload("res://scripts/2d/meadow_save_2d.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: PackedScene = load("res://scenes/2d/world_2d.tscn")
	var meadow := scene.instantiate() as Node2D
	root.add_child(meadow)
	await process_frame
	var world: Variant = meadow.get("world")
	var hack: Variant = meadow.get("session")
	var processor: Variant = meadow.get("processor")
	var registry: Variant = meadow.get("registry")
	var player := meadow.get_node("Entities/Player") as CharacterBody2D
	var decor := meadow.get_node("GroundDecorScatter")
	var chosen: Sprite2D = null
	for item in decor.spawned:
		if str(item.get_meta("decor_kind")) == "flower":
			chosen = item
			break
	assert(chosen != null)
	assert(world.count_live() == 6)
	var id := str(chosen.get_meta("entity_id"))
	var promoted: Node = meadow._promote_decoration(chosen)
	assert(promoted != null and world.count_live() == 7)
	assert(str(promoted.record.id) == id)
	assert(str(promoted.record.category) == "arcane_object")
	assert(promoted.visual.kind == "flower")
	assert(decor.spawned.size() == 15)
	assert(promoted.visual.legs.current_source != "")
	assert(not promoted.visual.legs.visible)
	hack.touch_rift()
	assert(hack.edit(promoted, "alive", true, processor))
	await physics_frame
	await process_frame
	assert(promoted.visual.legs.visible)
	assert(promoted.visual.legs.left != null and promoted.visual.legs.right != null)
	assert(meadow.get_node("Entities/Player/Visual").has_method("set_motion"))
	var snapshot := Save2D.new("user://modular_decor_persistence_test.json")
	assert(snapshot.write(player, world, hack))
	assert(processor.execute_entity_delete(meadow.get("lifecycle"), id))
	assert(world.count_live() == 6)
	assert(snapshot.read(player, world, hack, registry, meadow.get("lifecycle")))
	decor.reconcile_promoted(world)
	var restored: Node = world.get_entity(id)
	assert(restored != null)
	assert(bool(restored.get_parameter("alive")))
	assert(restored.visual.kind == "flower")
	assert(restored.visual.legs != null)
	meadow.queue_free()
	print("Hackable decoration / reusable legs / save restoration: PASS")
	quit()
