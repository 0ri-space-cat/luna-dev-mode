extends SceneTree

const Rules = preload("res://scripts/core/observation_rules.gd")
const Surface = preload("res://scripts/world/observation_surface_3d.gd")

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var bridge := Surface.new()
	bridge.base_visible = false
	var collider := CollisionShape3D.new()
	collider.shape = BoxShape3D.new()
	bridge.add_child(collider)
	root.add_child(bridge)
	bridge.update_observation(true, false, true)
	await physics_frame
	assert(not bridge.visible)
	assert(_hits_bridge(bridge))

	bridge.solidity_law = Rules.SolidityLaw.UNSEEN_BY_LUNA
	bridge.update_observation(true, false, true)
	await physics_frame
	assert(not _hits_bridge(bridge))
	bridge.update_observation(true, true, true)
	await physics_frame
	assert(_hits_bridge(bridge))

	bridge.solidity_law = Rules.SolidityLaw.UNSEEN_BY_PLAYER
	bridge.update_observation(true, true, true)
	await physics_frame
	assert(not _hits_bridge(bridge))
	assert(not Rules.allows_transition(true, true))
	bridge.update_observation(true, false, false)
	await physics_frame
	assert(_hits_bridge(bridge))
	assert(Rules.allows_transition(true, false))

	bridge.solidity_law = Rules.SolidityLaw.EYES_OPEN
	bridge.update_observation(false, false, false)
	await physics_frame
	assert(_hits_bridge(bridge))
	bridge.update_observation(true, true, false)
	await physics_frame
	assert(not _hits_bridge(bridge))
	bridge.free()
	print("Observation: invisible solid surface, independent observers, door and transition passed")
	quit(0)


func _hits_bridge(bridge: StaticBody3D) -> bool:
	var query := PhysicsRayQueryParameters3D.create(Vector3(0, 2, 0), Vector3(0, -2, 0))
	return bridge.get_world_3d().direct_space_state.intersect_ray(query).get("collider") == bridge
