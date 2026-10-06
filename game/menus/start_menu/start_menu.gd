extends Control
## The title screen (the game's main scene): a comic splash with the title, Start and Quit (Quit is
## hidden on the web, where a page can't close itself). Start goes to the character design screen.
## Enter/Space presses the focused button (Start has focus). The music (Audio autoload) just plays on.

const CHARACTER_SELECT := "res://menus/character_select/character_select.tscn"
const START_SOUND := preload("res://assets/audio/sfx/400_sounds_pack/pop_2.wav")

@onready var title: Label = %Title
@onready var tagline: Control = %Tagline
@onready var start_button: Button = %StartButton
@onready var quit_button: Button = %QuitButton

var _starting := false


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	ComicCursor.apply()
	tree_exiting.connect(ComicCursor.reset)
	quit_button.visible = not OS.has_feature("web")
	start_button.pressed.connect(_start)
	quit_button.pressed.connect(get_tree().quit)
	start_button.grab_focus()
	_pop_in.call_deferred()


func _pop_in() -> void:
	for node: Control in [title, tagline, start_button, quit_button]:
		node.pivot_offset = node.size / 2.0
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


func _start() -> void:
	if _starting:
		return
	_starting = true
	Audio.play_sfx(START_SOUND)
	ComicBurst.spawn(self, start_button.get_global_rect().get_center(), "GO!")
	await get_tree().create_timer(0.35).timeout
	Transition.change_scene(CHARACTER_SELECT)
