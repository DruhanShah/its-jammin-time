class_name SpeechBubble
extends Control
## A comic speech balloon over a 3D point (e.g. a gargoyle's head): off-white paper, thick black
## outline, solid offset shadow, the speaker's name tag in Comic Relief Bold and a tail pointing at
## the point. Follows it every frame (`Camera3D.unproject_position`), hides while it's behind the camera.
## Lives on a CanvasLayer; fill the screen with it (it ignores the mouse).

const NAME_FONT := preload("res://assets/fonts/ComicRelief-Bold.ttf")
const PAPER := Color("#fff8e7")
const TEXT_WIDTH := 330.0
## Gap between the balloon's bottom and the point it talks from.
const LIFT := 46.0
const MARGIN := 12.0
const SHADOW := Vector2(7, 7)
const TAIL_HALF_WIDTH := 16.0

var anchor: Node3D
## Shifts the balloon sideways from the point (-1 left ... 1 right), so two speakers' balloons don't overlap.
var lean := 0.0
var _panel := PanelContainer.new()
var _name_label := Label.new()
var _text_label := Label.new()
var _tail_cover := Control.new() ## Draws the tail's fill over the panel's outline, so they join.
var _tip := Vector2.ZERO
var _base := Vector2.ZERO
var _pop: Tween


func _init() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	set_anchors_preset(PRESET_FULL_RECT)
	var style := StyleBoxFlat.new()
	style.bg_color = PAPER
	style.border_color = Color.BLACK
	style.set_border_width_all(4)
	style.set_corner_radius_all(22)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 10
	style.content_margin_bottom = 14
	style.shadow_color = Color(0, 0, 0, 0.85)
	style.shadow_offset = SHADOW
	_panel.add_theme_stylebox_override(&"panel", style)
	_panel.mouse_filter = MOUSE_FILTER_IGNORE
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 0)
	_name_label.add_theme_font_override(&"font", NAME_FONT)
	_name_label.add_theme_font_size_override(&"font_size", 17)
	_name_label.add_theme_color_override(&"font_color", Color("#c0392b"))
	_text_label.add_theme_font_size_override(&"font_size", 23)
	_text_label.add_theme_color_override(&"font_color", Color("#1a1a1a"))
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.custom_minimum_size.x = TEXT_WIDTH
	box.add_child(_name_label)
	box.add_child(_text_label)
	_panel.add_child(box)
	add_child(_panel)
	_tail_cover.mouse_filter = MOUSE_FILTER_IGNORE
	_tail_cover.draw.connect(_draw_tail_fill)
	add_child(_tail_cover)
	hide()


## Shows `text` from `speaker` (name tag) pointing at `point`, with a little pop.
func say(speaker: String, text: String, point: Node3D) -> void:
	anchor = point
	_name_label.text = speaker
	_text_label.text = text
	_panel.reset_size()
	show()
	_follow()
	_panel.pivot_offset = Vector2(_panel.size.x / 2.0, _panel.size.y)
	_panel.scale = Vector2.ONE * 0.6
	if _pop:
		_pop.kill()
	_pop = create_tween()
	_pop.tween_property(_panel, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _process(_delta: float) -> void:
	if visible:
		_follow()


func _follow() -> void:
	var camera := get_viewport().get_camera_3d()
	if not camera or not is_instance_valid(anchor) or camera.is_position_behind(anchor.global_position):
		_panel.visible = false
		queue_redraw()
		_tail_cover.queue_redraw()
		return
	_panel.visible = true
	_panel.reset_size() # The wrapped text's height settles a frame after the text changes.
	var screen := get_viewport_rect().size
	_tip = camera.unproject_position(anchor.global_position)
	var top_left := _tip - Vector2(_panel.size.x * (0.5 - lean * 0.4), _panel.size.y + LIFT)
	top_left.x = clampf(top_left.x, MARGIN, screen.x - _panel.size.x - MARGIN - SHADOW.x)
	top_left.y = clampf(top_left.y, MARGIN, screen.y - _panel.size.y - MARGIN - SHADOW.y)
	_panel.position = top_left
	var bottom := top_left.y + _panel.size.y
	_base = Vector2(clampf(_tip.x, top_left.x + 40.0, top_left.x + _panel.size.x - 40.0), bottom)
	queue_redraw()
	_tail_cover.queue_redraw()


func _tail(inset: float, grow: float) -> PackedVector2Array:
	var tip := _tip.move_toward(_base, 14.0)
	if tip.y < _base.y + 10.0:
		tip.y = _base.y + 10.0 # Never point back up into the balloon.
	return PackedVector2Array([
		_base + Vector2(-TAIL_HALF_WIDTH - grow, -inset),
		_base + Vector2(TAIL_HALF_WIDTH + grow, -inset),
		tip + Vector2(0, grow),
	])


## Outline + shadow of the tail, under the panel.
func _draw() -> void:
	if not _panel.visible:
		return
	var shadow := _tail(8.0, 4.0)
	for i in shadow.size():
		shadow[i] += SHADOW
	draw_colored_polygon(shadow, Color(0, 0, 0, 0.85))
	draw_colored_polygon(_tail(8.0, 4.5), Color.BLACK)


## Paper fill of the tail, over the panel's bottom border.
func _draw_tail_fill() -> void:
	if _panel.visible:
		_tail_cover.draw_colored_polygon(_tail(10.0, -0.5), PAPER)
