extends CharacterBody2D
## Physics/identity adapter. Art is an independently replaceable scene under
## VisualAnchor, not a bake of the entity or its collision footprint.

const EntityRecord = preload("res://scripts/core/entity_record.gd")
const BehaviorBrain = preload("res://scripts/runtime2d/behavior_brain_2d.gd")
const PassiveAbilities = preload("res://scripts/runtime2d/passive_ability_runtime_2d.gd")
const LocalAvoidance = preload("res://scripts/runtime2d/local_avoidance_2d.gd")

signal passive_ability_applied(event_data: Dictionary)

var record
var player_controlled := false
var location_id := ""
var _visual_scene: PackedScene
var art_anchor: Node2D
var _collision: CollisionShape2D
var _debug_marker := true
var _external_motion := false
var _requested_direction := Vector2.ZERO
var world_registry
var time_clock
var navigation
var behavior = BehaviorBrain.new()
var avoidance = LocalAvoidance.new()
var passive_abilities = PassiveAbilities.new()
var _glow_light: PointLight2D


func configure(entity_id: String, category: String, label: String, registry, player: bool = false) -> bool:
	if entity_id.is_empty() or not entity_id.is_valid_identifier():
		return false
	record = EntityRecord.new(entity_id, category, label, registry, {"color": Color.WHITE})
	player_controlled = player
	return true


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	collision_layer = 2 # ACTOR
	collision_mask = 1 | 2 | 4 | 8 | 16 # WALL | ACTOR | LOW | SWIM | CLIMB
	_collision = CollisionShape2D.new()
	_collision.name = "PhysicalFootprint"
	var shape := CircleShape2D.new()
	shape.radius = 11.0
	_collision.shape = shape
	add_child(_collision)
	art_anchor = Node2D.new()
	art_anchor.name = "VisualAnchor"
	add_child(art_anchor)
	_sync_visual()
	refresh_capabilities()


func attach_visual(scene: PackedScene) -> bool:
	if not is_node_ready():
		return false
	# Validate the replacement BEFORE removing a currently displayed sprite.
	# A malformed asset delivered by another branch must not erase live art.
	var replacement: Node2D = null
	if scene != null:
		var instantiated: Node = scene.instantiate()
		if not (instantiated is Node2D):
			instantiated.free()
			return false
		replacement = instantiated as Node2D
	for item in art_anchor.get_children():
		art_anchor.remove_child(item)
		item.queue_free()
	if replacement != null:
		art_anchor.add_child(replacement)
	_visual_scene = scene
	_debug_marker = scene == null
	_sync_visual()
	queue_redraw()
	return true


func get_world_location_id() -> String:
	return location_id


func get_visual_scene() -> PackedScene:
	return _visual_scene


func has_ability(id: String) -> bool:
	if record == null or not record.has_component("ABILITY_SET"):
		return false
	return (record.get_component("ABILITY_SET").get("ids", []) as Array).has(id)


func refresh_capabilities() -> void:
	# FLY bypasses low/ground-only barriers, never true walls or other actors.
	var desired_mask := 1 | 2
	if not has_ability("FLY"):
		desired_mask |= 4
	if not has_ability("FLY") and not has_ability("SWIM"):
		desired_mask |= 8
	if not has_ability("FLY") and not has_ability("CLIMB"):
		desired_mask |= 16
	collision_mask = desired_mask
	if is_node_ready():
		_glow_light = PassiveAbilities.setup_light(self, _glow_light, has_ability("GLOW"))


func get_parameter(key: String) -> Variant:
	if record == null:
		return null
	return record.get_parameter(key)


func set_parameter(key: String, value: Variant) -> bool:
	if record == null or not record.set_parameter(key, value):
		return false
	if key in ["size", "color", "is_visible"]:
		_sync_visual()
	if key == "alive" or key == "ai_enabled":
		velocity = Vector2.ZERO
	return true


func set_external_drive(direction: Vector2) -> void:
	_external_motion = true
	_requested_direction = direction.limit_length()


func clear_external_drive() -> void:
	_external_motion = false


func _physics_process(delta: float) -> void:
	if record == null:
		return
	refresh_capabilities()
	var factor: float = time_clock.scale() if time_clock != null else 1.0
	var simulated_delta := delta * factor
	var restored: Dictionary = passive_abilities.advance(self, simulated_delta)
	if not restored.is_empty():
		passive_ability_applied.emit(restored)
	var movement := Vector2.ZERO
	if _external_motion:
		movement = _requested_direction
	elif player_controlled:
		movement = _read_input()
	elif bool(get_parameter("alive")) and bool(get_parameter("ai_enabled")):
		movement = behavior.direction_for(self, world_registry, simulated_delta)
		movement = avoidance.adjust(self, world_registry, movement, behavior.last_target_id, simulated_delta)
	var speed_px: float = float(get_parameter("speed")) * 80.0 * factor
	velocity = movement.normalized() * speed_px if movement.length_squared() > 0.0 else Vector2.ZERO
	move_and_slide()
	if get_slide_collision_count() > 0 and not player_controlled:
		behavior.avoid_obstacle()


func _read_input() -> Vector2:
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if Input.is_physical_key_pressed(KEY_A):
		direction.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		direction.x += 1.0
	if Input.is_physical_key_pressed(KEY_W):
		direction.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S):
		direction.y += 1.0
	return direction.limit_length()


func _sync_visual() -> void:
	if record == null:
		return
	var size: float = float(get_parameter("size"))
	if is_instance_valid(_collision) and _collision.shape != null:
		(_collision.shape as CircleShape2D).radius = 11.0 * size
	if is_instance_valid(art_anchor):
		art_anchor.scale = Vector2.ONE * size
		art_anchor.modulate = get_parameter("color") as Color
		art_anchor.visible = bool(record.parameters.get("is_visible", true))
	queue_redraw()


func _draw() -> void:
	if not _debug_marker or record == null or not bool(record.parameters.get("is_visible", true)):
		return
	# Neutral collision marker, not a temporary stick-limbed character.
	var color: Color = get_parameter("color") as Color
	var radius: float = 12.0 * float(get_parameter("size"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, -radius * 1.9), Vector2(radius, -radius),
		Vector2(radius, 0.0), Vector2(0.0, radius * 0.35),
		Vector2(-radius, 0.0), Vector2(-radius, -radius)
	]), color)


func snapshot() -> Dictionary:
	var encoded := {}
	for key in record.parameters:
		var value: Variant = record.parameters[key]
		encoded[key] = (value as Color).to_html() if value is Color else value
	return {
		"id": record.id, "category": record.category, "label": record.display_name,
		"location_id": location_id,
		"player": player_controlled, "position": [position.x, position.y],
		"parameters": encoded, "roles": record.get_stored_roles(),
		"tags": record.get_tags(), "components": record.get_components()
	}


func load_snapshot(data: Dictionary, registry) -> bool:
	var identifier := str(data.get("id", ""))
	var coord: Variant = data.get("position", [])
	var params: Variant = data.get("parameters", {})
	if not (coord is Array) or coord.size() != 2 or not (params is Dictionary):
		return false
	for value in coord:
		if typeof(value) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(value)):
			return false
	if absf(float(coord[0])) > 100000.0 or absf(float(coord[1])) > 100000.0:
		return false
	if not configure(identifier, str(data.get("category", "")), str(data.get("label", "")),
			registry, bool(data.get("player", false))):
		return false
	avoidance.reset()
	for key in params:
		var value: Variant = params[key]
		if str(key) == "color":
			if not (value is String) or not Color.html_is_valid(str(value)):
				return false
			value = Color(str(value))
		if not record.set_parameter(str(key), value):
			return false
	if not record.set_traits(data.get("roles", []), data.get("tags", [])):
		return false
	if not record.set_components(data.get("components", {})):
		return false
	location_id = str(data.get("location_id", ""))
	if not location_id.is_empty() and not location_id.is_valid_identifier():
		return false
	position = Vector2(float(coord[0]), float(coord[1]))
	if is_node_ready():
		_sync_visual()
		refresh_capabilities()
	return true


func clone_as(new_id: String, offset: Vector2 = Vector2(28, 0)) -> CharacterBody2D:
	var copy := get_script().new() as CharacterBody2D
	var info: Dictionary = snapshot()
	info["id"] = new_id
	info["player"] = false
	info["position"] = [position.x + offset.x, position.y + offset.y]
	if not copy.load_snapshot(info, record.registry):
		copy.free()
		return null
	return copy
