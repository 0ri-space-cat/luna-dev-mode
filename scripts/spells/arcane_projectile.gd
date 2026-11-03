extends Node3D
## Visual projectile with a fixed target ID. Its impact is routed back into
## SpellService -> EffectEngine. Simple homing flight; world collisions later.

signal struck(spell_id: String, caster_id: String, target_id: String)
signal faded()

const ArcaneGrammar = preload("res://scripts/core/arcane_grammar.gd")

var spell_id := ""
var caster_id := ""
var target_id := ""
var destination_ref: WeakRef
var flight_speed := 14.0
var lifetime := 3.5
var age := 0.0


func configure(recipe: Dictionary, origin: Node3D, target: Node3D, spell: String, caster: String, target_entity: String) -> void:
	spell_id = spell
	caster_id = caster
	target_id = target_entity
	destination_ref = weakref(target)
	flight_speed = float(recipe["speed"])
	position = origin.global_position + Vector3(0, 1.2, 0)
	var size: float = float(recipe["size"])
	var tint: Color = ArcaneGrammar.tint(str(recipe["essence"]))
	var core := MeshInstance3D.new()
	var shape: String = str(recipe["form"])
	if shape == "SHARD":
		var crystal := CylinderMesh.new()
		crystal.top_radius = 0.0
		crystal.bottom_radius = size * 0.65
		crystal.height = size * 2.3
		crystal.radial_segments = 5
		core.mesh = crystal
	elif shape == "BOLT":
		var bolt := CapsuleMesh.new()
		bolt.radius = size * 0.55
		bolt.height = size * 2.6
		core.mesh = bolt
	else:
		var orb := SphereMesh.new()
		orb.radius = size
		orb.height = size * 2.0
		core.mesh = orb
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.emission_enabled = true
	material.emission = tint
	material.emission_energy_multiplier = 2.4
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	core.material_override = material
	add_child(core)
	var aura := MeshInstance3D.new()
	var aura_mesh := SphereMesh.new()
	aura_mesh.radius = size * 1.45
	aura_mesh.height = size * 2.9
	aura.mesh = aura_mesh
	var glow := StandardMaterial3D.new()
	glow.albedo_color = Color(tint.r, tint.g, tint.b, 0.22)
	glow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	aura.material_override = glow
	add_child(aura)


func _physics_process(delta: float) -> void:
	age += delta
	if age >= lifetime:
		faded.emit()
		queue_free()
		return
	if destination_ref == null:
		faded.emit()
		queue_free()
		return
	var target: Object = destination_ref.get_ref()
	if not is_instance_valid(target) or not (target is Node3D):
		faded.emit()
		queue_free()
		return
	var goal: Vector3 = (target as Node3D).global_position + Vector3(0, 1.2, 0)
	var distance := global_position.distance_to(goal)
	if distance <= flight_speed * delta + 0.25:
		struck.emit(spell_id, caster_id, target_id)
		queue_free()
		return
	global_position = global_position.move_toward(goal, flight_speed * delta)
	rotate_y(delta * 9.0)
