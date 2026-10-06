extends CanvasLayer
## Autoload "PauseMenu": the pause screen (comic style, built in code). Pauses the tree and holds the
## narrator's current line (`Narrator.set_paused`); the music plays on (Audio is Process Always).
## Menu: Resume, Narration log (every line spoken so far, newest at the bottom; ▶ replays a voiced
## line), Save, Quit to title, Quit (desktop only).
##
## Keys (one rule: Esc keeps any meaning a screen already gives it, P always pauses):
## - Esc opens it where Esc meant nothing else: walking around the office (it used to just free the
##   mouse; Player calls `open()`) and the computer screen (except under the antivirus pop-up, whose
##   gag is a refused Esc-close).
## - P opens it anywhere in the game: also in the switch close-ups, the gargoyle quiz and the scope,
##   where Esc still walks away/leaves. Not at the computer or the keypad, where P types a letter.
## - While open: Esc or P resumes (Esc in the log goes back to the menu).
## Opens only in game scenes (`SaveGame.in_game()`) and never during a Transition fade.
## Layer 110: above the HUD, Transition (100) and the subtitles (101).

const MENU_THEME := preload("res://menus/menu_theme.tres")
const HALFTONE := preload("res://core/ui/comic/halftone.gdshader")
const TITLE_FONT := preload("res://assets/fonts/ComicRelief-Bold.ttf")
const LINE_FONT := preload("res://assets/fonts/ComicNeue-Bold.ttf")
const NOTE_FONT := preload("res://assets/fonts/ComicNeue-Italic.ttf")
const OPEN_SOUND := preload("res://assets/audio/sfx/400_sounds_pack/pop_2.wav")
const START_MENU := "res://menus/start_menu/start_menu.tscn"
const INK := Color("#141414")
const RED := Color("#ff3b30")
const PAPER := Color("#fff8e7")

var _open := false
var _mouse_before := Input.MOUSE_MODE_VISIBLE
var _root: Control
var _menu: Control
var _log: Control
var _log_list: VBoxContainer
var _log_scroll: ScrollContainer
var _note: Label
var _resume_button: Button
var _replay: AudioStreamPlayer
var _replay_button: Button ## The ▶ of the line being replayed (shows ■), or null.


func _ready() -> void:
	layer = 110
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	_root.hide()


func is_open() -> bool:
	return _open


## Opens the pause screen if the game can pause right now. Returns true if it opened.
func open() -> bool:
	if _open or not SaveGame.in_game() or Transition.is_busy():
		return false
	_open = true
	_mouse_before = Input.mouse_mode
	get_tree().paused = true
	Narrator.set_paused(true)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	ComicCursor.apply()
	Audio.play_sfx(OPEN_SOUND, -6.0)
	_note.text = "The game autosaves at every story beat."
	_show_menu()
	_root.show()
	_menu.pivot_offset = _menu.size / 2.0
	_menu.scale = Vector2.ONE * 0.6
	create_tween().tween_property(_menu, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return true


## Closes the pause screen and carries on where the game was.
func resume() -> void:
	if not _open:
		return
	_close()
	if _mouse_before != Input.MOUSE_MODE_VISIBLE:
		ComicCursor.reset() # 3D views and close-ups use the system cursor (or none).
	Input.mouse_mode = _mouse_before # Captured again in the office (a click recaptures it too).


func _close() -> void:
	_open = false
	_stop_replay()
	_root.hide()
	get_tree().paused = false
	Narrator.set_paused(false)


func _quit_to_title() -> void:
	SaveGame.save()
	_close()
	Narrator.stop()
	Transition.change_scene(START_MENU)


func _quit() -> void:
	SaveGame.save()
	get_tree().quit()


func _save() -> void:
	if SaveGame.save():
		_note.text = "Saved at %s. It also autosaves at every story beat." % Time.get_time_string_from_system().left(5)
		ComicBurst.spawn(_root, _note.get_global_rect().get_center(), "SAVED!")


func _input(event: InputEvent) -> void:
	if not _open:
		_check_computer_escape(event)
		return
	if event.is_action_pressed("ui_cancel") or _is_pause_key(event):
		get_viewport().set_input_as_handled()
		if _log.visible and event.is_action_pressed("ui_cancel"):
			_show_menu()
		else:
			resume()


## P pauses anywhere a screen didn't use the key itself (the computer types it).
func _unhandled_input(event: InputEvent) -> void:
	if not _open and _is_pause_key(event) and not get_tree().current_scene is Computer:
		if open():
			get_viewport().set_input_as_handled()


## On the computer Esc pauses: caught before the minigames and the document swallow every key.
func _check_computer_escape(event: InputEvent) -> void:
	var computer := get_tree().current_scene as Computer
	if not computer or not event.is_action_pressed("ui_cancel"):
		return
	if not computer.active_minigames(&"antivirus_offer").is_empty():
		return # Its Esc is a refused close (the gag); P can't pause here, Esc after it can.
	if open():
		get_viewport().set_input_as_handled()


func _is_pause_key(event: InputEvent) -> bool:
	var key := event as InputEventKey
	return key != null and key.pressed and not key.echo and key.physical_keycode == KEY_P


# --- Narration log ----------------------------------------------------------------------------------

func _show_menu() -> void:
	_stop_replay()
	_log.hide()
	_menu.show()
	_resume_button.grab_focus()


func _show_log() -> void:
	_menu.hide()
	_log.show()
	for child in _log_list.get_children():
		child.queue_free()
	if GameState.narration_log.is_empty():
		_log_list.add_child(_label("Nothing yet. Enjoy the silence while it lasts.", NOTE_FONT, 22, Color(0.3, 0.3, 0.3)))
	for entry in GameState.narration_log:
		_log_list.add_child(_log_row(entry))
	_scroll_to_bottom.call_deferred()


func _scroll_to_bottom() -> void:
	await get_tree().process_frame # Let the rows wrap first.
	var bar := _log_scroll.get_v_scroll_bar()
	_log_scroll.scroll_vertical = int(bar.max_value)


func _log_row(entry: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 12)
	var play := Button.new()
	play.custom_minimum_size = Vector2(46, 40)
	play.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	play.add_theme_font_size_override(&"font_size", 18)
	play.add_theme_constant_override(&"h_separation", 0)
	play.focus_mode = Control.FOCUS_NONE
	if entry.get("audio", false):
		play.text = "▶"
		play.tooltip_text = "Hear it again"
		play.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		play.pressed.connect(_replay_line.bind(StringName(entry.get("cue", &"")), play))
	else:
		play.text = "…"
		play.disabled = true
		play.tooltip_text = "No recording (yet)"
	row.add_child(play)
	var text := _label(str(entry.get("text", "")), LINE_FONT, 22, INK)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(text)
	return row


func _replay_line(cue_id: StringName, button: Button) -> void:
	var was_this := _replay_button == button
	_stop_replay()
	if was_this:
		return # Second press stops it.
	var path := Narrator.CUE_DIR + cue_id + ".tres"
	var cue := load(path) as NarratorCue if ResourceLoader.exists(path) else null
	if not cue or not cue.stream:
		return
	_replay.stream = cue.stream
	_replay.play()
	_replay_button = button
	button.text = "■"


func _stop_replay() -> void:
	_replay.stop()
	if is_instance_valid(_replay_button):
		_replay_button.text = "▶"
	_replay_button = null


func _on_replay_finished() -> void:
	_stop_replay()


# --- UI ---------------------------------------------------------------------------------------------

func _build() -> void:
	_replay = AudioStreamPlayer.new()
	_replay.bus = &"Voice"
	_replay.finished.connect(_on_replay_finished)
	add_child(_replay)

	_root = Control.new()
	_root.theme = MENU_THEME
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	var shade := ColorRect.new() # The game darkened (also over the bright computer screen)...
	shade.color = Color(0.03, 0.02, 0.06, 0.72)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new() # ...under Ben-Day dots.
	var dots := ShaderMaterial.new()
	dots.shader = HALFTONE
	dots.set_shader_parameter(&"paper_color", Color(0.05, 0.04, 0.08, 0.62))
	dots.set_shader_parameter(&"dot_color", Color(0.0, 0.0, 0.0, 0.85))
	dots.set_shader_parameter(&"cell_size", 12.0)
	dots.set_shader_parameter(&"min_size", 0.05)
	dots.set_shader_parameter(&"max_size", 0.75)
	dots.set_shader_parameter(&"radial", 1.0)
	dim.material = dots
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_menu = _build_menu()
	_root.add_child(_menu)
	_log = _build_log()
	_root.add_child(_log)


func _build_menu() -> Control:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 18)
	center.add_child(box)

	var title := _label("PAUSED!", TITLE_FONT, 76, RED)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override(&"font_outline_color", INK)
	title.add_theme_color_override(&"font_shadow_color", INK)
	title.add_theme_constant_override(&"outline_size", 22)
	title.add_theme_constant_override(&"shadow_outline_size", 22)
	title.add_theme_constant_override(&"shadow_offset_x", 7)
	title.add_theme_constant_override(&"shadow_offset_y", 7)
	title.rotation = deg_to_rad(-3.0)
	box.add_child(title)

	var caption := PanelContainer.new()
	caption.theme_type_variation = &"CaptionPanel"
	caption.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	caption.rotation = deg_to_rad(1.5)
	caption.add_child(_label("Meanwhile, the overtime clock keeps ticking...", NOTE_FONT, 20, INK))
	box.add_child(caption)

	var buttons := VBoxContainer.new()
	buttons.add_theme_constant_override(&"separation", 14)
	buttons.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(buttons)
	_resume_button = _button(buttons, "RESUME", resume, 32)
	_button(buttons, "NARRATION LOG", _show_log)
	_button(buttons, "SAVE GAME", _save)
	_button(buttons, "QUIT TO TITLE", _quit_to_title)
	if not OS.has_feature("web"):
		_button(buttons, "QUIT GAME", _quit)

	_note = _label("", NOTE_FONT, 18, PAPER)
	_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_note.add_theme_color_override(&"font_outline_color", INK)
	_note.add_theme_constant_override(&"outline_size", 6)
	box.add_child(_note)
	return center


func _build_log() -> Control:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in [&"margin_left", &"margin_right"]:
		margin.add_theme_constant_override(side, 90)
	for side in [&"margin_top", &"margin_bottom"]:
		margin.add_theme_constant_override(side, 36)
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 16)
	margin.add_child(box)

	var header := HBoxContainer.new()
	header.add_theme_constant_override(&"separation", 20)
	box.add_child(header)
	var title := _label("WHAT THE NARRATOR SAID", TITLE_FONT, 40, Color("#ffd23f"))
	title.add_theme_color_override(&"font_outline_color", INK)
	title.add_theme_color_override(&"font_shadow_color", INK)
	title.add_theme_constant_override(&"outline_size", 14)
	title.add_theme_constant_override(&"shadow_outline_size", 14)
	title.add_theme_constant_override(&"shadow_offset_x", 5)
	title.add_theme_constant_override(&"shadow_offset_y", 5)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	_button(header, "BACK", _show_menu)

	var paper := PanelContainer.new()
	paper.theme_type_variation = &"PaperPanel"
	paper.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(paper)
	_log_scroll = ScrollContainer.new()
	_log_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	paper.add_child(_log_scroll)
	var pad := MarginContainer.new()
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.add_theme_constant_override(&"margin_left", 8)
	pad.add_theme_constant_override(&"margin_right", 18)
	pad.add_theme_constant_override(&"margin_top", 8)
	pad.add_theme_constant_override(&"margin_bottom", 8)
	_log_scroll.add_child(pad)
	_log_list = VBoxContainer.new()
	_log_list.add_theme_constant_override(&"separation", 14)
	pad.add_child(_log_list)
	return margin


func _button(parent: Control, text: String, action: Callable, font_size := 24) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(300, 0) if parent is VBoxContainer else Vector2.ZERO
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override(&"font_size", font_size)
	button.pressed.connect(action)
	parent.add_child(button)
	return button


func _label(text: String, font: Font, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override(&"font", font)
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_color", color)
	return label
