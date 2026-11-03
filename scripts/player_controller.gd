extends CharacterBody3D
## Placeholder for Luna: no external models required.

const WALK_SPEED := 7.5
const ACCELERATION := 42.0
const GRAVITY := 18.0

var visual_root: Node3D
var surface_service


func _ready() -> void:
	name = "Luna"
	collision_layer = 4
	collision_mask = 1
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.32
	capsule.height = 1.5
	var collision := CollisionShape3D.new()
	collision.shape = capsule
	collision.position.y = 0.75
	add_child(collision)

	visual_root = Node3D.new()
	visual_root.name = "PlaceholderAppearance"
	add_child(visual_root)
	_add_sphere(Vector3(0, 0.91, 0), 0.45, Color("f4c4ee"))
	_add_sphere(Vector3(0, 1.48, 0), 0.39, Color("f5d8ed"))
	_add_box(Vector3(0, 0.42, 0), Vector3(0.75, 0.82, 0.50), Color("8363b5"))
	_add_cylinder(Vector3(0, 1.82, 0), 0.59, 0.11, Color("553b88"))
	_add_cylinder(Vector3(0, 2.11, 0), 0.28, 0.55, Color("6649a7"))
	_add_sphere(Vector3(-0.13, 1.49, -0.32), 0.065, Color("342345"))
	_add_sphere(Vector3(0.13, 1.49, -0.32), 0.065, Color("342345"))
	_add_box(Vector3(0.39, 0.85, 0), Vector3(0.09, 0.8, 0.09), Color("e3c9ff"))


func _physics_process(delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var traction := surface_service.traction(global_position) if surface_service != null else 1.0
	velocity.x = move_toward(velocity.x, direction.x * WALK_SPEED, ACCELERATION * traction * delta)
	velocity.z = move_toward(velocity.z, direction.y * WALK_SPEED, ACCELERATION * traction * delta)
	velocity.y -= GRAVITY * delta
	move_and_slide()
	if direction.length_squared() > 0.01:
		visual_root.rotation.y = lerp_angle(visual_root.rotation.y, atan2(-direction.x, -direction.y), minf(delta * 10.0, 1.0))


func _material(color: Color) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = 1.0
	return result


func _add_sphere(where: Vector3, radius: float, color: Color) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = where
	node.material_override = _material(color)
	visual_root.add_child(node)


func _add_box(where: Vector3, dimensions: Vector3, color: Color) -> void:
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = where
	node.material_override = _material(color)
	visual_root.add_child(node)


func _add_cylinder(where: Vector3, radius: float, height: float, color: Color) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius * 1.15
	mesh.height = height
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = where
	node.material_override = _material(color)
	visual_root.add_child(node)
