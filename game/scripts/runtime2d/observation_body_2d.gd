extends StaticBody2D
## Opt-in physical response to the already-existing gaze/camera laws.
## Generic world object: no authored bridge, door or level is hardcoded.
## A rule can be attached to any surface created by the level author.

const ALWAYS := "ALWAYS"
const WHEN_UNOBSERVED := "WHEN_UNOBSERVED"
const WHEN_OBSERVED := "WHEN_OBSERVED"
const LUNA := "LUNA"
const CAMERA := "CAMERA"

@export_enum("ALWAYS", "WHEN_UNOBSERVED", "WHEN_OBSERVED") var solidity_rule := ALWAYS
@export_enum("LUNA", "CAMERA") var observer_source := LUNA
@export var starts_invisible := true
@export var invisible_to_luna := false
@export var physical_size := Vector2(80, 20)

var is_solid := true


func _ready() -> void:
	add_to_group("runtime2d_observation_law")
	collision_mask = 0
	var footprint := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = physical_size
	footprint.shape = shape
	add_child(footprint)
	visible = not starts_invisible
	apply_observation({"luna_eyes": false, "player_camera": false})


func apply_observation(state: Dictionary) -> void:
	var seen: bool = bool(state.get("player_camera" if observer_source == CAMERA else "luna_eyes", false))
	var desired: bool = true
	if solidity_rule == WHEN_UNOBSERVED:
		desired = not seen
	elif solidity_rule == WHEN_OBSERVED:
		desired = seen
	is_solid = desired
	# Collision changes are deferred: safe even during physics flushing.
	set_deferred("collision_layer", 1 if desired else 0)
