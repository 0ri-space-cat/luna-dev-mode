extends CharacterBody2D
const EntityRecord = preload("res://scripts/core/entity_record.gd")
var record
var home := Vector2.ZERO
var destination := Vector2.ZERO
var wander_timer := 0.0
func setup(id: String, category: String, label: String, registry, overrides: Dictionary) -> void:
 record = EntityRecord.new(id, category, label, registry, overrides)
 home = position
 destination = position
 queue_redraw()
func get_parameter(key: String) -> Variant:
 return record.get_parameter(key)
func set_parameter(key: String, value: Variant) -> bool:
 if not record.set_parameter(key, value):
  return false
 scale = Vector2.ONE * float(record.get_parameter("size"))
 queue_redraw()
 return true
func _physics_process(delta: float) -> void:
 if record == null or not bool(get_parameter("alive")) or not bool(get_parameter("ai_enabled")) or str(get_parameter("behavior_mode")) == "IDLE":
  velocity = Vector2.ZERO
  return
 wander_timer -= delta
 if wander_timer <= 0.0:
  wander_timer = randf_range(1.0, 3.0)
  destination = home + Vector2(randf_range(-90,90), randf_range(-60,60))
 velocity = global_position.direction_to(destination) * float(get_parameter("speed")) * 32.0 if global_position.distance_to(destination) > 8.0 else Vector2.ZERO
 move_and_slide()
func _draw() -> void:
 if record == null:
  return
 var c: Color = get_parameter("color")
 draw_ellipse_shadow()
 match record.category:
  "tree":
   draw_rect(Rect2(-8,-25,16,45),Color("#9c6385"))
   draw_circle(Vector2(0,-35),31,c)
  "fridge":
   draw_rect(Rect2(-24,-55,48,78),c)
   draw_rect(Rect2(-24,-55,48,78),Color("#493063"),false,3.0)
  _:
   draw_circle(Vector2(0,-12),22,c)
 if bool(get_parameter("alive")):
  draw_circle(Vector2(-8,-19),3,Color("#32204f"))
  draw_circle(Vector2(8,-19),3,Color("#32204f"))
  draw_arc(Vector2(0,-8),7,0,PI,12,Color("#32204f"),2)
func draw_ellipse_shadow() -> void:
 draw_circle(Vector2(0,16),18,Color(0,0,0,0.17))
