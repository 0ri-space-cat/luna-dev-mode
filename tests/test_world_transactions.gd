extends SceneTree
## 0.22: one atomic world action can affect other Entities and COPY/DELETE.
## Uses a real Main scene, EventBus, RuleEngine and SpellService.
const SaveService = preload("res://scripts/core/save_service.gd")
const TEMP := "user://luna_world_transaction_022.json"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if FileAccess.file_exists(TEMP):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEMP))
	var stage = load("res://scenes/main.tscn").instantiate()
	root.add_child(stage)
	stage.save_service = SaveService.new(TEMP)
	var world = stage.world_registry
	var commands = stage.command_processor
	var effects = stage.effect_engine
	var tree: Node3D = world.get_entity("tree_001") as Node3D
	var fridge: Node3D = world.get_entity("fridge_001") as Node3D
	assert(tree != null and fridge != null)
	assert(effects.lifecycle == stage.entity_lifecycle)
	var initial_speed: float = float(fridge.get_parameter("speed"))

	# A single spell changes a DIFFERENT entity then creates a new entity.
	# One undo/redo must reverse both changes with stable new IDs.
	assert(effects.apply_batch([
		{"operation": "ADD", "parameter_id": "speed", "target_id": "fridge_001", "value": 1.0},
		{"operation": "COPY_ENTITY", "target_id": "tree_001", "new_id": "tree_copy_0001"}
	], "tree_001", "luna", "spell:DUPLICATE"))
	var copied: Node3D = world.get_entity("tree_copy_0001") as Node3D
	assert(copied != null)
	assert(copied.record.category == "tree")
	assert(copied.get_meta("copy_origin") == "tree_001")
	assert(is_equal_approx(float(fridge.get_parameter("speed")), initial_speed + 1.0))
	assert(commands.get_recent_audit(1)[0]["action"] == "ENTITY_CREATE")
	assert(commands.get_recent_audit(1)[0]["source_id"] == "spell:DUPLICATE")
	assert(commands.undo())
	assert(world.get_entity("tree_copy_0001") == null)
	assert(world.was_deleted("tree_copy_0001"))
	assert(is_equal_approx(float(fridge.get_parameter("speed")), initial_speed))
	assert(commands.redo())
	var redone: Node3D = world.get_entity("tree_copy_0001") as Node3D
	assert(redone != null and redone != copied)
	assert(not world.was_deleted("tree_copy_0001"))
	assert(is_equal_approx(float(fridge.get_parameter("speed")), initial_speed + 1.0))

	# Reject invalid tails BEFORE any mutation; no audit or gameplay events.
	var previous_audit: int = commands.get_audit_log().size()
	var previous_pending: int = stage.event_bus.pending_count()
	assert(not effects.apply_batch([
		{"operation": "ADD", "parameter_id": "speed", "target_id": "fridge_001", "value": 1.0},
		{"operation": "COPY_ENTITY", "target_id": "tree_001", "new_id": "fridge_copy_0005"}
	], "tree_001", "luna", "spell:BAD"))
	assert(is_equal_approx(float(fridge.get_parameter("speed")), initial_speed + 1.0))
	assert(world.get_entity("fridge_copy_0005") == null)
	assert(commands.get_audit_log().size() == previous_audit)
	assert(stage.event_bus.pending_count() == previous_pending)
	assert(not effects.apply_batch([
		{"operation": "DELETE_ENTITY"},
		{"operation": "ADD", "parameter_id": "speed", "value": 1.0}
	], "tree_001", "luna", "spell:EARLY_DELETE"))
	assert(not effects.apply_batch([
		{"operation": "ADD", "parameter_id": "health", "value": -1},
		{"operation": "DELETE_ENTITY"}
	], "tree_001", "luna", "spell:SELF_DELETE_MIX"))
	assert(world.get_entity("tree_001") != null)

	# A stale preview is rejected without deleting anything.
	var preview: Dictionary = effects.preview_batch([
		{"operation": "SET", "parameter_id": "health", "target_id": "fridge_001", "value": 26},
		{"operation": "DELETE_ENTITY", "target_id": "tree_001"}
	], "tree_001")
	assert(preview["ok"] and preview.has("lifecycle"))
	assert(fridge.set_parameter("health", 65))
	var steps: Array[Dictionary] = preview["steps"]
	assert(not commands.execute_world_batch(steps, stage.entity_lifecycle,
		"DELETE", preview["lifecycle"]["blueprint"], "luna", "stale:preview"))
	assert(world.get_entity("tree_001") != null)
	assert(fridge.get_parameter("health") == 65)

	# Relationships/statuses on the deleted actor restore with a single undo.
	assert(stage.relationship_service.set_attitude("tree_001", "luna", "FRIEND"))
	assert(stage.elemental_status_service.apply_element("tree_001", "FROST"))
	var original_color: Color = tree.get_parameter("color")
	assert(effects.apply_batch([
		{"operation": "SET", "parameter_id": "color", "target_id": "fridge_001", "value": Color("f49fc9")},
		{"operation": "DELETE_ENTITY", "target_id": "tree_001"}
	], "tree_001", "luna", "rule:VANISH"))
	assert(world.get_entity("tree_001") == null)
	assert(world.was_deleted("tree_001"))
	assert(stage.relationship_service.get_attitude("tree_001", "luna") == "NEUTRAL")
	assert(not stage.elemental_status_service.has_status("tree_001", "CHILL"))
	assert(commands.undo())
	var rebuilt: Node3D = world.get_entity("tree_001") as Node3D
	assert(rebuilt != null and rebuilt != tree)
	assert(rebuilt.get_parameter("color") == original_color)
	assert(stage.relationship_service.get_attitude("tree_001", "luna") == "FRIEND")
	assert(stage.elemental_status_service.has_status("tree_001", "CHILL"))
	assert(fridge.get_parameter("color") == Color("87bfe8"))
	assert(commands.redo())
	assert(world.get_entity("tree_001") == null)
	assert(fridge.get_parameter("color") == Color("f49fc9"))
	assert(commands.undo())  # Restore original tree for subsequent tests.

	# Bare JSON-safe rules may copy creatures with automatically allocated IDs.
	assert(stage.rule_engine.register_rule({
		"id": "test:copy_tree", "event_type": "test.trigger_copy",
		"owner_id": "fridge_001", "target": "EVENT_TARGET",
		"repeat_limit": 1, "author_id": "luna",
		"effects": [{"operation": "COPY_ENTITY", "offset": [2.0, 0.0, 0.0]}]
	}))
	assert(stage.event_bus.enqueue({
		"type": "test.trigger_copy", "source_id": "fridge_001",
		"target_id": "tree_001", "payload": {}
	}))
	assert(stage.event_bus.drain(stage.rule_engine) >= 1)
	assert(stage.rule_engine.fired_count("test:copy_tree") == 1)
	var ids: Array[String] = world.query_ids({"category": "tree"}, 24)
	var newly_copied := false
	for entity_id in ids:
		if entity_id.begins_with("tree_copy_") and entity_id != "tree_copy_0001":
			newly_copied = true
	assert(newly_copied)
	assert(not stage.rule_engine.register_rule({
		"id": "test:unsafe_delete", "event_type": "test.any",
		"owner_id": "fridge_001", "target": "EVENT_TARGET",
		"effects": [{"operation": "DELETE_ENTITY", "script": "OS.execute"}]
	}))

	# Direct spells can COPY/DELETE; area-chain destructive spells are
	# explicitly rejected until a proper multi-entity planner exists.
	assert(stage.spell_service.register_spell({
		"id": "DISAPPEAR", "label": "DISAPPEAR", "cast_range": 20.0,
		"effects": [{"operation": "DELETE_ENTITY"}]
	}))
	assert(not stage.spell_service.register_spell({
		"id": "BAD_AREA_DELETE", "label": "BAD", "cast_range": 20.0,
		"impact": {"mode": "BURST", "radius": 3.0},
		"effects": [{"operation": "DELETE_ENTITY"}]
	}))
	assert(stage.spell_service.cast_spell("DISAPPEAR", "luna", "tree_002"))
	assert(world.get_entity("tree_002") == null)
	assert(commands.undo())
	assert(world.get_entity("tree_002") != null)

	# Explicit typed CREATE works without custom code or a new scene.
	var blueprint: Dictionary = stage.entity_lifecycle.capture("tree_002")
	blueprint["id"] = "tree_copy_0097"
	blueprint["copy_origin"] = "tree_002"
	blueprint["position"] = Vector3(2.0, 0.1, -2.0)
	assert(effects.apply_batch([
		{"operation": "CREATE_ENTITY", "blueprint": blueprint}
	], "tree_002", "luna", "system:CREATE"))
	assert(world.get_entity("tree_copy_0097") != null)
	assert(commands.undo())
	assert(world.get_entity("tree_copy_0097") == null)
	assert(commands.redo())
	assert(world.get_entity("tree_copy_0097") != null)

	stage._save_checkpoint(false)
	assert(stage.save_service.has_save())
	stage.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEMP))
	print("LUNA 0.22: atomic world effects, rule/spell lifecycle and undo/redo passed")
	quit(0)
