class_name CharacterSelect
extends Node2D
## The character design screen (after the start menu): an autotyped comic caption, then the player
## picks one option per CharacterCategory and confirms, Deltarune style, on a comic backdrop. The picks
## don't persist: the character is destroyed (you don't get any control here), and the game cuts to
## black for the intro (menus/intro/intro_darkness.tscn).
## The EventManager child decides which step plays when; this only shows them.
## Keys: left/right (or A/D) cycle, Enter/Z next, Backspace/X back. Any key skips the intro.

## Emitted when the player finishes step `id` (intro typed out, option picked, YES chosen).
signal step_completed(id: StringName)
## Emitted when the player asks to go back a step.
signal step_back_requested
## Emitted when the player skips straight to step `id` (the random button jumps to &"confirm").
signal jump_requested(id: StringName)

const SCENE := "res://menus/character_select/character_select.tscn"
const INTRO_SCENE := "res://menus/intro/intro_darkness.tscn"
const SCRATCH_SOUND := preload("res://assets/audio/sfx/400_sounds_pack/record_scratch.wav")
const CRUNCH_SOUND := preload("res://assets/audio/sfx/400_sounds_pack/punch.wav")
const CLATTER_SOUND := preload("res://assets/audio/sfx/freesound/panel_clatter_vent_me_studios.wav")
const CURSOR := "▌"
const HEART := "♥"
const HEART_COLOR := "#e03030"
const CONFIRM_TITLE := "IS THIS YOUR CHARACTER?"
## Narrator lines after YES: one of the two choice lines, then the post-choice line.
const CHOICE_MADE_CUE := &"character_choice_made"
const CHOICE_RANDOM_CUE := &"character_choice_random"
const POST_CHOICE_CUE := &"character_post_choice"

## Choosable categories, one step each (step id = CharacterCategory.id). Order here only affects the
## file listing; the step order is the EventManager's `steps`, the draw order is CharacterCategory.layer.
@export var categories: Array[CharacterCategory] = []

@export_group("Intro")
## Pages autotyped on boot. Each page is typed out, held, then cleared before the next one.
@export_multiline var intro_pages: Array[String] = []
## Seconds per typed character.
@export var type_interval := 0.03
## Seconds a full page stays up before it's cleared.
@export var page_hold := 0.8

@export_group("Random")
## What the random button picks: category id -> option id. Not random at all. Categories left out keep
## the current pick; empty = actually random.
@export var random_preset: Dictionary[StringName, StringName] = {}

@export_group("Ending")
## Seconds into the post-choice line when the character is destroyed (on "...will never be used in the game!").
@export var destroy_at := 3.4

var _step := &"" ## Step on screen and taking input; empty while waiting between steps.
var _picks: Dictionary[StringName, int] = {} ## Option index per category id.
var _yes_focused := true ## Confirm prompt: YES (true) or NO focused.
var _typed := "" ## Intro text typed so far.
var _skip_intro := false
var _used_random := false ## The final picks came from the random button (any manual change resets it).
var _finishing := false
var _line_cue := &"" ## The narrator line finish() is waiting on, when it started and its length.
var _line_started_msec := 0
var _line_length := 0.0
var _layers: Dictionary[StringName, Array] = {} ## Category id -> [TextureRect, placeholder ColorRect].

@onready var screen: Control = $Screen
@onready var editor: RichTextLabel = $Screen/Editor
@onready var status_bar: Label = $Screen/LowerMenu
@onready var chooser: Control = $Screen/Chooser
@onready var title: Label = $Screen/Chooser/Title
@onready var listing: RichTextLabel = $Screen/Chooser/Listing
@onready var preview: Control = $Screen/Chooser/Preview
@onready var picker: Control = $Screen/Chooser/Picker
@onready var option_name: Label = $Screen/Chooser/Picker/OptionName
@onready var confirm_prompt: Control = $Screen/Chooser/ConfirmPrompt
@onready var yes_button: Button = $Screen/Chooser/ConfirmPrompt/YesButton
@onready var no_button: Button = $Screen/Chooser/ConfirmPrompt/NoButton
@onready var random_button: Button = $Screen/RandomButton
@onready var back_button: Button = $Screen/BackButton
@onready var next_button: Button = $Screen/NextButton


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	ComicCursor.apply()
	Audio.play_music(Audio.MENU_MUSIC) # Already playing from the start menu: keeps going.
	tree_exiting.connect(ComicCursor.reset)
	preview.clip_contents = true
	get_viewport().size_changed.connect(_fit_screen)
	_fit_screen()
	for category in categories:
		_picks[category.id] = 0
	_build_preview()
	$Screen/Chooser/Picker/LeftArrow.pressed.connect(_cycle.bind(-1))
	$Screen/Chooser/Picker/RightArrow.pressed.connect(_cycle.bind(1))
	yes_button.pressed.connect(_answer.bind(true))
	no_button.pressed.connect(_answer.bind(false))
	random_button.pressed.connect(_randomize)
	back_button.pressed.connect(_back)
	next_button.pressed.connect(_next)
	chooser.hide()
	_show_buttons(false)
	_refresh_status()


func _process(_delta: float) -> void:
	if editor.visible:
		var blink := Time.get_ticks_msec() % 1000 < 500
		var text := _typed + (CURSOR if blink else "")
		if editor.text != text:
			editor.text = text


## Shows step `id` (called by the EventManager): &"intro", a category id, or &"confirm".
func start_step(id: StringName) -> void:
	_step = id
	if id == &"intro":
		_play_intro()
		return
	editor.hide()
	chooser.show()
	_show_buttons(true)
	var category := _category(id)
	picker.visible = category != null
	confirm_prompt.visible = id == &"confirm"
	if category:
		title.text = category.title
	elif id == &"confirm":
		title.text = CONFIRM_TITLE
		_yes_focused = true
	else:
		push_error("CharacterSelect: unknown step '%s'" % id)
	_refresh()


## Called by the EventManager after the last step: the narrator admires the choice ("W O W."), thanks
## the player, and on "...will never be used in the game!" the character is destroyed (the music dies
## with it); after the line ends, a hard cut to black. Input is ignored throughout (_step is empty), and
## every wait is capped, so a muted or cut-short line can't hang it.
func finish() -> void:
	if _finishing:
		return
	_finishing = true
	_step = &""
	_show_buttons(false)
	confirm_prompt.hide()
	picker.hide()
	status_bar.hide() # The key hints: nothing takes input any more.
	_say(CHOICE_RANDOM_CUE if _used_random else CHOICE_MADE_CUE)
	await _line_end()
	_say(POST_CHOICE_CUE)
	await _line_end(destroy_at)
	Audio.fade_out_music(0.3) # The music dies with the character (under the record scratch).
	await _destroy()
	await _line_end()
	await get_tree().create_timer(0.4).timeout
	get_tree().change_scene_to_file(INTRO_SCENE) # A hard cut to black, no fade.


## Starts narrator cue `cue`; _line_end() then waits for it.
func _say(cue: StringName) -> void:
	Narrator.play(cue)
	_line_cue = cue
	_line_started_msec = Time.get_ticks_msec()
	var stream: AudioStream = Narrator.voice.stream if Narrator.current_cue == cue and Narrator.voice.playing else null
	_line_length = stream.get_length() if stream else 0.0


## Waits until the line started by _say() ends (finished, cut short or muted), or until `at` seconds into
## it if given, but never longer than its length plus a second, so nothing can hang here.
func _line_end(at := -1.0) -> void:
	var cap := _line_length + 1.0
	var until := _line_started_msec + int(1000.0 * (minf(at, cap) if at >= 0.0 else cap))
	while Narrator.current_cue == _line_cue and Narrator.is_speaking() and Time.get_ticks_msec() < until:
		await get_tree().process_frame


## Record scratch, the portrait shakes, then crumples into a ball with a KRAKK! and drops off screen.
func _destroy() -> void:
	Audio.play_sfx(SCRATCH_SOUND)
	listing.hide()
	status_bar.hide()
	title.text = "..."
	preview.pivot_offset = preview.size / 2.0
	var origin := preview.position
	var shake := create_tween()
	for i in 10:
		shake.tween_property(preview, "position", origin + Vector2(randf_range(-9, 9), randf_range(-6, 6)), 0.05)
	shake.tween_property(preview, "position", origin, 0.05)
	await shake.finished
	Audio.play_sfx(CRUNCH_SOUND)
	ComicBurst.spawn(screen, preview.get_global_rect().get_center(), "KRAKK!", Color("#ff3b30"))
	var crumple := create_tween()
	crumple.tween_property(preview, "scale", Vector2(0.15, 0.12), 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	crumple.parallel().tween_property(preview, "rotation", TAU * 1.5, 0.45)
	crumple.parallel().tween_property(preview, "modulate", Color(0.6, 0.6, 0.6), 0.45)
	crumple.tween_interval(0.25)
	crumple.tween_callback(Audio.play_sfx.bind(CLATTER_SOUND))
	crumple.tween_property(preview, "position:y", screen.size.y + 100.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	crumple.parallel().tween_property(preview, "rotation", TAU * 2.5, 0.5)
	await crumple.finished
	title.text = ""


func _unhandled_input(event: InputEvent) -> void:
	if _step == &"intro":
		if event.is_pressed() and not event.is_echo() and (event is InputEventKey or event is InputEventMouseButton):
			_skip_intro = true
			get_viewport().set_input_as_handled()
		return
	var key := event as InputEventKey
	if not key or not key.pressed or _step.is_empty():
		return
	match key.keycode:
		KEY_LEFT, KEY_A:
			_cycle(-1)
		KEY_RIGHT, KEY_D:
			_cycle(1)
		KEY_ENTER, KEY_KP_ENTER, KEY_Z:
			_next()
		KEY_BACKSPACE, KEY_X:
			_back()
		_:
			return
	get_viewport().set_input_as_handled()


func _play_intro() -> void:
	chooser.hide()
	editor.show()
	_skip_intro = false
	for page in intro_pages:
		_typed = ""
		for character in page:
			if _skip_intro:
				break
			_typed += character
			await get_tree().create_timer(type_interval).timeout
		if _skip_intro:
			break
		await get_tree().create_timer(page_hold).timeout
	_typed = ""
	editor.hide()
	if _step == &"intro":
		_step = &""
		step_completed.emit(&"intro")


## Left/right: the next option of the current category, or YES/NO on the confirm prompt.
func _cycle(direction: int) -> void:
	var category := _category(_step)
	if category and category.options:
		_picks[category.id] = posmod(_picks[category.id] + direction, category.options.size())
		_used_random = false
		_refresh()
	elif _step == &"confirm":
		_yes_focused = not _yes_focused
		_refresh()


func _next() -> void:
	if _step == &"confirm":
		_answer(_yes_focused)
	elif not _step.is_empty():
		_complete()


func _back() -> void:
	if not _step.is_empty():
		step_back_requested.emit()


func _answer(yes: bool) -> void:
	if _step != &"confirm":
		return
	if yes:
		_complete()
	else:
		_back()


func _complete() -> void:
	var id := _step
	_step = &""
	step_completed.emit(id)


func _randomize() -> void:
	if _step.is_empty():
		return
	for category in categories:
		if not category.options:
			continue
		if random_preset.is_empty():
			_picks[category.id] = randi() % category.options.size()
		elif random_preset.has(category.id):
			var index := category.options.find_custom(func(o: CharacterOption) -> bool: return o.id == random_preset[category.id])
			if index == -1:
				push_warning("CharacterSelect: random_preset option '%s' not in '%s'" % [random_preset[category.id], category.id])
			else:
				_picks[category.id] = index
	_used_random = true
	_step = &""
	jump_requested.emit(&"confirm")


func _category(id: StringName) -> CharacterCategory:
	for category in categories:
		if category.id == id:
			return category
	return null


## One layer per category, drawn in CharacterCategory.layer order: the texture, or a placeholder block.
func _build_preview() -> void:
	var sorted := categories.duplicate()
	sorted.sort_custom(func(a: CharacterCategory, b: CharacterCategory) -> bool: return a.layer < b.layer)
	for category: CharacterCategory in sorted:
		var placeholder := ColorRect.new()
		placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		placeholder.anchor_left = category.placeholder_region.position.x
		placeholder.anchor_top = category.placeholder_region.position.y
		placeholder.anchor_right = category.placeholder_region.end.x
		placeholder.anchor_bottom = category.placeholder_region.end.y
		var texture := TextureRect.new()
		texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# The art is a 2048 px square with the figure down the middle: overscan it so the figure fills the
		# frame (the frame clips the rest).
		texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		texture.offset_left = -120.0
		texture.offset_right = 120.0
		texture.offset_top = -10.0
		texture.offset_bottom = 200.0
		texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		preview.add_child(placeholder)
		preview.add_child(texture)
		_layers[category.id] = [texture, placeholder]


func _refresh() -> void:
	var lines: PackedStringArray = []
	for category in categories:
		var option: CharacterOption = category.options[_picks[category.id]] if category.options else null
		var layer: Array = _layers[category.id]
		(layer[0] as TextureRect).texture = option.texture if option else null
		(layer[1] as ColorRect).visible = option != null and option.texture == null
		(layer[1] as ColorRect).color = option.placeholder_color if option else Color.TRANSPARENT
		var row := "%-10s %s" % [category.id, option.display_name if option else "-"]
		if category.id == _step:
			row = "[color=%s]%s[/color] [color=#e03030]%s[/color]" % [HEART_COLOR, HEART, row]
		else:
			row = "  " + row
		lines.append(row)
	listing.text = "\n".join(lines)
	var current := _category(_step)
	if current and current.options:
		option_name.text = current.options[_picks[current.id]].display_name
	yes_button.text = (HEART + " YES") if _yes_focused else "  YES"
	no_button.text = "  NO" if _yes_focused else (HEART + " NO")
	_refresh_status()


func _refresh_status() -> void:
	var index := categories.find(_category(_step))
	var where := "step %d/%d" % [index + 1, categories.size()] if index >= 0 else String(_step).to_upper()
	status_bar.text = "%s    \u2190 \u2192 choose   Enter next   Backspace back" % where


func _show_buttons(on: bool) -> void:
	for button in [random_button, back_button, next_button]:
		button.visible = on


## A Control under a Node2D can't anchor to the viewport, so size the screen by hand.
func _fit_screen() -> void:
	screen.size = get_viewport_rect().size
