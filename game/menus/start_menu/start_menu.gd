extends Control
## The title screen (the game's main scene): the team's hand-drawn start art (assets/ui/start_screen/,
## layered: background + their hand-lettered buttons at their drawn spots). The art lives on a 1920x1080
## Stage that is cover-scaled to the window. NEW GAME and CONT. LAST GAME both start the game (there is no
## save); SETTINGS is "the button that does nothing" (shakes, plays `settings_cue` if set); EXIT quits
## (hidden on the web, where a page can't close itself). Enter presses the focused button (New Game).

const CHARACTER_SELECT := "res://menus/character_select/character_select.tscn"
const START_SOUND := preload("res://assets/audio/sfx/400_sounds_pack/pop_2.wav")
const STAGE_SIZE := Vector2(1920, 1080)

## Narrator cue for the do-nothing SETTINGS button (empty = silent; the team adds the line later).
@export var settings_cue: StringName = &""

@onready var stage: Control = %Stage
@onready var title: Label = %Title
@onready var new_game_button: TextureButton = %NewGameButton
@onready var continue_button: TextureButton = %ContinueButton
@onready var settings_button: TextureButton = %SettingsButton
@onready var exit_button: TextureButton = %ExitButton

var _starting := false
var _settings_x := 0.0


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	ComicCursor.apply()
	tree_exiting.connect(ComicCursor.reset)
	exit_button.visible = not OS.has_feature("web")
	new_game_button.pressed.connect(_start.bind(new_game_button))
	continue_button.pressed.connect(_start.bind(continue_button))
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


## SETTINGS: the button that does nothing. A tiny shake, and (once the team writes it) a narrator line.
func _do_nothing() -> void:
	var tween := settings_button.create_tween()
	for offset: float in [-12.0, 10.0, -6.0, 0.0]:
		tween.tween_property(settings_button, "position:x", _settings_x + offset, 0.05)
	if settings_cue != &"":
		Narrator.play(settings_cue)


func _start(button: TextureButton) -> void:
	if _starting:
		return
	_starting = true
	Audio.play_sfx(START_SOUND)
	ComicBurst.spawn(self, button.get_global_rect().get_center(), "GO!")
	await get_tree().create_timer(0.35).timeout
	Transition.change_scene(CHARACTER_SELECT)
