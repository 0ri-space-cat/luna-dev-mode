extends Node2D
## Generic authored-level slot. The plate contains no physics.
## Sheets/SAI geometry will later populate separate collision/occluder nodes.

const PlatePair = preload("res://scripts/runtime2d/plate_pair_2d.gd")

@export var level_size := Vector2(1536, 1024)
@export var ordinary_background: Texture2D
@export var underside_background: Texture2D

var plate
var collision_root: Node2D
var entity_mount: Node2D
var effects_mount: Node2D


func _ready() -> void:
	plate = PlatePair.new()
	plate.name = "RegisteredBackgroundPlates"
	plate.level_size = level_size
	plate.normal_plate = ordinary_background
	plate.underside_plate = underside_background
	add_child(plate)
	collision_root = Node2D.new()
	collision_root.name = "AuthoredCollision"
	add_child(collision_root)
	entity_mount = Node2D.new()
	entity_mount.name = "LocationEntities"
	entity_mount.y_sort_enabled = true
	add_child(entity_mount)
	effects_mount = Node2D.new()
	effects_mount.name = "AmbientEffects"
	add_child(effects_mount)


func set_underside(active: bool) -> void:
	plate.set_underside(active)


func set_background_pair(ordinary: Texture2D, hidden: Texture2D) -> bool:
	return plate.set_plates(ordinary, hidden)
