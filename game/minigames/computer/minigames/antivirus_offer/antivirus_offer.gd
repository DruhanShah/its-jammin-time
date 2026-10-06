extends Minigame
## Visit 2, beat 1: a "free" antivirus pop-up (ZappWare Total Defence 3000) with no close X. The word
## processor stays visible behind a dim layer. Where the X should be there is only a dashed outline (as
## if it was peeled off): clicking it, or pressing Esc, shakes the window ("NOPE!"). "Remind me later"
## turns into "Remind me NOW" and then downloads too; dragging the window off screen springs it back;
## idling wiggles the DOWNLOAD button. DOWNLOAD closes the window ("DOWNLOADING!") and completes, and
## the next step (`antivirus_download`) takes over. Every key is swallowed while it's up (nothing types
## behind it), except the F-keys and Ctrl/Cmd shortcuts (debug keys).

const HEADLINE_FONT := preload("res://assets/fonts/ComicRelief-Bold.ttf")
const BODY_FONT := preload("res://assets/fonts/ComicNeue-Regular.ttf")
const FINE_FONT := preload("res://assets/fonts/ComicNeue-Italic.ttf")
const GHOST_SIZE := 32.0

var _window: AppWindow
var _download: Button
var _download_slot: Control
var _later: LinkButton
var _later_slot: Control
var _ghost: Control
var _idle := 0.0
var _nudged := false
var _refusals := 0
var _later_clicks := 0
var _dragged := false
var _sprung := false
var _done := false
var _shown := false


func begin() -> void:
	var cfg := _cfg()
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.35)
	add_child(dim)
	dim.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_build_window(cfg)
	_window.hide()
	get_tree().create_timer(cfg.appear_delay).timeout.connect(_appear)


func _cfg() -> AntivirusOfferConfig:
	return config as AntivirusOfferConfig


func _appear() -> void:
	if _done or not is_inside_tree():
		return
	_window.size = _window.get_combined_minimum_size()
	_window.position = _centre()
	_window.pop_in()
	_shown = true
	_pulse_download()
	Narrator.play(_cfg().intro_cue)


func _process(delta: float) -> void:
	if not _shown or _done:
		return
	_idle += delta
	if _idle >= _cfg().nudge_after and not _nudged:
		_nudged = true
		_wiggle_download()
		Narrator.play(_cfg().nudge_cue)


## Swallow every key while the pop-up is up; Esc is a refused "close". Debug F-keys and shortcuts pass.
func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if (key.keycode >= KEY_F1 and key.keycode <= KEY_F12) or key.ctrl_pressed or key.meta_pressed:
		return
	get_viewport().set_input_as_handled()
	if key.pressed and not key.echo and key.keycode == KEY_ESCAPE and _shown and not _done:
		_refuse(_ghost.get_global_rect().get_center())


func _build_window(cfg: AntivirusOfferConfig) -> void:
	_window = AppWindow.new()
	_window.title = cfg.title
	_window.title_color = Color("#ff4d4d")
	_window.closable = false
	_window.close_word = "DOWNLOADING!"
	add_child(_window)
	_window.gui_input.connect(_on_window_input)
	_ghost = Control.new()
	_ghost.mouse_filter = MOUSE_FILTER_STOP
	_ghost.size = Vector2(GHOST_SIZE, GHOST_SIZE)
	_ghost.draw.connect(_draw_ghost_x)
	_ghost.gui_input.connect(_on_ghost_input)
	_window.add_child(_ghost, false, INTERNAL_MODE_BACK)
	_window.resized.connect(func() -> void: _ghost.position = Vector2(_window.size.x - GHOST_SIZE - 7.0, 6.0))

	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 12)
	box.custom_minimum_size = Vector2(580, 0)
	_window.add_child(box)

	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 18)
	box.add_child(row)
	var zappy := Zappy.new()
	zappy.custom_minimum_size = Vector2(130, 150)
	row.add_child(zappy)
	var pitch := VBoxContainer.new()
	pitch.size_flags_horizontal = SIZE_EXPAND_FILL
	pitch.add_theme_constant_override(&"separation", 6)
	row.add_child(pitch)
	pitch.add_child(_label(cfg.headline, HEADLINE_FONT, 28, Color("#d62828")))
	pitch.add_child(_label(cfg.body, BODY_FONT, 18, Color(0.1, 0.1, 0.12)))
	pitch.add_child(_label(cfg.tagline, FINE_FONT, 16, Color(0.2, 0.2, 0.25)))
	pitch.add_child(_label(cfg.fine_print, FINE_FONT, 12, Color(0.45, 0.45, 0.48)))

	_download_slot = Control.new()
	_download_slot.custom_minimum_size = Vector2(440, 68)
	_download_slot.size_flags_horizontal = SIZE_SHRINK_CENTER
	_download_slot.mouse_filter = MOUSE_FILTER_IGNORE
	box.add_child(_download_slot)
	_download = Button.new()
	_download.text = cfg.download_text
	_download.focus_mode = FOCUS_NONE
	_download.mouse_default_cursor_shape = CURSOR_POINTING_HAND
	_download.add_theme_font_override(&"font", HEADLINE_FONT)
	_download.add_theme_font_size_override(&"font_size", 28)
	for state: StringName in [&"font_color", &"font_hover_color", &"font_pressed_color", &"font_focus_color"]:
		_download.add_theme_color_override(state, Color.WHITE)
	_download.add_theme_color_override(&"font_outline_color", Color.BLACK)
	_download.add_theme_constant_override(&"outline_size", 8)
	_download.add_theme_stylebox_override(&"normal", _button_style(Color("#2fbf4a")))
	_download.add_theme_stylebox_override(&"hover", _button_style(Color("#45d862")))
	_download.add_theme_stylebox_override(&"pressed", _button_style(Color("#24963a")))
	_download.add_theme_stylebox_override(&"disabled", _button_style(Color("#24963a")))
	_download.add_theme_stylebox_override(&"focus", StyleBoxEmpty.new())
	_download_slot.add_child(_download)
	_download.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_download.resized.connect(func() -> void: _download.pivot_offset = _download.size / 2.0)
	_download.pressed.connect(_on_download)

	_later_slot = Control.new()
	_later_slot.custom_minimum_size = Vector2(200, 24)
	_later_slot.size_flags_horizontal = SIZE_SHRINK_CENTER
	_later_slot.mouse_filter = MOUSE_FILTER_IGNORE
	box.add_child(_later_slot)
	_later = LinkButton.new()
	_later.text = cfg.later_text
	_later.focus_mode = FOCUS_NONE
	_later.mouse_default_cursor_shape = CURSOR_POINTING_HAND
	_later.add_theme_font_override(&"font", BODY_FONT)
	_later.add_theme_font_size_override(&"font_size", 15)
	for state: StringName in [&"font_color", &"font_hover_color", &"font_pressed_color", &"font_focus_color"]:
		_later.add_theme_color_override(state, Color(0.45, 0.45, 0.5))
	_later_slot.add_child(_later)
	_later.set_anchors_and_offsets_preset(PRESET_CENTER)
	_later.resized.connect(_centre_later)
	_later_slot.resized.connect(_centre_later)
	_later.pressed.connect(_on_later)


func _label(text: String, font: Font, size_px: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(400, 0)
	label.add_theme_font_override(&"font", font)
	label.add_theme_font_size_override(&"font_size", size_px)
	label.add_theme_color_override(&"font_color", color)
	return label


func _button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color.BLACK
	style.set_border_width_all(4)
	style.set_corner_radius_all(14)
	style.shadow_color = Color(0, 0, 0, 0.85)
	style.shadow_offset = Vector2(5, 5)
	style.shadow_size = 1
	style.anti_aliasing = true
	return style


func _centre() -> Vector2:
	return ((size - _window.size) / 2.0).round()


func _centre_later() -> void:
	_later.position = ((_later_slot.size - _later.size) / 2.0).round()


func _pulse_download() -> void:
	var tween := create_tween().set_loops()
	tween.tween_property(_download, "scale", Vector2.ONE * 1.05, 0.4).set_trans(Tween.TRANS_SINE)
	tween.tween_property(_download, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_SINE)


func _wiggle_download() -> void:
	var tween := create_tween()
	for i in 6:
		tween.tween_property(_download, "rotation", deg_to_rad(6.0 if i % 2 == 0 else -6.0), 0.06)
	tween.tween_property(_download, "rotation", 0.0, 0.06)


## Where the X used to be: a dashed square with a faint X, as if someone peeled it off.
func _draw_ghost_x() -> void:
	var rect := Rect2(Vector2.ZERO, _ghost.size).grow(-2.0)
	_ghost.draw_rect(rect, Color(1, 1, 1, 0.35))
	var corners := [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]
	for i in 4:
		_ghost.draw_dashed_line(corners[i], corners[(i + 1) % 4], Color(0, 0, 0, 0.6), 2.0, 4.0, true, true)
	var font := HEADLINE_FONT
	var x_size := font.get_string_size("X", HORIZONTAL_ALIGNMENT_LEFT, -1, 18)
	_ghost.draw_string(font, Vector2((_ghost.size.x - x_size.x) / 2.0, (_ghost.size.y + x_size.y * 0.55) / 2.0), "X",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0, 0, 0, 0.2))


func _on_ghost_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		_ghost.accept_event()
		_refuse(click.global_position)


## The "close" that isn't: the window shakes, NOPE!, and the narrator comments.
func _refuse(where: Vector2) -> void:
	if _done:
		return
	_idle = 0.0
	_window.shake()
	ComicBurst.spawn(self, where, "NOPE!", Color("#ff7a6b"))
	if _cfg().refuse_sfx:
		Audio.play_sfx(_cfg().refuse_sfx, _cfg().refuse_db)
	_refusals += 1
	if _refusals == 1:
		Narrator.play(_cfg().no_x_cue)
	elif not Narrator.is_speaking():
		Narrator.play(_cfg().no_x_again_cue)


## Clicks reset the idle nudge; a drag that leaves most of the window off screen springs it back.
func _on_window_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button and button.button_index == MOUSE_BUTTON_LEFT:
		_idle = 0.0
		if button.pressed:
			_dragged = false
		elif _dragged:
			_check_off_screen()
	var motion := event as InputEventMouseMotion
	if motion and motion.button_mask & MOUSE_BUTTON_MASK_LEFT:
		_dragged = true


func _check_off_screen() -> void:
	var rect := _window.get_rect()
	var visible_area := rect.intersection(Rect2(Vector2.ZERO, size)).get_area()
	if visible_area >= rect.get_area() * _cfg().min_on_screen:
		return
	var tween := create_tween()
	tween.tween_property(_window, "position", _centre(), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if not _sprung:
		_sprung = true
		Narrator.play(_cfg().drag_away_cue)


func _on_later() -> void:
	if _done:
		return
	_idle = 0.0
	_later_clicks += 1
	if _later_clicks >= 2:
		_on_download()
		return
	_later.text = _cfg().later_again_text
	var tween := create_tween()
	tween.tween_property(_later, "position:y", _later.position.y - 16.0, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(_later, "position:y", _later.position.y, 0.25).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	Narrator.play(_cfg().remind_cue)


func _on_download() -> void:
	if _done:
		return
	_done = true
	_download.disabled = true
	_later.disabled = true
	ComicBurst.spawn(self, _download.get_global_rect().get_center(), "POW!")
	if _cfg().download_sfx:
		Audio.play_sfx(_cfg().download_sfx, _cfg().download_db)
	_window.closed.connect(complete)
	_window.close()
