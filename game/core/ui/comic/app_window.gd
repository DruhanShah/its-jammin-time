@tool
class_name AppWindow
extends Container
## A comic-style app window for the computer: thick black outline, off-white paper body, a coloured
## title bar in Comic Relief Bold with a close X, a solid offset shadow, squash-and-stretch pop in/out
## and a "POOF!" burst when it closes. Draggable by the title bar.
##
## It's a container: put the app's content as its children (in a scene or from code) and they fill
## the body. A minigame stays a `Minigame` and simply contains an AppWindow:
##   Minigame (root) → AppWindow → your content (a VBoxContainer, ...)
## Call `pop_in()` when the minigame begins and `close()` (or let the X do it) when it ends; listen to
## `closed` to finish (e.g. `window.closed.connect(complete)`).
## For close-button gags set `auto_close = false`: the X then only emits `close_requested`.

## The X was pressed (always emitted, also when `auto_close` closes the window right after).
signal close_requested
## The close animation finished; the window is hidden now (not freed).
signal closed

const TITLE_FONT := preload("res://assets/fonts/ComicRelief-Bold.ttf")
const OPEN_SOUND := preload("res://assets/audio/sfx/400_sounds_pack/pop_2.wav")
const CLOSE_SOUND := preload("res://assets/audio/sfx/400_sounds_pack/whoosh_1.wav")

@export var title := "Untitled":
	set(value):
		title = value
		update_minimum_size()
		queue_redraw()
@export var title_color := Color("#ffd23f"):
	set(value):
		title_color = value
		_restyle()
@export var paper_color := Color("#fff8e7"):
	set(value):
		paper_color = value
		_restyle()
@export var title_font_size := 22:
	set(value):
		title_font_size = value
		_restyle()
@export var title_height := 44.0:
	set(value):
		title_height = value
		_restyle()
## Space between the window's edge and its content.
@export var padding := 18.0:
	set(value):
		padding = value
		queue_sort()
@export var outline_width := 4:
	set(value):
		outline_width = value
		_restyle()
@export var shadow_offset := Vector2(9, 9):
	set(value):
		shadow_offset = value
		queue_redraw()
## Show the X.
@export var closable := true:
	set(value):
		closable = value
		if _close_button:
			_close_button.visible = value
## The X closes the window by itself. Off: it only emits `close_requested` (for gags).
@export var auto_close := true
@export var draggable := true
## Word in the burst when the window closes; empty = no burst.
@export var close_word := "POOF!"
@export var sounds := true

var _close_button: Button
var _body_style := StyleBoxFlat.new()
var _bar_style := StyleBoxFlat.new()
var _shadow_style := StyleBoxFlat.new()
var _dragging := false
var _closing := false
var _tween: Tween


func _init() -> void:
	mouse_filter = MOUSE_FILTER_STOP
	_close_button = Button.new()
	_close_button.text = "X"
	_close_button.focus_mode = FOCUS_NONE
	_close_button.mouse_default_cursor_shape = CURSOR_POINTING_HAND
	_close_button.add_theme_font_override(&"font", TITLE_FONT)
	_close_button.pressed.connect(_on_close_pressed)
	add_child(_close_button, false, INTERNAL_MODE_FRONT)
	_restyle()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_SORT_CHILDREN:
			var side := title_height - 12.0
			fit_child_in_rect(_close_button, Rect2(size.x - side - 7.0, 6.0, side, side))
			for child in get_children():
				var control := child as Control
				if control and control.visible and not control.top_level:
					fit_child_in_rect(control, _body_rect())
		NOTIFICATION_RESIZED:
			pivot_offset = size / 2.0


func _get_minimum_size() -> Vector2:
	var content := Vector2.ZERO
	for child in get_children():
		var control := child as Control
		if control and control.visible and not control.top_level:
			content = content.max(control.get_combined_minimum_size())
	var title_width := TITLE_FONT.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, title_font_size).x + title_height + 40.0
	return Vector2(maxf(content.x + padding * 2.0, title_width), content.y + title_height + padding * 2.0)


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_style_box(_shadow_style, Rect2(shadow_offset, size))
	draw_style_box(_body_style, rect)
	draw_style_box(_bar_style, Rect2(Vector2.ZERO, Vector2(size.x, title_height)))
	var baseline_y := (title_height + TITLE_FONT.get_ascent(title_font_size) - TITLE_FONT.get_descent(title_font_size)) / 2.0
	draw_string(TITLE_FONT, Vector2(16.0, baseline_y), title, HORIZONTAL_ALIGNMENT_LEFT, size.x - title_height - 30.0, title_font_size, Color.BLACK)


## Squash-and-stretch entrance (also shows the window).
func pop_in() -> void:
	_closing = false
	show()
	_kill_tween()
	scale = Vector2(0.3, 0.3)
	modulate.a = 0.0
	if sounds:
		Audio.play_sfx(OPEN_SOUND, -4.0)
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 1.0, 0.08)
	_tween.parallel().tween_property(self, "scale", Vector2(1.12, 0.9), 0.13).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "scale", Vector2(0.95, 1.06), 0.09).set_trans(Tween.TRANS_SINE)
	_tween.tween_property(self, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Squashes the window away with a burst word (`word`, default `close_word`), then hides it and emits `closed`.
func close(word := "") -> void:
	if _closing or not visible:
		return
	_closing = true
	_dragging = false
	_kill_tween()
	if sounds:
		Audio.play_sfx(CLOSE_SOUND, -2.0)
	var burst_word := word if word else close_word
	if burst_word and get_parent():
		ComicBurst.spawn(get_parent(), get_global_rect().get_center(), burst_word)
	_tween = create_tween()
	_tween.tween_property(self, "scale", Vector2(1.12, 0.88), 0.07).set_trans(Tween.TRANS_SINE)
	_tween.tween_property(self, "scale", Vector2(0.05, 1.25), 0.13).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	_tween.parallel().tween_property(self, "modulate:a", 0.0, 0.13).set_ease(Tween.EASE_IN)
	_tween.tween_callback(_finish_close)


## A quick sideways shake ("no!"), e.g. when the X refuses to work.
func shake(strength := 10.0) -> void:
	if _closing:
		return
	_kill_tween()
	var home := position
	_tween = create_tween()
	for i in 6:
		var dir := 1.0 if i % 2 == 0 else -1.0
		_tween.tween_property(self, "position:x", home.x + dir * strength * (1.0 - i / 6.0), 0.04)
	_tween.tween_property(self, "position:x", home.x, 0.04)


func _gui_input(event: InputEvent) -> void:
	if not draggable or _closing:
		return
	var button := event as InputEventMouseButton
	if button and button.button_index == MOUSE_BUTTON_LEFT:
		_dragging = button.pressed and button.position.y <= title_height
		accept_event()
	var motion := event as InputEventMouseMotion
	if motion and _dragging:
		var area := get_parent_area_size()
		position = (position + motion.relative).clamp(-size * 0.5, area - size * 0.5)
		accept_event()


func _on_close_pressed() -> void:
	close_requested.emit()
	if auto_close:
		close()


func _finish_close() -> void:
	hide()
	scale = Vector2.ONE
	modulate.a = 1.0
	closed.emit()


func _kill_tween() -> void:
	if _tween:
		_tween.kill()


func _body_rect() -> Rect2:
	return Rect2(Vector2(padding, title_height + padding), (size - Vector2(padding * 2.0, title_height + padding * 2.0)).max(Vector2.ZERO))


func _restyle() -> void:
	for style: StyleBoxFlat in [_body_style, _bar_style]:
		style.border_color = Color.BLACK
		style.set_border_width_all(outline_width)
		style.anti_aliasing = true
	_body_style.bg_color = paper_color
	_body_style.set_corner_radius_all(12)
	_bar_style.bg_color = title_color
	_bar_style.corner_radius_top_left = 12
	_bar_style.corner_radius_top_right = 12
	_shadow_style.bg_color = Color(0, 0, 0, 0.85)
	_shadow_style.set_corner_radius_all(12)
	if _close_button:
		var normal := _button_style(Color("#ff4d4d"))
		_close_button.add_theme_stylebox_override(&"normal", normal)
		_close_button.add_theme_stylebox_override(&"hover", _button_style(Color("#ff7a6b")))
		_close_button.add_theme_stylebox_override(&"pressed", _button_style(Color("#d92b2b")))
		_close_button.add_theme_stylebox_override(&"focus", StyleBoxEmpty.new())
		_close_button.add_theme_color_override(&"font_color", Color.WHITE)
		_close_button.add_theme_color_override(&"font_hover_color", Color.WHITE)
		_close_button.add_theme_color_override(&"font_pressed_color", Color.WHITE)
		_close_button.add_theme_color_override(&"font_outline_color", Color.BLACK)
		_close_button.add_theme_constant_override(&"outline_size", 6)
		_close_button.add_theme_font_size_override(&"font_size", title_font_size - 2)
	update_minimum_size()
	queue_sort()
	queue_redraw()


func _button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color.BLACK
	style.set_border_width_all(3)
	style.set_corner_radius_all(8)
	style.anti_aliasing = true
	return style
