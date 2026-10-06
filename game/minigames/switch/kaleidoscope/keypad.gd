extends Control
## Switch game "kaleidoscope", second half (see kaleidoscope.gd): the switchboard's security keypad,
## opened by the power switch. Type the password the TWIST ME painting showed through the scope, by
## clicking the keys or typing. Wrong guesses get buzzed and mocked; the right one opens the panel and
## moves straight on to the restore game. Esc or the window's X leaves (the password is kept).

const ID := Kaleidoscope.ID
const MAX_LENGTH := 9
const ROWS: Array[String] = ["ABCDEFG", "HIJKLMN", "OPQRSTU", "VWXYZ"]
const BACKSPACE := "⌫"
const ENTER := "ENTER"
const FONT := preload("res://assets/fonts/ComicRelief-Bold.ttf")
const LCD_GREEN := Color("#7dff7d")
const LCD_RED := Color("#ff5a3c")
const KEY_SOUNDS: Array[AudioStream] = [
	preload("res://assets/audio/sfx/400_sounds_pack/keyboard_key_1.wav"),
	preload("res://assets/audio/sfx/400_sounds_pack/keyboard_key_2.wav"),
	preload("res://assets/audio/sfx/400_sounds_pack/keyboard_key_3.wav"),
	preload("res://assets/audio/sfx/400_sounds_pack/keyboard_key_4.wav"),
]

## Seconds after the panel opens before moving on (longer while the narrator is still talking).
@export var exit_delay := 1.0
## Longest wait for the narrator's line before moving on anyway.
@export var max_line_wait := 8.0
@export var wrong_sound: AudioStream
@export var right_sound: AudioStream
@export var click_sound: AudioStream

var _typed := ""
var _blink := 0.0
var _locked := false ## Showing a verdict (no typing).
var _done := false
var _wrong := 0
var _buttons: Dictionary[String, Button] = {}

@onready var _window: AppWindow = %Window
@onready var _lcd: Label = %LcdText
@onready var _lcd_panel: PanelContainer = %Lcd
@onready var _keys: GridContainer = %Keys
@onready var _status: Label = %Status
@onready var _burst: Control = $Burst


func _ready() -> void:
	Kaleidoscope.ensure()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	ComicCursor.apply()
	_build_keys()
	_window.close_requested.connect(_leave)
	_window.pop_in()
	_set_status("ENTER PASSWORD", Color.WHITE)
	_refresh()
	Narrator.play(&"keypad_intro") # A `once` cue: the first time the switch asks for a password.


func _exit_tree() -> void:
	ComicCursor.reset()


func _process(delta: float) -> void:
	_blink += delta
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_leave()
		return
	var key := event as InputEventKey
	if not key or not key.pressed or key.echo:
		return
	if key.keycode == KEY_BACKSPACE:
		_press(BACKSPACE)
	elif key.keycode == KEY_ENTER or key.keycode == KEY_KP_ENTER:
		_press(ENTER)
	else:
		var letter := char(key.unicode).to_upper() if key.unicode > 0 else ""
		if letter.length() == 1 and letter >= "A" and letter <= "Z":
			_press(letter)
		else:
			return
	get_viewport().set_input_as_handled()


func _build_keys() -> void:
	for row in ROWS:
		for letter in row:
			_add_key(letter, Color("#fff8e7"))
	_add_key(BACKSPACE, Color("#ffb0a0"))
	_add_key(ENTER, Color("#9be89b"))


func _add_key(label: String, color: Color) -> void:
	var button := Button.new()
	button.text = label
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.custom_minimum_size = Vector2(66, 58)
	button.add_theme_font_override(&"font", FONT)
	button.add_theme_font_size_override(&"font_size", 26 if label.length() == 1 else 20)
	for state in [&"font_color", &"font_hover_color", &"font_pressed_color"]:
		button.add_theme_color_override(state, Color.BLACK)
	button.add_theme_stylebox_override(&"normal", _key_style(color))
	button.add_theme_stylebox_override(&"hover", _key_style(color.lightened(0.15).lerp(Color("#ffe14d"), 0.35)))
	button.add_theme_stylebox_override(&"pressed", _key_style(Color("#ffb347"), true))
	button.add_theme_stylebox_override(&"focus", StyleBoxEmpty.new())
	button.pressed.connect(_press.bind(label))
	_keys.add_child(button)
	_buttons[label] = button


func _key_style(color: Color, pressed := false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color.BLACK
	style.set_border_width_all(3)
	style.border_width_bottom = 3 if pressed else 7
	style.set_corner_radius_all(9)
	style.content_margin_top = 4.0 if pressed else 0.0
	style.anti_aliasing = true
	return style


func _press(label: String) -> void:
	if _locked or _done:
		return
	_flash_key(label)
	Audio.play_sfx(KEY_SOUNDS.pick_random(), -4.0)
	match label:
		BACKSPACE:
			_typed = _typed.left(-1)
		ENTER:
			if _typed:
				_submit(_typed)
		_:
			if _typed.length() < MAX_LENGTH:
				_typed += label
	_blink = 0.0
	_refresh()


## Physical typing pushes the on-screen key down for a moment too.
func _flash_key(label: String) -> void:
	var button: Button = _buttons.get(label)
	if not button:
		return
	button.pivot_offset = button.size / 2.0
	var tween := button.create_tween()
	tween.tween_property(button, "scale", Vector2.ONE * 0.88, 0.05)
	tween.tween_property(button, "scale", Vector2.ONE, 0.1)


func _refresh() -> void:
	var cursor := "_" if fmod(_blink, 1.0) < 0.55 and not _locked and _typed.length() < MAX_LENGTH else " "
	_lcd.text = _typed + cursor if not _done else _typed


func _set_status(text: String, color: Color) -> void:
	_status.text = text
	_status.add_theme_color_override(&"font_color", color)


func _submit(text: String) -> void:
	if text == GameState.scope_password:
		_accept()
		return
	_wrong += 1
	_locked = true
	_window.shake(14.0)
	Audio.play_sfx(wrong_sound, -6.0)
	_set_status("ACCESS DENIED", LCD_RED)
	_lcd.add_theme_color_override(&"font_color", LCD_RED)
	ComicBurst.spawn(_burst, _lcd_panel.get_global_rect().get_center(), "BZZT!", Color("#ff7a6b"))
	Narrator.play(_wrong_cue(text))
	await get_tree().create_timer(0.9).timeout
	_typed = ""
	_locked = false
	_lcd.add_theme_color_override(&"font_color", LCD_GREEN)
	_set_status("ENTER PASSWORD", Color.WHITE)


func _wrong_cue(text: String) -> StringName:
	if text == "TWISTME":
		return &"keypad_twist_me"
	if GameState.password and text == GameState.password.to_upper():
		return &"keypad_old_password"
	if not GameState.scope_solved and _wrong == 1:
		return &"keypad_no_password"
	return &"keypad_wrong_1"


func _accept() -> void:
	_done = true
	_set_status("ACCESS GRANTED", LCD_GREEN)
	Audio.play_sfx(click_sound, -2.0)
	Audio.play_sfx(right_sound, -4.0)
	ComicBurst.spawn(_burst, _lcd_panel.get_global_rect().get_center(), "CLICK!", Color("#7dff7d"))
	Narrator.play(&"keypad_right")
	await get_tree().create_timer(exit_delay).timeout
	var waited := 0.0
	while Narrator.is_speaking() and waited < max_line_wait:
		await get_tree().create_timer(0.2).timeout
		waited += 0.2
	Story.switch_game_done(ID)
	Transition.change_scene(Story.next_switch_scene())


func _leave() -> void:
	if not _done:
		_done = true
		Transition.change_scene(Story.OFFICE)
