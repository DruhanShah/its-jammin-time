extends Control
## Stand-in for a minigame that isn't built yet. Esc, X or the button returns to the office.

@export_file("*.tscn") var return_scene := "res://world/office/office.tscn"


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	$Center/Box/BackButton.pressed.connect(_go_back)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("interact"):
		_go_back()


func _go_back() -> void:
	get_tree().change_scene_to_file(return_scene)
