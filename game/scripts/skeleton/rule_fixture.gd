extends "res://scripts/skeleton/entity_fixture.gd"
## Drives an authored world rule from an actual 2D+Z contact in the test room.

const Rules = preload("res://scripts/runtime2d/world_rule_engine_2d.gd")
const Events = preload("res://scripts/core/event_bus.gd")
const Clock = preload("res://scripts/runtime2d/world_clock_2d.gd")
const RULE_PATH := "res://data/skeleton/DEV_WAKE_FRIDGE.json"
const RULE_ID := "DEV_WAKE_FRIDGE"
const PLATE_ID := "DEV_WAKE_PLATE"
const PLATE := Rect2(275, 245, 48, 38)

var rules := Rules.new()
var events := Events.new()
var world_clock := Clock.new()
var _plate_occupied := false

var world_registry:
	get:
		return entities
var command_processor:
	get:
		return commands
var current_location_id: String:
	get:
		return _location_id()


func _location_id() -> String:
	return "DEV_WORLD_RULE"


func _ready() -> void:
	super._ready()
	var definitions: Variant = JSON.parse_string(FileAccess.get_file_as_string(RULE_PATH))
	if not rules.configure_location(current_location_id, definitions):
		set_physics_process(false)
		push_error("Could not load the day plate rule: " + rules.last_error)
		return
	var fridge := entities.get_entity(TARGET_ID) as EntityBody
	fridge.set_parameter("behavior_mode", "WANDER")
	world_clock.set_time_of_day(Clock.NIGHT_MINUTE)


func _on_plate() -> bool:
	return actor.motion.grounded and is_equal_approx(actor.motion.elevation, UPPER_HEIGHT) \
		and PLATE.has_point(actor.position)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if is_instance_valid(_debug_editor):
		return
	world_clock.advance(delta)
	var occupied := _on_plate()
	if occupied != _plate_occupied:
		_plate_occupied = occupied
		queue_world_event({
			"type": "ZONE_ENTERED" if occupied else "ZONE_EXITED",
			"zone_id": PLATE_ID, "entity_id": actor.entity_id,
			"location_id": current_location_id,
		})
		queue_redraw()
	events.drain(self)
	var day := world_clock.phase() == Clock.Phase.DAY
	$RuleReadout.text = "%s  ·  %s" % [
		"День" if day else "Вне дневного окна",
		"Холодильник ожил" if rules.has_fired(RULE_ID) else "Плита ждёт",
	]


func queue_world_event(event: Dictionary) -> bool:
	return events.enqueue(event)


func process_event(event: Dictionary) -> void:
	rules.process_event(event, self)


func _unhandled_key_input(event: InputEvent) -> void:
	if keyboard and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_T:
		if not is_instance_valid(_debug_editor):
			var minute := Clock.NIGHT_MINUTE if world_clock.phase() == Clock.Phase.DAY else Clock.START_MINUTE
			world_clock.set_time_of_day(minute)
			get_viewport().set_input_as_handled()
		return
	super._unhandled_key_input(event)


func make_snapshot() -> Dictionary:
	var data := super.make_snapshot()
	data["world_clock"] = world_clock.snapshot()
	data["rule_flags"] = rules.snapshot_flags()
	return data


func apply_snapshot(data: Dictionary) -> bool:
	var flags: Variant = data.get("rule_flags")
	var next_clock := Clock.new()
	if not rules.validate_flags(flags) or not next_clock.restore(data.get("world_clock")):
		return false
	for flag in flags:
		if flag != RULE_ID:
			return false
	if not super.apply_snapshot(data):
		return false
	rules.restore_flags(flags)
	world_clock.restore(next_clock.snapshot())
	_plate_occupied = _on_plate()
	events.clear_pending()
	queue_redraw()
	return true


func _draw() -> void:
	super._draw()
	var screen_plate := Rect2(PLATE.position - Vector2(0, UPPER_HEIGHT), PLATE.size)
	draw_rect(screen_plate, Color("c0a1d4") if _plate_occupied else Color("817297"))
	draw_rect(screen_plate, Color("e2cce8"), false, 2.0)
