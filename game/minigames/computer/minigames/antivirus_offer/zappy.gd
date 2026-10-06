class_name Zappy
extends Control
## "Zappy", ZappWare's mascot: a blue shield with a yellow lightning bolt and angry googly eyes that
## follow the mouse. Drawn with `_draw()` only; rocks ±4° on its own.

const SHIELD := Color("#3a7bff")
const SHIELD_DARK := Color("#2457c9")
const BOLT := Color("#ffd23f")
const OUTLINE := Color.BLACK

## Shield outline in a 100 × 120 box (scaled to the control's size).
const SHIELD_POINTS: Array[Vector2] = [
	Vector2(50, 4), Vector2(66, 12), Vector2(94, 14), Vector2(94, 52), Vector2(88, 78),
	Vector2(72, 100), Vector2(50, 116), Vector2(28, 100), Vector2(12, 78), Vector2(6, 52), Vector2(6, 14), Vector2(34, 12),
]
const BOLT_POINTS: Array[Vector2] = [
	Vector2(58, 50), Vector2(38, 82), Vector2(50, 82), Vector2(42, 110), Vector2(70, 72), Vector2(56, 72), Vector2(64, 50),
]

var _time := 0.0


func _init() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_time += delta
	pivot_offset = size / 2.0
	rotation = deg_to_rad(4.0) * sin(_time * 2.6)
	queue_redraw()


func _draw() -> void:
	var k := minf(size.x / 100.0, size.y / 120.0)
	var origin := (size - Vector2(100, 120) * k) / 2.0
	var shield := _scaled(SHIELD_POINTS, k, origin)
	_shape(shield, SHIELD, 5.0)
	# A darker right half for some depth.
	var half := PackedVector2Array([shield[0], shield[1], shield[2], shield[3], shield[4], shield[5], shield[6]])
	draw_colored_polygon(half, SHIELD_DARK)
	_outline(shield, 5.0)
	_shape(_scaled(BOLT_POINTS, k, origin), BOLT, 4.0)
	# Angry googly eyes, pupils toward the mouse.
	var mouse := get_local_mouse_position()
	for side in [-1.0, 1.0]:
		var eye := origin + Vector2(50.0 + side * 19.0, 36.0) * k
		var r := 13.0 * k
		draw_circle(eye, r, Color.WHITE)
		draw_arc(eye, r, 0.0, TAU, 32, OUTLINE, 3.0, true)
		var look := (mouse - eye).limit_length(r * 0.45)
		draw_circle(eye + look, r * 0.45, OUTLINE)
		# Eyebrow slanting down toward the middle.
		var inner := eye + Vector2(-side * r * 0.9, -r * 1.05)
		var outer := eye + Vector2(side * r * 1.1, -r * 1.65)
		draw_line(outer, inner, OUTLINE, 5.0 * k, true)


func _scaled(points: Array[Vector2], k: float, origin: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in points:
		out.append(origin + p * k)
	return out


func _shape(points: PackedVector2Array, fill: Color, width: float) -> void:
	draw_colored_polygon(points, fill)
	_outline(points, width)


func _outline(points: PackedVector2Array, width: float) -> void:
	var loop := points.duplicate()
	loop.append(points[0])
	draw_polyline(loop, OUTLINE, width, true)
