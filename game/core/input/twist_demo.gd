extends Control
## Try `TwistInput`: roll T Y H B V F around G. The needle follows the total turn.

const DIAL_RADIUS := 150.0

var _flash := 0.0
## What each ring key is called on this keyboard layout.
var _labels: Dictionary[Key, String] = {}

@onready var _twist: TwistInput = $TwistInput
@onready var _info: Label = $Info


func _ready() -> void:
	for code in TwistInput.RING:
		var local := code if DisplayServer.get_name() == "headless" else DisplayServer.keyboard_get_keycode_from_physical(code)
		_labels[code] = OS.get_keycode_string(local)
	_twist.twisted.connect(func(_d: float) -> void: _flash = 1.0)
	_twist.broken.connect(func() -> void: _flash = 0.0)


func _process(delta: float) -> void:
	_flash = move_toward(_flash, 0.0, delta * 3.0)
	var turning := {1: "clockwise (screw in)", -1: "anticlockwise (unscrew)", 0: "-"}
	_info.text = "Total: %d°  (%.2f turns)\nStreak: %d°\nDirection: %s\nR: reset" % [
		_twist.total_degrees, _twist.rotations, _twist.streak_degrees, turning[_twist.direction]]
	queue_redraw()


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_pressed() and (event as InputEventKey).physical_keycode == KEY_R:
		_twist.reset()


func _draw() -> void:
	var center := size / 2.0
	var font := get_theme_default_font()
	draw_circle(center, DIAL_RADIUS, Color(0.15, 0.15, 0.2))
	draw_arc(center, DIAL_RADIUS, 0.0, TAU, 64, Color(0.5, 0.5, 0.6), 3.0)
	var needle := Vector2.UP.rotated(deg_to_rad(_twist.total_degrees)) * DIAL_RADIUS * 0.8
	draw_line(center, center + needle, Color.ORANGE.lerp(Color.WHITE, _flash), 6.0)
	draw_circle(center, 24.0, Color.ORANGE)
	for code in TwistInput.RING:
		var pos := center + Vector2.UP.rotated(deg_to_rad(TwistInput.key_angle(code))) * (DIAL_RADIUS + 50.0)
		draw_circle(pos, 28.0, Color.ORANGE if code in _twist.held else Color(0.3, 0.3, 0.35))
		_draw_label(font, pos, _labels[code])
	_draw_label(font, center, "G", Color.BLACK)


func _draw_label(font: Font, pos: Vector2, text: String, color := Color.WHITE) -> void:
	var size_px := 28
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px)
	draw_string(font, pos + Vector2(-text_size.x / 2.0, text_size.y / 4.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, color)
