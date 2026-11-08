extends CharacterBody2D
## Canonical EntityRecord + live 2D locomotion. Presentation stays a child.
const EntityRecord = preload("res://scripts/core/entity_record.gd")
const CreatureVisual = preload("res://scripts/2d/creature_visual_2d.gd")
signal parameter_changed(key: String, value: Variant)
var record
var visual: Node2D
var player: CharacterBody2D
var world
var home := Vector2.ZERO
var destination := Vector2.ZERO
var wander_timer := 0.0
var wait_timer := 0.0
var last_alive := false
var visual_species := ""

func setup(id: String, category: String, label: String, registry, overrides: Dictionary) -> void:
	record = EntityRecord.new(id, category, label, registry, overrides)
	home = position
	destination = position
	last_alive = bool(record.get_parameter("alive"))
	visual_species = _species_for(id, category)
	visual = CreatureVisual.new()
	visual.configure(visual_species)
	add_child(visual)
	_refresh_size()

func set_context(controlled_player: CharacterBody2D, environment) -> void:
	player = controlled_player
	world = environment

func _species_for(id: String, category: String) -> String:
	if id.begins_with("sheep"):
		return "sheep"
	if id.begins_with("duck"):
		return "duck"
	if id.begins_with("slime"):
		return "slime"
	if category == "fridge":
		return "fridge"
	if category == "tree":
		return "tree"
	return "slime"

func get_parameter(key: String) -> Variant:
	return record.get_parameter(key)

func set_parameter(key: String, value: Variant) -> bool:
	if not record.set_parameter(key, value):
		return false
	_refresh_size()
	if is_instance_valid(visual) and key in ["alive", "behavior_mode", "color", "size"]:
		visual.react("surprised")
	parameter_changed.emit(key, record.get_parameter(key))
	return true

func _refresh_size() -> void:
	if record != null:
		scale = Vector2.ONE * float(record.get_parameter("size"))

func _target_location() -> Vector2:
	if not is_instance_valid(player):
		return home
	var target_group := str(get_parameter("target_group"))
	if target_group == "LUNA" or target_group == "ANY":
		return player.global_position
	if world != null:
		var nearest := INF
		var where := player.global_position
		for entity_id in world.list_ids():
			var entity: Node = world.get_entity(entity_id)
			if not is_instance_valid(entity) or entity == self:
				continue
			if target_group == "TREE" and str(entity.record.category) != "tree":
				continue
			if target_group == "FRIDGE" and str(entity.record.category) != "fridge":
				continue
			var distance: float = global_position.distance_squared_to(entity.global_position)
			if distance < nearest:
				nearest = distance
				where = entity.global_position
		return where
	return player.global_position

func _physics_process(delta: float) -> void:
	if record == null:
		return
	var alive := bool(get_parameter("alive"))
	if alive != last_alive:
		last_alive = alive
		wander_timer = 0.0
	if not alive or not bool(get_parameter("ai_enabled")):
		velocity = Vector2.ZERO
		return
	var mode := str(get_parameter("behavior_mode"))
	var relation := str(get_parameter("luna_relation"))
	if mode == "AUTO":
		mode = "FLEE" if relation == "AFRAID" else ("CHASE" if relation == "HOSTILE" else ("FOLLOW" if relation == "FRIEND" else "WANDER"))
	var speed := float(get_parameter("speed")) * 32.0
	if mode == "IDLE" or speed <= 0.01:
		velocity = Vector2.ZERO
		return
	if mode == "WANDER":
		if wait_timer > 0.0:
			wait_timer -= delta
			velocity = Vector2.ZERO
			return
		wander_timer -= delta
		if wander_timer <= 0.0 or global_position.distance_to(destination) < 12.0:
			wander_timer = randf_range(1.2, 2.8)
			wait_timer = randf_range(0.3, 1.2)
			destination = home + Vector2(randf_range(-105.0, 105.0),randf_range(-75.0,75.0))
	else:
		var target := _target_location()
		var gap := global_position.distance_to(target)
		var threshold := float(get_parameter("follow_distance")) * 32.0
		if mode in ["FOLLOW", "CHASE"]:
			if gap < (threshold if mode == "FOLLOW" else 25.0):
				velocity = Vector2.ZERO
				return
			destination = target
		elif mode == "FLEE":
			if gap > float(get_parameter("sense_range")) * 32.0:
				velocity = Vector2.ZERO
				return
			destination = global_position + (global_position - target).normalized() * 145.0
	var step := destination - global_position
	velocity = Vector2.ZERO if step.length_squared() < 9.0 else step.normalized() * speed
	move_and_slide()
	# Prototype world bounds: keep entities on the playable meadow.
	global_position = global_position.clamp(Vector2(52, 100), Vector2(1410, 712))
