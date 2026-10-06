class_name WireBoard
extends Control
## The wires game's board (rules in wires.gd): a flat comic drawing of the switch box, cover off.
## Three loose wires on the left (red, blue, yellow, as in the screwdriver's reveal), three sockets
## on the same rows on the right with shuffled coloured rims, and the lever. The lever's ON / OFF
## is the only text (user's call): the player works the rest out, the narrator mocks.
## Only drawing, mouse drag and hit tests live here (no story code), so it can be tested alone.

signal dropped(wire: int, socket: int) ## socket = -1: dropped on nothing.
signal lever_pulled

const FONT := preload("res://assets/fonts/ComicRelief-Bold.ttf")
const COLORS: Array[Color] = [Color(0.9, 0.15, 0.1), Color(0.15, 0.35, 0.95), Color(0.95, 0.8, 0.1)]
const ROWS: Array[float] = [120.0, 215.0, 310.0]
const LEFT_X := 70.0
const STUB := 95.0
const RIGHT_X := 690.0
const METAL := Color(0.42, 0.44, 0.46)
const STRIPE := Color(0.95, 0.75, 0.1)
const LEVER_RED := Color(0.85, 0.12, 0.08)
const BRASS := Color(0.85, 0.66, 0.25)
const INK := Color(0.06, 0.06, 0.07)
const STRIPE_HEIGHT := 46.0
const LEVER_PIVOT := Vector2(380, 407)
const LEVER_LENGTH := 80.0
const LAMP := Vector2(590, 410)

## Colour index of each right socket. Must be a derangement, so straight never matches colours.
@export var socket_order := PackedInt32Array([1, 2, 0])
@export var grab_radius := 34.0
@export var snap_radius := 46.0

var connected := PackedInt32Array([-1, -1, -1]) ## Socket of each wire, -1 = loose.
var lever_ready := false: set = _set_lever_ready
var lever_up := 0.0: set = _set_lever_up ## 0 down (off) .. 1 up (on).
var lamp_on := false: set = _set_lamp_on

var _drag := -1
var _loose: Array[Vector2] = [] ## Where each wire's plug is now.
var _back: Array[Tween] = [null, null, null]
var _pulse := 0.0


func _ready() -> void:
	for i in COLORS.size():
		_loose.append(tip(i))


## Rest position of loose plug `i`.
func tip(i: int) -> Vector2:
	return Vector2(LEFT_X + STUB, ROWS[i] + 16.0)


func anchor(i: int) -> Vector2:
	return Vector2(LEFT_X, ROWS[i])


func socket_pos(j: int) -> Vector2:
	return Vector2(RIGHT_X, ROWS[j])


func lever_rect() -> Rect2:
	return Rect2(LEVER_PIVOT + Vector2(-80.0, -100.0), Vector2(180.0, 150.0))


func plug(wire: int, socket: int) -> void:
	connected[wire] = socket
	_loose[wire] = socket_pos(socket)
	queue_redraw()


## The wire springs back to its rest position.
func snap_back(wire: int) -> void:
	_back[wire] = create_tween()
	_back[wire].tween_method(_move_plug.bind(wire), _loose[wire], tip(wire), 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func all_straight() -> bool:
	return connected == PackedInt32Array([0, 1, 2])


func _gui_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button and button.button_index == MOUSE_BUTTON_LEFT:
		if button.pressed:
			var wire := _free_wire_at(button.position)
			if wire >= 0:
				if _back[wire]:
					_back[wire].kill()
				_drag = wire
				_move_plug(button.position, wire)
				accept_event()
			elif lever_ready and lever_rect().has_point(button.position):
				lever_pulled.emit()
				accept_event()
		elif _drag >= 0:
			var wire := _drag
			_drag = -1
			_move_plug(button.position, wire)
			dropped.emit(wire, _socket_at(button.position))
			accept_event()
	elif event is InputEventMouseMotion and _drag >= 0:
		_move_plug((event as InputEventMouseMotion).position, _drag)


func _process(delta: float) -> void:
	var mouse := get_local_mouse_position()
	var hot := _drag >= 0 or _free_wire_at(mouse) >= 0 or (lever_ready and lever_rect().has_point(mouse))
	mouse_default_cursor_shape = CURSOR_POINTING_HAND if hot else CURSOR_ARROW
	if lever_ready:
		_pulse += delta
		queue_redraw()


## Nearest loose wire whose plug is within `grab_radius` of `at`, else -1.
func _free_wire_at(at: Vector2) -> int:
	var best := -1
	var best_distance := grab_radius
	for wire in COLORS.size():
		var distance := at.distance_to(_loose[wire])
		if connected[wire] < 0 and distance < best_distance:
			best = wire
			best_distance = distance
	return best


## Nearest free socket within `snap_radius` of `at`, else -1.
func _socket_at(at: Vector2) -> int:
	var best := -1
	var best_distance := snap_radius
	for socket in ROWS.size():
		var distance := at.distance_to(socket_pos(socket))
		if not connected.has(socket) and distance < best_distance:
			best = socket
			best_distance = distance
	return best


func _move_plug(at: Vector2, wire: int) -> void:
	_loose[wire] = at
	queue_redraw()


func _set_lever_ready(value: bool) -> void:
	lever_ready = value
	queue_redraw()


func _set_lever_up(value: float) -> void:
	lever_up = value
	queue_redraw()


func _set_lamp_on(value: bool) -> void:
	lamp_on = value
	queue_redraw()


func _draw() -> void:
	var box := Rect2(Vector2.ZERO, size)
	draw_rect(Rect2(Vector2(10.0, 10.0), size), Color(0.0, 0.0, 0.0, 0.6))
	draw_rect(box, METAL)
	draw_line(Vector2(8.0, STRIPE_HEIGHT + 6.0), Vector2(8.0, size.y - 8.0), METAL.lightened(0.25), 4.0)
	_draw_stripe()
	for corner: Vector2 in [Vector2(18, 64), Vector2(size.x - 18, 64), Vector2(18, size.y - 18), Vector2(size.x - 18, size.y - 18)]:
		_draw_bolt(corner, 7.0, METAL.lightened(0.3))
	draw_rect(box, INK, false, 6.0)
	_draw_block(Rect2(LEFT_X - 42.0, 73.0, 84.0, 290.0))
	_draw_block(Rect2(RIGHT_X - 42.0, 73.0, 84.0, 290.0))
	for socket in ROWS.size():
		_draw_socket(socket)
	_draw_sticker()
	_draw_lamp()
	for wire in COLORS.size():
		if wire != _drag:
			_draw_wire(wire)
	if _drag >= 0:
		_draw_wire(_drag)
	for wire in COLORS.size():
		_draw_bolt(anchor(wire), 14.0, BRASS)
	_draw_lever() # In front of the cables, so the knob never hides behind the yellow one.


## Yellow stripe with black hazard diagonals along the top.
func _draw_stripe() -> void:
	var stripe := Rect2(0.0, 0.0, size.x, STRIPE_HEIGHT)
	draw_rect(stripe, STRIPE)
	var clip := PackedVector2Array([stripe.position, Vector2(stripe.end.x, 0.0), stripe.end, Vector2(0.0, stripe.end.y)])
	var x := -STRIPE_HEIGHT
	while x < size.x + STRIPE_HEIGHT:
		var band := PackedVector2Array([Vector2(x, 0.0), Vector2(x + 24.0, 0.0), Vector2(x + 24.0 - STRIPE_HEIGHT, STRIPE_HEIGHT), Vector2(x - STRIPE_HEIGHT, STRIPE_HEIGHT)])
		for part in Geometry2D.intersect_polygons(band, clip):
			draw_colored_polygon(part, INK)
		x += 52.0
	draw_line(Vector2(0.0, STRIPE_HEIGHT), Vector2(size.x, STRIPE_HEIGHT), INK, 5.0)


func _draw_block(rect: Rect2) -> void:
	draw_rect(rect, Color(0.2, 0.21, 0.23))
	draw_rect(rect, INK, false, 4.0)
	_draw_bolt(rect.position + Vector2(rect.size.x / 2.0, 14.0), 6.0, BRASS)
	_draw_bolt(rect.end - Vector2(rect.size.x / 2.0, 14.0), 6.0, BRASS)


func _draw_bolt(at: Vector2, radius: float, color: Color) -> void:
	draw_circle(at, radius + 3.0, INK)
	draw_circle(at, radius, color)
	draw_line(at - Vector2(radius * 0.7, -radius * 0.2), at + Vector2(radius * 0.7, -radius * 0.2), INK, 2.0)


func _draw_socket(socket: int) -> void:
	var at := socket_pos(socket)
	draw_circle(at, 25.0, INK)
	draw_circle(at, 21.0, COLORS[socket_order[socket]])
	draw_arc(at, 17.0, PI * 1.05, PI * 1.55, 8, Color(1.0, 1.0, 1.0, 0.5), 3.0)
	draw_circle(at, 12.0, INK)


func _draw_lever() -> void:
	var base := Rect2(LEVER_PIVOT + Vector2(-64.0, -16.0), Vector2(128.0, 40.0))
	draw_rect(base, Color(0.2, 0.21, 0.23))
	draw_rect(base, INK, false, 4.0)
	draw_string(FONT, LEVER_PIVOT + Vector2(-100.0, 12.0), "ON", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, INK)
	draw_string(FONT, LEVER_PIVOT + Vector2(104.0, 36.0), "OFF", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, INK)
	var angle := lerpf(deg_to_rad(115.0), deg_to_rad(-25.0), lever_up)
	var end := LEVER_PIVOT + Vector2.UP.rotated(angle) * LEVER_LENGTH
	var knob := LEVER_RED if lever_ready or lever_up > 0.0 else LEVER_RED.lerp(Color(0.45, 0.42, 0.42), 0.6)
	if lever_ready:
		var glow := Color(1.0, 0.9, 0.2, 0.55 + 0.45 * sin(_pulse * 8.0))
		draw_line(LEVER_PIVOT, end, glow, 32.0)
		draw_circle(end, 27.0, glow)
	draw_line(LEVER_PIVOT, end, INK, 18.0)
	draw_line(LEVER_PIVOT, end, Color(0.72, 0.72, 0.74), 10.0)
	draw_circle(end, 18.0, INK)
	draw_circle(end, 14.0, knob)
	draw_circle(end + Vector2(-4.0, -5.0), 4.0, knob.lightened(0.5))
	_draw_bolt(LEVER_PIVOT, 9.0, METAL.lightened(0.3))


## Hazard sticker in the bottom-left corner (decoration, no text).
func _draw_sticker() -> void:
	var at := Vector2(120.0, 412.0)
	var triangle := PackedVector2Array([at + Vector2(0.0, -26.0), at + Vector2(28.0, 22.0), at + Vector2(-28.0, 22.0)])
	draw_colored_polygon(triangle, STRIPE)
	triangle.append(triangle[0])
	draw_polyline(triangle, INK, 4.0, true)
	draw_line(at + Vector2(0.0, -12.0), at + Vector2(0.0, 6.0), INK, 6.0)
	draw_circle(at + Vector2(0.0, 14.0), 3.5, INK)


## Power lamp next to the lever: dark red while off, bright green once the power is back.
func _draw_lamp() -> void:
	if lamp_on:
		draw_circle(LAMP, 30.0, Color(0.4, 1.0, 0.4, 0.3))
	draw_circle(LAMP, 15.0, INK)
	draw_circle(LAMP, 11.0, Color(0.45, 1.0, 0.45) if lamp_on else Color(0.3, 0.08, 0.07))
	draw_circle(LAMP + Vector2(-3.0, -4.0), 3.0, Color(1.0, 1.0, 1.0, 0.6))


## A fat cartoon cable from its terminal to its plug, sagging, with a highlight and the plug on top.
func _draw_wire(wire: int) -> void:
	var start := anchor(wire)
	var end := _loose[wire]
	var color := COLORS[wire]
	var reach := maxf(30.0, start.distance_to(end) * 0.35)
	var sag := 10.0 + 0.07 * start.distance_to(end)
	var control_1 := start + Vector2(reach, sag)
	var control_2 := end + Vector2(-reach, sag)
	var points := PackedVector2Array()
	var shine := PackedVector2Array()
	for k in 25:
		var point := start.bezier_interpolate(control_1, control_2, end, k / 24.0)
		points.append(point)
		shine.append(point + Vector2(0.0, -3.0))
	draw_polyline(points, INK, 20.0, true)
	draw_polyline(points, color, 12.0, true)
	draw_polyline(shine, color.lightened(0.45), 3.0, true)
	draw_set_transform(end, (end - control_2).angle())
	if connected[wire] < 0:
		draw_rect(Rect2(-2.0, -7.0, 14.0, 4.0), BRASS)
		draw_rect(Rect2(-2.0, 3.0, 14.0, 4.0), BRASS)
	draw_rect(Rect2(-36.0, -12.0, 36.0, 24.0), color.darkened(0.25))
	draw_rect(Rect2(-14.0, -12.0, 6.0, 24.0), color.lightened(0.3))
	draw_rect(Rect2(-36.0, -12.0, 36.0, 24.0), INK, false, 4.0)
	draw_set_transform(Vector2.ZERO)
