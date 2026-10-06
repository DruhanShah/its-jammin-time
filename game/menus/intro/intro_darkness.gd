extends Control
## The black screen after the character is destroyed: the narrator's opening line ("You've finally
## come to...", cue `story_intro`) over warm, comforting darkness, then the game proper begins at the
## computer (the password screen). Click, Enter or Space skips the line.

## Seconds of silent black before the line, and after it.
@export var lead_in := 1.0
@export var hold := 0.6

var _leaving := false


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	await get_tree().create_timer(lead_in).timeout
	Narrator.play(&"story_intro")
	if Narrator.current_cue == &"story_intro" and Narrator.is_speaking():
		await Narrator.line_finished
	await get_tree().create_timer(hold).timeout
	_wake()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_accept") or (event is InputEventMouseButton and event.pressed):
		get_viewport().set_input_as_handled()
		Narrator.stop() # Ends the line, which moves on.


## The office would send a fresh start straight to the computer; go there directly instead (Story
## then knows the intro was handled, and its own story_intro call is skipped: the cue is `once`).
## Anything else (not a fresh start) goes to the office.
func _wake() -> void:
	if _leaving:
		return
	_leaving = true
	Transition.change_scene(Computer.SCENE if Story.take_fresh_start() else Story.OFFICE)
