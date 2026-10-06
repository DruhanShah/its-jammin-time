extends Control
## Placeholder for a switch game that isn't built yet (see switch_games.gd): one big button beats the
## current one (`Story.switch_game()`) and moves on to the next game's scene, or back to the office
## once the power is back. Esc leaves without fixing anything (progress so far is kept).

@export var flip_sound: AudioStream = preload("res://assets/audio/sfx/400_sounds_pack/click_double_on.wav")

var _game := &""


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_game = Story.switch_game()
	if _game:
		$Center/Box/Title.text = "The Switch: %s" % _game
	$Center/Box/FlipButton.pressed.connect(_flip)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Transition.change_scene(Story.OFFICE)


func _flip() -> void:
	Audio.play_sfx(flip_sound)
	if _game:
		Story.switch_game_done(_game)
	else:
		GameState.set_power(true) # Opened outside a switch step (e.g. run on its own).
	Transition.change_scene(Story.next_switch_scene())
