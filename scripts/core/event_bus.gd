extends RefCounted
## A bounded event queue. Reactive changes enqueue new events instead of
## executing recursively; both chain depth and work per frame are limited.
## Events are plain Dictionaries and do not retain scene nodes.

signal event_dropped(reason: String)

const MAX_QUEUE := 128
const MAX_DEPTH := 6
const MAX_PER_DRAIN := 48

var _queue: Array[Dictionary] = []
var _root_sequence := 0
var _dispatching := false
var _active_depth := 0
var _active_root := 0
var dropped_count := 0
var processed_count := 0


func enqueue(event: Dictionary) -> bool:
	if str(event.get("type", "")).is_empty():
		return false
	if _queue.size() >= MAX_QUEUE:
		_drop("Queue capacity exceeded")
		return false
	var queued: Dictionary = event.duplicate(true)
	if _dispatching:
		queued["depth"] = _active_depth + 1
		queued["root_id"] = _active_root
	else:
		_root_sequence += 1
		queued["depth"] = 0
		queued["root_id"] = _root_sequence
	if int(queued["depth"]) > MAX_DEPTH:
		_drop("Event chain depth exceeded")
		return false
	_queue.append(queued)
	return true


func drain(rule_engine) -> int:
	if _dispatching:
		return 0
	_dispatching = true
	var handled := 0
	while handled < MAX_PER_DRAIN and not _queue.is_empty():
		var event: Dictionary = _queue.pop_front()
		_active_depth = int(event["depth"])
		_active_root = int(event["root_id"])
		rule_engine.process_event(event)
		handled += 1
		processed_count += 1
	_dispatching = false
	_active_depth = 0
	_active_root = 0
	return handled


func pending_count() -> int:
	return _queue.size()


func _drop(reason: String) -> void:
	dropped_count += 1
	event_dropped.emit(reason)
