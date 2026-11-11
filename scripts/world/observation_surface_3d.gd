extends StaticBody3D
## Optional graybox adapter. Feed it sight state from the owning scene.

const Rules = preload("res://scripts/core/observation_rules.gd")

@export var base_visible := true
@export var base_solid := true
@export var solidity_law := Rules.SolidityLaw.ALWAYS
@export_flags_3d_physics var solid_layer := 1


func update_observation(luna_has_sight: bool, eyes_closed: bool, player_observes: bool) -> void:
	var state := Rules.resolve(base_visible, base_solid, solidity_law,
		luna_has_sight, eyes_closed, player_observes)
	visible = state["visible"]
	# Deferred so a sensor signal can change solidity during a physics step.
	set_deferred("collision_layer", solid_layer if state["solid"] else 0)
