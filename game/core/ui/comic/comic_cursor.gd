class_name ComicCursor
## Cartoon glove mouse cursor (our own drawing, `cursor/glove*.svg`): a tilted pointing glove as the
## arrow, an upright one over anything clickable (Controls with `mouse_default_cursor_shape` =
## Pointing Hand, e.g. buttons). Call `apply()` when a comic screen opens and `reset()` when it closes,
## so the 3D office keeps the system cursor.

const ARROW := preload("res://core/ui/comic/cursor/glove.svg")
const POINTING := preload("res://core/ui/comic/cursor/glove_tap.svg")
## Fingertips in the 60 px images.
const ARROW_HOTSPOT := Vector2(7, 3)
const POINTING_HOTSPOT := Vector2(26, 4)


static func apply() -> void:
	Input.set_custom_mouse_cursor(ARROW, Input.CURSOR_ARROW, ARROW_HOTSPOT)
	Input.set_custom_mouse_cursor(POINTING, Input.CURSOR_POINTING_HAND, POINTING_HOTSPOT)


static func reset() -> void:
	Input.set_custom_mouse_cursor(null, Input.CURSOR_ARROW)
	Input.set_custom_mouse_cursor(null, Input.CURSOR_POINTING_HAND)
