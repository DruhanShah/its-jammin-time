extends Node3D
## Switch game "valve" (restore game of the second blackout, see switch_games.gd): a 3D close-up
## of the new switchboard, which runs on plumbing. Electricity glows in the pipes like a liquid:
## full up to the valve, a trickle past it. Rolling the keys around G (`TwistInput`) turns the red
## hand wheel. The gag: lefty-loosey is a lie. The hint arrow (and the wheel's "< OPEN") say
## anticlockwise, but that only tightens it; after `reverse_degrees` the pipe clunks, the arrow
## flips and clockwise opens it (or the other way round if they went clockwise first). Fully open
## and flowing: the switchboard's lever flips up by itself, the lights come back, the story moves
## on. No text on screen besides what's printed on the hardware (the narrator carries the joke).
## Esc leaves (the valve is shut again next time).

const ID := &"valve"
const EMERGENCY_AMBIENT := 0.35
const NORMAL_AMBIENT := 0.6

## Clockwise turns (after the gag) to open the valve fully (one key step = 60°).
@export var open_turns := 3.0
## Degrees turned anticlockwise ("lefty-loosey") before the reverse-thread gag.
@export var reverse_degrees := 240.0
## Degrees turned clockwise before the gag, if they never tried lefty-loosey.
@export var early_degrees := 120.0
## Flow before anything is touched (shows the electricity is there, stuck at the valve).
@export var trickle := 0.12
## How fast the flow follows the opening (per second).
@export var flow_rate := 0.8
## How fast the wheel catches up with the keys (1/s).
@export var wheel_follow := 12.0
## Degrees turned between squeaks.
@export var squeak_every := 180.0
## Normal light energy once the power is back.
@export var ceiling_energy := 1.4
## Seconds after the lights come back before moving on (longer while the narrator is still talking).
@export var exit_delay := 1.5
## Longest wait for the narrator's line before moving on anyway.
@export var max_line_wait := 10.0
@export var squeak_sound: AudioStream
@export var squeak_volume_db := -6.0
@export var clunk_sound: AudioStream
@export var clunk_volume_db := -2.0
@export var spark_sound: AudioStream
@export var spark_volume_db := -12.0
@export var lever_sound: AudioStream
@export var lever_volume_db := -2.0
@export var hum_sound: AudioStream
@export var hum_volume_db := -8.0

## 0..1: how much electricity gets past the valve (eases toward the opening).
var flow := 0.0
var _opened := 0.0 ## Degrees opened (after the gag), 0.._need().
var _tightened := 0.0 ## Anticlockwise degrees before the gag.
var _gag := false
var _closing_said := false
var _wheel_deg := 0.0 ## Target wheel angle in degrees, clockwise positive.
var _shown_deg := 0.0 ## Eases toward `_wheel_deg`.
var _since_squeak := 0.0
var _turning := 0.0 ## Seconds left of "the wheel is moving" (drives the rusty loop and the judder).
var _spark_wait := 0.5
var _done := false
var _wheel_home := Vector3.ZERO

@onready var _camera: Camera3D = $Camera3D
@onready var _env: Environment = $WorldEnvironment.environment
@onready var _emergency: Node3D = $Emergency
@onready var _normal: Node3D = $Normal
@onready var _ceiling: OmniLight3D = $Normal/Ceiling
@onready var _valve: Node3D = $Valve
@onready var _wheel: Node3D = $Valve/Wheel
@onready var _needle: Node3D = $Valve/Gauge/Needle
@onready var _ticks: Node3D = $Valve/Gauge/Ticks
@onready var _plasma_out: ShaderMaterial = $PipeOut/Plasma.material_override
@onready var _plasma_in: ShaderMaterial = $PipeIn/Plasma.material_override
@onready var _leaks: Array[Node] = $Leaks.get_children()
@onready var _lever: Node3D = $Switchboard/Lever
@onready var _bulb_mat: StandardMaterial3D = $Switchboard/Bulb.material_override
@onready var _bulb_light: OmniLight3D = $Switchboard/BulbLight
@onready var _twist: TwistInput = $TwistInput
@onready var _turn_loop: AudioStreamPlayer = $TurnLoop
@onready var _flow_loop: AudioStreamPlayer = $FlowLoop
@onready var _surge: AudioStreamPlayer = $Surge
@onready var _hint: TwistHint = $Hud/Hint
@onready var _burst: Control = $Hud/Burst


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	_twist.twisted.connect(_on_twisted)
	_wheel_home = _wheel.position
	_lever.rotation = Vector3(deg_to_rad(150.0), 0.0, 0.0) # Down (set here: the euler read from the basis flips).
	_add_ticks()
	flow = trickle
	_set_lights(false)
	Narrator.play(&"valve_intro")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not _done:
		Transition.change_scene(Story.OFFICE)


func _on_twisted(delta: float) -> void:
	if _done:
		return
	_turning = 0.3
	if not _gag:
		if delta < 0.0: # "Lefty-loosey": stiff, it only tightens.
			_tightened -= delta
			_wheel_deg += delta * 0.5
			if _tightened >= reverse_degrees:
				_reverse_gag(&"valve_reverse_thread")
		else: # Clockwise first: it gives. Reverse thread, they found it themselves.
			_opened += delta
			_wheel_deg += delta
			if _opened >= early_degrees:
				_reverse_gag(&"valve_righty_early")
	else:
		var before := _opened
		_opened = clampf(_opened + delta, 0.0, _need())
		_wheel_deg += _opened - before
		if _opened == before:
			return # Against a stop: nothing moves, no sound.
		if delta < 0.0 and not _closing_said:
			_closing_said = true
			Narrator.play(&"valve_closing")
	_since_squeak += absf(delta)
	if _since_squeak >= squeak_every:
		_since_squeak = 0.0
		Audio.play_sfx(squeak_sound, squeak_volume_db)


## The thread turns out to be reversed: clunk, a jolt, the arrow flips.
func _reverse_gag(cue: StringName) -> void:
	_gag = true
	Audio.play_sfx(clunk_sound, clunk_volume_db)
	_shake_camera(0.03, 0.35)
	Narrator.play(cue)
	_hint.arrow_direction = 1
	_hint.restart()


func _process(delta: float) -> void:
	if _done:
		return
	var opening := _opened / _need() if _gag else 0.0
	var target := opening
	if not _gag: # The trickle dies as they tighten it; a clockwise try lets a little more through.
		target = maxf(trickle * (1.0 - clampf(_tightened / reverse_degrees, 0.0, 1.0)), trickle + _opened / _need())
	flow = move_toward(flow, target, flow_rate * delta)
	_shown_deg = lerpf(_shown_deg, _wheel_deg, 1.0 - exp(-wheel_follow * delta))
	_wheel.rotation.z = -deg_to_rad(_shown_deg) # Facing the camera: clockwise on screen is -z.
	_turning -= delta
	if not _gag and _turning > 0.0 and _tightened > 0.0: # Stiff: it judders.
		_wheel.position = _wheel_home + Vector3(randf_range(-0.003, 0.003), randf_range(-0.003, 0.003), 0.0)
	else:
		_wheel.position = _wheel_home
	_show_flow()
	_turn_loop.volume_db = move_toward(_turn_loop.volume_db, -8.0 if _turning > 0.0 else -60.0, 240.0 * delta)
	_flow_loop.volume_db = linear_to_db(maxf(flow, 0.001)) - 6.0
	_hint.progress = opening
	_spark_wait -= delta
	if flow > 0.3 and _spark_wait <= 0.0:
		_spark_wait = randf_range(0.4, 1.2)
		Audio.play_sfx(spark_sound, spark_volume_db)
	if opening >= 0.5:
		Narrator.play(&"valve_leak") # Once (the cue's `once` flag).
	if _gag and opening >= 1.0 and flow >= 0.97:
		_finish()


## Pipe fill, gauge, bulb and leaks follow the flow.
func _show_flow() -> void:
	_plasma_out.set_shader_parameter(&"fill", flow)
	_plasma_out.set_shader_parameter(&"flow", flow)
	var stuck := 0.5 + 0.3 * (1.0 - flow) # Upstream churns harder while it's stuck at the valve.
	_plasma_in.set_shader_parameter(&"flow", stuck)
	_needle.rotation.z = deg_to_rad(lerpf(120.0, -120.0, flow) + randf_range(-1.5, 1.5) * flow)
	_bulb_mat.emission_energy_multiplier = flow * 3.0
	_bulb_light.light_energy = flow * 0.6
	for leak: CPUParticles3D in _leaks:
		leak.emitting = flow > 0.15
		leak.speed_scale = 0.6 + 0.6 * flow


## Full flow: surge, the lever flips itself up, the lights come back, then back to the office.
func _finish() -> void:
	_done = true
	_hint.hide()
	_turn_loop.stop()
	_wheel.position = _wheel_home
	_surge.play()
	create_tween().tween_property(_surge, "volume_db", -40.0, 0.6).set_delay(2.5)
	Narrator.play(&"valve_done")
	var t := create_tween()
	t.tween_property(_bulb_mat, "emission_energy_multiplier", 10.0, 0.4)
	t.parallel().tween_property(_bulb_light, "light_energy", 2.0, 0.4)
	t.tween_property(_lever, "rotation:x", deg_to_rad(30.0), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_callback(Audio.play_sfx.bind(lever_sound, lever_volume_db))
	t.tween_callback(_pop.bind(_lever.global_position, Color("#ffe14d"), 60))
	t.tween_callback(_shake_camera.bind(0.02, 0.25))
	t.tween_interval(0.25)
	for on in [true, false, true, false]:
		t.tween_callback(_set_lights.bind(on))
		t.tween_interval(0.07)
	t.tween_callback(_set_lights.bind(true))
	t.tween_callback(Audio.play_sfx.bind(hum_sound, hum_volume_db))
	t.tween_property(_bulb_mat, "emission_energy_multiplier", 4.0, 0.5)
	t.parallel().tween_property(_bulb_light, "light_energy", 0.6, 0.5)
	t.tween_interval(exit_delay)
	await t.finished
	var waited := 0.0
	while Narrator.is_speaking() and waited < max_line_wait:
		await get_tree().create_timer(0.2).timeout
		waited += 0.2
	Story.switch_game_done(ID) # Last game of SWITCH_2: the power comes on, the story moves on.
	Transition.change_scene(Story.next_switch_scene())


## Emergency (red, dim) or normal (cool white ceiling light).
func _set_lights(on: bool) -> void:
	_emergency.visible = not on
	_normal.visible = on
	_ceiling.light_energy = ceiling_energy if on else 0.0
	_env.ambient_light_energy = NORMAL_AMBIENT if on else EMERGENCY_AMBIENT


## The gauge's scale: 9 ticks over 240°, the last two in the red.
func _add_ticks() -> void:
	var black := StandardMaterial3D.new()
	black.albedo_color = Color(0.08, 0.08, 0.08)
	var red := StandardMaterial3D.new()
	red.albedo_color = Color(0.85, 0.08, 0.05)
	for i in 9:
		var tick := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.004, 0.012, 0.002)
		box.material = red if i >= 7 else black
		tick.mesh = box
		var angle := deg_to_rad(lerpf(120.0, -120.0, i / 8.0))
		tick.rotation.z = angle
		tick.position = Vector3(0.0, 0.05, 0.0).rotated(Vector3.BACK, angle)
		_ticks.add_child(tick)


func _need() -> float:
	return open_turns * 360.0


func _shake_camera(strength: float, duration: float) -> void:
	var shake := create_tween()
	var steps := int(duration / 0.05)
	for i in steps:
		var fade := 1.0 - float(i) / steps
		shake.tween_property(_camera, "h_offset", randf_range(-strength, strength) * fade, 0.05)
		shake.parallel().tween_property(_camera, "v_offset", randf_range(-strength, strength) * fade, 0.05)
	shake.tween_property(_camera, "h_offset", 0.0, 0.05)
	shake.parallel().tween_property(_camera, "v_offset", 0.0, 0.05)


## A wordless comic starburst (no text on screen in this game) over a point in the world.
func _pop(world: Vector3, color: Color, radius: int) -> void:
	var burst := ComicBurst.new()
	burst.word = ""
	burst.fill = color
	burst.font_size = radius
	_burst.add_child(burst)
	burst.position = _camera.unproject_position(world) - burst.size / 2.0
