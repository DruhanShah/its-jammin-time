extends Control
## Switch game "wires" (restore game of the first blackout, see switch_games.gd): the cover is off
## and three wires hang loose (board drawing and dragging: `WireBoard`). Matching colours zaps
## you; plugging each wire straight across is right. Then pull the lever: the power comes back on
## and the story moves on. No text on screen at all (user's call): the board and the narrator's
## escalating mockery (which ends up spelling out "straight across") are all the player gets.
## Even the comic bursts are wordless. Esc leaves (the wires come loose again next time).

const ID := &"wires"
## Mocking lines for colour matches, in order; the last one repeats.
const MATCH_CUES: Array[StringName] = [&"wires_match_1", &"wires_match_2", &"wires_match_3", &"wires_match_4", &"wires_match_5"]
const ZAP_COLOR := Color("#ff5a3c")
const CLICK_COLOR := Color("#7dff7d")

## Emergency light multiplied over the scene (white = normal light).
@export var emergency_tint := Color(1.0, 0.6, 0.5)
## Seconds after the lights come back before moving on (longer while the narrator is still talking).
@export var exit_delay := 1.5
## Longest wait for the narrator's line before moving on anyway.
@export var max_line_wait := 10.0
@export var plug_sound: AudioStream
@export var zap_sound: AudioStream
@export var zap_volume_db := -2.0
@export var small_zap_sound: AudioStream
@export var small_zap_volume_db := -6.0
@export var lever_sound: AudioStream
@export var lever_volume_db := -2.0
@export var hum_sound: AudioStream
@export var hum_volume_db := -8.0

var _matches := 0 ## Colour-match attempts.
var _mocked := 0 ## Mocking lines actually played.
var _done := false
var _time := 0.0
var _shake: Tween
var _home := Vector2.ZERO

@onready var _board: WireBoard = $Board
@onready var _light: ShaderMaterial = $EmergencyTint.material
@onready var _spark_fx: CPUParticles2D = $Sparks
@onready var _burst: Control = $Burst


func _ready() -> void:
	for socket in _board.socket_order.size():
		assert(_board.socket_order[socket] != socket, "WireBoard.socket_order must be a derangement")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	ComicCursor.apply()
	_board.dropped.connect(_on_dropped)
	_board.lever_pulled.connect(_on_lever)
	_board.scale = Vector2.ONE * 0.85
	create_tween().tween_property(_board, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Narrator.play(&"wires_intro")


func _exit_tree() -> void:
	ComicCursor.reset()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not _done:
		Transition.change_scene(Story.OFFICE)


## The emergency light breathes until the power is back.
func _process(delta: float) -> void:
	if _done:
		return
	_time += delta
	var pulse := 0.05 * sin(_time * 2.2)
	_light.set_shader_parameter("tint", Color(emergency_tint.r, emergency_tint.g + pulse, emergency_tint.b + pulse))


func _on_dropped(wire: int, socket: int) -> void:
	if _done:
		return
	if socket < 0:
		_board.snap_back(wire)
	elif socket == wire:
		_board.plug(wire, socket)
		Audio.play_sfx(plug_sound)
		_pop(_global(socket), CLICK_COLOR, 40)
		Narrator.play(&"wires_finally" if _matches > 0 else &"wires_straight_first")
		if _board.all_straight():
			_board.lever_ready = true
	elif _board.socket_order[socket] == wire:
		_matches += 1
		_zap(socket, zap_sound, zap_volume_db, 46)
		_board.snap_back(wire)
		_shake_board()
		# Escalate only through lines the player actually got (the intro may be cut short).
		if not Narrator.is_speaking() or Narrator.current_cue == &"wires_intro":
			Narrator.play(MATCH_CUES[mini(_mocked, MATCH_CUES.size() - 1)])
			_mocked += 1
	else:
		_zap(socket, small_zap_sound, small_zap_volume_db, 28)
		_board.snap_back(wire)
		Narrator.play(&"wires_crossed")


## Lever up: breaker clunk, the lights flicker back on, then back to the office.
func _on_lever() -> void:
	_done = true
	_board.lever_ready = false
	create_tween().tween_property(_board, "lever_up", 1.0, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Audio.play_sfx(lever_sound, lever_volume_db)
	_pop(_board.get_global_transform() * _board.lever_rect().get_center(), Color("#ffe14d"), 70)
	Narrator.play(&"wires_done")
	var lights := create_tween()
	lights.tween_interval(0.25)
	for flick in [Color.WHITE, emergency_tint, Color.WHITE, emergency_tint * 0.7]:
		lights.tween_property(_light, "shader_parameter/tint", flick, 0.06)
		lights.tween_interval(0.06)
	lights.tween_callback(func() -> void: _board.lamp_on = true)
	lights.tween_callback(Audio.play_sfx.bind(hum_sound, hum_volume_db))
	lights.tween_property(_light, "shader_parameter/tint", Color.WHITE, 0.3)
	lights.parallel().tween_property(_light, "shader_parameter/vignette", 0.25, 0.3)
	lights.tween_interval(exit_delay)
	await lights.finished
	var waited := 0.0
	while Narrator.is_speaking() and waited < max_line_wait:
		await get_tree().create_timer(0.2).timeout
		waited += 0.2
	Story.switch_game_done(ID) # Last game of SWITCH_1: the power comes on, the story moves on.
	Transition.change_scene(Story.next_switch_scene())


func _zap(socket: int, stream: AudioStream, volume_db: float, burst_radius: int) -> void:
	_spark_fx.global_position = _global(socket)
	_spark_fx.restart()
	Audio.play_sfx(stream, volume_db)
	_pop(_global(socket), ZAP_COLOR, burst_radius)


## A wordless comic starburst (no text on screen in this game); `radius` sets its size.
func _pop(at: Vector2, color: Color, radius: int) -> void:
	var burst := ComicBurst.new()
	burst.word = ""
	burst.fill = color
	burst.font_size = radius
	_burst.add_child(burst)
	burst.position = at - burst.size / 2.0


func _shake_board() -> void:
	if _shake and _shake.is_running():
		_shake.kill()
	else:
		_home = _board.position
	_shake = create_tween()
	for i in 4:
		_shake.tween_property(_board, "position", _home + Vector2(randf_range(-10.0, 10.0), randf_range(-6.0, 6.0)), 0.05)
	_shake.tween_property(_board, "position", _home, 0.05)


func _global(socket: int) -> Vector2:
	return _board.get_global_transform() * _board.socket_pos(socket)
