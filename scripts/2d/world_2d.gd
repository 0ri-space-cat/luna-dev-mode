extends Node2D
const Actor = preload("res://scripts/2d/entity_actor_2d.gd")
const Registry = preload("res://scripts/core/parameter_registry.gd")
const Processor = preload("res://scripts/core/command_processor.gd")
const World = preload("res://scripts/core/world_registry.gd")
@onready var player: CharacterBody2D = $Entities/Player
var registry = Registry.new()
var processor = Processor.new()
var world = World.new()
var selected
var actors = []
var info: Label
func _ready() -> void:
 processor.configure_world(world)
 _spawn("tree_01","tree","Клён",Vector2(420,300),Color("#9bd65b"))
 _spawn("fridge_01","fridge","Холодильник",Vector2(800,420),Color("#e0b7ec"))
 _spawn("tree_02","tree","Вишня",Vector2(970,250),Color("#f4a0d0"))
 var layer := CanvasLayer.new()
 add_child(layer)
 info = Label.new()
 info.position = Vector2(20,20)
 info.text = "♡ HEALTH 120/120   ◇ MANA 80/80   ⚡ STAMINA 100/100"
 layer.add_child(info)
 queue_redraw()
func _spawn(id: String, category: String, title: String, at: Vector2, color: Color) -> void:
 var actor = Actor.new()
 actor.position = at
 $Entities.add_child(actor)
 actor.setup(id,category,title,registry,{"color":color})
 world.register_entity(id,actor,category.to_upper())
 actors.append(actor)
func _physics_process(_delta: float) -> void:
 player.velocity = Input.get_vector("ui_left","ui_right","ui_up","ui_down") * 220.0
 player.move_and_slide()
 queue_redraw()
func _unhandled_input(event: InputEvent) -> void:
 if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
  selected = null
  for actor in actors:
   if actor.global_position.distance_to(get_global_mouse_position()) < 48:
    selected = actor
    break
  if selected != null:
   info.text = "%s | %s | IS_ALIVE=%s | click SPACE to toggle, Z undo" % [selected.record.display_name,selected.record.id,str(selected.get_parameter("alive"))]
 if event is InputEventKey and event.pressed and selected != null:
  if event.keycode == KEY_SPACE:
   processor.execute_set(selected,"alive",not bool(selected.get_parameter("alive")),"luna","wand:luna")
  if event.keycode == KEY_Z:
   processor.undo()
  info.text = "%s | IS_ALIVE=%s" % [selected.record.display_name,str(selected.get_parameter("alive"))]
func _draw() -> void:
 draw_rect(Rect2(0,0,1280,800),Color("#91d650"))
 draw_rect(Rect2(0,620,1280,180),Color("#7756a6"))
 draw_rect(Rect2(0,610,1280,12),Color("#c3ee79"))
 draw_circle(player.position + Vector2(0,-8),20,Color("#f5b6e7"))
 draw_colored_polygon(PackedVector2Array([player.position+Vector2(-27,-24),player.position+Vector2(0,-65),player.position+Vector2(27,-24)]),Color("#8848c8"))
