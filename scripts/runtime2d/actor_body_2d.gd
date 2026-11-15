extends CharacterBody2D
## Physics/identity adapter. Art is an independently replaceable scene under
## VisualAnchor, not a bake of the entity or its collision footprint.

const EntityRecord = preload("res://scripts/core/entity_record.gd")

var record
var player_controlled := false
var art_anchor: Node2D
var _collision: CollisionShape2D
var _debug_marker := true
var _external_motion := false
var _requested_direction := Vector2.ZERO
var _wander_timer := 0.0
var _wander_heading := Vector2.RIGHT


func configure(entity_id: String, category: String, label: String, registry, player: bool = false) -> bool:
	if entity_id.is_empty() or not entity_id.is_valid_identifier():
		return false
	record = EntityRecord.new(entity_id, category, label, registry)
	player_controlled = player
	return true


func _ready() -> void:
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


func attach_visual(scene: PackedScene) -> bool:
	if not is_node_ready():
		return false
	for item in art_anchor.get_children():
		art_anchor.remove_child(item)
		item.queue_free()
	if scene != null:
		var visual: Node = scene.instantiate()
		if not (visual is Node2D):
			visual.free()
			return false
		art_anchor.add_child(visual)
	_debug_marker = scene == null
	queue_redraw()
	return true


func get_parameter(key: String) -> Variant:
	if record == null:
		return null
	return record.get_parameter(key)


func set_parameter(key: String, value: Variant) -> bool:
	if record == null or not record.set_parameter(key, value):
		return false
	if key == "size" or key == "color":
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
	var movement := Vector2.ZERO
	if player_controlled:
		movement = _requested_direction if _external_motion else _read_input()
	elif bool(get_parameter("alive")) and bool(get_parameter("ai_enabled")):
		if str(get_parameter("behavior_mode")) != "IDLE":
			_wander_timer -= delta
			if _wander_timer <= 0.0:
				_wander_timer = 1.7
				_wander_heading = _wander_heading.rotated(1.27)
			movement = _wander_heading
	var speed_px: float = float(get_parameter("speed")) * 80.0
	velocity = movement.normalized() * speed_px if movement.length_squared() > 0.0 else Vector2.ZERO
	move_and_slide()
	if get_slide_collision_count() > 0 and not player_controlled:
		_wander_heading = -_wander_heading
		_wander_timer = 1.7


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
	queue_redraw()


func _draw() -> void:
	if not _debug_marker or record == null:
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
	if absf(float(coord[0])) > 100000.0 or absf(float(coord[1])) > 100000.0:
		return false
	if not configure(identifier, str(data.get("category", "")), str(data.get("label", "")),
			registry, bool(data.get("player", false))):
		return false
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
	position = Vector2(float(coord[0]), float(coord[1]))
	if is_node_ready():
		_sync_visual()
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
