extends CharacterBody3D
## First hackable entity implementation. The base category never changes on awakening.

const EntityRecord = preload("res://scripts/core/entity_record.gd")
const GRAVITY := 18.0

var record
var visual_root: Node3D
var primary_part: MeshInstance3D
var legs: Array[MeshInstance3D] = []
var walk_direction := Vector3.ZERO
var wander_timer := 0.0
var age := 0.0
var rng := RandomNumberGenerator.new()


func configure(entity_id: String, entity_type: String, start_position: Vector3) -> void:
	name = entity_id
	position = start_position
	collision_layer = 2
	collision_mask = 1
	rng.randomize()
	var is_tree := entity_type == "tree"
	var base_color := Color("b790dd") if is_tree else Color("87bfe8")
	var label := "Дерево" if is_tree else "Холодильник"
	record = EntityRecord.new(entity_id, entity_type, label, {
		"color": base_color,
		"size": 1.0,
		"alive": false,
		"speed": 1.3 if is_tree else 2.6,
		"health": 65 if is_tree else 100
	})

	var collider := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.6, 2.6, 1.6) if is_tree else Vector3(1.15, 1.8, 1.0)
	collider.shape = box
	collider.position.y = box.size.y * 0.5
	add_child(collider)

	visual_root = Node3D.new()
	visual_root.name = "Appearance"
	add_child(visual_root)
	if is_tree:
		_build_tree()
	else:
		_build_fridge()

	# The legs belong to the appearance, not the definition of life itself.
	for x in [-0.3, 0.3]:
		var leg := _make_box(Vector3(0.18, 0.46, 0.19), Vector3(x, 0.23, 0.0), Color("56456e"))
		leg.visible = false
		legs.append(leg)


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
			wander_timer = 0.0
			walk_direction = Vector3.ZERO
	return true


func _physics_process(delta: float) -> void:
	age += delta
	if bool(record.get_parameter("alive")):
		wander_timer -= delta
		if wander_timer <= 0.0:
			wander_timer = rng.randf_range(1.0, 2.5)
			walk_direction = Vector3(rng.randf_range(-1.0, 1.0), 0, rng.randf_range(-1.0, 1.0)).normalized()
			if rng.randf() < 0.15:
				walk_direction = Vector3.ZERO
		if absf(global_position.x) > 8.5:
			walk_direction.x = -signf(global_position.x)
		if absf(global_position.z) > 8.5:
			walk_direction.z = -signf(global_position.z)
		velocity.x = walk_direction.x * float(record.get_parameter("speed"))
		velocity.z = walk_direction.z * float(record.get_parameter("speed"))
		for i in range(legs.size()):
			legs[i].rotation.x = sin(age * 10.0 + float(i) * PI) * 0.45 if walk_direction.length_squared() > 0.01 else 0.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, delta * 8.0)
		velocity.z = move_toward(velocity.z, 0.0, delta * 8.0)
	velocity.y -= GRAVITY * delta
	move_and_slide()


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
