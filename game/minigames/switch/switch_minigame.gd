extends Control
## Placeholder for the switch minigames (each switch will be its own minigame later). The big button
## restores the power and goes back to where you were; Esc leaves without fixing anything.

@export_file("*.tscn") var return_scene := "res://world/office/office.tscn"
@export var flip_sound: AudioStream = preload("res://assets/audio/sfx/400_sounds_pack/click_double_on.wav")


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	$Center/Box/FlipButton.pressed.connect(_flip)
	Narrator.play(&"switch_minigame")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Transition.change_scene(return_scene)


func _flip() -> void:
	Audio.play_sfx(flip_sound)
	GameState.set_power(true)
	Transition.change_scene(return_scene)
