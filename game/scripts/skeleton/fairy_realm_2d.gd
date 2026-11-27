extends Node2D
## Q12 uses ordinary doors, supports, actor input and a single saved fox.

const Map = preload("res://scripts/skeleton/fairy_realm_layout.gd")
const GazeLaw = preload("res://scripts/runtime2d/observation_body_2d.gd")
const MAX_TRAIL := 96
const SAMPLE_SECONDS := 0.10
const HIT_SPEED := 66.0
const FOX_TUNING := 2.6
const COMMITTED_RUSH := 0.9
const PHASES := ["unseen", "demo", "after_demo", "late", "replay", "closed"]
const START := {"turn": 0, "grove_step": 0, "phase": "unseen", "trail": [],
	"demo_elapsed": 0.0, "rush_remaining": 0.0}

var home: Node
var state := START.duplicate(true)
var initial_residents: Array[Dictionary] = []
var _root_trail: Array = []
var _sample_left := 0.0
var _future_time := -1.0
var _past_time := -1.0
var _barrier: StaticBody2D
var _canopy_door: StaticBody2D
var _impact := false


func mount(world: Node) -> void:
	home = world
	_barrier = _dynamic_wall(Map.BARRIER)
	_canopy_door = _dynamic_wall(Map.CANOPY_DOOR)
	_sync_barrier()
	sync_observation()
	var fox = home.spawn_entity({"id": Map.FOX_ID, "category": "slime_fox", "label": "Слайм-лиса",
		"material": "FABRIC"}, Map.FOX_LATE, 0.0)
	if fox == null:
		push_error("Could not place the Fairy Realm fox")
		return
	fox.set_parameter("size", 1.75)
	fox.set_parameter("speed", FOX_TUNING)
	fox.set_parameter("behavior_mode", "CHASE")
	fox.set_parameter("target_group", "LUNA")
	fox.set_parameter("sense_range", 3.0)
	fox.set_parameter("ai_enabled", false)
	var fairy = home.spawn_entity({"id": Map.CANOPY_RESIDENT, "category": "fairy", "label": "Фея",
		"material": "FABRIC"}, Map.CANOPY_RESIDENT_START, 0.0)
	if fairy == null:
		push_error("Could not place the canopy fairy")
		return
	fairy.set_parameter("size", 0.62)
	fairy.set_parameter("behavior_mode", "IDLE")
	fairy.set_parameter("speed", 1.3)
	bind_fox()
	for saved in home.make_snapshot()["entities"]:
		if saved["id"] in [Map.FOX_ID, Map.CANOPY_RESIDENT]:
			initial_residents.append(saved.duplicate(true))


func bind_fox() -> void:
	var fox = home.entities.get_entity(Map.FOX_ID)
	if fox != null and not fox.planar_impact.is_connected(_on_fox_impact):
		fox.planar_impact.connect(_on_fox_impact)


func snapshot() -> Dictionary:
	return state.duplicate(true)


static func valid_snapshot(data: Variant) -> bool:
	if not data is Dictionary or data.size() != START.size():
		return false
	if not _whole_in(data.get("turn"), 0, 7) or not _whole_in(data.get("grove_step"), 0, Map.GROVE_COUNT):
		return false
	if data.get("phase") not in PHASES or not _number_in(data.get("demo_elapsed"), 0.0, 2.0):
		return false
	if not _number_in(data.get("rush_remaining"), 0.0, COMMITTED_RUSH):
		return false
	var trail: Variant = data.get("trail")
	if not trail is Array or trail.size() > MAX_TRAIL:
		return false
	for sample in trail:
		if not sample is Array or sample.size() != 4:
			return false
		if not _number_in(sample[0], Map.ROOTS.position.x, Map.ROOTS.end.x) \
				or not _number_in(sample[1], Map.ROOTS.position.y, Map.ROOTS.end.y) \
				or not _number_in(sample[2], 0.0, 160.0) or not _number_in(sample[3], 0.25, 3.0):
			return false
	return true


static func _number_in(value: Variant, low: float, high: float) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) and float(value) >= low and float(value) <= high


static func _whole_in(value: Variant, low: int, high: int) -> bool:
	return _number_in(value, low, high) and float(value) == floorf(float(value))


func stage_snapshot(data: Dictionary) -> void:
	state = data.duplicate(true)
	_sync_barrier()
	_set_wall(_canopy_door, Map.CANOPY_DOOR, false)
	if not home._surfaces.has(Map.CANOPY_SPAN):
		home._surfaces.append(Map.CANOPY_SPAN)


func finish_snapshot() -> void:
	_root_trail.clear()
	_future_time = -1.0
	_past_time = -1.0
	_impact = false
	bind_fox()
	sync_observation()
	queue_redraw()


func view_bounds(point: Vector2) -> Rect2:
	if Map.CANOPY_LOWER["bounds"].has_point(point) or Map.CANOPY.has_point(point) or Map.CANOPY_FAR.has_point(point):
		return Map.CANOPY.merge(Map.CANOPY_FAR)
	return Map.room_at(point)


func action() -> Dictionary:
	var body = home.actor
	if not is_instance_valid(body) or not body.motion.grounded or body.is_attached() or not is_zero_approx(float(body.motion.elevation)):
		return {}
	var point: Vector2 = body.position
	if not Map.owns(point):
		if Map.take_near(point, Map.ENTRY):
			return _action("roots", "За корнями")
		return {}
	for exit in [Map.ROOT_ENTRY, Map.EARLY_EXIT, Map.LATE_EXIT, Map.CANOPY_EXIT,
			Map.CANOPY_SIDE_EXIT, Vector2(7568, 8755)]:
		if Map.take_near(point, exit):
			return _action("leave", "На лесную тропу")
	if Map.take_near(point, Map.ROOT_FAR):
		return _action("grove", "К кругу деревьев")
	if Map.take_near(point, Map.EARLY_TO_LATE):
		return _action("late", "За поворот")
	if Map.take_near(point, Map.LATE_SEAM):
		return _action("replay", "Шагнуть в проём")
	if Map.take_near(point, Map.CANOPY_NEAR):
		return _action("canopy", "Под кроны")
	var index := Map.grove_index(point)
	if index < 0:
		return {}
	var offset := Map.GROVE_OFFSET * index
	if Map.take_near(point, Map.GROVE_RETURN + offset):
		return _action("leave", "На лесную тропу")
	if int(state["grove_step"]) == Map.GROVE_COUNT and Map.take_near(point, Map.GROVE_EXIT + offset):
		return _action("early", "Вслед за звуком")
	for slot in Map.THRESHOLDS.size():
		if Map.take_near(point, Map.THRESHOLDS[slot] + offset):
			return _action("turn", "Пройти между деревьями", motif_at(index, slot))
	return {}


func _action(kind: String, label: String, motif := -1) -> Dictionary:
	return {"kind": kind, "label": label, "motif": motif}


func motif_at(room: int, slot: int) -> int:
	var turn := int(state["turn"])
	var side := slot if turn < 4 else -slot
	return posmod(side + turn + room * 3, Map.MOTIFS.size())


func interact(move: Dictionary) -> bool:
	var target := Vector2.INF
	match move["kind"]:
		"roots": target = Map.ROOT_ENTRY + Vector2(30, 0)
		"leave":
			for point: Vector2 in Map.FOREST_RETURNS:
				if _can_land(point):
					target = point
					break
		"grove": target = Map.GROVE_ARRIVAL
		"turn":
			var step := int(state["grove_step"])
			var next := step + 1 if step < Map.GROVE_COUNT and move["motif"] == Map.MOTIFS[step] else 0
			var room := mini(next, Map.GROVE_COUNT - 1)
			target = Map.GROVE_ARRIVAL + Map.GROVE_OFFSET * room
			if not _can_land(target):
				return false
			state["grove_step"] = next
			if next == 0:
				state["turn"] = (int(state["turn"]) + 1) % 8
		"early": target = Map.EARLY_WATCH
		"late": target = Map.LATE_ARRIVAL
		"replay": target = Map.EARLY_REPLAY
		"canopy": target = Map.CANOPY_ENTRY
	if not _can_land(target):
		return false
	match move["kind"]:
		"roots":
			_future_time = 0.0
			_past_time = -1.0
			_root_trail.clear()
			_sample_left = 0.0
		"grove": state["grove_step"] = 0
		"early":
			if state["phase"] == "unseen":
				_start_demo()
		"late":
			if state["phase"] in ["demo", "after_demo", "replay"]:
				_enter_late(state["phase"] != "replay")
		"replay": _start_replay()
	home._move_home_travelers(target, home._entity_location(target))
	sync_observation()
	queue_redraw()
	return true


func _can_land(point: Vector2) -> bool:
	if not point.is_finite():
		return false
	return home._ordinary_arrival_is_safe(home._entity_location(point), point)


func _place_fox(point: Vector2) -> void:
	var fox = home.entities.get_entity(Map.FOX_ID)
	home._place_friend(fox, point, 0.0)
	fox.autonomous_destination = Vector2.INF


func _start_demo() -> void:
	_place_fox(Map.FOX_RUSH)
	var fox = home.entities.get_entity(Map.FOX_ID)
	fox.set_parameter("alive", true)
	fox.set_parameter("ai_enabled", true)
	state["phase"] = "demo"
	state["demo_elapsed"] = 0.0
	_sync_barrier()


func _enter_late(reset: bool) -> void:
	_place_fox(Map.FOX_LATE)
	if reset:
		var fox = home.entities.get_entity(Map.FOX_ID)
		fox.set_parameter("alive", false)
		fox.set_parameter("ai_enabled", false)
	state["phase"] = "late"
	state["demo_elapsed"] = 0.0
	state["rush_remaining"] = 0.0
	_sync_barrier()


func _start_replay() -> void:
	var fox = home.entities.get_entity(Map.FOX_ID)
	if state["phase"] != "late" or not fox.get_parameter("alive") or not fox.motion.grounded \
			or fox.position.distance_to(Map.LATE_SEAM) > 66.0:
		return
	_place_fox(Map.FOX_RUSH)
	state["phase"] = "replay"
	state["rush_remaining"] = 0.0
	_sync_barrier()


func _on_fox_impact(target: Object, incoming: float) -> void:
	if target == _barrier and state["phase"] in ["demo", "replay"] and incoming >= HIT_SPEED:
		_impact = true


func tick(delta: float) -> void:
	var player = home.actor
	if not is_instance_valid(player):
		return
	_tick_canopy_resident()
	sync_observation()
	_tick_echo(delta)
	var fox = home.entities.get_entity(Map.FOX_ID)
	if fox == null or not state["phase"] in ["demo", "after_demo", "replay"]:
		return
	if _impact:
		_impact = false
		state["phase"] = "after_demo" if state["phase"] == "demo" else "closed"
		state["rush_remaining"] = 0.0
		fox.autonomous_destination = Vector2.INF
		_sync_barrier()
		queue_redraw()
	if state["phase"] == "after_demo":
		state["demo_elapsed"] = minf(2.0, float(state["demo_elapsed"]) + delta)
		if float(state["demo_elapsed"]) >= 1.4:
			_enter_late(true)
		return
	if state["phase"] == "demo":
		fox.autonomous_destination = Map.EARLY_TO_LATE
	elif state["phase"] == "replay":
		var can_chase: bool = fox.get_parameter("ai_enabled") and fox.get_parameter("behavior_mode") == "CHASE"
		var gap: Vector2 = player.position - fox.position
		# A charge has momentum after Luna turns into the side pocket.
		# A slow body still has to hit the actual wall with enough speed.
		var rushing := maxf(0.0, float(state["rush_remaining"]) - delta)
		if can_chase and Map.EARLY.has_point(player.position) and gap.x > 22.0 and gap.x < 180.0 and absf(gap.y) < 78.0:
			rushing = COMMITTED_RUSH
		state["rush_remaining"] = rushing if can_chase else 0.0
		fox.autonomous_destination = Map.EARLY_TO_LATE if can_chase and rushing > 0.0 else Vector2.INF
	queue_redraw()


func _tick_canopy_resident() -> void:
	var fairy = home.entities.get_entity(Map.CANOPY_RESIDENT)
	if fairy == null:
		return
	var before_destination: bool = Map.CANOPY_FAR.has_point(fairy.position) \
		and fairy.position.x < Map.CANOPY_RESIDENT_END.x - 3.0
	var crossing: bool = before_destination and Map.owns(home.actor.position) \
		and home.actor.position.y >= Map.CANOPY.position.y and fairy.get_parameter("alive") \
		and fairy.get_parameter("ai_enabled") and fairy.get_parameter("behavior_mode") == "IDLE" \
		and fairy.get_parameter("control_source") == "NONE" and not fairy.is_attached()
	fairy.close_eyes(crossing and absf(fairy.position.x - Map.CANOPY_DOOR["bounds"].get_center().x) < 35.0)
	fairy.autonomous_destination = Map.CANOPY_RESIDENT_END if crossing else Vector2.INF


func _tick_echo(delta: float) -> void:
	var actor = home.actor
	if not Map.ROOTS.has_point(actor.position):
		return
	if _future_time >= 0.0:
		_future_time += delta
		if _future_time >= 3.4:
			_future_time = -1.0
	_sample_left -= delta
	if _sample_left <= 0.0 and actor.position.x >= Map.ROOT_START_X and actor.position.x < Map.ROOT_END_X:
		_sample_left = SAMPLE_SECONDS
		if _number_in(actor.motion.elevation, 0.0, 160.0) and _number_in(actor.body_size, 0.25, 3.0):
			if _root_trail.size() >= MAX_TRAIL:
				_root_trail.pop_front()
			_root_trail.append([actor.position.x, actor.position.y, actor.motion.elevation, actor.body_size])
	if not _root_trail.is_empty() and actor.position.x >= Map.ROOT_END_X:
		state["trail"] = _root_trail.duplicate(true)
		_root_trail.clear()
		_past_time = 0.0
	if _past_time >= 0.0:
		_past_time += delta
		if _past_time >= state["trail"].size() * SAMPLE_SECONDS:
			_past_time = -1.0
	queue_redraw()


func sync_observation() -> void:
	if not is_instance_valid(home.actor):
		return
	var span: Rect2 = Map.CANOPY_SPAN["bounds"]
	var gaze: Dictionary = home.crystal_observer.evaluate(home.actor, null, span.get_center())
	var solid := GazeLaw.solid_for(GazeLaw.WHEN_UNOBSERVED, GazeLaw.LUNA, gaze)
	if solid and not home._surfaces.has(Map.CANOPY_SPAN):
		home._surfaces.append(Map.CANOPY_SPAN)
	elif not solid:
		home._surfaces.erase(Map.CANOPY_SPAN)
	var door: Rect2 = Map.CANOPY_DOOR["bounds"]
	var close: bool = home.crystal_observer.luna_eyes_open
	if close and not home._walls.has(Map.CANOPY_DOOR):
		for identity in home.entities.list_ids():
			var body = home.entities.get_entity(identity)
			if identity == Map.CANOPY_RESIDENT and body.eyes_closed:
				continue
			if body.motion.elevation < Map.CANOPY_DOOR["height"] and door.grow(body.foot_radius()).has_point(body.position):
				close = false
				break
	_set_wall(_canopy_door, Map.CANOPY_DOOR, close)


func _sync_barrier() -> void:
	_set_wall(_barrier, Map.BARRIER, state["phase"] in ["unseen", "demo", "replay"])


func _dynamic_wall(definition: Dictionary) -> StaticBody2D:
	var wall := StaticBody2D.new()
	wall.collision_mask = 0
	wall.collision_layer = 0
	wall.disable_mode = CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
	wall.position = definition["bounds"].get_center()
	var shape := RectangleShape2D.new()
	shape.size = definition["bounds"].size
	var collider := CollisionShape2D.new()
	collider.shape = shape
	wall.add_child(collider)
	add_child(wall)
	return wall


func _set_wall(body: StaticBody2D, definition: Dictionary, solid: bool) -> void:
	if not is_instance_valid(body):
		return
	if solid == home._walls.has(definition):
		return
	if solid:
		home._walls.append(definition)
	else:
		home._walls.erase(definition)
	body.collision_layer = int(definition["layer"]) if solid else 0
	queue_redraw()


func _draw() -> void:
	_draw_threshold(Map.ENTRY, Color("9f9f72"))
	for room in Map.decks():
		draw_rect(room.grow(4), Color("3e3b56"))
		draw_rect(room, Color("69647b"))
		draw_rect(room.grow(-5), Color("8d839b"), false, 2.0)
	for wall in Map.ROOT_WALLS:
		var root: Rect2 = wall["bounds"]
		draw_rect(root, Color("504261"))
		draw_line(root.position + Vector2(8, 10), root.end - Vector2(8, 10), Color("806785"), 2.0)
	_draw_threshold(Map.ROOT_ENTRY)
	_draw_threshold(Map.ROOT_FAR)
	for index in Map.GROVE_COUNT:
		_draw_grove(index)
	_draw_threshold(Map.EARLY_EXIT)
	_draw_threshold(Map.EARLY_TO_LATE)
	_draw_threshold(Map.LATE_EXIT)
	_draw_threshold(Map.LATE_SEAM, Color("c5aed6"))
	_draw_threshold(Map.CANOPY_NEAR)
	_draw_threshold(Map.CANOPY_EXIT)
	_draw_threshold(Map.CANOPY_SIDE_EXIT)
	_draw_threshold(Vector2(7568, 8755))
	var barrier: Rect2 = Map.BARRIER["bounds"]
	if is_instance_valid(_barrier) and _barrier.collision_layer != 0:
		for y in range(int(barrier.position.y), int(barrier.end.y), 10):
			draw_line(Vector2(barrier.position.x, y), Vector2(barrier.end.x, y + 13), Color("997d73"), 4.0, true)
	elif state["phase"] != "unseen":
		for y in range(int(barrier.position.y), int(barrier.end.y), 16):
			draw_line(Vector2(barrier.position.x - 11, y + 7), Vector2(barrier.end.x + 11, y - 2), Color("997d73"), 2.0)
	if home != null and home._surfaces.has(Map.CANOPY_SPAN):
		draw_rect(Map.CANOPY_SPAN["bounds"], Color(0.71, 0.72, 0.88, 0.4))
	if is_instance_valid(_canopy_door) and _canopy_door.collision_layer != 0:
		draw_rect(Map.CANOPY_DOOR["bounds"], Color("9a86ab"))
	_draw_echoes()


func _draw_grove(index: int) -> void:
	var offset := Map.GROVE_OFFSET * index
	var landmark := Map.grove(index).get_center() - Vector2(0, 16)
	# The same landmarks appear on the antechamber tree, beyond the exits,
	# and as large features in their own clearings.
	for step in Map.MOTIFS.size():
		_draw_motif(Map.MOTIFS[step], landmark + Vector2((float(step) - 1.5) * 28.0, 40.0), 0.8)
	_draw_motif(Map.MOTIFS[index], landmark, 2.2)
	_draw_threshold(Map.GROVE_RETURN + offset)
	if int(state["grove_step"]) == Map.GROVE_COUNT and index == Map.GROVE_COUNT - 1:
		_draw_threshold(Map.GROVE_EXIT + offset, Color("e6c99b"))
	for slot in Map.THRESHOLDS.size():
		var point: Vector2 = Map.THRESHOLDS[slot] + offset
		_draw_threshold(point, Color("a8a291"))
		_draw_motif(motif_at(index, slot), point + Vector2(0, -27), 1.0)


func _draw_threshold(point: Vector2, color := Color("bb9ac2")) -> void:
	draw_arc(point - Vector2(0, 9), 15, PI, TAU, 20, color, 3.0, true)
	draw_line(point - Vector2(16, 0), point + Vector2(16, 0), color, 2.0, true)


func _draw_motif(motif: int, point: Vector2, size: float) -> void:
	match motif:
		0:
			draw_circle(point, 8.0 * size, Color("e5d4aa"))
			draw_circle(point + Vector2(4, -3) * size, 6.0 * size, Color("69647b"))
		1:
			for offset in [-7.0, 0.0, 7.0]:
				var stem := point + Vector2(offset, 2) * size
				draw_line(stem, stem + Vector2(0, 5) * size, Color("ecd4ae"), 2.0 * size, true)
				draw_arc(stem, 4.0 * size, PI, TAU, 12, Color("dd9cb1"), 3.0 * size, true)
		2:
			for offset in [-5.0, 5.0]:
				var bell := point + Vector2(offset, 0) * size
				draw_arc(bell, 5.0 * size, 0, PI, 14, Color("b9abe1"), 2.0 * size, true)
				draw_circle(bell + Vector2(0, 7) * size, 1.5 * size, Color("e5d4aa"))
		3:
			for offset in [Vector2(-6, 2), Vector2(3, -4), Vector2(8, 5)]:
				var star: Vector2 = point + offset * size
				draw_line(star - Vector2(0, 4) * size, star + Vector2(0, 4) * size, Color("b7dae4"), 1.5 * size, true)
				draw_line(star - Vector2(4, 0) * size, star + Vector2(4, 0) * size, Color("b7dae4"), 1.5 * size, true)


func _draw_echoes() -> void:
	if home == null or not is_instance_valid(home.actor):
		return
	if _future_time >= 0.0:
		var traveled := clampf((_future_time - 0.65) / 2.1, 0.0, 1.0)
		var foot := Vector2(lerpf(7240.0, 7500.0, traveled), 318)
		var shrinking := smoothstep(0.20, 0.58, _future_time)
		var growing := smoothstep(2.78, 3.12, _future_time)
		_draw_echo(foot, 1.0 - 0.5 * (shrinking - growing), 0.45)
	var trail: Array = state["trail"]
	if _past_time >= 0.0 and not trail.is_empty():
		var index := mini(int(_past_time / SAMPLE_SECONDS), trail.size() - 1)
		var sample: Array = trail[index]
		_draw_echo(Vector2(sample[0], float(sample[1]) - float(sample[2])), float(sample[3]), 0.37)


func _draw_echo(foot: Vector2, size: float, opacity: float) -> void:
	var polygon := PackedVector2Array()
	for vertex in home.actor._marker.polygon:
		polygon.append(foot + vertex * size)
	draw_colored_polygon(polygon, Color(0.82, 0.69, 0.93, opacity))
