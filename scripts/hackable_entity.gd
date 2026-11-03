extends CharacterBody3D

signal target_acquired(source_id: String, target_id: String, target_group: String)
## First hackable entity implementation. The base category never changes on awakening.

const EntityRecord = preload("res://scripts/core/entity_record.gd")
const BehaviorBrain = preload("res://scripts/systems/behavior_brain.gd")
const ArcaneGrammar = preload("res://scripts/core/arcane_grammar.gd")
const GRAVITY := 18.0

var record
var visual_root: Node3D
var primary_part: MeshInstance3D
var legs: Array[MeshInstance3D] = []
var brain = BehaviorBrain.new()
var world_registry
var relationship_service
var elemental_statuses
var elemental_label: Label3D
var arcane_manifestation: Dictionary = {}
var age := 0.0
var _previous_engaged_target := ""


func configure(entity_id: String, entity_type: String, start_position: Vector3, parameter_registry, registry_of_world = null, relations = null, arcane_recipe: Dictionary = {}, status_service = null) -> void:
	name = entity_id
	position = start_position
	collision_layer = 2
	collision_mask = 1
	world_registry = registry_of_world
	relationship_service = relations
	elemental_statuses = status_service
	arcane_manifestation = ArcaneGrammar.normalize(arcane_recipe)
	var is_tree := entity_type == "tree"
	var is_arcane: bool = not arcane_manifestation.is_empty()
	var base_color: Color = ArcaneGrammar.tint(str(arcane_manifestation["element"])) if is_arcane else (Color("b790dd") if is_tree else Color("87bfe8"))
	var label := "Магическое существо" if entity_type == "arcane_creature" else ("Магический предмет" if entity_type == "arcane_object" else ("Магическая энергия" if entity_type == "arcane_energy" else ("Дерево" if is_tree else "Холодильник")))
	record = EntityRecord.new(entity_id, entity_type, label, parameter_registry, {
		"color": base_color,
		"size": 1.0,
		"alive": false,
		"ai_enabled": true,
		"behavior_mode": "WANDER",
		"target_group": "LUNA",
		"luna_relation": "NEUTRAL",
		"sense_range": 12.0,
		"follow_distance": 2.0,
		"speed": 1.3 if is_tree else 2.6,
		"health": 65 if is_tree else 100
	})

	var collider := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.9, 1.3, 0.9) if is_arcane else (Vector3(1.6, 2.6, 1.6) if is_tree else Vector3(1.15, 1.8, 1.0))
	collider.shape = box
	collider.position.y = box.size.y * 0.5
	add_child(collider)

	visual_root = Node3D.new()
	visual_root.name = "Appearance"
	add_child(visual_root)
	if is_arcane:
		_build_arcane_shape()
	elif is_tree:
		_build_tree()
	else:
		_build_fridge()

	elemental_label = Label3D.new()
	elemental_label.position = Vector3(0.0, 3.1 if is_tree else 2.3, 0.0)
	elemental_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	elemental_label.font_size = 28
	elemental_label.pixel_size = 0.008
	elemental_label.visible = false
	add_child(elemental_label)

	# The legs belong to the appearance, not the definition of life itself.
	for x in [-0.3, 0.3]:
		var leg := _make_box(Vector3(0.18, 0.46, 0.19), Vector3(x, 0.23, 0.0), Color("56456e"))
		leg.visible = false
		legs.append(leg)
	if is_arcane:
		var behavior: String = str(arcane_manifestation["behavior"])
		var is_creature: bool = entity_type == "arcane_creature"
		var can_move: bool = is_creature or behavior in ["SEEK", "WANDER", "FOLLOW", "CHASE", "FLEE"]
		var brain_mode: String = "CHASE" if behavior == "SEEK" else ("IDLE" if behavior == "STRAIGHT" else behavior)
		set_parameter("alive", can_move)
		set_parameter("ai_enabled", can_move and brain_mode != "IDLE")
		set_parameter("behavior_mode", brain_mode)
		set_parameter("speed", 2.5 if is_creature else 1.8)




func show_elemental_statuses(active: Dictionary) -> void:
	if not is_instance_valid(elemental_label):
		return
	var names := PackedStringArray()
	for kind in ["BURN", "CHILL", "FROZEN", "SHOCK"]:
		if active.has(kind):
			names.append(kind)
	elemental_label.text = " / ".join(names)
	elemental_label.visible = not names.is_empty()
	if active.has("SHOCK"):
		elemental_label.modulate = Color("e6d77a")
	elif active.has("CHILL") or active.has("FROZEN"):
		elemental_label.modulate = Color("9edffa")
	else:
		elemental_label.modulate = Color("ff884a")


func get_parameter(key: String) -> Variant:
	return record.get_parameter(key)


func set_parameter(key: String, value: Variant) -> bool:
	if not record.set_parameter(key, value):
		return false
	match key:
		"color":
			var material := primary_part.material_override as StandardMaterial3D
			material.albedo_color = record.get_parameter("color")
		"size":
			scale = Vector3.ONE * float(record.get_parameter("size"))
		"alive":
			for leg in legs:
				leg.visible = bool(record.get_parameter("alive"))

	return true


func reset_after_load() -> void:
	# A restored object starts with a fresh steering state.
	brain = BehaviorBrain.new()
	_previous_engaged_target = ""
	velocity = Vector3.ZERO


func _physics_process(delta: float) -> void:
	age += delta
	var nearby: Array[Dictionary] = []
	if world_registry != null:
		nearby = world_registry.candidates(
			record.id,
			global_position,
			str(record.get_parameter("target_group")),
			float(record.get_parameter("sense_range"))
		)
	var effective_parameters: Dictionary = record.parameters
	if relationship_service != null and str(record.get_parameter("behavior_mode")) == "AUTO":
		var nearest_id := ""
		var nearest_distance := INF
		for candidate in nearby:
			var distance: float = global_position.distance_squared_to(candidate["position"])
			if distance < nearest_distance:
				nearest_distance = distance
				nearest_id = str(candidate["id"])
		if not nearest_id.is_empty():
			effective_parameters = record.parameters.duplicate()
			effective_parameters["target_relation"] = relationship_service.get_attitude(record.id, nearest_id)
	var wanted_velocity: Vector3 = brain.calculate(delta, global_position, effective_parameters, nearby)
	if elemental_statuses != null:
		wanted_velocity *= elemental_statuses.movement_factor(record.id)
	var engaged: String = brain.last_target_id if brain.last_decision in ["FOLLOW", "CHASE", "FLEE"] else ""
	if not engaged.is_empty() and engaged != _previous_engaged_target:
		var chosen_group := ""
		for candidate in nearby:
			if str(candidate["id"]) == engaged:
				chosen_group = str(candidate["group"])
				break
		target_acquired.emit(record.id, engaged, chosen_group)
	_previous_engaged_target = engaged
	# Acceleration and smooth heading are independent of the animation model.
	var acceleration := 9.0
	velocity.x = move_toward(velocity.x, wanted_velocity.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, wanted_velocity.z, acceleration * delta)
	velocity.y -= GRAVITY * delta
	move_and_slide()
	if is_on_wall():
		for i in range(get_slide_collision_count()):
			var hit := get_slide_collision(i)
			if absf(hit.get_normal().y) < 0.6:
				brain.turn_away_from_wall(hit.get_normal())
				break
	var speed_horizontal := Vector2(velocity.x, velocity.z).length()
	var walking: bool = speed_horizontal > 0.15 and brain.last_decision != "IDLE"
	for i in range(legs.size()):
		legs[i].rotation.x = sin(age * (5.5 + speed_horizontal * 2.0) + float(i) * PI) * 0.36 if walking else 0.0
	if speed_horizontal > 0.15:
		visual_root.rotation.y = lerp_angle(
			visual_root.rotation.y,
			atan2(-velocity.x, -velocity.z),
			minf(delta * 5.0, 1.0)
		)


func _build_arcane_shape() -> void:
	## Same generic actor for ENERGY, OBJECT and CREATURE. No scripts per spell.
	var shape: String = str(arcane_manifestation["shape"])
	var radius: float = float(arcane_manifestation["size"]) * 1.5
	var tint: Color = record.get_parameter("color")
	match shape:
		"ORB":
			primary_part = _make_sphere(radius, Vector3(0, 0.8, 0), tint)
		"SHARD":
			var crystal := CylinderMesh.new()
			crystal.top_radius = 0.0
			crystal.bottom_radius = radius * 0.72
			crystal.height = radius * 2.8
			crystal.radial_segments = 5
			primary_part = MeshInstance3D.new()
			primary_part.mesh = crystal
			primary_part.position = Vector3(0, 0.85, 0)
			primary_part.material_override = _material(tint)
			visual_root.add_child(primary_part)
		"BOLT":
			var bolt := CapsuleMesh.new()
			bolt.radius = radius * 0.58
			bolt.height = radius * 2.8
			primary_part = MeshInstance3D.new()
			primary_part.mesh = bolt
			primary_part.position = Vector3(0, 0.8, 0)
			primary_part.material_override = _material(tint)
			visual_root.add_child(primary_part)


func _build_tree() -> void:
	_make_cylinder(0.31, 1.5, Vector3(0, 1.0, 0), Color("745369"))
	primary_part = _make_sphere(1.0, Vector3(0, 2.08, 0), record.get_parameter("color"))
	_make_sphere(0.62, Vector3(-0.61, 1.86, 0.1), Color("cfa0e2"))
	_make_sphere(0.62, Vector3(0.60, 1.89, 0.1), Color("ac85d4"))
	_make_sphere(0.10, Vector3(-0.2, 1.05, -0.30), Color("292441"))
	_make_sphere(0.10, Vector3(0.2, 1.05, -0.30), Color("292441"))


func _build_fridge() -> void:
	primary_part = _make_box(Vector3(1.05, 1.60, 0.82), Vector3(0, 1.00, 0), record.get_parameter("color"))
	_make_box(Vector3(0.92, 0.05, 0.03), Vector3(0, 1.32, -0.43), Color("edf2fc"))
	_make_box(Vector3(0.07, 0.38, 0.05), Vector3(0.39, 0.91, -0.44), Color("dfe9f5"))
	_make_sphere(0.085, Vector3(-0.19, 1.52, -0.43), Color("332746"))
	_make_sphere(0.085, Vector3(0.19, 1.52, -0.43), Color("332746"))


func _material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 1.0
	return mat


func _make_box(dimensions: Vector3, where: Vector3, color: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = where
	node.material_override = _material(color)
	visual_root.add_child(node)
	return node


func _make_sphere(radius: float, where: Vector3, color: Color) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = where
	node.material_override = _material(color)
	visual_root.add_child(node)
	return node


func _make_cylinder(radius: float, height: float, where: Vector3, color: Color) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = where
	node.material_override = _material(color)
	visual_root.add_child(node)
	return node
