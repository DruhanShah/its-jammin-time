class_name Controls
## Runtime control remaps. The InputMap is global, so a remap survives scene changes by itself.
## Story derives the shift from the story step (`Story._sync_controls()`): from the third blackout
## (SWITCH_3) on, the movement and interact keys move one key to the right (WASD → ESDF, X → C), by
## physical position so it works on any keyboard layout. Nothing is saved: a restart is back on WASD.
## The HUD prompt follows by itself (`PlayerHud.key_name()`).

## Shifted bindings (physical keycodes). Everything else (touch, ui_*, debug keys) is unchanged.
const SHIFTED := {
	&"move_forward": KEY_E,
	&"move_left": KEY_S,
	&"move_back": KEY_D,
	&"move_right": KEY_F,
	&"interact": KEY_C,
}

static var shifted := false


static func set_shifted(on: bool) -> void:
	if on == shifted:
		return
	shifted = on
	InputMap.load_from_project_settings() # Back to the project defaults (WASD + X).
	if on:
		for action: StringName in SHIFTED:
			InputMap.action_erase_events(action)
			var event := InputEventKey.new()
			event.physical_keycode = SHIFTED[action]
			InputMap.action_add_event(action, event)
	for action: StringName in SHIFTED:
		Input.action_release(action) # A key held during the swap would otherwise stay "pressed".
