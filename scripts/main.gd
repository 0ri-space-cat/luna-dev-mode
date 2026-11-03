extends Node3D
## LUNA: DEV MODE — first playable graybox, deliberately without final art.

const PlayerController = preload("res://scripts/player_controller.gd")
const HackableEntity = preload("res://scripts/hackable_entity.gd")
const HackEditor = preload("res://scripts/hack_editor.gd")
const ParameterRegistry = preload("res://scripts/core/parameter_registry.gd")
const CommandProcessor = preload("res://scripts/core/command_processor.gd")
const WorldRegistry = preload("res://scripts/core/world_registry.gd")
const EntityLifecycleService = preload("res://scripts/core/entity_lifecycle_service.gd")
const EventBus = preload("res://scripts/core/event_bus.gd")
const EffectEngine = preload("res://scripts/core/effect_engine.gd")
const RuleEngine = preload("res://scripts/core/rule_engine.gd")
const SaveService = preload("res://scripts/core/save_service.gd")
const RelationshipService = preload("res://scripts/core/relationship_service.gd")
const SocialAwarenessService = preload("res://scripts/core/social_awareness_service.gd")
const ProfileService = preload("res://scripts/core/profile_service.gd")
const SpellService = preload("res://scripts/core/spell_service.gd")
const ElementalStatusService = preload("res://scripts/core/elemental_status_service.gd")
const SurfaceFieldService = preload("res://scripts/core/surface_field_service.gd")
const SpellWorkshopService = preload("res://scripts/core/spell_workshop_service.gd")
const SpellWorkshop = preload("res://scripts/spell_workshop.gd")
const ArcaneProjectile = preload("res://scripts/spells/arcane_projectile.gd")
const ArcaneLink = preload("res://scripts/spells/arcane_link.gd")
const ArcaneGrammar = preload("res://scripts/core/arcane_grammar.gd")
const UiLanguage = preload("res://scripts/core/ui_language.gd")

var ui_language = UiLanguage.new()
var ui_layer: CanvasLayer
var language_choice: OptionButton
var duplicate_serial := 0
const MAX_DUPLICATES := 24
var luna: CharacterBody3D
var camera: Camera3D
var editor
var pause_tint: ColorRect
var pending_selection := Vector2(-1, -1)
var parameter_registry
var command_processor
var world_registry
var entity_lifecycle
var event_bus
var effect_engine
var rule_engine
var save_service
var relationship_service
var social_awareness
var profile_service
var spell_service
var elemental_status_service
var surface_field_service
var environment_visuals: Array[Node3D] = []
var spell_workshop_service
var spell_workshop_panel
var selected_spell_id := "FIREBALL"
var pending_spell_cast := false
var arcane_serial := 0
const MAX_ARCANE_ENTITIES := 40
var spell_hint_label: Label
var journal_panel: PanelContainer
var journal_label: Label
var save_status_label: Label
var _autosave_elapsed := 0.0
var _save_message_seconds := 0.0
const AUTO_SAVE_INTERVAL := 30.0


func _ready() -> void:
	parameter_registry = ParameterRegistry.new()
	command_processor = CommandProcessor.new()
	world_registry = WorldRegistry.new()
	relationship_service = RelationshipService.new()
	social_awareness = SocialAwarenessService.new(world_registry, relationship_service)
	social_awareness.alert_changed.connect(_on_social_alert_changed)
	event_bus = EventBus.new()
	effect_engine = EffectEngine.new(world_registry, command_processor, relationship_service)
	surface_field_service = SurfaceFieldService.new()
	surface_field_service.fields_changed.connect(_on_surface_fields_changed)
	elemental_status_service = ElementalStatusService.new(world_registry, effect_engine, surface_field_service)
	elemental_status_service.fire_spread.connect(_on_fire_spread)
	elemental_status_service.reaction_triggered.connect(_on_elemental_reaction)
	elemental_status_service.state_changed.connect(_on_elemental_state_changed)
	spell_service = SpellService.new(world_registry, effect_engine, elemental_status_service)
	spell_service.damage_applied.connect(_on_spell_damage)
	spell_service.projectile_requested.connect(_spawn_arcane_projectile)
	spell_service.chain_resolved.connect(_on_chain_resolved)
	spell_service.manifestation_requested.connect(_on_arcane_place)
	spell_workshop_service = SpellWorkshopService.new(parameter_registry, spell_service)
	if spell_workshop_service.has_library():
		if not spell_workshop_service.load_library():
			push_warning("Spell recipes could not be loaded: %s" % spell_workshop_service.last_error)
	rule_engine = RuleEngine.new(effect_engine)
	save_service = SaveService.new()
	profile_service = ProfileService.new()
	if profile_service.has_profile():
		if not profile_service.load_profile():
			push_warning("Profile could not be read: %s" % profile_service.last_error)
	command_processor.parameter_changed.connect(_on_parameter_changed)
	command_processor.trait_changed.connect(_on_trait_changed)
	command_processor.entity_changed.connect(_on_entity_changed)
	relationship_service.relationship_changed.connect(_on_relationship_changed)
	_register_controls()
	_build_environment()
	_build_ground()
	_spawn_player()
	_spawn_entities()
	entity_lifecycle = EntityLifecycleService.new(
		world_registry, parameter_registry, relationship_service,
		elemental_status_service, social_awareness,
		Callable(self, "_spawn_lifecycle_actor")
	)
	_register_example_rules()
	_build_interface()
	if save_service.has_save():
		_load_checkpoint(true)


func _process(delta: float) -> void:
	# Keep an orthographic game view that reads like a 2D cartoon.
	if is_instance_valid(luna):
		camera.global_position = luna.global_position + Vector3(0, 14, 13)
		camera.look_at(luna.global_position + Vector3(0, 0.65, 0))
	_autosave_elapsed += delta
	if _autosave_elapsed >= AUTO_SAVE_INTERVAL:
		_autosave_elapsed = 0.0
		_save_checkpoint(false)
	if _save_message_seconds > 0.0:
		_save_message_seconds -= delta
		if _save_message_seconds <= 0.0 and is_instance_valid(save_status_label):
			save_status_label.text = ""


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode >= KEY_1 and event.keycode <= KEY_9:
			var index: int = int(event.keycode) - int(KEY_1)
			var spell_ids: Array[String] = spell_service.list_spell_ids()
			if index >= 0 and index < spell_ids.size():
				selected_spell_id = spell_ids[index]
				_update_spell_hint()
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_TAB:
			_select_next_spell()
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_B:
			_open_workshop()
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_J:
			_toggle_journal()
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_F6:
			_save_checkpoint(true)
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_F9:
			_load_checkpoint(false)
			get_viewport().set_input_as_handled()
			return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		pending_selection = event.position
		pending_spell_cast = event.shift_pressed


func _physics_process(delta: float) -> void:
	if elemental_status_service != null:
		elemental_status_service.advance(delta)
	if surface_field_service != null:
		surface_field_service.advance(delta)
	if social_awareness != null:
		social_awareness.advance(delta)
	# Reactive events are delivered in a bounded batch, never recursively.
	event_bus.drain(rule_engine)
	# Physics queries are intentionally performed in a physics tick, not in input callbacks.
	if pending_selection != Vector2(-1, -1):
		var mouse_position := pending_selection
		var casting: bool = pending_spell_cast
		pending_selection = Vector2(-1, -1)
		pending_spell_cast = false
		_try_select(mouse_position, casting)


func _exit_tree() -> void:
	# Save on normal exit as well as on the periodic checkpoint.
	if save_service != null and world_registry != null and is_instance_valid(luna):
		save_service.save_world(world_registry, luna, relationship_service, elemental_status_service, surface_field_service, social_awareness, rule_engine)
	if profile_service != null:
		profile_service.save_profile()
	if get_tree() != null:
		get_tree().paused = false


func _register_controls() -> void:
	_add_key("move_left", KEY_A)
	_add_key("move_left", KEY_LEFT)
	_add_key("move_right", KEY_D)
	_add_key("move_right", KEY_RIGHT)
	_add_key("move_forward", KEY_W)
	_add_key("move_forward", KEY_UP)
	_add_key("move_backward", KEY_S)
	_add_key("move_backward", KEY_DOWN)


func _add_key(action: String, key: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var keyboard := InputEventKey.new()
	keyboard.physical_keycode = key
	InputMap.action_add_event(action, keyboard)


func _build_environment() -> void:
	var world_environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("342e51")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("ddd3f7")
	env.ambient_light_energy = 0.8
	world_environment.environment = env
	add_child(world_environment)

	var sunlight := DirectionalLight3D.new()
	sunlight.rotation_degrees = Vector3(-55, -32, 0)
	sunlight.light_energy = 1.6
	add_child(sunlight)

	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 15.5
	camera.near = 0.1
	camera.far = 130.0
	add_child(camera)
	camera.make_current()


func _build_ground() -> void:
	var floor_body := StaticBody3D.new()
	floor_body.name = "PastelGround"
	floor_body.collision_layer = 1
	floor_body.collision_mask = 0
	floor_body.position = Vector3(0, -0.12, 0)
	add_child(floor_body)
	var shape := BoxShape3D.new()
	shape.size = Vector3(22, 0.24, 22)
	var collider := CollisionShape3D.new()
	collider.shape = shape
	floor_body.add_child(collider)
	var floor_mesh := BoxMesh.new()
	floor_mesh.size = shape.size
	var surface := MeshInstance3D.new()
	surface.mesh = floor_mesh
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color("b6aacd")
	floor_material.roughness = 1.0
	surface.material_override = floor_material
	floor_body.add_child(surface)

	# Decorative stepping stones, deliberately not collidable.
	for i in range(7):
		var stone_mesh := SphereMesh.new()
		stone_mesh.radius = 0.46
		stone_mesh.height = 0.16
		var stone := MeshInstance3D.new()
		stone.mesh = stone_mesh
		stone.position = Vector3(-5.1 + float(i) * 1.65, 0.04, 3.2)
		var material := StandardMaterial3D.new()
		material.albedo_color = Color("e9d6ec")
		stone.material_override = material
		add_child(stone)


func _spawn_player() -> void:
	luna = PlayerController.new()
	luna.surface_service = surface_field_service
	luna.position = Vector3(0, 0.1, 3.3)
	add_child(luna)
	world_registry.register_entity("luna", luna, "LUNA")


func _spawn_entities() -> void:
	_spawn("tree_001", "tree", Vector3(-3.2, 0.1, -1.0))
	_spawn("tree_002", "tree", Vector3(4.5, 0.1, -3.0))
	_spawn("fridge_001", "fridge", Vector3(2.0, 0.1, -1.3))


func _spawn(entity_id: String, category: String, where: Vector3) -> Node:
	if world_registry.get_entity(entity_id) != null or category not in ["tree", "fridge"]:
		return null
	var entity := HackableEntity.new()
	add_child(entity)
	entity.configure(entity_id, category, where, parameter_registry, world_registry,
		relationship_service, {}, elemental_status_service, social_awareness)
	if not world_registry.register_entity(entity_id, entity, category.to_upper()):
		entity.queue_free()
		return null
	entity.target_acquired.connect(_on_target_acquired)
	return entity


func _spawn_lifecycle_actor(spec: Dictionary) -> Node:
	var entity_id: String = str(spec["id"])
	var category: String = str(spec["category"])
	var location: Vector3 = spec["position"]
	match category:
		"tree", "fridge":
			if spec.has("copy_origin"):
				return _spawn_saved_duplicate(entity_id, category, location, str(spec["copy_origin"]))
			return _spawn(entity_id, category, location)
		_:
			if category.begins_with("arcane_"):
				return _spawn_arcane_actor_with_id(entity_id, spec["construct"], location)
	return null


func _restore_base_actor(entity_id: String, category: String, location: Vector3) -> Node:
	return _spawn(entity_id, category, location)


func _remove_saved_entity(entity_id: String) -> bool:
	return entity_lifecycle.unload_entity(entity_id)


func _register_example_rules() -> void:
	# Proof of the reusable rule system: when the fridge notices a tree,
	# the tree gets a pink tint. No special-case logic in the fridge itself.
	rule_engine.register_rule({
		"id": "demo:fridge_notices_tree",
		"owner_id": "fridge_001",
		"event_type": "entity.target_acquired",
		"conditions": [{"field": "group", "equals": "TREE"}],
		"target": "EVENT_TARGET",
		"effects": [{"operation": "SET", "parameter_id": "color", "value": Color("f49fc9")}],
		"cooldown_ms": 0
	})


func _on_target_acquired(source_id: String, target_id: String, target_group: String) -> void:
	event_bus.enqueue({
		"type": "entity.target_acquired",
		"source_id": source_id,
		"target_id": target_id,
		"payload": {"group": target_group}
	})


func _on_social_alert_changed(entity_id: String, alert: Dictionary) -> void:
	var actor: Node = world_registry.get_entity(entity_id)
	if actor != null and actor.has_method("show_social_alert"):
		actor.call("show_social_alert", alert)


func _on_spell_damage(details: Dictionary) -> void:
	var targets: Array[String] = []
	for entity_id in details.get("targets", []):
		targets.append(str(entity_id))
	social_awareness.observe_damage(str(details.get("caster_id", "")), targets)


func _on_parameter_changed(change: Dictionary) -> void:
	# Mirror social edits even when the internal API undoes/ redoes a command.
	if str(change.get("parameter_id", "")) == "luna_relation":
		relationship_service.set_attitude(
			str(change["entity_id"]), "luna", str(change["after"]),
			str(change["initiator_id"]), str(change["source_id"])
		)
	# Undo/redo restores prior state without triggering gameplay rules.
	if str(change.get("action", "")) != "SET":
		return
	if str(change.get("initiator_id", "")) == "luna" and str(change.get("source_id", "")) == "wand:luna":
		var inspected: Node = world_registry.get_entity(str(change.get("entity_id", "")))
		if inspected != null and inspected.has_method("get_parameter"):
			var entity_record: Variant = inspected.get("record")
			if entity_record != null and profile_service.discover_parameter(
				str(entity_record.category), str(change["parameter_id"])
			):
				profile_service.save_profile()
	# Direct harmful wand edits are witnessed just like harmful spells.
	if str(change.get("source_id", "")) == "wand:luna" 			and str(change.get("initiator_id", "")) == "luna" 			and str(change.get("parameter_id", "")) == "health" 			and float(change.get("after", 0)) < float(change.get("before", 0)):
		social_awareness.observe_damage("luna", [str(change["entity_id"])])
	event_bus.enqueue({
		"type": "parameter.changed",
		"source_id": str(change["entity_id"]),
		"target_id": str(change["entity_id"]),
		"payload": {
			"parameter_id": str(change["parameter_id"]),
			"value": change["after"],
			"initiator_id": str(change["initiator_id"])
		}
	})


func _on_entity_changed(change: Dictionary) -> void:
	var entity_id: String = str(change["entity_id"])
	if not bool(change["present"]) and is_instance_valid(editor) and editor.visible \
			and is_instance_valid(editor.target) and str(editor.target.record.id) == entity_id:
		_close_editor()
	event_bus.enqueue({
		"type": "entity.created" if bool(change["present"]) else "entity.deleted",
		"source_id": entity_id,
		"target_id": entity_id,
		"payload": {
			"category": str(change["category"]),
			"initiator_id": str(change["initiator_id"]),
			"command_source_id": str(change["source_id"])
		}
	})


func _on_trait_changed(change: Dictionary) -> void:
	# Entity classification is part of the same causal event system as parameters.
	event_bus.enqueue({
		"type": "entity.traits_changed",
		"source_id": str(change["entity_id"]),
		"target_id": str(change["entity_id"]),
		"payload": {
			"roles": change["after"]["roles"],
			"tags": change["after"]["tags"],
			"initiator_id": str(change["initiator_id"]),
			"command_source_id": str(change["source_id"])
		}
	})


func _on_relationship_changed(change: Dictionary) -> void:
	event_bus.enqueue({
		"type": "relationship.changed",
		"source_id": str(change["from_id"]),
		"target_id": str(change["to_id"]),
		"payload": {"before": change["before"], "attitude": change["after"]}
	})


func _sync_luna_relationships() -> void:
	# Covers older saves that only had LUNA_RELATION on each entity.
	for entity_id in world_registry.list_ids():
		var target: Node = world_registry.get_entity(entity_id)
		if target == null or not target.has_method("get_parameter"):
			continue
		var relation: Variant = target.call("get_parameter", "luna_relation")
		if relation != null:
			relationship_service.set_attitude(entity_id, "luna", str(relation), "system", "save:restore")


func _build_interface() -> void:
	var layer := CanvasLayer.new()
	ui_layer = layer
	layer.name = "ScreenUI"
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)

	pause_tint = ColorRect.new()
	pause_tint.name = "HackModeTurquoiseMist"
	pause_tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_tint.color = Color(0.20, 0.89, 0.86, 0.13)
	pause_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pause_tint.visible = false
	layer.add_child(pause_tint)

	var header := Label.new()
	header.text = "LUNA: DEV MODE   ✦   ПРОТОТИП 0.20"
	header.position = Vector2(24, 16)
	header.add_theme_font_size_override("font_size", 22)
	header.add_theme_color_override("font_color", Color("efe2ff"))
	header.set_meta("ui_source", header.text)
	layer.add_child(header)

	language_choice = OptionButton.new()
	language_choice.position = Vector2(1112, 13)
	language_choice.custom_minimum_size.x = 142
	language_choice.add_item("ENGLISH")
	language_choice.add_item("РУССКИЙ")
	language_choice.select(0 if ui_language.locale == "en" else 1)
	language_choice.item_selected.connect(_on_language_selected)
	layer.add_child(language_choice)

	var instructions := Label.new()
	instructions.text = "WASD — ходить   •   ЛКМ — взломать   •   Shift+ЛКМ — колдовать   •   1–9 / Tab — выбрать   •   B — конструктор"
	instructions.position = Vector2(24, 50)
	instructions.add_theme_font_size_override("font_size", 15)
	instructions.add_theme_color_override("font_color", Color("e0f7f4"))
	instructions.set_meta("ui_source", instructions.text)
	layer.add_child(instructions)

	spell_hint_label = Label.new()
	spell_hint_label.position = Vector2(24, 80)
	spell_hint_label.add_theme_font_size_override("font_size", 14)
	spell_hint_label.add_theme_color_override("font_color", Color("ffe1f5"))
	layer.add_child(spell_hint_label)
	_update_spell_hint()

	var bottom := Label.new()
	bottom.text = "Попробуй: FRIDGE → IS_ALIVE TRUE → BEHAVIOR_MODE CHASE → TARGET_GROUP TREE"
	bottom.position = Vector2(24, 750)
	bottom.add_theme_color_override("font_color", Color("f7e2f4"))
	bottom.add_theme_font_size_override("font_size", 16)
	bottom.set_meta("ui_source", bottom.text)
	layer.add_child(bottom)


	save_status_label = Label.new()
	save_status_label.position = Vector2(24, 708)
	save_status_label.add_theme_font_size_override("font_size", 15)
	save_status_label.add_theme_color_override("font_color", Color("d2ffe9"))
	layer.add_child(save_status_label)


	journal_panel = PanelContainer.new()
	journal_panel.position = Vector2(24, 100)
	journal_panel.custom_minimum_size = Vector2(400, 350)
	journal_panel.visible = false
	layer.add_child(journal_panel)
	var journal_style := StyleBoxFlat.new()
	journal_style.bg_color = Color("28233e")
	journal_style.border_color = Color("aa8ae0")
	journal_style.set_border_width_all(2)
	journal_style.set_corner_radius_all(10)
	journal_style.set_content_margin_all(14)
	journal_panel.add_theme_stylebox_override("panel", journal_style)
	var journal_layout := VBoxContainer.new()
	journal_panel.add_child(journal_layout)
	var title := Label.new()
	title.text = "ДНЕВНИК ЛУНЫ   [J]"
	title.add_theme_font_size_override("font_size", 18)
	title.set_meta("ui_source", title.text)
	journal_layout.add_child(title)
	var journal_scroller := ScrollContainer.new()
	journal_scroller.custom_minimum_size = Vector2(360, 280)
	journal_scroller.size_flags_vertical = Control.SIZE_EXPAND_FILL
	journal_layout.add_child(journal_scroller)
	journal_label = Label.new()
	journal_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	journal_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	journal_scroller.add_child(journal_label)

	editor = HackEditor.new()
	layer.add_child(editor)
	editor.configure(parameter_registry, command_processor, ui_language)
	editor.closed.connect(_close_editor)
	editor.duplicate_requested.connect(_on_duplicate_requested)
	editor.delete_requested.connect(_on_delete_requested)

	spell_workshop_panel = SpellWorkshop.new()
	layer.add_child(spell_workshop_panel)
	spell_workshop_panel.configure(parameter_registry, spell_workshop_service, ui_language)
	spell_workshop_panel.closed.connect(_close_workshop)
	spell_workshop_panel.spell_created.connect(_on_custom_spell_created)
	_refresh_language()


func _on_language_selected(index: int) -> void:
	ui_language.set_locale("en" if index == 0 else "ru")
	_refresh_language()


func _refresh_language() -> void:
	if is_instance_valid(ui_layer):
		_localize_control_tree(ui_layer)
	if is_instance_valid(editor):
		editor.refresh_language()
	if is_instance_valid(spell_workshop_panel):
		spell_workshop_panel.refresh_language()
	if is_instance_valid(journal_panel) and journal_panel.visible:
		_refresh_journal()
	_update_spell_hint()


func _localize_control_tree(node: Node) -> void:
	if node.has_meta("ui_source") and node is Label:
		(node as Label).text = ui_language.translated(str(node.get_meta("ui_source")))
	for child in node.get_children():
		if child == editor or child == spell_workshop_panel:
			continue
		_localize_control_tree(child)


func _on_duplicate_requested(source: Node3D) -> void:
	var copied: Node3D = _duplicate_entity(source)
	if is_instance_valid(copied):
		editor.show_for(copied)
		_show_checkpoint_message(ui_language.text("ENTITY COPIED", "ОБЪЕКТ СКОПИРОВАН"))


func _on_delete_requested(source: Node3D) -> void:
	if not is_instance_valid(source) or entity_lifecycle == null:
		return
	var entity_id: String = str(source.record.id)
	_close_editor()
	if not command_processor.execute_entity_delete(entity_lifecycle, entity_id, "luna", "wand:luna"):
		_show_checkpoint_message(ui_language.text("DELETE FAILED", "ОШИБКА УДАЛЕНИЯ"))
	else:
		_show_checkpoint_message(ui_language.text("ENTITY DELETED", "ОБЪЕКТ УДАЛЁН"))


func _duplicate_entity(source: Node3D) -> Node3D:
	if not is_instance_valid(source) or entity_lifecycle == null:
		return null
	var count := 0
	for entity_id in world_registry.list_ids():
		var existing: Node = world_registry.get_entity(entity_id)
		if existing != null and existing.has_meta("copy_origin"):
			count += 1
	if count >= MAX_DUPLICATES:
		_show_checkpoint_message(ui_language.text("COPY LIMIT REACHED", "ДОСТИГНУТ ПРЕДЕЛ КОПИЙ"))
		return null
	var category: String = str(source.record.category)
	if category not in ["tree", "fridge"] and not category.begins_with("arcane_"):
		return null
	var blueprint: Dictionary = entity_lifecycle.capture(str(source.record.id))
	if blueprint.is_empty():
		return null
	blueprint["position"] = source.position + Vector3(1.7, 0.0, 0.8)
	if category.begins_with("arcane_"):
		arcane_serial += 1
		var generated_id := "arcane_%04d" % arcane_serial
		while world_registry.get_entity(generated_id) != null or world_registry.was_deleted(generated_id):
			arcane_serial += 1
			generated_id = "arcane_%04d" % arcane_serial
		blueprint["id"] = generated_id
	else:
		duplicate_serial += 1
		var copy_id := "%s_copy_%04d" % [category, duplicate_serial]
		while world_registry.get_entity(copy_id) != null or world_registry.was_deleted(copy_id):
			duplicate_serial += 1
			copy_id = "%s_copy_%04d" % [category, duplicate_serial]
		blueprint["id"] = copy_id
		blueprint["copy_origin"] = str(source.record.id)
	var copied: Node = command_processor.execute_entity_create(entity_lifecycle, blueprint,
		"luna", "wand:luna")
	return copied as Node3D


func _spawn_saved_duplicate(entity_id: String, category: String, location: Vector3, original_id: String) -> Node3D:
	if world_registry.get_entity(entity_id) != null or category not in ["tree", "fridge"]:
		return null
	var copy := HackableEntity.new()
	add_child(copy)
	copy.configure(entity_id, category, location, parameter_registry, world_registry,
		relationship_service, {}, elemental_status_service, social_awareness)
	if not world_registry.register_entity(entity_id, copy, category.to_upper()):
		copy.queue_free()
		return null
	copy.set_meta("copy_origin", original_id)
	copy.target_acquired.connect(_on_target_acquired)
	var parts := entity_id.split("_copy_")
	if parts.size() == 2:
		duplicate_serial = maxi(duplicate_serial, int(parts[1]))
	return copy


func _restore_saved_duplicate(entity_id: String, category: String, location: Vector3, original_id: String) -> Node3D:
	return _spawn_saved_duplicate(entity_id, category, location, original_id)


func _try_select(mouse_position: Vector2, casting: bool = false) -> void:
	var from := camera.project_ray_origin(mouse_position)
	var to := from + camera.project_ray_normal(mouse_position) * 150.0
	var query := PhysicsRayQueryParameters3D.create(from, to, 2)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return
	var entity: Object = hit.get("collider")
	if entity == null or not entity.has_method("get_parameter"):
		return
	if casting:
		var selected: Node = entity as Node
		var record: Variant = selected.get("record")
		if record == null:
			return
		if spell_service.cast_spell(selected_spell_id, "luna", str(record.id)):
			_show_checkpoint_message(ui_language.text("SPELL: %s", "ЗАКЛИНАНИЕ: %s") % selected_spell_id)
		else:
			_show_checkpoint_message(spell_service.last_error)
		return
	_open_editor(entity as Node3D)


func _open_editor(entity: Node3D) -> void:
	if profile_service.discover_category(str(entity.record.category)):
		profile_service.save_profile()
	pause_tint.visible = true
	editor.show_for(entity)
	get_tree().paused = true


func _close_editor() -> void:
	editor.visible = false
	pause_tint.visible = false
	get_tree().paused = false


func _save_checkpoint(notify_player: bool) -> void:
	if save_service == null or not is_instance_valid(luna):
		return
	var success: bool = save_service.save_world(
		world_registry, luna, relationship_service,
		elemental_status_service, surface_field_service, social_awareness, rule_engine
	)
	if notify_player or not success:
		_show_checkpoint_message(ui_language.text("WORLD SAVED", "МИР СОХРАНЁН") if success else ui_language.text("SAVE ERROR: %s", "ОШИБКА СОХРАНЕНИЯ: %s") % save_service.last_error)


func _load_checkpoint(automatic: bool) -> void:
	if save_service == null or not save_service.has_save() or not is_instance_valid(luna):
		if not automatic:
			_show_checkpoint_message(ui_language.text("NO SAVE FOUND", "НЕТ СОХРАНЕНИЯ"))
		return
	var success: bool = save_service.load_world(
		world_registry, luna, relationship_service,
		Callable(self, "_restore_arcane_actor"), parameter_registry,
		elemental_status_service, surface_field_service, social_awareness,
		Callable(self, "_restore_saved_duplicate"), rule_engine,
		Callable(self, "_remove_saved_entity"), Callable(self, "_restore_base_actor")
	)
	if success:
		for entity_id in world_registry.list_ids():
			var saved_actor: Node = world_registry.get_entity(entity_id)
			var is_created: bool = entity_id.begins_with("arcane_") or (saved_actor != null and saved_actor.has_meta("copy_origin"))
			if is_created and not save_service.last_restored_ids.has(entity_id):
				var removed: Node = world_registry.get_entity(entity_id)
				if removed != null:
					entity_lifecycle.unload_entity(entity_id)
		_sync_luna_relationships()
		# Restores do not count as player hacks, nor do pre-load queued events.
		command_processor.clear_history()
		event_bus.clear_pending()
		for entity_id in world_registry.list_ids():
			var node: Node = world_registry.get_entity(entity_id)
			if node != null and node.has_method("reset_after_load"):
				node.call("reset_after_load")
		_autosave_elapsed = 0.0
	if not automatic or not success:
		_show_checkpoint_message(ui_language.text("WORLD LOADED", "МИР ЗАГРУЖЕН") if success else ui_language.text("LOAD ERROR: %s", "ОШИБКА ЗАГРУЗКИ: %s") % save_service.last_error)


func _show_checkpoint_message(message: String) -> void:
	if not is_instance_valid(save_status_label):
		return
	save_status_label.text = ui_language.translated(message)
	_save_message_seconds = 3.0


func _toggle_journal() -> void:
	if not is_instance_valid(journal_panel):
		return
	journal_panel.visible = not journal_panel.visible
	if journal_panel.visible:
		_refresh_journal()


func _refresh_journal() -> void:
	if not is_instance_valid(journal_label):
		return
	var lines := PackedStringArray()
	lines.append(ui_language.text("What have I figured out so far?", "Что я уже успела исследовать:"))
	var categories: Array[String] = profile_service.list_categories()
	if categories.is_empty():
		lines.append(ui_language.text("Nothing yet. Rude.", "Пока ничего. Даже обидно."))
	for category in categories:
		lines.append("")
		lines.append("• %s" % category.to_upper())
		var fields: Array[String] = profile_service.list_parameters(category)
		if fields.is_empty():
			lines.append(ui_language.text("  Looked, but didn't touch.", "  Смотрела, но пока не трогала."))
		else:
			for parameter_id in fields:
				lines.append("  — %s" % parameter_id.to_upper())
	journal_label.text = "\n".join(lines)


func _update_spell_hint() -> void:
	if not is_instance_valid(spell_hint_label) or spell_service == null:
		return
	var spell: Dictionary = spell_service.get_spell(selected_spell_id)
	spell_hint_label.text = ui_language.text("WAND: %s  |  SHIFT+LMB TO CAST", "ПАЛОЧКА: %s  |  Shift+ЛКМ по объекту") % ui_language.translated(str(spell.get("label", selected_spell_id)))


func _open_workshop() -> void:
	if not is_instance_valid(spell_workshop_panel) or (is_instance_valid(editor) and editor.visible):
		return
	if is_instance_valid(journal_panel):
		journal_panel.visible = false
	pause_tint.visible = true
	spell_workshop_panel.show_workshop(selected_spell_id)
	get_tree().paused = true


func _close_workshop() -> void:
	if not is_instance_valid(spell_workshop_panel):
		return
	spell_workshop_panel.visible = false
	if not (is_instance_valid(editor) and editor.visible):
		pause_tint.visible = false
		get_tree().paused = false


func _on_custom_spell_created(spell_id: String) -> void:
	selected_spell_id = spell_id
	_update_spell_hint()
	_close_workshop()
	_show_checkpoint_message(ui_language.text("DONE: %s. TRY SHIFT+LMB!", "ГОТОВО: %s. ПРОБУЙ Shift+ЛКМ!") % spell_id)


func _select_next_spell() -> void:
	var ids: Array[String] = spell_service.list_spell_ids()
	if ids.is_empty():
		return
	var index: int = ids.find(selected_spell_id)
	selected_spell_id = ids[(index + 1) % ids.size()]
	_update_spell_hint()



func _spawn_arcane_projectile(details: Dictionary) -> void:
	var caster: Node = world_registry.get_entity(str(details["caster_id"]))
	var target: Node = world_registry.get_entity(str(details["target_id"]))
	if not (caster is Node3D) or not (target is Node3D):
		return
	var projectile := ArcaneProjectile.new()
	add_child(projectile)
	projectile.configure(
		details["manifestation"], caster as Node3D, target as Node3D,
		str(details["spell_id"]), str(details["caster_id"]), str(details["target_id"])
	)
	projectile.struck.connect(_on_arcane_impact)


func _on_chain_resolved(details: Dictionary) -> void:
	for segment in details.get("links", []):
		var from_actor: Node = world_registry.get_entity(str(segment["from_id"]))
		var to_actor: Node = world_registry.get_entity(str(segment["to_id"]))
		if not (from_actor is Node3D) or not (to_actor is Node3D):
			continue
		var link := ArcaneLink.new()
		add_child(link)
		link.configure(
			(from_actor as Node3D).global_position + Vector3.UP * 1.3,
			(to_actor as Node3D).global_position + Vector3.UP * 1.3
		)


func _on_arcane_impact(spell_id: String, caster_id: String, target_id: String) -> void:
	if not spell_service.resolve_impact(spell_id, caster_id, target_id):
		_show_checkpoint_message(spell_service.last_error)
		return
	var spell: Dictionary = spell_service.get_spell(spell_id)
	var recipe: Dictionary = spell.get("manifestation", {})
	if str(recipe.get("create", "ENERGY")) != "ENERGY":
		_create_arcane_entity(recipe, target_id)


func _on_elemental_state_changed(entity_id: String, active: Dictionary) -> void:
	var entity: Node = world_registry.get_entity(entity_id)
	if entity != null and entity.has_method("show_elemental_statuses"):
		entity.call("show_elemental_statuses", active)


func _on_fire_spread(_details: Dictionary) -> void:
	_show_checkpoint_message("Огонь перекинулся!")


func _on_surface_fields_changed(fields: Array) -> void:
	# Visuals are regenerated from saved field data. No independent timers.
	for visual in environment_visuals:
		if is_instance_valid(visual):
			visual.queue_free()
	environment_visuals.clear()
	for field in fields:
		var kind: String = str(field["kind"])
		if kind not in ["ICE", "STEAM"]:
			continue
		var instance := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = float(field["radius"])
		mesh.bottom_radius = float(field["radius"])
		mesh.height = 0.045 if kind == "ICE" else 1.6
		mesh.radial_segments = 24
		instance.mesh = mesh
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.52, 0.88, 1.0, 0.36) if kind == "ICE" else Color(0.84, 0.89, 0.92, 0.22)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		instance.material_override = mat
		var origin: Vector3 = field["center"]
		instance.position = Vector3(origin.x, 0.06 if kind == "ICE" else 0.85, origin.z)
		add_child(instance)
		environment_visuals.append(instance)


func _on_elemental_reaction(details: Dictionary) -> void:
	var names := {
		"STEAM": "ПШШ! Пар!",
		"QUENCH": "Потушили!",
		"FREEZE": "Ледышка! Буквально.",
		"THAW": "Пшш! Лёд растаял.",
		"SUPERCONDUCT": "Сверхразряд!",
		"OVERLOAD": "Искры и огонь!"
	}
	_show_checkpoint_message(str(names.get(str(details["reaction"]), "Магия реагирует.")))


func _on_arcane_place(details: Dictionary) -> void:
	_create_arcane_entity(details["manifestation"], str(details["target_id"]))


func _create_arcane_entity(recipe: Dictionary, target_id: String) -> Node:
	var target: Node = world_registry.get_entity(target_id)
	if not (target is Node3D):
		return null
	var location: Vector3 = (target as Node3D).global_position + Vector3(1.6, 0.0, 0.7)
	location.y = 0.1
	arcane_serial += 1
	var id: String = "arcane_%04d" % arcane_serial
	while world_registry.get_entity(id) != null:
		arcane_serial += 1
		id = "arcane_%04d" % arcane_serial
	return _spawn_arcane_actor_with_id(id, recipe, location)


func _restore_arcane_actor(entity_id: String, recipe: Dictionary, location: Vector3) -> Node:
	return _spawn_arcane_actor_with_id(entity_id, recipe, location)


func _spawn_arcane_actor_with_id(entity_id: String, recipe: Dictionary, location: Vector3) -> Node:
	var constructed: Dictionary = ArcaneGrammar.normalize(recipe)
	if not ArcaneGrammar.valid(constructed) or constructed.is_empty():
		return null
	if world_registry.get_entity(entity_id) != null:
		return null
	var generated_count := 0
	for world_id in world_registry.list_ids():
		if world_id.begins_with("arcane_"):
			generated_count += 1
	if generated_count >= MAX_ARCANE_ENTITIES:
		_show_checkpoint_message(ui_language.text("Too much magic. Even for me.", "Магии слишком много. Даже для меня."))
		return null
	var create_kind: String = str(constructed["create"])
	var entity := HackableEntity.new()
	add_child(entity)
	entity.configure(
		entity_id, "arcane_" + create_kind.to_lower(), location,
		parameter_registry, world_registry, relationship_service, constructed,
		elemental_status_service, social_awareness
	)
	if not world_registry.register_entity(entity_id, entity, create_kind):
		entity.queue_free()
		return null
	entity.target_acquired.connect(_on_target_acquired)
	if entity_id.begins_with("arcane_"):
		arcane_serial = maxi(arcane_serial, entity_id.substr(7).to_int())
	return entity
