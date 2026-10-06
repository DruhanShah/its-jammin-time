class_name ConfirmLine
extends Resource
## A narrator line for a confirmed character. CharacterSelect plays the first ConfirmLine whose
## `requires` all match the selection.

## Category id -> option id, e.g. {&"hairstyle": &"mohawk"}. Empty matches anything.
@export var requires: Dictionary[StringName, StringName] = {}
## Narrator cue id (res://narration/<cue>.tres).
@export var cue: StringName


func matches(selection: Dictionary[StringName, StringName]) -> bool:
	for category in requires:
		if selection.get(category) != requires[category]:
			return false
	return true
