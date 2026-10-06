extends Control
## The title screen (the game's main scene): the team's hand-drawn start art (assets/ui/start_screen/,
## layered: background + their hand-lettered buttons at their drawn spots). The art lives on a 1920x1080
## Stage that is cover-scaled to the window. NEW GAME and CONT. LAST GAME both start the game (there is no
## save); SETTINGS is "the button that does nothing" (shakes, plays `settings_cue` if set); EXIT quits
## (hidden on the web, where a page can't close itself). Enter presses the focused button (New Game).

const START_SOUND := preload("res://assets/audio/sfx/400_sounds_pack/pop_2.wav")
const STAGE_SIZE := Vector2(1920, 1080)
const BUBBLE_FONT := preload("res://assets/fonts/ComicRelief-Bold.ttf")
const BUBBLE_PAPER := Color("#fff8e7")
const BUBBLE_INK := Color("#141414")
## Stage position of the SETTINGS speech bubble's top-left corner, and where its tail points.
const BUBBLE_AT := Vector2(150, 610)
const BUBBLE_TAIL_TIP := Vector2(250, 470)

## Narrator cue for the do-nothing SETTINGS button (empty = silent). Its subtitle shows over the menu.
@export var settings_cue: StringName = &""

@onready var stage: Control = %Stage
@onready var title: Label = %Title
@onready var new_game_button: TextureButton = %NewGameButton
@onready var continue_button: TextureButton = %ContinueButton
@onready var settings_button: TextureButton = %SettingsButton
@onready var exit_button: TextureButton = %ExitButton

var _starting := false
var _settings_x := 0.0
var _bubble: Control


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	ComicCursor.apply()
	tree_exiting.connect(ComicCursor.reset)
	exit_button.visible = not OS.has_feature("web")
	new_game_button.pressed.connect(_start.bind(new_game_button, false))
	continue_button.pressed.connect(_start.bind(continue_button, true))
	settings_button.pressed.connect(_do_nothing)
	exit_button.pressed.connect(get_tree().quit)
	for button: TextureButton in [new_game_button, continue_button, settings_button, exit_button]:
		button.pivot_offset = button.size / 2.0
		button.mouse_entered.connect(_hover.bind(button, true))
		button.mouse_exited.connect(_hover.bind(button, false))
		button.focus_entered.connect(_hover.bind(button, true))
		button.focus_exited.connect(_hover.bind(button, false))
		button.button_down.connect(_squash.bind(button))
	_settings_x = settings_button.position.x
	resized.connect(_fit_stage)
	_fit_stage()
	title.pivot_offset = title.size / 2.0
	new_game_button.grab_focus()
	_pop_in()


## Cover-scale the 16:9 art to the window and centre it (crops a little on other aspects).
func _fit_stage() -> void:
	var s := maxf(size.x / STAGE_SIZE.x, size.y / STAGE_SIZE.y)
	stage.scale = Vector2.ONE * s
	stage.position = (size - STAGE_SIZE * s) / 2.0


func _pop_in() -> void:
	title.scale = Vector2.ONE * 0.2
	var tween := create_tween()
	tween.tween_property(title, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_wobble_title)


## The title rocks gently forever, like a sticker on a comic cover.
func _wobble_title() -> void:
	var base := title.rotation
	var loop := create_tween().set_loops()
	loop.tween_property(title, "rotation", base + deg_to_rad(2.0), 1.6).set_trans(Tween.TRANS_SINE)
	loop.tween_property(title, "rotation", base - deg_to_rad(2.0), 1.6).set_trans(Tween.TRANS_SINE)


## Lettering grows and wobbles when hovered or focused.
func _hover(button: TextureButton, on: bool) -> void:
	var big := on or button.has_focus() or button.is_hovered()
	button.create_tween().tween_property(button, "scale", Vector2.ONE * (1.1 if big else 1.0), 0.2) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if on:
		var wobble := button.create_tween()
		wobble.tween_property(button, "rotation", 0.05, 0.08)
		wobble.tween_property(button, "rotation", -0.035, 0.1)
		wobble.tween_property(button, "rotation", 0.0, 0.12).set_trans(Tween.TRANS_SINE)


func _squash(button: TextureButton) -> void:
	var tween := button.create_tween()
	tween.tween_property(button, "scale", Vector2(1.14, 0.9), 0.06)
	tween.tween_property(button, "scale", Vector2.ONE * 1.1, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## SETTINGS: the button that does nothing. A tiny shake and a narrator line, shown in a speech bubble by
## the button (the cue hides its own subtitle; the narrator's subtitle bar is hard to read on the art).
func _do_nothing() -> void:
	var tween := settings_button.create_tween()
	for offset: float in [-12.0, 10.0, -6.0, 0.0]:
		tween.tween_property(settings_button, "position:x", _settings_x + offset, 0.05)
	# Once per press, and not again while the line is still up.
	if settings_cue != &"" and Narrator.current_cue != settings_cue:
		Narrator.play(settings_cue)
		if Narrator.current_cue == settings_cue:
			_show_bubble((load(Narrator.CUE_DIR + settings_cue + ".tres") as NarratorCue).subtitle)


func _show_bubble(text: String) -> void:
	if _bubble:
		_bubble.queue_free()
	_bubble = Control.new()
	_bubble.mouse_filter = MOUSE_FILTER_IGNORE
	_bubble.position = BUBBLE_AT
	stage.add_child(_bubble)
	var tail := _tail_points(BUBBLE_TAIL_TIP - BUBBLE_AT)
	var tail_ink := Polygon2D.new()
	tail_ink.polygon = tail
	tail_ink.color = BUBBLE_INK
	_bubble.add_child(tail_ink)
	var panel := PanelContainer.new()
	panel.mouse_filter = MOUSE_FILTER_IGNORE
	var box := StyleBoxFlat.new()
	box.bg_color = BUBBLE_PAPER
	box.border_color = BUBBLE_INK
	box.set_border_width_all(6)
	box.set_corner_radius_all(28)
	box.shadow_color = BUBBLE_INK
	box.shadow_offset = Vector2(10, 10)
	box.set_content_margin_all(26)
	panel.add_theme_stylebox_override(&"panel", box)
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = 520
	label.add_theme_font_override(&"font", BUBBLE_FONT)
	label.add_theme_font_size_override(&"font_size", 46)
	label.add_theme_color_override(&"font_color", BUBBLE_INK)
	panel.add_child(label)
	_bubble.add_child(panel)
	# Paper-coloured tail on top of the panel's border, so the balloon opens into it.
	var tail_paper := Polygon2D.new()
	tail_paper.polygon = _tail_points(BUBBLE_TAIL_TIP - BUBBLE_AT, 9.0)
	tail_paper.color = BUBBLE_PAPER
	_bubble.add_child(tail_paper)
	_bubble.pivot_offset = BUBBLE_TAIL_TIP - BUBBLE_AT
	_bubble.scale = Vector2.ONE * 0.2
	_bubble.rotation = deg_to_rad(-3.0)
	_bubble.create_tween().tween_property(_bubble, "scale", Vector2.ONE, 0.3) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Narrator.line_finished.connect(_on_settings_line_finished.bind(_bubble), CONNECT_ONE_SHOT)


## A triangle from the balloon's top edge (local y 0, around x 60..140) up to `tip`, shrunk by `inset`.
func _tail_points(tip: Vector2, inset := 0.0) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(70.0 + inset * 1.6, 8.0 + inset),
		tip + Vector2(0, inset * 2.2),
		Vector2(150.0 - inset * 1.6, 8.0 + inset),
	])


func _on_settings_line_finished(_cue_id: StringName, bubble: Control) -> void:
	if not is_instance_valid(bubble):
		return
	var tween := bubble.create_tween()
	tween.tween_property(bubble, "scale", Vector2.ZERO, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_callback(bubble.queue_free)


## NEW GAME starts fresh; CONT. LAST GAME resumes the autosave (or starts fresh when there is none).
func _start(button: TextureButton, resume: bool) -> void:
	if _starting:
		return
	_starting = true
	Audio.play_sfx(START_SOUND)
	ComicBurst.spawn(self, button.get_global_rect().get_center(), "GO!")
	await get_tree().create_timer(0.35).timeout
	if resume and SaveGame.has_save() and SaveGame.continue_game():
		return
	SaveGame.new_game()
