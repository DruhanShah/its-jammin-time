class_name TwistHint
extends Control
## Teaches the `TwistInput` circle. Drop `core/input/twist_hint.tscn` into any twist game's HUD
## (anchor it where you like; it shrinks toward its bottom-right corner), set `twist`, and set
## `arrow_direction` to the way the game wants (1 = clockwise / screw in, -1 = anticlockwise / unscrew,
## 0 = hide the arrow and demo). Optional `progress` (0..1) draws an arc around G.
## It shows the six keys around G as on the keyboard (named for the player's layout), plays a demo
## (keys lighting up in order) while the player isn't rolling the right way, lights the keys they
## press, and says "Keep going!" / "Other way!" / "Don't stop!". After `mastery_degrees` turned the
## right way it shrinks and fades out of the way; after `stall_time` without progress it comes back.
## The first hint ever shown plays `intro_cue` (a `once` narrator cue).

## The TwistInput to teach (its held keys light up, its twists drive the feedback).
@export var twist: TwistInput
## 1 = clockwise arrow, -1 = anticlockwise, 0 = no arrow (and no demo).
@export var arrow_direction := -1
## 0..1, drawn as an arc around G (0 = hidden).
@export_range(0.0, 1.0) var progress := 0.0
## Degrees turned the right way before the hint gets out of the way.
@export var mastery_degrees := 360.0
## Seconds without a right-way twist before a shrunk hint comes back.
@export var stall_time := 4.0
## Seconds per key in the demo.
@export var demo_step := 0.22
@export var intro_cue := &"twist_tutorial"
@export var radius := 62.0
@export var key_color := Color(0.22, 0.22, 0.26, 0.9)
@export var lit_color := Color(1.0, 0.62, 0.15)
@export var demo_color := Color(0.55, 0.75, 1.0)
@export var arrow_color := Color(1.0, 0.85, 0.3)

const GOOD := Color(0.55, 1.0, 0.55)
const WARN := Color(1.0, 0.7, 0.35)

var _labels: Dictionary[Key, String] = {}
var _good := 0.0 ## Degrees turned the right way since the hint (re)appeared.
var _idle := 0.0 ## Seconds since the last right-way twist.
var _demo_time := 0.0
var _compact := false
var _last_direction := 0 ## Direction of the last twist (1 / -1).
var _tween: Tween

@onready var _feedback: Label = $Feedback


func _ready() -> void:
	for code in TwistInput.RING:
		var local := code if DisplayServer.get_name() == "headless" else DisplayServer.keyboard_get_keycode_from_physical(code)
		_labels[code] = OS.get_keycode_string(local)
	if twist:
		twist.twisted.connect(_on_twisted)
		twist.broken.connect(_on_broken)
	_say("Roll the keys in a circle, following the arrow", Color.WHITE)
	if intro_cue:
		Narrator.play(intro_cue)


func _process(delta: float) -> void:
	_idle += delta
	_demo_time += delta
	if _compact and _idle >= stall_time:
		_set_compact(false)
	pivot_offset = size
	queue_redraw()


func _draw() -> void:
	var center := Vector2(size.x / 2.0, size.x / 2.0)
	var font := get_theme_default_font()
	var key_radius := radius * 0.32
	var demo_key := _demo_key()
	if arrow_direction != 0:
		_draw_arrow(center, radius * 1.55, arrow_direction)
	for code in TwistInput.RING:
		var pos := center + Vector2.UP.rotated(deg_to_rad(TwistInput.key_angle(code))) * radius
		var lit := twist != null and code in twist.held
		var color := lit_color if lit else (demo_color if code == demo_key else key_color)
		draw_circle(pos, key_radius, color)
		_draw_label(font, pos, _labels[code], Color.BLACK if color != key_color else Color.WHITE)
	draw_circle(center, key_radius, Color(0.5, 0.5, 0.55, 0.9))
	if progress > 0.0:
		var dir := arrow_direction if arrow_direction else 1
		draw_arc(center, key_radius + 5.0, -PI / 2.0, -PI / 2.0 + dir * TAU * progress, 32, lit_color, 5.0, true)
	_draw_label(font, center, "G", Color.BLACK)


## The key the demo lights now, or KEY_NONE while the player is rolling the right way (or no arrow).
func _demo_key() -> Key:
	if arrow_direction == 0 or _compact or (_idle < 1.0 and _good > 0.0):
		return KEY_NONE
	var steps := int(_demo_time / demo_step)
	return TwistInput.RING[posmod(3 + arrow_direction * steps, 6)] # Starts at B.


func _on_twisted(delta: float) -> void:
	if arrow_direction == 0:
		return
	_last_direction = signi(int(delta))
	if _last_direction == arrow_direction:
		_good += absf(delta)
		_idle = 0.0
		_say("Keep going!", GOOD)
		if _good >= mastery_degrees and not _compact:
			_set_compact(true)
	else:
		_say("Other way! Follow the arrow.", WARN)


func _on_broken() -> void:
	if _last_direction == arrow_direction and not _compact and _good < mastery_degrees:
		_say("Don't stop: keep the keys rolling round.", WARN)


## Shrunk + faded toward the bottom-right corner (true) or full size (false).
func _set_compact(on: bool) -> void:
	_compact = on
	if not on:
		_good = 0.0
		_demo_time = 0.0
		_say("Roll the keys in a circle, following the arrow", Color.WHITE)
	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel().set_trans(Tween.TRANS_SINE)
	_tween.tween_property(self, "scale", Vector2.ONE * (0.5 if on else 1.0), 0.4)
	_tween.tween_property(self, "modulate:a", 0.45 if on else 1.0, 0.4)
	_tween.tween_property(_feedback, "modulate:a", 0.0 if on else 1.0, 0.4)


func _say(text: String, color: Color) -> void:
	_feedback.text = text
	_feedback.add_theme_color_override(&"font_color", color)


## A 120° arc outside the keys with an arrowhead, going clockwise (1) or anticlockwise (-1).
func _draw_arrow(center: Vector2, r: float, dir: int) -> void:
	var start := -PI / 2.0 - dir * PI / 3.0
	var end := -PI / 2.0 + dir * PI / 3.0
	draw_arc(center, r, start, end, 24, arrow_color, 6.0, true)
	var tip := center + Vector2.from_angle(end) * r
	var along := Vector2.from_angle(end + dir * PI / 2.0) # Tangent in the direction of travel.
	var side := Vector2.from_angle(end)
	draw_colored_polygon(PackedVector2Array([tip + along * 16.0, tip - along * 4.0 + side * 12.0, tip - along * 4.0 - side * 12.0]), arrow_color)


func _draw_label(font: Font, pos: Vector2, text: String, color: Color) -> void:
	var size_px := int(radius * 0.32)
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px)
	draw_string(font, pos + Vector2(-text_size.x / 2.0, text_size.y / 4.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, color)
