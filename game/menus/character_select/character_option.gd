class_name CharacterOption
extends Resource
## One pick in a character select category (a hairstyle, an outfit, a skin...).

## What confirm lines and the random preset refer to, e.g. &"bob".
@export var id: StringName
## Shown between the arrows.
@export var display_name := ""
## The layer drawn in the preview. Leave empty until the art exists; `placeholder_color` is drawn instead.
@export var texture: Texture2D
@export var placeholder_color := Color.WHITE
