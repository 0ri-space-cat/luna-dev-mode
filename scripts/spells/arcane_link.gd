extends Node3D
## Short-lived glowing segment for any chained magic. No external art assets.
var lifetime := 0.24


func configure(start: Vector3, finish: Vector3) -> void:
	var direction: Vector3 = finish - start
	if direction.length_squared() < 0.0001:
		queue_free()
		return
	global_position = (start + finish) * 0.5
	quaternion = Quaternion(Vector3.UP, direction.normalized())
	var beam := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.055
	mesh.bottom_radius = 0.055
	mesh.height = direction.length()
	mesh.radial_segments = 5
	beam.mesh = mesh
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color("f5e6a0")
	material.emission_enabled = true
	material.emission = Color("e6d77a")
	material.emission_energy_multiplier = 4.0
	beam.material_override = material
	add_child(beam)


func _process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
