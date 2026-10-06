class_name NarratorCue
extends Resource
## One narrator line. Save as res://narration/<cue_id>.tres and play with Narrator.play(&"<cue_id>").

## Leave empty for a subtitle-only line; it stays on screen for an estimated reading time.
@export var stream: AudioStream
## Long text is shown in short chunks one after another (see narrator.gd); a "|" or a newline forces a break.
@export_multiline var subtitle := ""
## False = no subtitle on screen (the text is shown elsewhere, e.g. a quiz question the narrator reads
## out); the text still sets the reading time of a line without audio.
@export var show_subtitle := true
## If true, the line only ever plays once per game session.
@export var once := false
