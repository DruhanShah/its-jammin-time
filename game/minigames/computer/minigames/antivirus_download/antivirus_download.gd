extends Minigame
## Visit 2, beat 2: the antivirus "downloads", but only while the player cranks it. A dark installer
## window over the (dimmed) word processor: a round spinner on the left, a wide bar with the percentage.
## It sits at 0 % until the player clicks the circle, which turns into a crank; rolling the keys around
## G clockwise (TwistInput, with a TwistHint) winds it up, one ratchet click per key. Stop and it slips
## back to the last checkpoint (25/50/75 %); anticlockwise un-downloads. At 100 % it starts "quarantining
## 120 lights", spins on its own and completes: in the story the EventManager → Story → Computer.blackout().
## Free use only completes. Keys never reach the document: the Computer types every key in its own
## `_unhandled_key_input`, so the TwistInput doesn't listen; this feeds it (Esc/F-keys/shortcuts pass).

enum Phase { WAITING, CRANKING, DONE }

const TITLE_FONT := preload("res://assets/fonts/ComicRelief-Bold.ttf")
const MONO_FONT := preload("res://assets/fonts/ComicShannsMono-Regular.ttf")
const HALFTONE := preload("res://core/ui/comic/halftone.gdshader")
const TWIST_HINT := preload("res://core/input/twist_hint.tscn")
const ALARM := Color("#ff5a4a")
const STATUS := Color("#cfc5aa")
## Seconds of clockwise steps the speed readout averages over.
const SPEED_WINDOW := 2.0

## Downloads started this session (a restart after Power gets a "corrupted" status).
static var _attempts := 0

var _phase := Phase.WAITING
var _percent := 0.0
var _peak := 0.0
var _last_clockwise := 0.0
var _slip_timer := 0.0
var _slipping := false
var _turns := 0 ## Full crank turns so far (one creak each).
var _steps: Array[Vector2] = [] ## (time, degrees) of recent clockwise steps, for the speed readout.

var _window: AppWindow
var _dial: CrankDial
var _bar: DownloadBar
var _status: Label
var _speed: Label
var _twist: TwistInput
var _hint: TwistHint
var _ratchet: AudioStreamPlayer


func begin() -> void:
	_attempts += 1
	var cfg := _cfg()
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	add_child(dim)
	dim.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_twist = TwistInput.new()
	_twist.listen = false
	add_child(_twist)
	_twist.twisted.connect(_on_twisted)
	_ratchet = AudioStreamPlayer.new()
	_ratchet.bus = &"SFX"
	_ratchet.max_polyphony = 4
	_ratchet.stream = cfg.ratchet_sfx
	_ratchet.volume_db = cfg.ratchet_db
	add_child(_ratchet)
	_build_window(cfg)
	_hint = TWIST_HINT.instantiate() as TwistHint
	_hint.twist = _twist
	_hint.arrow_direction = 1
	_hint.intro_cue = &"" # twist_tutorial is about screws; no line here.
	_hint.key_color = Color(0.36, 0.37, 0.43, 0.95)
	_hint.hide()
	add_child(_hint)
	_status.text = cfg.restart_text if _attempts > 1 else cfg.waiting_text
	_layout.call_deferred()
	_window.pop_in()
	Narrator.play(cfg.intro_cue)


func _cfg() -> AntivirusDownloadConfig:
	return config as AntivirusDownloadConfig


## The installer sits right of centre so the key hint fits on its left, its ring level with the dial.
func _layout() -> void:
	_window.size = _window.get_combined_minimum_size()
	_window.position = Vector2(size.x - _window.size.x - 24.0, (size.y - _window.size.y) / 2.0 - 30.0).round()
	var dial_centre := _dial.get_global_rect().get_center() - global_position
	_hint.position = Vector2((_window.position.x - _hint.size.x) / 2.0, dial_centre.y - _hint.size.x / 2.0).round()


## Percent per degree of the key ring.
func _per_degree() -> float:
	return 100.0 / (360.0 * _cfg().rotations_to_finish)


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key.keycode == KEY_ESCAPE or (key.keycode >= KEY_F1 and key.keycode <= KEY_F12) or key.ctrl_pressed or key.meta_pressed:
		return # Debug keys and shortcuts go through.
	get_viewport().set_input_as_handled() # Nothing types into the document behind the installer.
	if _phase == Phase.CRANKING:
		_twist.handle(event)


func _process(delta: float) -> void:
	if _phase == Phase.CRANKING:
		_slip(delta)
		_refresh_speed()


func _build_window(cfg: AntivirusDownloadConfig) -> void:
	_window = AppWindow.new()
	_window.title = cfg.title
	_window.title_color = Color("#ff4d4d")
	_window.paper_color = Color("#1b1d22")
	_window.closable = false
	_window.draggable = false
	_window.padding = 8.0
	add_child(_window)

	var backdrop := ColorRect.new()
	backdrop.mouse_filter = MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = HALFTONE
	mat.set_shader_parameter(&"paper_color", Color("#1b1d22"))
	mat.set_shader_parameter(&"dot_color", Color("#2c3038"))
	mat.set_shader_parameter(&"cell_size", 7.0)
	mat.set_shader_parameter(&"radial", 0.6)
	backdrop.material = mat
	_window.add_child(backdrop)

	var margin := MarginContainer.new()
	for side: StringName in [&"margin_left", &"margin_right", &"margin_top", &"margin_bottom"]:
		margin.add_theme_constant_override(side, 26)
	margin.mouse_filter = MOUSE_FILTER_IGNORE
	_window.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 16)
	box.mouse_filter = MOUSE_FILTER_IGNORE
	margin.add_child(box)
	box.add_child(_label(cfg.heading, TITLE_FONT, 30, Color("#f1e4c3")))
	box.add_child(_label(cfg.file_text, MONO_FONT, 16, Color("#a9a08a")))

	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 28)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = MOUSE_FILTER_IGNORE
	box.add_child(row)
	_dial = CrankDial.new()
	_dial.custom_minimum_size = Vector2(164, 164)
	_dial.pressed.connect(_on_dial_pressed)
	row.add_child(_dial)
	_bar = DownloadBar.new()
	_bar.custom_minimum_size = Vector2(500, 96)
	_bar.size_flags_vertical = SIZE_SHRINK_CENTER
	_bar.checkpoints = cfg.checkpoints
	_bar.number_size = 56
	row.add_child(_bar)

	_status = _label("", MONO_FONT, 18, STATUS)
	box.add_child(_status)
	_speed = _label(cfg.speed_text % 0, MONO_FONT, 14, Color("#8f8775"))
	box.add_child(_speed)


func _label(text: String, font: Font, size_px: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override(&"font", font)
	label.add_theme_font_size_override(&"font_size", size_px)
	label.add_theme_color_override(&"font_color", color)
	return label


func _on_dial_pressed() -> void:
	if _phase != Phase.WAITING:
		return
	_phase = Phase.CRANKING
	_dial.engaged = true
	_dial.pop()
	_play(_cfg().engage_sfx, _cfg().engage_db)
	_hint.show()
	_last_clockwise = _now()
	_refresh_status()


func _on_twisted(delta: float) -> void:
	if _phase != Phase.CRANKING:
		return
	var now := _now()
	_ratchet.pitch_scale = 1.0 if delta > 0.0 else 0.85
	_ratchet.play()
	if delta > 0.0:
		_last_clockwise = now
		_steps.append(Vector2(now, delta))
		_set_percent(_percent + delta * _per_degree())
	else:
		_set_percent(maxf(_floor(), _percent + delta * _per_degree()))


## Not cranking for `slip_delay` → it unwinds toward the last checkpoint reached, ticking slowly.
func _slip(delta: float) -> void:
	var cfg := _cfg()
	var floor_percent := _floor()
	if _now() - _last_clockwise < cfg.slip_delay or _percent <= floor_percent:
		_slipping = false
		return
	if not _slipping:
		_slipping = true
		_slip_timer = 0.0
	_slip_timer -= delta
	if _slip_timer <= 0.0:
		_slip_timer = cfg.slip_tick
		_ratchet.pitch_scale = cfg.slip_pitch
		_ratchet.play()
	_set_percent(maxf(floor_percent, _percent - cfg.slip_rate * delta))
	if _percent <= floor_percent:
		_slipping = false
		_play(cfg.clack_sfx, cfg.clack_db)
		_bar.shake()


## The highest checkpoint reached so far (slipping and turning back stop there).
func _floor() -> float:
	var best := 0.0
	for mark in _cfg().checkpoints:
		if _peak >= mark:
			best = maxf(best, mark)
	return best


func _set_percent(value: float) -> void:
	var cfg := _cfg()
	_percent = clampf(value, 0.0, 100.0)
	_peak = maxf(_peak, _percent)
	_bar.value = _percent
	_dial.angle = _percent / _per_degree() * cfg.spin_ratio
	_hint.progress = _percent / 100.0
	var turns := int(_dial.angle / 360.0)
	if turns > _turns:
		_turns = turns
		_play(cfg.creak_sfx, cfg.creak_db)
	_refresh_status()
	if _percent >= 100.0:
		_finish()


func _refresh_status() -> void:
	var cfg := _cfg()
	var text := ""
	for entry: Array in cfg.status_texts:
		if _percent >= entry[0]:
			text = entry[1]
	_status.text = text
	_status.add_theme_color_override(&"font_color", ALARM if _percent >= cfg.alarm_from else STATUS)


func _refresh_speed() -> void:
	var now := _now()
	while _steps and now - _steps[0].x > SPEED_WINDOW:
		_steps.pop_front()
	var degrees := 0.0
	for step in _steps:
		degrees += step.y
	_speed.text = _cfg().speed_text % roundi(degrees / 360.0 * 60.0 / SPEED_WINDOW)


func _finish() -> void:
	var cfg := _cfg()
	_phase = Phase.DONE
	_bar.flash()
	_bar.fill_color = Color("#ff6a3d")
	ComicBurst.spawn(self, _bar.get_global_rect().get_center(), "DING!")
	_play(cfg.done_sfx, cfg.done_db)
	_status.text = cfg.done_text
	_status.add_theme_color_override(&"font_color", ALARM)
	_speed.text = cfg.speed_text % roundi(cfg.done_spin / 6.0)
	_dial.self_spin = cfg.done_spin
	create_tween().tween_property(_hint, "modulate:a", 0.0, 0.3)
	get_tree().create_timer(cfg.finish_hold).timeout.connect(complete)


func _play(stream: AudioStream, volume_db: float) -> void:
	if stream:
		Audio.play_sfx(stream, volume_db)
