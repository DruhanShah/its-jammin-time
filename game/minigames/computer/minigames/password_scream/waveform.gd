extends Control
## Scrolling voice-memo style waveform: `push(level)` adds a bar (0..1) on the right and the history
## scrolls left. `comic` redraws it as a wobbly hand-drawn line. `status` is drawn in the top-left
## corner ("● REC" blinks).

const BARS := 56
const BACKGROUND := Color("#1f2a44")
const BAR_COLOR := Color("#3ee08f")
const COMIC_FILL := Color("#ffd23f")
const FONT := preload("res://assets/fonts/ComicShannsMono-Regular.ttf")

var comic := false:
	set(value):
		comic = value
		queue_redraw()
var status := ""
var status_color := Color("#ff5a4f")
var blink := false

var _levels := PackedFloat32Array()
var _time := 0.0
var _panel := StyleBoxFlat.new()


func _init() -> void:
	custom_minimum_size = Vector2(400, 170)
	mouse_filter = MOUSE_FILTER_IGNORE
	_levels.resize(BARS)
	_panel.bg_color = BACKGROUND
	_panel.border_color = Color.BLACK
	_panel.set_border_width_all(5)
	_panel.set_corner_radius_all(14)
	_panel.anti_aliasing = true


func push(level: float) -> void:
	_levels.remove_at(0)
	_levels.append(clampf(level, 0.0, 1.0))
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	if comic or blink:
		queue_redraw()


func _draw() -> void:
	draw_style_box(_panel, Rect2(Vector2.ZERO, size))
	var mid := size.y / 2.0 + 10.0
	var height := size.y / 2.0 - 26.0
	var step := (size.x - 40.0) / BARS
	if comic:
		var points := PackedVector2Array()
		for i in BARS:
			var side := 1.0 if i % 2 == 0 else -1.0
			var y := mid + side * (6.0 + _levels[i] * height) + sin(_time * 9.0 + i) * 3.0
			points.append(Vector2(20.0 + (i + 0.5) * step + randf_range(-1.5, 1.5), y))
		draw_polyline(points, Color.BLACK, 11.0, true)
		draw_polyline(points, COMIC_FILL, 5.0, true)
	else:
		for i in BARS:
			var half := maxf(2.5, _levels[i] * height)
			var x := 20.0 + (i + 0.5) * step
			draw_line(Vector2(x, mid - half), Vector2(x, mid + half), BAR_COLOR, step * 0.55, true)
	if status and (not blink or fmod(_time, 1.0) < 0.65):
		draw_string(FONT, Vector2(16, 30), status, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, status_color)
