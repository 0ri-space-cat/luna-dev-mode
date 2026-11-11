extends SceneTree
## Portable world/control clock and bounded checkpoint history contracts.
const TimeService = preload("res://scripts/core/time_service.gd")

var live_state := {"entities": {"luna": {"x": 0, "hp": 10}}, "effects": []}
var fail_restore := false

func _initialize() -> void:
	call_deferred("_run")

func _capture() -> Dictionary:
	return live_state.duplicate(true)

func _validate(data: Dictionary) -> bool:
	return data.has("entities") and data.has("effects")

func _restore(data: Dictionary) -> bool:
	if fail_restore:
		return false
	live_state = data.duplicate(true)
	return true

func _run() -> void:
	var time = TimeService.new()
	assert(time.configure(Callable(self, "_capture"), Callable(self, "_validate"),
		Callable(self, "_restore"), 0.1, 4))
	assert(time.capture_checkpoint())
	live_state["entities"]["luna"]["x"] = 4
	assert(time.advance(0.1)["world_delta"] == 0.1)
	assert(time.checkpoint_count() == 2)
	assert(time.set_world_time_scale(0.0))
	var stopped = time.advance(0.2)
	assert(stopped["world_delta"] == 0.0 and stopped["control_delta"] == 0.2)
	assert(time.set_world_time_scale(2.0))
	assert(time.rewind_steps())
	assert(live_state["entities"]["luna"]["x"] == 0)
	assert(is_equal_approx(time.world_seconds, 0.0))
	# Failed restoration enters ERROR and preserves the target checkpoint for retry.
	live_state["entities"]["luna"]["x"] = 9
	assert(time.capture_checkpoint())
	fail_restore = true
	assert(not time.rewind_steps())
	assert(time.runtime_state == TimeService.RuntimeState.ERROR)
	fail_restore = false
	assert(time.recover_to_latest_checkpoint())
	assert(live_state["entities"]["luna"]["x"] == 9)
	# Bounded history evicts old states deterministically.
	for i in range(8):
		live_state["entities"]["luna"]["x"] = i
		time.world_seconds += 1.0
		assert(time.capture_checkpoint())
	assert(time.checkpoint_count() == 4)
	assert(not time.set_world_time_scale(5.0))
	assert(time.configure(Callable(self, "_capture"), Callable(self, "_validate"), Callable(self, "_restore")))
	assert(time.checkpoint_count() == 0 and time.world_seconds == 0.0)
	live_state["node"] = root
	assert(not time.capture_checkpoint())
	live_state.erase("node")
	print("Portable time service: dual clocks, bounded snapshots, rewind and recovery passed")
	quit(0)
