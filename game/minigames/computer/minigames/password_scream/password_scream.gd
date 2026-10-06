extends Minigame
## Login screen: scream the password N times, then it lets you type it instead.

const BUS := &"MicTap"

var _cfg: PasswordScreamConfig
var _capture: AudioEffectCapture
var _mic: AudioStreamPlayer
var _loud_for := 0.0
var _armed := true ## must go quiet between screams
var _screams := 0

@onready var prompt: Label = %Prompt
@onready var meter: ProgressBar = %Meter
@onready var count: Label = %Count
@onready var password: LineEdit = %Password


func begin() -> void:
	_cfg = config as PasswordScreamConfig
	password.text_submitted.connect(func(t: String): if not t.is_empty(): complete())
	_start_mic()
	_update_count()
	Narrator.play(&"password_intro")


func cleanup() -> void:
	if _mic:
		_mic.stop()
	var idx := AudioServer.get_bus_index(BUS)
	if idx >= 0:
		AudioServer.remove_bus(idx)


func _process(delta: float) -> void:
	var peak := 0.0
	for f in _capture.get_buffer(_capture.get_frames_available()):
		peak = maxf(peak, maxf(absf(f.x), absf(f.y)))
	var db := linear_to_db(peak) if peak > 0.0 else -80.0
	meter.value = clampf(db, -60.0, 0.0)
	if password.visible:
		return
	if db >= _cfg.threshold_db:
		_loud_for += delta
		if _armed and _loud_for >= _cfg.scream_time:
			_armed = false
			_screamed()
	else:
		_loud_for = 0.0
		_armed = true


## Keys the LineEdit doesn't take must not type into the editor behind the login.
func _unhandled_key_input(_e: InputEvent) -> void:
	get_viewport().set_input_as_handled()


func _screamed() -> void:
	_screams += 1
	_update_count()
	if _screams >= _cfg.screams_needed:
		prompt.text = "Voice recognised. Now please type it, like a normal person."
		meter.hide()
		count.hide()
		password.show()
		password.grab_focus()
		Narrator.play(&"password_type_instead")
	else:
		Narrator.play(&"password_again")


func _update_count() -> void:
	count.text = "%d / %d" % [_screams, _cfg.screams_needed]


func _start_mic() -> void:
	AudioServer.add_bus()
	var idx := AudioServer.bus_count - 1
	AudioServer.set_bus_name(idx, BUS)
	AudioServer.set_bus_mute(idx, true) ## don't play your own scream back
	_capture = AudioEffectCapture.new()
	AudioServer.add_bus_effect(idx, _capture)
	_mic = AudioStreamPlayer.new()
	_mic.stream = AudioStreamMicrophone.new()
	_mic.bus = BUS
	add_child(_mic)
	_mic.play()
