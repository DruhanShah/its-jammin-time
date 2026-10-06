extends Control
## Ending: the player put the glasses on and sees the real world: a full-screen video filmed in real
## life (`video`, an Ogg Theora .ogv; see docs/plans/ending.md for how to swap in the real one). The
## video keeps its aspect ratio on black bars. When it ends (or Esc), the credits roll.

const CREDITS := "res://ending/credits.tscn"

## Seconds before Esc may skip, so a key still held from the office can't skip it by accident.
const SKIP_DELAY := 1.0

@onready var _video: VideoStreamPlayer = %Video
@onready var _frame: AspectRatioContainer = %Frame

var _age := 0.0
var _done := false


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	Audio.stop_music()
	Narrator.stop()
	_video.finished.connect(_finish)
	_video.play()


func _process(delta: float) -> void:
	_age += delta
	var texture := _video.get_video_texture()
	if texture and texture.get_height() > 0:
		_frame.ratio = float(texture.get_width()) / texture.get_height()


func _unhandled_input(event: InputEvent) -> void:
	if _age >= SKIP_DELAY and event.is_action_pressed(&"ui_cancel"):
		_finish()


func _finish() -> void:
	if _done:
		return
	_done = true
	Transition.change_scene(CREDITS)
