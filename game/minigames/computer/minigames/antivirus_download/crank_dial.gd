class_name CrankDial
extends Control
## The download screen's round spinner: a dark circle with 12 cream dashes (fading round the ring).
## Clicking it (`pressed`) is how the player finds the crank: `engaged` adds a crank arm with a knob.
## `angle` (degrees, clockwise) is where it should point; the drawing eases toward it. `self_spin`
## (degrees per second) spins it on its own (the "now it spins by itself" ending). While not engaged and
## left alone for `idle_pulse_after` seconds it pulses and glows to say "click me". `_draw()` only.

signal pressed

const DARK := Color("#121316")
const CREAM := Color("#efe1bd")
const DASHES := 12

@export var radius := 78.0
@export var idle_pulse_after := 4.0

var angle := 0.0
var engaged := false:
	set(value):
		engaged = value
		queue_redraw()
var self_spin := 0.0

var _shown_angle := 0.0
var _idle := 0.0
var _time := 0.0
var _was_pulsing := false


func _init() -> void:
	mouse_filter = MOUSE_FILTER_STOP
	mouse_default_cursor_shape = CURSOR_POINTING_HAND


func _process(delta: float) -> void:
	_time += delta
	_idle += delta
	if self_spin != 0.0:
		angle += self_spin * delta
	_shown_angle = lerpf(_shown_angle, angle, 1.0 - exp(-delta / 0.08))
	pivot_offset = size / 2.0
	var pulsing := not engaged and _idle >= idle_pulse_after
	if pulsing:
		scale = Vector2.ONE * (1.04 + 0.04 * sin(_time * 6.0))
	elif _was_pulsing:
		scale = Vector2.ONE
	_was_pulsing = pulsing
	queue_redraw()


## A quick scale pop (e.g. when it turns into a crank).
func pop() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE * 1.18, 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.15)


func _gui_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click and click.pressed and click.button_index == MOUSE_BUTTON_LEFT \
			and click.position.distance_to(size / 2.0) <= radius + 8.0:
		_idle = 0.0
		accept_event()
		pressed.emit()


func _has_point(point: Vector2) -> bool:
	return point.distance_to(size / 2.0) <= radius + 8.0


func _draw() -> void:
	var c := size / 2.0
	if not engaged and _idle >= idle_pulse_after:
		var glow := 0.5 + 0.5 * sin(_time * 6.0)
		draw_circle(c, radius + 14.0, Color(1.0, 0.85, 0.4, 0.12 + 0.12 * glow))
	draw_circle(c, radius + 2.0, Color.BLACK) # 5 px outline incl. the rim below.
	draw_circle(c, radius - 3.0, CREAM)
	draw_circle(c, radius - 5.0, DARK)
	var turn := deg_to_rad(_shown_angle)
	for i in DASHES:
		# Dash i trails behind the leading one (i = 0), so the spinner reads as turning clockwise.
		var dir := Vector2.from_angle(turn - TAU * i / DASHES - PI / 2.0)
		var alpha := lerpf(1.0, 0.15, float(i) / (DASHES - 1))
		draw_line(c + dir * radius * 0.42, c + dir * radius * 0.72, Color(CREAM, alpha), 9.0, true)
		draw_circle(c + dir * radius * 0.42, 4.5, Color(CREAM, alpha))
		draw_circle(c + dir * radius * 0.72, 4.5, Color(CREAM, alpha))
	if engaged:
		var tip := c + Vector2.from_angle(turn - PI / 2.0) * radius * 0.88
		draw_line(c, tip, Color.BLACK, 16.0, true)
		draw_line(c, tip, CREAM, 10.0, true)
		draw_circle(c, 13.0, Color.BLACK)
		draw_circle(c, 9.0, Color("#c9b98f"))
		draw_circle(tip, 17.0, Color.BLACK)
		draw_circle(tip, 13.0, Color("#d62828"))
		draw_circle(tip + Vector2(-4, -4), 4.0, Color(1, 1, 1, 0.6))
