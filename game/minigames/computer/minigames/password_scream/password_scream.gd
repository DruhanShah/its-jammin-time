extends Minigame
## Login screen (VoiceLogin): scream/say the password, it fails `screams_needed` times on purpose
## (2 scripted verdicts, PasswordScreamConfig: prompts / fail_lines / fail_cues), then it lets you type
## it instead: the mic slides off and a plain text box accepts anything → complete(). A full-screen
## halftone login over the desktop with an AppWindow, a cartoon mic and a live waveform of the real mic.
##
## An attempt ends once the input stayed above `threshold_db` for `scream_time` (a scream) and then
## went quiet for `quiet_time`, or after `listen_timeout` with no scream at all (so silent players, no mic or a denied permission still get
## through). If the input is dead silent for `fake_after` s the waveform is faked (plausible random speech that also reacts to
## keys and the mouse) and says so.
##
## Mic capture: an AudioStreamMicrophone plays into a muted "MicTap" bus (created at runtime if
## missing) whose AudioEffectCapture is read every frame; needs the project setting
## audio/driver/enable_input. On the web the browser asks for the mic when it starts (https only, e.g.
## itch.io); until it's allowed, or if it's denied, the input is silent and the fake waveform shows.
## Nothing is recorded or kept: each frame's samples are reduced to one level and dropped.

enum Phase { LISTEN, PROCESS, VERDICT, WAIT_NO, FALLBACK, TYPE, DONE }

const BUS := &"MicTap"
## Seconds per waveform bar.
const BAR_TIME := 1.0 / 30.0
const SPINNER := ["|", "/", "-", "\\"]

var _phase := Phase.LISTEN
var _attempt := 0 ## 0-based attempt in progress.
var _timer := 0.0 ## Seconds in the current phase.
var _voice := 0.0 ## Seconds of voice this attempt.
var _quiet := 0.0 ## Seconds of quiet since the voice.
var _heard := false
var _level := 0.0 ## Current input level 0..1.
var _peak_db := -80.0 ## Loudest sample this frame.
var _dead_time := 0.0 ## Seconds the input has been exactly silent.
var _fake := false
var _fake_level := 0.0
var _fake_kick := 0.0
var _syllable_target := 0.0 ## Fake waveform: level of the current syllable or pause.
var _syllable_left := 0.0
var _bar_time := 0.0
var _player: AudioStreamPlayer
var _capture: AudioEffectCapture

@onready var window: AppWindow = %Window
@onready var prompt: Label = %Prompt
@onready var mic: Control = %Mic
@onready var waveform: Control = %Waveform
@onready var wave_note: Label = %WaveNote
@onready var verdict: Label = %Verdict
@onready var no_button: Button = %NoButton
@onready var listen_row: Control = %ListenRow
@onready var password_box: LineEdit = %Password
@onready var type_hint: Label = %TypeHint


func _ready() -> void:
	no_button.pressed.connect(_on_no_pressed)
	password_box.text_submitted.connect(_on_password_submitted)
	window.close_requested.connect(_on_close_requested)


func begin() -> void:
	window.hide()
	window.pop_in.call_deferred()
	_start_mic()
	_listen()


func cleanup() -> void:
	_stop_mic()
	var bus := AudioServer.get_bus_index(BUS)
	if bus >= 0:
		AudioServer.remove_bus(bus)


func _process(delta: float) -> void:
	_timer += delta
	_read_input(delta)
	_bar_time += delta
	if _bar_time >= BAR_TIME:
		_bar_time = 0.0
		waveform.push(_shown_level())
	mic.level = _shown_level() if _phase == Phase.LISTEN else 0.0
	match _phase:
		Phase.LISTEN:
			_update_listen(delta)
		Phase.PROCESS:
			verdict.text = "Processing %s" % SPINNER[int(_timer * 10.0) % SPINNER.size()]
			if _timer >= (config as PasswordScreamConfig).processing_time:
				_show_verdict()
		Phase.VERDICT:
			if _timer >= (config as PasswordScreamConfig).verdict_time:
				_next_attempt()


func _unhandled_key_input(event: InputEvent) -> void:
	if _phase == Phase.TYPE or _phase == Phase.DONE:
		return
	if event.is_pressed():
		_fake_kick = 1.0
	get_viewport().set_input_as_handled() # Don't type into the document hidden behind the login.


func _input(event: InputEvent) -> void:
	var motion := event as InputEventMouseMotion
	if motion and _fake:
		_fake_kick = maxf(_fake_kick, minf(motion.relative.length() / 60.0, 0.7))


# --- Attempts ---------------------------------------------------------------------------------------

func _listen() -> void:
	var cfg := config as PasswordScreamConfig
	_set_phase(Phase.LISTEN)
	_voice = 0.0
	_quiet = 0.0
	_heard = false
	prompt.text = cfg.prompts[_attempt]
	verdict.text = ""
	no_button.hide()
	waveform.status = "● REC"
	waveform.status_color = Color("#ff5a4f")
	waveform.blink = true


func _update_listen(delta: float) -> void:
	var cfg := config as PasswordScreamConfig
	var is_voice := not _fake and _peak_db >= cfg.threshold_db
	if is_voice:
		_voice += delta
		_quiet = 0.0
		_heard = _heard or _voice >= cfg.scream_time
	elif _heard:
		_quiet += delta
	var finished := _heard and _quiet >= cfg.quiet_time
	var timed_out := not _heard and _timer >= cfg.listen_timeout
	if finished or timed_out or _timer >= cfg.max_listen_time:
		_set_phase(Phase.PROCESS)
		waveform.status = "PROCESSING"
		waveform.status_color = Color("#ffd23f")
		waveform.blink = false


func _show_verdict() -> void:
	var cfg := config as PasswordScreamConfig
	var number := _attempt + 1
	_set_phase(Phase.VERDICT)
	waveform.status = "✗ FAILED"
	verdict.text = cfg.fail_lines[_attempt]
	_pop(verdict, 1.25)
	window.shake(6.0)
	var cue: StringName = cfg.fail_cues[_attempt] if _attempt < cfg.fail_cues.size() else &""
	if cue:
		Narrator.play(cue)
	if number == cfg.droop_attempt:
		mic.droop()
	if number == cfg.no_button_attempt:
		_set_phase(Phase.WAIT_NO)
		no_button.show()
		_pop(no_button, 1.3)


func _on_no_pressed() -> void:
	if _phase == Phase.WAIT_NO:
		no_button.hide()
		_next_attempt()


func _next_attempt() -> void:
	_attempt += 1
	if _attempt < _attempts():
		_listen()
	else:
		_fallback()


## The mic gives up: it slides off and a plain text box drops in.
func _fallback() -> void:
	_set_phase(Phase.FALLBACK)
	_stop_mic()
	var tween := create_tween()
	tween.tween_property(listen_row, "modulate:a", 0.0, 0.35)
	tween.parallel().tween_property(mic, "position:y", mic.position.y + 400.0, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_callback(_show_text_box)


func _show_text_box() -> void:
	_set_phase(Phase.TYPE)
	listen_row.hide()
	wave_note.hide()
	verdict.text = ""
	prompt.text = "Or just type it, I guess."
	var cue := (config as PasswordScreamConfig).type_cue
	if cue:
		Narrator.play(cue)
	type_hint.show()
	password_box.show()
	password_box.pivot_offset = password_box.size / 2.0
	_pop(password_box, 0.4)
	password_box.grab_focus.call_deferred()


func _on_password_submitted(text: String) -> void:
	var cfg := config as PasswordScreamConfig
	if _phase != Phase.TYPE or text.strip_edges().is_empty():
		window.shake(5.0)
		return
	_set_phase(Phase.DONE)
	GameState.password = text.strip_edges()
	password_box.editable = false
	type_hint.hide()
	verdict.add_theme_color_override(&"font_color", Color("#14853b"))
	verdict.text = cfg.accepted_line
	_pop(verdict, 1.25)
	if cfg.accepted_cue:
		Narrator.play(cfg.accepted_cue)
	var tween := create_tween()
	tween.tween_interval(3.0)
	tween.tween_callback(window.close.bind("ACCESS!"))
	window.closed.connect(_finish)


## Lets the (long) welcome line finish before the next screen talks over it.
func _finish(_reason := "") -> void:
	var waited := 0.0
	while Narrator.is_speaking() and waited < 25.0:
		await get_tree().create_timer(0.25).timeout
		waited += 0.25
	complete()


## The login screen can't be closed: you're not logged in.
func _on_close_requested() -> void:
	window.shake()


func _attempts() -> int:
	var cfg := config as PasswordScreamConfig
	return mini(cfg.screams_needed, mini(cfg.prompts.size(), cfg.fail_lines.size()))


func _set_phase(phase: Phase) -> void:
	_phase = phase
	_timer = 0.0


# --- Microphone -------------------------------------------------------------------------------------

func _start_mic() -> void:
	var bus := AudioServer.get_bus_index(BUS)
	if bus == -1:
		bus = AudioServer.bus_count
		AudioServer.add_bus(bus)
		AudioServer.set_bus_name(bus, BUS)
		AudioServer.set_bus_mute(bus, true) # Never hear yourself; the capture still reads it.
		AudioServer.add_bus_effect(bus, AudioEffectCapture.new())
	_capture = AudioServer.get_bus_effect(bus, 0) as AudioEffectCapture
	_capture.clear_buffer()
	_player = AudioStreamPlayer.new()
	_player.stream = AudioStreamMicrophone.new()
	_player.bus = BUS
	# Bus effects need Godot's own mixer; the web's default "Sample" playback skips them.
	_player.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
	add_child(_player)
	_player.play()


func _stop_mic() -> void:
	if _player:
		_player.stop()
		_player.queue_free()
		_player = null
	if _capture:
		_capture.clear_buffer()
		_capture = null


## Reduces this frame's mic samples to one level (RMS in dB mapped -60..0 dB → 0..1) and keeps the
## noise floor and the fake-waveform switch up to date.
func _read_input(delta: float) -> void:
	var peak := 0.0
	var sum := 0.0
	var read := 0
	if _capture:
		var frames := _capture.get_frames_available()
		if frames > 0:
			for frame in _capture.get_buffer(frames):
				var sample := (frame.x + frame.y) * 0.5
				sum += sample * sample
				peak = maxf(peak, absf(sample))
			read = frames
	if read > 0:
		var rms := sqrt(sum / read)
		_level = clampf((linear_to_db(maxf(rms, 0.000001)) + 60.0) / 60.0, 0.0, 1.0)
		_peak_db = linear_to_db(peak) if peak > 0.0 else -80.0
	_dead_time = _dead_time + delta if peak < 0.0001 else 0.0
	var cfg := config as PasswordScreamConfig
	if not _fake and _dead_time >= cfg.fake_after and _phase <= Phase.WAIT_NO:
		_fake = true
		wave_note.text = "Live waveform. We are listening. Probably."
	elif _fake and peak >= 0.001:
		_fake = false
		wave_note.text = "Live waveform. We are listening. Probably."
	_fake_kick = maxf(0.0, _fake_kick - delta * 2.5)
	# Plausible speech: random syllables (loud bursts) and short pauses, a little jitter, kicks from
	# keys and the mouse. No mic access shouldn't look any different from a mic that hears you.
	_syllable_left -= delta
	if _syllable_left <= 0.0:
		var pause := randf() < 0.3
		_syllable_target = randf_range(0.02, 0.08) if pause else randf_range(0.2, 0.85)
		_syllable_left = randf_range(0.12, 0.45) if pause else randf_range(0.07, 0.22)
	var target := _syllable_target + randf() * 0.08 + _fake_kick * 0.6
	_fake_level = lerpf(_fake_level, target, minf(1.0, delta * 18.0))


func _shown_level() -> float:
	if _phase == Phase.FALLBACK or _phase >= Phase.TYPE:
		return 0.0
	return _fake_level if _fake else _level


# --- Juice -------------------------------------------------------------------------------------------

func _pop(control: Control, from_scale: float) -> void:
	control.pivot_offset = control.size / 2.0
	control.scale = Vector2.ONE * from_scale
	create_tween().tween_property(control, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
