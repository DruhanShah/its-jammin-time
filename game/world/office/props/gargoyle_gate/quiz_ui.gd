class_name QuizUI
extends CanvasLayer
## The gargoyle quiz's game-show screen (layout in quiz_ui.tscn, comic styling here): question bar,
## four answers, FINAL ANSWER, WALK AWAY, the prize plate, one big PHONE A FRIEND lifeline and the "timer" dial that
## only ever shows nonsense. No game rules: gargoyle_gate.gd listens to the signals and calls back.
## Keys while it's up: 1-4 / A-D pick, Enter locks in (a second click on the picked answer does too).
## A wrong answer stays red and can't be picked again; the others can (`resume_picking()`).

signal answer_selected(index: int)
signal answer_locked(index: int)
signal lifeline_used(lifeline: StringName)
signal walk_away

const HEAD_FONT := preload("res://assets/fonts/ComicRelief-Bold.ttf")
const NAVY := Color("#1d1f5c")
const GOLD := Color("#f5c518")
const ORANGE := Color("#ff9f1c")
const GREEN := Color("#2bb34a")
const RED := Color("#e0372b")
const LETTERS := ["A", "B", "C", "D"]
const KEYS := {KEY_1: 0, KEY_2: 1, KEY_3: 2, KEY_4: 3, KEY_A: 0, KEY_B: 1, KEY_C: 2, KEY_D: 3}

enum Look { NORMAL, SELECTED, CORRECT, WRONG }

## Accepting picks (false while locked in / revealing).
var accepting := false
var selected := -1
var _answers: Array[Button] = []
var _dial_text := ""
var _dial_arc := 0.6
var _slide: Tween

@onready var _root: Control = $Root
@onready var _title: Label = $Root/Title
@onready var _prize: Label = $Root/Prize
@onready var _question: Label = $Root/Strip/Question
@onready var _final: Button = $Root/Strip/Bottom/Final
@onready var _walk: Button = $Root/Strip/Bottom/WalkAway
@onready var _dial: Control = $Root/Dial
@onready var _lifelines: Dictionary[StringName, Button] = {&"phone": $Root/Lifelines/Phone}


func _ready() -> void:
	for letter in LETTERS:
		var button: Button = get_node("Root/Strip/Answers/" + letter)
		_answers.append(button)
		button.pressed.connect(_on_answer_pressed.bind(_answers.size() - 1))
	_style_all()
	_final.pressed.connect(func() -> void: if accepting and selected >= 0: _lock())
	_walk.pressed.connect(walk_away.emit)
	for id in _lifelines:
		_lifelines[id].pressed.connect(_on_lifeline.bind(id))
	_dial.draw.connect(_draw_dial)


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not accepting or not (event is InputEventKey and event.pressed and not event.echo):
		return
	var key: Key = event.keycode
	if KEYS.has(key):
		_on_answer_pressed(KEYS[key], true)
		get_viewport().set_input_as_handled()
	elif key in [KEY_ENTER, KEY_KP_ENTER] and selected >= 0:
		_lock()
		get_viewport().set_input_as_handled()


## Shows question `q` (`q` text, answers `a` in display order) fresh and starts accepting picks.
func show_question(q: Dictionary) -> void:
	_question.text = q.q
	for i in 4:
		var button := _answers[i]
		button.text = "%s:  %s" % [LETTERS[i], q.a[i]]
		button.disabled = false
		_set_look(button, Look.NORMAL)
	_set_prize(false)
	resume_picking()


## Accepts picks again (after a wrong answer); wrong ones stay out.
func resume_picking() -> void:
	selected = -1
	accepting = true
	_final.disabled = true
	_walk.disabled = false


## A locked-in answer was wrong: it turns red and can't be picked again.
func mark_wrong(i: int) -> void:
	_set_look(_answers[i], Look.WRONG)
	_answers[i].disabled = true


## A locked-in answer was right: it turns green and the prize lights up.
func mark_correct(i: int) -> void:
	_set_look(_answers[i], Look.CORRECT)
	_set_prize(true)


## The timer's current nonsense, and how much of the ring is "left" (0..1).
func set_dial(text: String, arc: float) -> void:
	_dial_text = text
	_dial_arc = arc
	_dial.queue_redraw()


func set_walk_away_enabled(on: bool) -> void:
	_walk.disabled = not on


func slide_in() -> void:
	show()
	_slide_to(0.0, 1.0)


func slide_out() -> void:
	_slide_to(get_viewport().get_visible_rect().size.y * 0.45, 0.0)
	_slide.tween_callback(hide)


## Every answer box's centre on screen (for ComicBursts).
func answer_center(i: int) -> Vector2:
	return _answers[i].get_global_rect().get_center()


func prize_center() -> Vector2:
	return _prize.get_global_rect().get_center()


func _slide_to(y: float, alpha: float) -> void:
	if _slide:
		_slide.kill()
	if alpha > 0.0:
		_root.position.y = get_viewport().get_visible_rect().size.y * 0.45
		_root.modulate.a = 0.0
	_slide = create_tween().set_parallel()
	_slide.tween_property(_root, "position:y", y, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT if alpha > 0.0 else Tween.EASE_IN)
	_slide.tween_property(_root, "modulate:a", alpha, 0.25)
	_slide.chain()


func _on_answer_pressed(i: int, from_key := false) -> void:
	if not accepting or _answers[i].disabled:
		return
	if i == selected and not from_key:
		_lock()
		return
	if selected >= 0:
		_set_look(_answers[selected], Look.NORMAL)
	selected = i
	_set_look(_answers[i], Look.SELECTED)
	_final.disabled = false
	answer_selected.emit(i)


func _lock() -> void:
	accepting = false
	_final.disabled = true
	_walk.disabled = true
	answer_locked.emit(selected)


func _on_lifeline(id: StringName) -> void:
	if not accepting:
		return
	_lifelines[id].disabled = true
	_lifelines[id].text = "USED"
	lifeline_used.emit(id)


func _draw_dial() -> void:
	var center := _dial.size / 2.0
	var radius := minf(center.x, center.y) - 4.0
	_dial.draw_circle(center + Vector2(5, 5), radius + 3.0, Color.BLACK)
	_dial.draw_circle(center, radius + 3.0, Color.BLACK)
	_dial.draw_circle(center, radius, NAVY)
	_dial.draw_arc(center, radius - 7.0, -PI / 2.0, -PI / 2.0 + TAU * _dial_arc, 48, GOLD, 9.0, true)
	var size := 34
	while size > 12 and HEAD_FONT.get_string_size(_dial_text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > radius * 1.45:
		size -= 2
	var text_size := HEAD_FONT.get_string_size(_dial_text, HORIZONTAL_ALIGNMENT_LEFT, -1, size)
	var baseline := center + Vector2(-text_size.x / 2.0, (HEAD_FONT.get_ascent(size) - HEAD_FONT.get_descent(size)) / 2.0)
	_dial.draw_string_outline(HEAD_FONT, baseline, _dial_text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 6, Color.BLACK)
	_dial.draw_string(HEAD_FONT, baseline, _dial_text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color.WHITE)


func _set_prize(won: bool) -> void:
	_prize.add_theme_stylebox_override(&"normal", _box(GOLD if won else NAVY, GOLD, 3))
	_prize.add_theme_color_override(&"font_color", NAVY if won else GOLD)


func _set_look(button: Button, look: Look) -> void:
	var fill: Color = [NAVY, ORANGE, GREEN, RED][look]
	var border := Color.BLACK if look == Look.NORMAL else Color.WHITE
	var normal := _box(fill, GOLD if look == Look.NORMAL else border, 3, 0.25)
	button.add_theme_stylebox_override(&"normal", normal)
	button.add_theme_stylebox_override(&"hover", _box(fill.lightened(0.18), GOLD, 3, 0.25))
	button.add_theme_stylebox_override(&"pressed", normal)
	button.add_theme_stylebox_override(&"disabled", _box(fill.darkened(0.35) if look == Look.NORMAL else fill, Color(0.4, 0.35, 0.1), 3, 0.25))
	for state: StringName in [&"font_color", &"font_hover_color", &"font_pressed_color", &"font_disabled_color"]:
		button.add_theme_color_override(state, NAVY if look == Look.SELECTED and state != &"font_disabled_color" else Color.WHITE)


## Comic box: fill, coloured border, solid black offset shadow; `skew` slants it like a game-show plate.
func _box(fill: Color, border: Color, width: int, skew := 0.0) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(width)
	box.set_corner_radius_all(6)
	box.skew = Vector2(skew, 0.0)
	box.shadow_color = Color.BLACK
	box.shadow_offset = Vector2(5, 5)
	box.content_margin_left = 22
	box.content_margin_right = 22
	box.content_margin_top = 4
	box.content_margin_bottom = 4
	return box


func _style_all() -> void:
	_title.add_theme_font_override(&"font", HEAD_FONT)
	_title.add_theme_font_size_override(&"font_size", 21)
	_title.add_theme_color_override(&"font_color", GOLD)
	_title.add_theme_color_override(&"font_outline_color", Color.BLACK)
	_title.add_theme_constant_override(&"outline_size", 10)
	_question.add_theme_font_override(&"font", HEAD_FONT)
	_question.add_theme_font_size_override(&"font_size", 25)
	_question.add_theme_stylebox_override(&"normal", _box(Color("#2a1a6e"), GOLD, 4, 0.12))
	_prize.add_theme_font_override(&"font", HEAD_FONT)
	_prize.add_theme_font_size_override(&"font_size", 17)
	var flat := _box(NAVY, GOLD, 3)
	for button: Button in [_final, _walk] + _lifelines.values():
		button.add_theme_font_override(&"font", HEAD_FONT)
		button.add_theme_font_size_override(&"font_size", 18)
		button.add_theme_stylebox_override(&"normal", flat)
		button.add_theme_stylebox_override(&"pressed", flat)
		button.add_theme_stylebox_override(&"hover", _box(NAVY.lightened(0.2), GOLD, 3))
		button.add_theme_stylebox_override(&"disabled", _box(Color(0.2, 0.2, 0.25), Color(0.35, 0.35, 0.35), 3))
		button.add_theme_color_override(&"font_color", GOLD)
		button.add_theme_color_override(&"font_hover_color", Color.WHITE)
	_final.add_theme_stylebox_override(&"normal", _box(ORANGE, Color.WHITE, 3))
	_final.add_theme_color_override(&"font_color", NAVY)
	# The one lifeline, loud and proud.
	var phone := _lifelines[&"phone"]
	phone.add_theme_font_size_override(&"font_size", 24)
	phone.add_theme_stylebox_override(&"normal", _box(GOLD, Color.WHITE, 4, 0.15))
	phone.add_theme_stylebox_override(&"hover", _box(GOLD.lightened(0.25), Color.WHITE, 4, 0.15))
	phone.add_theme_color_override(&"font_color", NAVY)
	phone.add_theme_color_override(&"font_hover_color", NAVY)
	for button in _answers:
		button.add_theme_font_size_override(&"font_size", 21)
		_set_look(button, Look.NORMAL)
