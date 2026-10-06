class_name PlayerHud
extends CanvasLayer
## Crosshair and interaction prompt at the centre of the screen, mini-map at the bottom left
## (`minimap.visible = false` to hide it, e.g. over a close-up).

@onready var crosshair: Panel = $Crosshair
@onready var prompt_label: Label = $Prompt
@onready var minimap: Minimap = $Minimap


## Shows "Press <interact key> to <verb>", or hides the prompt if verb is empty.
func show_prompt(verb: String) -> void:
	prompt_label.text = "Press %s to %s" % [key_name(&"interact"), verb]
	prompt_label.visible = verb != ""
	# Crosshair grows a little while aiming at something interactable.
	crosshair.scale = Vector2.ONE * (1.6 if verb else 1.0)


## Name of the first key bound to an input action (e.g. "X"), so prompts follow remapping.
static func key_name(action: StringName) -> String:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			var key: Key = event.keycode
			if key == KEY_NONE:
				key = DisplayServer.keyboard_get_keycode_from_physical(event.physical_keycode)
			return OS.get_keycode_string(key)
	return String(action)
