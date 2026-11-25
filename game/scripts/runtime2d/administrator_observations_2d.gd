extends RefCounted
## Optional remarks. State lives outside the sanction journals and rollback.

const YETI := "yeti"
const FRIDGES := "fridges"
const FOREST := "forest"
const TOPICS := [YETI, FRIDGES, FOREST]
const WAKE_THRESHOLD := 4
const MIN_NAP := 4.0
const FRIDGE_THRESHOLD := 6
const FRIDGE_SECONDS := 4.0
const MAX_COUNT := 2147483647

var wakes := 0
var forest_count := 0
var nap_available := true
var pending: Array[Dictionary] = []
var delivered: Array[String] = []
var _nap := 0.0
var _fridge_time := 0.0


func observe_sleep(asleep: bool, delta: float) -> void:
	if asleep and nap_available:
		_nap = minf(MIN_NAP, _nap + delta)
	else:
		_nap = 0.0


func start_nap() -> bool:
	if nap_available or wakes == WAKE_THRESHOLD:
		return false
	nap_available = true
	_nap = 0.0
	return true


func record_wake() -> bool:
	if not nap_available or wakes == WAKE_THRESHOLD:
		return false
	var slept := _nap >= MIN_NAP
	nap_available = false
	_nap = 0.0
	if slept:
		wakes += 1
		if wakes == WAKE_THRESHOLD:
			_queue(YETI, wakes)
	return true


func watching_fridges() -> bool:
	return not _is_known(FRIDGES)


func observe_fridges(actually_alive: int, delta: float) -> bool:
	if not watching_fridges():
		return false
	if actually_alive < FRIDGE_THRESHOLD:
		_fridge_time = 0.0
		return false
	_fridge_time += delta
	if _fridge_time < FRIDGE_SECONDS:
		return false
	return _queue(FRIDGES, actually_alive)


func record_forest_press() -> bool:
	if _is_known(FOREST) or forest_count >= MAX_COUNT:
		return false
	forest_count += 1
	return true


func queue_forest_report() -> bool:
	if forest_count <= 0 or _is_known(FOREST):
		return false
	pending.push_front({"topic": FOREST, "count": forest_count})
	return true


func clear_transient_observation() -> void:
	_nap = 0.0
	_fridge_time = 0.0


func take_pending() -> Dictionary:
	if pending.is_empty():
		return {}
	var item: Dictionary = pending.pop_front()
	delivered.append(item["topic"])
	return item


func _queue(topic: String, count: int) -> bool:
	if _is_known(topic):
		return false
	pending.append({"topic": topic, "count": count})
	return true


func _is_known(topic: String) -> bool:
	return delivered.has(topic) or pending.any(func(item): return item["topic"] == topic)


func snapshot() -> Dictionary:
	return {"wakes": wakes, "forest_count": forest_count, "nap_available": nap_available,
		"pending": pending.duplicate(true), "delivered": delivered.duplicate()}


func restore(value: Variant) -> bool:
	if not value is Dictionary:
		return false
	if value.is_empty():
		return true # profiles from before this slice
	if not _whole(value.get("wakes"), WAKE_THRESHOLD) or not _whole(value.get("forest_count"), MAX_COUNT) \
			or not value.get("nap_available") is bool \
			or not value.get("pending") is Array or not value.get("delivered") is Array \
			or value["pending"].size() + value["delivered"].size() > TOPICS.size():
		return false
	var known := {}
	for topic in value["delivered"]:
		if topic not in TOPICS or known.has(topic):
			return false
		known[topic] = true
	for item in value["pending"]:
		if not item is Dictionary or item.get("topic") not in TOPICS or known.has(item["topic"]) \
				or not _whole(item.get("count"), MAX_COUNT):
			return false
		var topic: String = item["topic"]
		var count := int(item["count"])
		if (topic == YETI and count != WAKE_THRESHOLD) \
				or (topic == FRIDGES and count < FRIDGE_THRESHOLD) \
				or (topic == FOREST and (count < 1 or count != int(value["forest_count"]))):
			return false
		known[topic] = true
	if known.has(YETI) != (int(value["wakes"]) == WAKE_THRESHOLD) \
			or (known.has(FOREST) and int(value["forest_count"]) == 0):
		return false
	wakes = int(value["wakes"])
	forest_count = int(value["forest_count"])
	nap_available = value["nap_available"]
	pending.assign(value["pending"].duplicate(true))
	delivered.assign(value["delivered"])
	return true


func _whole(value: Variant, maximum: int) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) \
		and float(value) >= 0.0 and float(value) <= maximum and floorf(float(value)) == float(value)
