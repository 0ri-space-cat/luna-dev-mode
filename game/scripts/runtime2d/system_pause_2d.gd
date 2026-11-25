extends Node
## The editor, recovery and stasis suspend the same world scope. A freed
## traveler still uses real physics against the frozen collision geometry.

signal ended(mode: String)

const RECOVERY := "recovery"
const EDITOR := "editor"
const STASIS := "stasis"
const BREAKOUT_ATTEMPTS := 3
const STASIS_GRACE := 0.55

var mode := ""
var attempts := 0
var remaining := 0.0
var freed := false
var keyboard := true
var _scope: Node
var _traveler: SkeletonElevationBody2D
var _scope_mode: ProcessMode
var _traveler_mode: ProcessMode
var _flinch := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func begin(reason: String, scope: Node, traveler: SkeletonElevationBody2D, limit: float = 0.0) -> bool:
	if not mode.is_empty() or reason not in [RECOVERY, EDITOR, STASIS] \
			or not is_instance_valid(scope) or not is_instance_valid(traveler) \
			or (reason == STASIS and limit <= 0.0):
		return false
	mode = reason
	_scope = scope
	_traveler = traveler
	_scope_mode = scope.process_mode
	_traveler_mode = traveler.process_mode
	_traveler.direction = Vector2.ZERO
	scope.process_mode = Node.PROCESS_MODE_DISABLED
	attempts = 0
	freed = false
	remaining = limit
	return true


func finish() -> void:
	if mode.is_empty():
		return
	var previous := mode
	mode = ""
	if is_instance_valid(_traveler):
		_reset_flinch()
		_traveler.process_mode = _traveler_mode
		_traveler.direction = Vector2.ZERO
	if is_instance_valid(_scope):
		_scope.process_mode = _scope_mode
	_scope = null
	_traveler = null
	remaining = 0.0
	freed = false
	attempts = 0
	ended.emit(previous)


func resist(direction: Vector2) -> bool:
	if mode not in [EDITOR, STASIS] or not direction.is_finite() or direction.is_zero_approx() \
			or not is_instance_valid(_traveler):
		return false
	if freed:
		return true
	attempts += 1
	if attempts == BREAKOUT_ATTEMPTS - 1 and _traveler._marker != null:
		_traveler._marker.position += direction.normalized() * 4.0
		_flinch = 0.14
	if attempts >= BREAKOUT_ATTEMPTS:
		_reset_flinch()
		freed = true
		_traveler.process_mode = Node.PROCESS_MODE_ALWAYS
		_traveler.direction = direction.normalized()
		if mode == STASIS:
			remaining = minf(remaining, STASIS_GRACE)
	return true


func _input(event: InputEvent) -> void:
	if not keyboard or freed or mode not in [EDITOR, STASIS] \
			or not event is InputEventKey or not event.pressed or event.echo:
		return
	var key: Key = event.physical_keycode if event.physical_keycode != KEY_NONE else event.keycode
	var direction := Vector2.ZERO
	match key:
		KEY_W, KEY_UP: direction = Vector2.UP
		KEY_S, KEY_DOWN: direction = Vector2.DOWN
		KEY_A, KEY_LEFT: direction = Vector2.LEFT
		KEY_D, KEY_RIGHT: direction = Vector2.RIGHT
	if resist(direction):
		get_viewport().set_input_as_handled()


func _reset_flinch() -> void:
	if _flinch <= 0.0:
		return
	_flinch = 0.0
	if is_instance_valid(_traveler) and is_instance_valid(_traveler._marker):
		_traveler._marker.position = Vector2(0, -_traveler.motion.elevation)


func _physics_process(delta: float) -> void:
	if _flinch > 0.0:
		if delta >= _flinch:
			_reset_flinch()
		else:
			_flinch -= delta
	if freed and keyboard and is_instance_valid(_traveler):
		var movement := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		movement.x += float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A))
		movement.y += float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))
		_traveler.direction = movement.limit_length()
	if mode == STASIS:
		remaining = maxf(0.0, remaining - delta)
		if remaining <= 0.0:
			finish()
