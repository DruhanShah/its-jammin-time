class_name TwistInput
extends Node
## "Twist" input: rolling the six keys around G in a circle, read by physical key position (works on any layout).
## Seen on the keyboard, clockwise is T → Y → H → B → V → F → T (screw in, positive degrees);
## B → H → Y → T → F → V → B is anticlockwise (unscrew, negative degrees).
## Each press of a neighbour of the last key turns 60° (120° if `allow_skip` and one key was skipped).
## A chain breaks on the same key twice, the opposite key, or a pause longer than `timeout`; the next key starts a new one.
## Reversing mid-chain isn't a break: it turns the other way and restarts the streak.

## Emitted for every step of a chain (positive = clockwise).
signal twisted(delta_degrees: float)
## Emitted when a chain of at least one step ends.
signal broken

## Clockwise from the top-left, 60° apart (T is at -30°, measured clockwise from straight up).
const RING: Array[Key] = [KEY_T, KEY_Y, KEY_H, KEY_B, KEY_V, KEY_F]

## Read key events from `_unhandled_input` (off = call `handle()` yourself).
@export var listen := true
## Seconds without a ring key press before the chain breaks.
@export var timeout := 0.7
## Missing one key in the circle still counts (as 120°), so fast, sloppy rolls don't break.
@export var allow_skip := true

## Net degrees turned since the last `reset()`.
var total_degrees := 0.0
## Degrees turned in the current chain in the current direction (signed).
var streak_degrees := 0.0
## 1 = clockwise, -1 = anticlockwise, 0 = no chain.
var direction := 0
## Ring keys currently held down (physical keycodes).
var held: Array[Key] = []

var _last := -1
var _last_time := 0.0

var rotations: float:
	get: return total_degrees / 360.0


func _process(_delta: float) -> void:
	check_timeout(_now())


func _unhandled_input(event: InputEvent) -> void:
	if listen:
		handle(event)


## Feed an input event. Returns true if it was a ring key (press or release).
func handle(event: InputEvent, now := -1.0) -> bool:
	var key := event as InputEventKey
	if key == null:
		return false
	var code := key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode
	if code not in RING:
		return false
	if not key.pressed:
		held.erase(code)
	elif not key.echo:
		if code not in held:
			held.append(code)
		press(code, _now() if now < 0.0 else now)
	return true


## A ring key went down at time `now` (seconds).
func press(code: Key, now: float) -> void:
	var index := RING.find(code)
	if index < 0:
		return
	check_timeout(now)
	_last_time = now
	if _last < 0:
		_last = index
		return
	var steps := posmod(index - _last + 3, 6) - 3  # -3..2: how many places clockwise from the last key
	_last = index
	if steps == 0 or steps == -3 or (absi(steps) == 2 and not allow_skip):
		_break()
		_last = index
		return
	var step_direction := signi(steps)
	if step_direction != direction:
		streak_degrees = 0.0
		direction = step_direction
	var delta := steps * 60.0
	streak_degrees += delta
	total_degrees += delta
	twisted.emit(delta)


## Breaks the chain if nothing was pressed for `timeout` seconds before `now`.
func check_timeout(now: float) -> void:
	if _last >= 0 and now - _last_time > timeout:
		_break()


func reset() -> void:
	_last = -1
	direction = 0
	streak_degrees = 0.0
	total_degrees = 0.0


## Degrees clockwise from straight up of a ring key around G.
static func key_angle(code: Key) -> float:
	return fposmod(RING.find(code) * 60.0 - 30.0, 360.0)


func _break() -> void:
	var had_steps := direction != 0
	_last = -1
	direction = 0
	streak_degrees = 0.0
	if had_steps:
		broken.emit()


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0
