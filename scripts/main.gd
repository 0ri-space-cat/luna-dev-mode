extends Node3D
## LUNA: DEV MODE — first playable graybox, deliberately without final art.

const PlayerController = preload("res://scripts/player_controller.gd")
const HackableEntity = preload("res://scripts/hackable_entity.gd")
const HackEditor = preload("res://scripts/hack_editor.gd")
const ParameterRegistry = preload("res://scripts/core/parameter_registry.gd")
const CommandProcessor = preload("res://scripts/core/command_processor.gd")
const WorldRegistry = preload("res://scripts/core/world_registry.gd")
const EventBus = preload("res://scripts/core/event_bus.gd")
const EffectEngine = preload("res://scripts/core/effect_engine.gd")
const RuleEngine = preload("res://scripts/core/rule_engine.gd")

var luna: CharacterBody3D
var camera: Camera3D
var editor
var pause_tint: ColorRect
var pending_selection := Vector2(-1, -1)
var parameter_registry
var command_processor
var world_registry
var event_bus
var effect_engine
var rule_engine


func _ready() -> void:
	parameter_registry = ParameterRegistry.new()
	command_processor = CommandProcessor.new()
	world_registry = WorldRegistry.new()
	event_bus = EventBus.new()
	effect_engine = EffectEngine.new(world_registry, command_processor)
	rule_engine = RuleEngine.new(effect_engine)
	command_processor.parameter_changed.connect(_on_parameter_changed)
	_register_controls()
	_build_environment()
	_build_ground()
	_spawn_player()
	_spawn_entities()
	_register_example_rules()
	_build_interface()


func _process(_delta: float) -> void:
	# Keep an orthographic game view that reads like a 2D cartoon.
	if is_instance_valid(luna):
		camera.global_position = luna.global_position + Vector3(0, 14, 13)
		camera.look_at(luna.global_position + Vector3(0, 0.65, 0))


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		pending_selection = event.position


func _physics_process(_delta: float) -> void:
	# Reactive events are delivered in a bounded batch, never recursively.
	event_bus.drain(rule_engine)
	# Physics queries are intentionally performed in a physics tick, not in input callbacks.
	if pending_selection != Vector2(-1, -1):
		var mouse_position := pending_selection
		pending_selection = Vector2(-1, -1)
		_try_select(mouse_position)


func _exit_tree() -> void:
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
	luna.position = Vector3(0, 0.1, 3.3)
	add_child(luna)
	world_registry.register_entity("luna", luna, "LUNA")


func _spawn_entities() -> void:
	_spawn("tree_001", "tree", Vector3(-3.2, 0.1, -1.0))
	_spawn("tree_002", "tree", Vector3(4.5, 0.1, -3.0))
	_spawn("fridge_001", "fridge", Vector3(2.0, 0.1, -1.3))


func _spawn(entity_id: String, category: String, where: Vector3) -> void:
	var entity := HackableEntity.new()
	add_child(entity)
	entity.configure(entity_id, category, where, parameter_registry, world_registry)
	world_registry.register_entity(entity_id, entity, category.to_upper())
	entity.target_acquired.connect(_on_target_acquired)


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


func _on_parameter_changed(change: Dictionary) -> void:
	# Undo/redo restores prior state without launching gameplay rules again.
	if str(change.get("action", "")) != "SET":
		return
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


func _build_interface() -> void:
	var layer := CanvasLayer.new()
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
	header.text = "LUNA: DEV MODE   ✦   ПРОТОТИП 0.4"
	header.position = Vector2(24, 16)
	header.add_theme_font_size_override("font_size", 22)
	header.add_theme_color_override("font_color", Color("efe2ff"))
	layer.add_child(header)

	var instructions := Label.new()
	instructions.text = "WASD / стрелки — ходить    •    ЛКМ на дереве или холодильнике — взломать    •    Esc — закрыть    •    Cmd/Ctrl+Z — отменить"
	instructions.position = Vector2(24, 50)
	instructions.add_theme_font_size_override("font_size", 15)
	instructions.add_theme_color_override("font_color", Color("e0f7f4"))
	layer.add_child(instructions)

	var bottom := Label.new()
	bottom.text = "Попробуй: FRIDGE → IS_ALIVE TRUE → BEHAVIOR_MODE CHASE → TARGET_GROUP TREE"
	bottom.position = Vector2(24, 750)
	bottom.add_theme_color_override("font_color", Color("f7e2f4"))
	bottom.add_theme_font_size_override("font_size", 16)
	layer.add_child(bottom)

	editor = HackEditor.new()
	layer.add_child(editor)
	editor.configure(parameter_registry, command_processor)
	editor.closed.connect(_close_editor)


func _try_select(mouse_position: Vector2) -> void:
	var from := camera.project_ray_origin(mouse_position)
	var to := from + camera.project_ray_normal(mouse_position) * 150.0
	var query := PhysicsRayQueryParameters3D.create(from, to, 2)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return
	var entity: Object = hit.get("collider")
	if entity == null or not entity.has_method("get_parameter"):
		return
	_open_editor(entity as Node3D)


func _open_editor(entity: Node3D) -> void:
	pause_tint.visible = true
	editor.show_for(entity)
	get_tree().paused = true


func _close_editor() -> void:
	editor.visible = false
	pause_tint.visible = false
	get_tree().paused = false
