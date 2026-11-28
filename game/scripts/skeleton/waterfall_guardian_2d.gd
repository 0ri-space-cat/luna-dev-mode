extends Node2D
## An optional W2-to-W6 route. The narrow span is real ground; the guardian
## occupies it only while recovering from a charge.

const ID := "W4_WATERFALL_GUARDIAN"
const PLACE := "ET_WATERFALL_GUARDIAN"
const ENTRY := Vector2(2232, 349)
const RETURN_POINTS := [Vector2(2215, 356), Vector2(2184, 351), Vector2(2155, 357)]
const WEST := Rect2(8200, 3020, 270, 214)
const EAST := Rect2(8768, 3020, 220, 214)
const SPAN := Rect2(8455, 3080, 333, 50)
const RECESS := Rect2(8535, 3096, 110, 134)
const LOWER_LEDGE := Rect2(8618, 3037, 102, 127)
const POOL := Rect2(8470, 3020, 298, 214)
const BED := {"bounds": POOL, "height": -36.0, "safe": false}
const DECKS := [WEST, EAST, SPAN, RECESS, LOWER_LEDGE]
const ARRIVAL := Vector2(8270, 3105)
const LEAVE := Vector2(8240, 3105)
const FAR_EXIT := Vector2(8954, 3105)
const DEN := Vector2(8585, 3193)
const CHOKE := Vector2(8585, 3105)
const ANCHOR := Vector2(8696, 3081)
const ANCHOR_WALL := {"bounds": Rect2(8685, 3058, 22, 25), "height": 43.0, "layer": 2}
const RING_RADIUS := 86.0
const DAMAGE := 25
const REACH := 25.0
const WINDUP := 1.25
const OPENING := 3.5

var home: Node
var initial_guard: Dictionary
var _phase := "den"
var _elapsed := 0.0
var _hit := false
var _was_here := false
var _bar: ProgressBar
var _name: Label


static func owns(point: Vector2) -> bool:
	return WEST.has_point(point) or EAST.has_point(point) or POOL.has_point(point) or SPAN.has_point(point)


func mount(world: Node) -> void:
	home = world
	var guard = home.spawn_entity({"id": ID, "label": "Гигантский аксолотль",
		"category": "giant_axolotl", "material": "FABRIC"}, DEN, 0.0)
	if guard == null:
		push_error("Could not place the waterfall guardian")
		return
	guard.set_parameter("size", 2.0)
	guard.set_parameter("speed", 3.0)
	guard.set_parameter("color", Color("f49fc9"))
	guard.set_parameter("luna_relation", "HOSTILE")
	guard.set_parameter("behavior_mode", "CHASE")
	guard.set_parameter("target_group", "LUNA")
	guard.set_parameter("sense_range", 2.5)
	for entity in home.make_snapshot()["entities"]:
		if entity["id"] == ID:
			initial_guard = entity.duplicate(true)
			break
	_bar = ProgressBar.new()
	_bar.max_value = guard.record.registry.get_spec(guard.record.category, "health")["default"]
	_bar.show_percentage = false
	_bar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_bar.offset_left = -132
	_bar.offset_right = 132
	_bar.offset_top = 80
	_bar.offset_bottom = 92
	_bar.hide()
	home.get_node("Interface").add_child(_bar)
	_name = Label.new()
	_name.text = "Гигантский аксолотль"
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_name.offset_left = -132
	_name.offset_right = 132
	_name.offset_top = 56
	_name.hide()
	home.get_node("Interface").add_child(_name)


func action(point: Vector2) -> String:
	if POOL.has_point(point) and home.actor.motion.elevation < -18.0:
		return "Выбраться на берег"
	if point.distance_squared_to(ENTRY) <= REACH * REACH:
		return "За водопад"
	if point.distance_squared_to(LEAVE) <= REACH * REACH:
		return "К речной тропе"
	if point.distance_squared_to(FAR_EXIT) <= REACH * REACH:
		return "К Озеру Дубликатов"
	return ""


func interact(point: Vector2) -> bool:
	if POOL.has_point(point) and home.actor.motion.elevation < -18.0:
		return _move(ARRIVAL)
	if point.distance_squared_to(ENTRY) <= REACH * REACH:
		return _move(ARRIVAL)
	if point.distance_squared_to(LEAVE) <= REACH * REACH:
		for target: Vector2 in RETURN_POINTS:
			if _move(target):
				return true
		return false
	for target: Vector2 in home.Lake.TUNNEL_ARRIVALS:
		if _move(target):
			return true
	return false


func _move(point: Vector2) -> bool:
	var address: String = home._entity_location(point)
	if not home._ordinary_arrival_is_safe(address, point):
		return false
	home._move_home_travelers(point, address)
	return true


func pull_to_anchor() -> bool:
	var actor = home.actor
	var offset: Vector2 = ANCHOR - actor.position
	if not owns(actor.position) or offset.length_squared() > 190.0 * 190.0 \
			or offset.length_squared() < 28.0 * 28.0 or not home._am_line_clear(ANCHOR):
		return false
	return actor.apply_impulse(offset.normalized() * 175.0, 315.0)


func restore() -> void:
	# Telegraphs restart after loading. The saved guardian retains its position,
	# health and parameters; the shared physics carries it back to its recess.
	_phase = "return"
	_elapsed = 0.0
	_hit = false


func tick(delta: float) -> void:
	var guard = home.entities.get_entity(ID)
	if guard == null or _bar == null:
		return
	var actor = home.actor
	if not owns(actor.position):
		if _was_here:
			_was_here = false
			_bar.hide()
			_name.hide()
			if actor.secondary_step_obstacle == guard:
				actor.secondary_step_obstacle = home.entities.get_entity(home.AM.GIANT)
			guard.collision_layer = 0
			guard.autonomous_destination = Vector2.INF
			_begin("return")
			queue_redraw()
		return
	_was_here = true
	var hostile := _is_hostile(guard)
	_bar.visible = hostile
	_name.visible = hostile
	var health: int = guard.get_parameter("health")
	_bar.value = health
	if hostile:
		_name.text = "Гигантский аксолотль · %d HP" % health
	else:
		actor.secondary_step_obstacle = null
		guard.collision_layer = 0
		guard.autonomous_destination = Vector2.INF
		if _phase != "den":
			_begin("den")
			queue_redraw()
		return
	actor.secondary_step_obstacle = guard
	guard.collision_layer = guard.BODY_OBSTACLE_LAYER if _phase in ["charge", "opening"] else 0
	_elapsed += delta
	match _phase:
		"den":
			guard.autonomous_destination = DEN
			if actor.position.distance_squared_to(CHOKE) < 220.0 * 220.0:
				_begin("windup")
		"windup":
			guard.autonomous_destination = DEN
			if _elapsed >= WINDUP:
				_begin("charge")
		"charge":
			guard.autonomous_destination = CHOKE
			if guard.position.distance_squared_to(CHOKE) < 8.0 * 8.0:
				_begin("opening")
			elif _elapsed >= 4.0:
				_begin("return")
		"opening":
			guard.autonomous_destination = CHOKE
			_check_attack(actor, guard)
			if _elapsed >= OPENING:
				_begin("return")
		"return":
			guard.autonomous_destination = DEN
			if guard.position.distance_squared_to(DEN) < 10.0 * 10.0:
				_begin("den")
	queue_redraw()


func _is_hostile(guard: Node) -> bool:
	return guard.get_parameter("alive") and guard.get_parameter("ai_enabled") \
		and guard.get_parameter("luna_relation") == "HOSTILE" and guard.get_parameter("behavior_mode") == "CHASE" \
		and guard.get_parameter("target_group") == "LUNA" and float(guard.get_parameter("speed")) > 0.0


func _begin(next: String) -> void:
	_phase = next
	_elapsed = 0.0
	_hit = false


func _check_attack(actor: Node, guard: Node) -> void:
	if _hit or _elapsed > 0.58 or actor.motion.elevation >= 19.0:
		return
	var distance: float = actor.position.distance_to(guard.position)
	if distance > lerpf(26.0, RING_RADIUS, clampf(_elapsed / 0.58, 0.0, 1.0)):
		return
	_hit = true
	var health := int(actor.get_parameter("health")) - DAMAGE
	if health <= 0 and _move(ARRIVAL):
		actor.record.set_parameter("health", 100)
		_begin("return")
		return
	actor.record.set_parameter("health", maxi(1, health))
	var direction: Vector2 = (actor.position - guard.position).normalized()
	actor.apply_impulse(direction * 92.0, 70.0)


func _draw() -> void:
	draw_arc(ENTRY - Vector2(0, 10), 17.0, PI, TAU, 20, Color("b9dddc"), 3.0, true)
	draw_rect(POOL, Color("385f70"))
	draw_rect(WEST, Color("698684"))
	draw_rect(EAST, Color("738788"))
	draw_rect(RECESS, Color("496f7d"))
	draw_rect(LOWER_LEDGE, Color("738788"))
	draw_rect(SPAN, Color("7a8e8d"))
	draw_rect(ANCHOR_WALL["bounds"], Color("a6a7a8"))
	for x in range(8473, 8765, 30):
		var y := 3154.0 + float(x % 3) * 8.0
		draw_line(Vector2(x, y), Vector2(x + 17, y + 4), Color("78a8ac"), 1.5, true)
	for point in [LEAVE, FAR_EXIT]:
		draw_arc(point - Vector2(0, 7), 12, PI, TAU, 18, Color("c3ddd2"), 2.0, true)
	if _phase == "windup":
		draw_arc(CHOKE, RING_RADIUS, 0.0, TAU, 40, Color("e3adba"), 2.0, true)
	elif _phase == "opening" and _elapsed <= 0.58:
		draw_arc(CHOKE, lerpf(26.0, RING_RADIUS, _elapsed / 0.58),
			0.0, TAU, 34, Color("e5e3ec"), 3.0, true)
