extends CanvasLayer
## Autoload "Transition": fades to black, changes scene, fades back in. Use instead of change_scene_to_file.
## Process mode Always (transition.tscn); all input is swallowed while a fade runs.
## Layer 100: above the HUD, below the narrator's subtitles (layer 101) so lines stay readable.

@export var fade_time := 0.3

var _busy := false

@onready var fade: ColorRect = $Fade


func change_scene(path: String) -> void:
	if _busy:
		return
	_busy = true
	await _fade_to(1.0)
	if get_tree().change_scene_to_file(path) == OK:
		await get_tree().scene_changed
	await _fade_to(0.0)
	_busy = false


## True while a fade/scene change runs.
func is_busy() -> bool:
	return _busy


func _input(_event: InputEvent) -> void:
	if _busy:
		get_viewport().set_input_as_handled()


func _fade_to(alpha: float) -> void:
	await create_tween().tween_property(fade, "color:a", alpha, fade_time).finished
