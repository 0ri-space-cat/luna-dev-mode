extends PanelContainer
## Data-driven 2D inspector. All edits flow through CommandProcessor.
var target: Node
var processor
var registry
var rows: VBoxContainer
var heading: Label
func _ready() -> void:
 custom_minimum_size = Vector2(320, 0)
 var outer := VBoxContainer.new()
 add_child(outer)
 heading = Label.new()
 outer.add_child(heading)
 var scroll := ScrollContainer.new()
 scroll.custom_minimum_size = Vector2(310, 300)
 outer.add_child(scroll)
 rows = VBoxContainer.new()
 scroll.add_child(rows)
 var close := Button.new()
 close.text = "✓ DONE"
 close.pressed.connect(hide)
 outer.add_child(close)
 hide()
func open_actor(actor: Node, commands, parameters) -> void:
 target = actor
 processor = commands
 registry = parameters
 heading.text = "%s   ID: %s" % [target.record.display_name, target.record.id]
 _refresh()
 show()
func _refresh() -> void:
 for child in rows.get_children():
  rows.remove_child(child)
  child.queue_free()
 for spec in registry.get_specs_for(target.record.category):
  var key := str(spec["id"])
  var line := HBoxContainer.new()
  rows.add_child(line)
  var caption := Label.new()
  caption.text = str(spec["label"])
  caption.custom_minimum_size.x = 150
  line.add_child(caption)
  match str(spec["kind"]):
   "bool":
    var toggle := CheckButton.new()
    toggle.button_pressed = bool(target.get_parameter(key))
    toggle.toggled.connect(_change.bind(key))
    line.add_child(toggle)
   "color":
    var color := ColorPickerButton.new()
    color.color = target.get_parameter(key)
    color.color_changed.connect(_change.bind(key))
    line.add_child(color)
   "enum":
    var choices := OptionButton.new()
    var options: Array = spec["choices"]
    for i in range(options.size()):
     choices.add_item(str(options[i]["name"]))
     if str(options[i]["value"]) == str(target.get_parameter(key)):
      choices.select(i)
    choices.item_selected.connect(func(i: int): _change(options[i]["value"],key))
    line.add_child(choices)
   _:
    var slider := HSlider.new()
    slider.custom_minimum_size.x = 135
    slider.min_value = float(spec["min"])
    slider.max_value = float(spec["max"])
    slider.step = float(spec["step"])
    slider.value = float(target.get_parameter(key))
    slider.value_changed.connect(func(v: float): _change(int(v) if str(spec["kind"]) == "int" else v,key))
    line.add_child(slider)
func _change(value: Variant, key: String) -> void:
 if is_instance_valid(target):
  processor.execute_set(target,key,value,"luna","wand:luna")
