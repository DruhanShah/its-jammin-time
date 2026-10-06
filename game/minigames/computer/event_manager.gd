extends Node
## Decides WHEN minigames start. Placeholder until the real event system is specified:
## plays a list of minigames one after another, each starting once the previous one is beaten.
## The list is GameState.computer_queue (set by the story through Computer.open()/queue()), or,
## when that's empty (free use), `start_on_open`.
## Only talk to the host through computer.start_minigame() and its signals, so this file can be
## swapped out (timers, typing thresholds, narrator beats, a global autoload...) without touching
## the minigames.

## Minigame ids (see minigame_registry.tres) played in order on free use (no story queue).
@export var start_on_open: Array[StringName] = [&"corporate_speak", &"ad_popup", &"bot_check", &"password_scream"]
## Seconds between one minigame being beaten and the next starting (also before a retry).
@export var step_delay := 1.0
## Seconds after the last queued minigame before the computer returns to the office by itself
## (story queue with GameState.computer_exit_when_done only).
@export var exit_delay := 1.5

var _free_queue: Array[StringName] = [] ## Free-use list in progress (copy of start_on_open).
var _story := false ## Playing GameState.computer_queue rather than _free_queue.
var _current: StringName ## Id of the step being played; empty between steps.
var _beaten := false ## Some instance of the current step completed.

@onready var computer := get_parent() as Computer


func _ready() -> void:
	_story = not GameState.computer_queue.is_empty()
	_free_queue = start_on_open.duplicate()
	computer.minigame_completed.connect(_on_completed)
	computer.minigame_failed.connect(_on_failed)
	_start_next.call_deferred()


func _queue() -> Array[StringName]:
	return GameState.computer_queue if _story else _free_queue


func _start_next() -> void:
	var queue := _queue()
	if queue.is_empty():
		return
	_current = queue[0]
	_beaten = false
	if not computer.start_minigame(_current):
		push_error("EventManager: couldn't start '%s', skipping it" % _current)
		queue.pop_front()
		_start_next()


func _on_completed(id: StringName) -> void:
	if id == _current:
		_beaten = true
		_check_step.call_deferred()


func _on_failed(id: StringName) -> void:
	if id == _current:
		_check_step.call_deferred()


## A minigame can spawn copies of itself (ads), so a step ends when its last instance is gone:
## beaten if any instance completed, otherwise (e.g. "I am a bot" clicked) it starts again.
func _check_step() -> void:
	if _current.is_empty() or not computer.active_minigames(_current).is_empty():
		return
	var id := _current
	_current = &""
	if not _beaten:
		_after(step_delay, _restart.bind(id))
		return
	var queue := _queue()
	queue.pop_front()
	GameState.minigames_completed[id] = GameState.minigames_completed.get(id, 0) + 1
	if _story:
		GameState.computer_minigame_finished.emit(id)
	if not queue.is_empty():
		_after(step_delay, _start_next)
	elif _story:
		GameState.computer_queue_finished.emit()
		if GameState.computer_exit_when_done:
			_after(exit_delay, computer.exit)


## Starts nothing more (the running minigame, if any, stays; see Computer.glance_blurry()).
func stop() -> void:
	_free_queue.clear()
	_current = &""
	_story = false


func _restart(id: StringName) -> void:
	if _queue() and _queue()[0] == id:
		_start_next()


func _after(seconds: float, callback: Callable) -> void:
	get_tree().create_timer(seconds).timeout.connect(callback)
