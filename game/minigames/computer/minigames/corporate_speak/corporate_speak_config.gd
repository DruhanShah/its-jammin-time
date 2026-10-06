class_name CorporateSpeakConfig
extends MinigameConfig
## Tunables for the fill-in-the-blank memo. Edit corporate_speak_default.tres.

## One sentence is picked at random each time. Write each blank as {word:points|word:points|...}:
##   Let's {circle back:10|talk again:2|give up:-5} on this {offline:10|later:2}.
## Words can contain spaces. Points can be negative; a word without ":points" is worth 0.
@export var sentences: Array[String] = []
## Show each blank's options in a random order (otherwise in the order written).
@export var shuffle_options := true
## Add the finished sentence to the document being typed.
@export var append_to_document := true
## Seconds the scored result stays on screen before the memo closes.
@export var result_display_time := 2.5
@export var choose_sfx: AudioStream
@export var submit_sfx: AudioStream
