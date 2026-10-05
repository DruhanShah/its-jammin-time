class_name NarratorCue
extends Resource
## One narrator line. Save as res://narration/<cue_id>.tres and play with Narrator.play(&"<cue_id>").

@export var stream: AudioStream
@export_multiline var subtitle := ""
## If true, the line only ever plays once per game session.
@export var once := false
