extends Minigame
## Visit 1, beat 2: opening the word processor. The narrator complains, the toolbar's font box pulses,
## and the player has to pick a font from its list (built here, under `computer.font_button`). Only a
## Comic font is accepted ("Comic Sans" is drawn with Comic Relief: we can't ship Microsoft's). Every
## other pick gets a red strike-through, a buzzer and the narrator's "Try again"; from the 2nd wrong
## pick the remaining non-Comic rows wobble. A Comic pick → KA-CHING! + confetti, GameState.document_font
## (+ name), the document switches font, complete(). Typing before that just opens the font list.
## Non-Comic rows are drawn with bundled free look-alike fonts (OFL, see `assets/fonts/CREDITS.md`), so
## they look the same everywhere, web included; the menu labels are the real names, no Microsoft or
## other commercial font is shipped.

const ROW_FONT_SIZE := 24
const ROW_HEIGHT := 38.0
const STRIKE_COLOR := Color("#e0201b")
## Top to bottom (the Comic ones at the bottom). `file`: the bundled font the row (and, for a Comic one,
## the document) is drawn with; `comic`: accepted.
const FONTS: Array[Dictionary] = [
	{"name": "Times New Roman", "file": "res://assets/fonts/Tinos-Regular-Latin.ttf"},
	{"name": "Arial", "file": "res://assets/fonts/Arimo-Regular-Latin.ttf"},
	{"name": "Helvetica", "file": "res://assets/fonts/Arimo-Regular-Latin.ttf"},
	{"name": "Calibri", "file": "res://assets/fonts/OfficeSans-Regular-Latin.ttf"},
	{"name": "Garamond", "file": "res://assets/fonts/EBGaramond-Regular-Latin.ttf"},
	{"name": "Papyrus", "file": "res://assets/fonts/Almendra-Regular.ttf"},
	{"name": "Impact", "file": "res://assets/fonts/Anton-Regular-Latin.ttf"},
	{"name": "Wingdings", "file": "res://assets/fonts/Jamdings-Regular.ttf"},
	{"name": "Comic Neue", "file": "res://assets/fonts/ComicNeue-Regular.ttf", "comic": true},
	{"name": "Comic Relief", "file": "res://assets/fonts/ComicRelief-Regular.ttf", "comic": true},
	{"name": "Comic Shanns Mono", "file": "res://assets/fonts/ComicShannsMono-Regular.ttf", "comic": true},
	{"name": "Comic Sans", "file": "res://assets/fonts/ComicRelief-Regular.ttf", "comic": true},
]

var _rows: Array[Button] = [] ## Same order as FONTS.
var _struck := {} ## Row index -> true.
var _wrong := 0
var _done := false
var _pulse: Tween
var _sticker: ComicBurst

@onready var catcher: Control = %Catcher
@onready var dropdown: Control = %Dropdown
@onready var list: VBoxContainer = %List
@onready var confetti: CPUParticles2D = %Confetti


func _ready() -> void:
	catcher.gui_input.connect(_on_catcher_input)


func begin() -> void:
	for i in FONTS.size():
		_rows.append(_make_row(i))
	computer.font_button.pressed.connect(_open_list)
	Narrator.play(_cfg().open_cue)
	_pulse = create_tween().set_loops()
	_pulse.tween_property(computer.font_button, "modulate", Color(1, 0.75, 0.3), 0.35).set_trans(Tween.TRANS_SINE)
	_pulse.tween_property(computer.font_button, "modulate", Color.WHITE, 0.35).set_trans(Tween.TRANS_SINE)
	var box := _local_rect(computer.font_button)
	_sticker = ComicBurst.sticker(self, Vector2(box.end.x + 300.0, box.get_center().y + 4.0), "PICK A FONT!", Color("#ffe14d"), 18)


func cleanup() -> void:
	if computer.font_button.pressed.is_connected(_open_list):
		computer.font_button.pressed.disconnect(_open_list)
	computer.font_button.modulate = Color.WHITE


func _process(_delta: float) -> void:
	if _wrong < _cfg().wobble_after_wrong:
		return
	var t := Time.get_ticks_msec() / 1000.0
	for i in _rows.size():
		if not _struck.has(i) and not FONTS[i].has("comic"):
			_rows[i].rotation = sin(t * 9.0 + i) * 0.035


## Nothing types until a font is chosen; a key just opens the font list. Debug F-keys get through.
func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if _done or (key.keycode >= KEY_F1 and key.keycode <= KEY_F12):
		return
	get_viewport().set_input_as_handled()
	if key.pressed and not key.echo:
		_open_list()


func _open_list() -> void:
	if _done or dropdown.visible:
		return
	var box := _local_rect(computer.font_button)
	dropdown.position = Vector2(box.position.x, box.end.y + 4.0)
	dropdown.show()
	catcher.show()
	dropdown.pivot_offset = Vector2(dropdown.size.x / 2.0, 0.0)
	dropdown.scale = Vector2(1.0, 0.6)
	create_tween().tween_property(dropdown, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _close_list() -> void:
	dropdown.hide()
	catcher.hide()


func _on_catcher_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click and click.pressed:
		_close_list()


## A row is a Button inside a plain slot Control, so the VBox never resets its rotation (containers
## do on every sort) while it wobbles.
func _make_row(i: int) -> Button:
	var slot := Control.new()
	slot.custom_minimum_size = Vector2(0, ROW_HEIGHT)
	slot.mouse_filter = MOUSE_FILTER_IGNORE
	list.add_child(slot)
	var row := Button.new()
	row.text = FONTS[i].name
	row.focus_mode = FOCUS_NONE
	row.alignment = HORIZONTAL_ALIGNMENT_LEFT
	row.mouse_default_cursor_shape = CURSOR_POINTING_HAND
	row.add_theme_font_override(&"font", _font_for(FONTS[i]))
	row.add_theme_font_size_override(&"font_size", ROW_FONT_SIZE)
	for state: StringName in [&"font_color", &"font_hover_color", &"font_pressed_color", &"font_focus_color"]:
		row.add_theme_color_override(state, Color(0.08, 0.08, 0.1))
	var plain := _row_style(Color(0, 0, 0, 0))
	var lit := _row_style(Color("#ffe14d"))
	for state: StringName in [&"normal", &"disabled", &"focus"]:
		row.add_theme_stylebox_override(state, plain)
	row.add_theme_stylebox_override(&"hover", lit)
	row.add_theme_stylebox_override(&"pressed", lit)
	slot.add_child(row)
	row.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	row.resized.connect(func() -> void: row.pivot_offset = row.size / 2.0)
	row.mouse_entered.connect(_on_hover)
	row.pressed.connect(_choose.bind(i))
	row.draw.connect(_draw_strike.bind(i))
	return row


func _font_for(entry: Dictionary) -> Font:
	return load(entry.file)


func _on_hover() -> void:
	if _cfg().hover_sfx:
		Audio.play_sfx(_cfg().hover_sfx, _cfg().hover_db)


func _choose(i: int) -> void:
	if _done:
		return
	if FONTS[i].has("comic"):
		_accept(i)
		return
	_shake(dropdown)
	if _struck.has(i):
		return
	_wrong += 1
	_struck[i] = true
	_rows[i].rotation = 0.0
	_rows[i].queue_redraw()
	_play(_cfg().wrong_sfx)
	Narrator.play(_cfg().wrong_cue) # Repeats on purpose: same complaint, every time.


func _accept(i: int) -> void:
	_done = true
	var cfg := _cfg()
	GameState.document_font = FONTS[i].file
	GameState.document_font_name = FONTS[i].name
	computer.apply_document_font()
	_pulse.kill()
	computer.font_button.modulate = Color.WHITE
	_sticker.queue_free()
	_rows[i].add_theme_stylebox_override(&"normal", _rows[i].get_theme_stylebox(&"hover"))
	_play(cfg.accept_sfx)
	var center := _rows[i].get_global_rect().get_center()
	ComicBurst.spawn(self, center, "KA-CHING!")
	confetti.global_position = center
	confetti.restart()
	Narrator.play(cfg.accept_cue)
	var tween := create_tween() # A tween, not a timer: it dies with the minigame if Power is pressed.
	tween.tween_interval(0.8)
	tween.tween_callback(_close_list)
	tween.tween_interval(maxf(0.0, cfg.accept_delay - 0.8))
	tween.tween_callback(complete)


func _shake(control: Control) -> void:
	var home := control.position
	var tween := create_tween()
	for offset: float in [8.0, -8.0, 5.0, -3.0, 0.0]:
		tween.tween_property(control, "position:x", home.x + offset, 0.04)


func _play(stream: AudioStream) -> void:
	if stream:
		Audio.play_sfx(stream)


## `control`'s rect in this (full-screen) minigame's coordinates.
func _local_rect(control: Control) -> Rect2:
	var rect := control.get_global_rect()
	rect.position -= global_position
	return rect


func _draw_strike(i: int) -> void:
	if not _struck.has(i):
		return
	var row := _rows[i]
	var left := row.get_theme_stylebox(&"normal").get_margin(SIDE_LEFT)
	var width := row.get_theme_font(&"font").get_string_size(row.text, HORIZONTAL_ALIGNMENT_LEFT, -1, ROW_FONT_SIZE).x
	var y := row.size.y / 2.0
	row.draw_line(Vector2(left - 4.0, y), Vector2(minf(left + width + 4.0, row.size.x - 2.0), y), STRIKE_COLOR, 4.0)


func _cfg() -> FontPickerConfig:
	return config as FontPickerConfig


func _row_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(6)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	return style
