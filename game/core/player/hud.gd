class_name PlayerHud
extends CanvasLayer
## Crosshair and interaction prompt at the centre of the screen.

@onready var crosshair: Panel = $Crosshair
@onready var prompt_label: Label = $Prompt


func show_prompt(text: String) -> void:
	prompt_label.text = text
	prompt_label.visible = text != ""
	# Crosshair grows a little while aiming at something interactable.
	crosshair.scale = Vector2.ONE * (1.6 if text else 1.0)
