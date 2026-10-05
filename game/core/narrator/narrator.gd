extends Node
## Autoload "Narrator": plays narrator cues with subtitles. A new line interrupts the current one.
## Process mode Always (narrator.tscn): lines and subtitles carry on while the tree is paused.

signal line_started(cue_id: StringName)
signal line_finished(cue_id: StringName)

const CUE_DIR := "res://narration/"
## Subtitle-only cues (no audio) stay up for their length at this reading speed, but at least MIN_READ_TIME.
## 15 chars/s sits under Netflix's 17 chars/s adult limit, since the player is also walking around.
const READ_CHARS_PER_SECOND := 15.0
const MIN_READ_TIME := 2.0

var current_cue := &""
var _played: Dictionary[StringName, bool] = {}
var _line_scene_id := 0 ## Instance ID of the scene that was current when the line started.

@onready var voice: AudioStreamPlayer = $Voice
@onready var read_timer: Timer = $ReadTimer
@onready var subtitle_label: Label = $Subtitles/Label


func _ready() -> void:
	voice.finished.connect(_on_line_finished)
	read_timer.timeout.connect(_on_line_finished)
	get_tree().scene_changed.connect(_on_scene_changed)
	subtitle_label.hide()


func play(cue_id: StringName) -> void:
	var path := CUE_DIR + cue_id + ".tres"
	if not ResourceLoader.exists(path):
		push_error("Narrator cue not found: " + path)
		return
	var cue: NarratorCue = load(path)
	if cue.stream == null and cue.subtitle == "":
		push_error("Narrator cue has no audio or subtitle: " + path)
		return
	if cue.once and _played.has(cue_id):
		return
	_played[cue_id] = true
	if current_cue:
		line_finished.emit(current_cue)
	current_cue = cue_id
	_line_scene_id = get_tree().current_scene.get_instance_id() if get_tree().current_scene else 0
	voice.stop()
	read_timer.stop()
	if cue.stream:
		voice.stream = cue.stream
		voice.play()
	else:
		read_timer.start(maxf(MIN_READ_TIME, cue.subtitle.length() / READ_CHARS_PER_SECOND))
	subtitle_label.text = cue.subtitle
	subtitle_label.visible = cue.subtitle != ""
	line_started.emit(cue_id)


func is_speaking() -> bool:
	return voice.playing or not read_timer.is_stopped()


## Cuts the current line short and hides its subtitle.
func stop() -> void:
	if current_cue:
		voice.stop()
		read_timer.stop()
		_on_line_finished()


func _on_scene_changed() -> void:
	# Lines belong to the scene they were cued in; one cued by the new scene's _ready() keeps playing.
	if get_tree().current_scene.get_instance_id() != _line_scene_id:
		stop()


func _on_line_finished() -> void:
	subtitle_label.hide()
	var cue_id := current_cue
	current_cue = &""
	line_finished.emit(cue_id)
