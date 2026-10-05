extends Node
## Autoload "Narrator": plays narrator cues with subtitles. A new line interrupts the current one.

signal line_started(cue_id: StringName)
signal line_finished(cue_id: StringName)

const CUE_DIR := "res://narration/"

var current_cue := &""
var _played: Dictionary[StringName, bool] = {}

@onready var voice: AudioStreamPlayer = $Voice
@onready var subtitle_label: Label = $Subtitles/Label


func _ready() -> void:
	voice.finished.connect(_on_voice_finished)
	subtitle_label.hide()


func play(cue_id: StringName) -> void:
	var path := CUE_DIR + cue_id + ".tres"
	if not ResourceLoader.exists(path):
		push_error("Narrator cue not found: " + path)
		return
	var cue: NarratorCue = load(path)
	if cue.stream == null:
		push_error("Narrator cue has no audio stream: " + path)
		return
	if cue.once and _played.has(cue_id):
		return
	_played[cue_id] = true
	if current_cue:
		line_finished.emit(current_cue)
	current_cue = cue_id
	voice.stream = cue.stream
	voice.play()
	subtitle_label.text = cue.subtitle
	subtitle_label.visible = cue.subtitle != ""
	line_started.emit(cue_id)


func is_speaking() -> bool:
	return voice.playing


func _on_voice_finished() -> void:
	subtitle_label.hide()
	var cue_id := current_cue
	current_cue = &""
	line_finished.emit(cue_id)
