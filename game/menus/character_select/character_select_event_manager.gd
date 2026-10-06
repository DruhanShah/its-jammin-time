extends Node
## Decides WHEN each character select step (intro cutscene, hairstyle, outfit, ...) starts.
## Plays `steps` one after another, each starting once the previous one is completed; Back returns to
## the previous step (never into the intro). Finishing the last step tells the host to finish().
## Only talks to the host through start_step()/finish() and its signals, so the order can change
## without touching the UI.

## Step ids, in order: &"intro", any CharacterCategory id (see CharacterSelect.categories), &"confirm".
@export var steps: Array[StringName] = [&"intro", &"skin", &"outfit", &"hairstyle", &"eyes", &"confirm"]
## Seconds between one step being completed and the next starting.
@export var step_delay := 0.2

var _index := -1 ## Index into `steps` of the step being played; -1 before the first.

@onready var host := get_parent() as CharacterSelect


func _ready() -> void:
	host.step_completed.connect(_on_completed)
	host.step_back_requested.connect(_on_back)
	host.jump_requested.connect(_go_to)
	_go_to.call_deferred(steps[0])


func current() -> StringName:
	return steps[_index] if _index in range(steps.size()) else &""


func _go_to(id: StringName) -> void:
	var index := steps.find(id)
	if index == -1:
		push_error("CharacterSelectEventManager: no step '%s'" % id)
		return
	_index = index
	host.start_step(id)


func _on_completed(id: StringName) -> void:
	if id != current():
		return
	if _index == steps.size() - 1:
		_index = steps.size() # Nothing is current any more, so input is ignored.
		host.finish()
		return
	_index += 1
	var next := steps[_index]
	get_tree().create_timer(step_delay).timeout.connect(func() -> void:
		if current() == next:
			host.start_step(next))


func _on_back() -> void:
	var index := _index - 1
	if index < 0 or steps[index] == &"intro":
		return
	_go_to(steps[index])
