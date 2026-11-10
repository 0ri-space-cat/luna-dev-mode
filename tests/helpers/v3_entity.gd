extends Node3D
## Tiny record-backed actor used for data-first V3 mechanics tests.
## No 2D/3D rendering resources and no final scene dependencies.
const EntityRecord = preload("res://scripts/core/entity_record.gd")

var record = null


func configure(entity_id: String, category: String, registry, overrides: Dictionary = {}) -> void:
	name = entity_id
	record = EntityRecord.new(entity_id, category, entity_id, registry, overrides)


func get_parameter(key: String) -> Variant:
	return record.get_parameter(key)


func set_parameter(key: String, value: Variant) -> bool:
	return record.set_parameter(key, value)
