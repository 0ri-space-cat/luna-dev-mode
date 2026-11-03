extends SceneTree
## Approved magical grammar: CREATE ENTITY + SHAPE + ELEMENT + BEHAVIOR
## is a real generated, hackable Entity, not a cosmetic recipe label.

const Grammar = preload("res://scripts/core/arcane_grammar.gd")
const SaveService = preload("res://scripts/core/save_service.gd")

const TEST_PATH := "user://luna_create_grammar_test.json"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	var old_recipe: Dictionary = {
		"form": "ORB", "essence": "FIRE", "delivery": "PROJECTILE",
		"speed": 14.0, "size": 0.4
	}
	assert(Grammar.valid(old_recipe))
	assert(Grammar.normalize(old_recipe)["create"] == "ENERGY")
	assert(Grammar.normalize(old_recipe)["shape"] == "ORB")
	assert(Grammar.normalize(old_recipe)["element"] == "FIRE")
	assert(Grammar.normalize(old_recipe)["release"] == "PROJECTILE")
	assert(Grammar.normalize(old_recipe)["behavior"] == "SEEK")
	assert(not Grammar.valid({"create": "CREATURE", "shape": "ORB"}))
	assert(not Grammar.valid(Grammar.make_recipe("DRAGON", "ORB", "FIRE", "WANDER", "PLACE")))
	assert(Grammar.valid(Grammar.make_recipe("CREATURE", "ORB", "FIRE", "WANDER", "PLACE")))
	assert(Grammar.readable(Grammar.make_recipe("OBJECT", "SHARD", "FROST", "IDLE", "PLACE")).contains("Предмет"))

	var stage = load("res://scenes/main.tscn").instantiate()
	root.add_child(stage)
	stage.save_service = SaveService.new(TEST_PATH)
	var count: int = stage.world_registry.count_live()
	var target_id := "fridge_001"
	var actor_id := "luna"
	var object_magic := Grammar.make_recipe("OBJECT", "SHARD", "FROST", "IDLE", "PLACE", 10.0, 0.38)
	assert(stage.spell_service.register_spell({
		"id": "CREATE_TEST_OBJECT", "label": "ЛЕДЯНАЯ ШТУКА",
		"cast_range": 20.0, "effects": [], "manifestation": object_magic
	}))
	assert(stage.spell_service.cast_spell("CREATE_TEST_OBJECT", actor_id, target_id))
	assert(stage.world_registry.count_live() == count + 1)
	var object_node: Node = stage.world_registry.get_entity("arcane_0001")
	assert(object_node != null)
	assert(object_node.record.category == "arcane_object")
	assert(object_node.arcane_manifestation["shape"] == "SHARD")
	assert(object_node.get_parameter("color") == Grammar.tint("FROST"))
	assert(object_node.get_parameter("alive") == false)
	assert(object_node.primary_part.mesh is CylinderMesh)
	assert(stage.command_processor.execute_set(object_node, "color", Color("f49fc9"), "luna", "wand:luna"))
	assert(object_node.get_parameter("color") == Color("f49fc9"))

	var creature_magic := Grammar.make_recipe("CREATURE", "ORB", "FIRE", "FOLLOW", "PLACE", 10.0, 0.50)
	assert(stage.spell_service.register_spell({
		"id": "CREATE_TEST_CREATURE", "label": "ЖИВОЙ ШАР",
		"cast_range": 20.0, "effects": [], "manifestation": creature_magic
	}))
	assert(stage.spell_service.cast_spell("CREATE_TEST_CREATURE", actor_id, target_id))
	var creature: Node = stage.world_registry.get_entity("arcane_0002")
	assert(creature != null)
	assert(creature.record.category == "arcane_creature")
	assert(creature.get_parameter("alive") == true)
	assert(creature.get_parameter("ai_enabled") == true)
	assert(creature.get_parameter("behavior_mode") == "FOLLOW")
	assert(creature.get_parameter("color") == Grammar.tint("FIRE"))
	assert(creature.primary_part.mesh is SphereMesh)
	assert(creature.record.id != object_node.record.id)

	# Live recipe editor always works with those same data fields.
	stage._open_workshop()
	var panel = stage.spell_workshop_panel
	assert(panel.load_spell("CREATE_TEST_CREATURE"))
	assert(panel._choice_value(panel.create_choice) == "CREATURE")
	assert(panel._choice_value(panel.form_choice) == "ORB")
	assert(panel._choice_value(panel.essence_choice) == "FIRE")
	assert(panel._choice_value(panel.behavior_choice) == "FOLLOW")
	assert(panel._choice_value(panel.release_choice) == "PLACE")
	var raw: Dictionary = panel._manifestation()
	assert(raw == creature_magic)
	panel._select_choice(panel.essence_choice, "STORM")
	assert(panel._manifestation()["element"] == "STORM")
	panel._on_new_recipe()
	assert(panel._manifestation()["create"] == "ENERGY")
	assert(panel._manifestation()["release"] == "PROJECTILE")
	stage._close_workshop()

	# Even a copied recipe containing no ON_HIT effects can produce a creature.
	var created_id: String = stage.spell_workshop_service.create_recipe(
		"Ходячий огненный шар", 20.0, [], creature_magic
	)
	assert(not created_id.is_empty())
	assert(stage.spell_service.cast_spell(created_id, actor_id, target_id))
	assert(stage.world_registry.get_entity("arcane_0003") != null)

	# Generated entities must survive a full scene shutdown and restoration.
	assert(stage.save_service.save_world(
		stage.world_registry, stage.luna, stage.relationship_service
	))
	var checkpoint: Dictionary = stage.save_service.snapshot(
		stage.world_registry, stage.luna, stage.relationship_service
	)
	assert(checkpoint["entities"]["arcane_0001"]["construct"]["create"] == "OBJECT")
	assert(checkpoint["entities"]["arcane_0002"]["construct"]["create"] == "CREATURE")
	stage.free()
	var reloaded = load("res://scenes/main.tscn").instantiate()
	root.add_child(reloaded)
	reloaded.save_service = SaveService.new(TEST_PATH)
	reloaded._load_checkpoint(false)
	var restored_object: Node = reloaded.world_registry.get_entity("arcane_0001")
	var restored_creature: Node = reloaded.world_registry.get_entity("arcane_0002")
	assert(restored_object != null and restored_creature != null)
	assert(restored_object.get_parameter("color") == Color("f49fc9"))
	assert(restored_creature.get_parameter("alive") == true)
	assert(restored_creature.get_parameter("behavior_mode") == "FOLLOW")
	assert(reloaded.world_registry.get_entity("arcane_0003") != null)

	var damaged: Dictionary = checkpoint.duplicate(true)
	damaged["entities"]["arcane_0002"]["construct"]["create"] = "DRAGON"
	assert(not reloaded.save_service.apply_snapshot(
		damaged, reloaded.world_registry, reloaded.luna, reloaded.relationship_service,
		Callable(reloaded, "_restore_arcane_actor"), reloaded.parameter_registry
	))
	assert(reloaded.world_registry.get_entity("arcane_0002") != null)
	reloaded.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	print("LUNA grammar: created entities, editing and restored world passed")
	quit(0)
