class_name FontPickerConfig
extends MinigameConfig
## Tunables for the visit-1 font step in the word processor's font box (any Comic font is accepted).
## Edit font_picker_default.tres. The font list itself is `FONTS` in font_picker.gd.

## From this many wrong picks on, the remaining non-Comic rows wobble.
@export var wobble_after_wrong := 2
## Seconds between picking a Comic font and the step completing (the narrator's line runs on).
@export var accept_delay := 2.2

@export_group("Narrator cues")
## When the word processor opens.
@export var open_cue := &"font_editor_open"
## Every non-Comic pick (repeats).
@export var wrong_cue := &"font_wrong"
## Any Comic pick.
@export var accept_cue := &"font_comic"

@export_group("Sounds")
@export var hover_sfx: AudioStream
@export var hover_db := -12.0
@export var wrong_sfx: AudioStream
@export var accept_sfx: AudioStream
