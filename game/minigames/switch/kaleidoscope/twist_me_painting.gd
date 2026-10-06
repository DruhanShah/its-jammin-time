extends Node3D
## The TWIST ME painting beside the power switch (kaleidoscope game, see kaleidoscope.gd). It hangs there
## from the start as foreshadowing. While the kaleidoscope is the current switch game it's the puzzle;
## before that, looking at it only gets a narrator line (`TOO_EARLY_CUE`); once beaten, it's just a painting.
## Its canvas is the password picture shuffled into kaleidoscope wedges. Without the kaleidoscope you
## get mocked; with it, the scope view opens on it.
## Every look gets a line: if the narrator is mid-line, the reply waits for it to finish (up to
## `MAX_QUIET_WAIT` s) instead of being dropped or cutting it off; `CUE_COOLDOWN` only stops spam.
## While the kaleidoscope is the current game and you were told about it but haven't picked it up,
## walking out of the server room gets `SAME_ROOM_CUE` (at most `SAME_ROOM_MAX` times, `SAME_ROOM_COOLDOWN` apart).

const SCOPE_VIEW := preload("res://minigames/switch/kaleidoscope/scope_view.tscn")
const SHADER := preload("res://minigames/switch/kaleidoscope/painting_kaleido.gdshader")
## Where Painting.fbx's canvas sits in its UVs (x, y, width, height), measured from the mesh.
const CANVAS_UV := Vector4(0.00983, 0.009057, 0.984705, 0.476886)
## Played when the painting is looked at before the kaleidoscope's turn.
const TOO_EARLY_CUE := &"painting_too_early"
## Played when it's the kaleidoscope's turn but you haven't picked it up.
const BARE_HANDS_CUE := &"twist_me_bare_hands"
## Leaving the server room without the kaleidoscope after being told about it.
const SAME_ROOM_CUE := &"scope_same_room"
## Seconds after one of the painting's lines before another look gets one again.
const CUE_COOLDOWN := 3.5
## Longest wait for the narrator to finish its current line before the reply is dropped.
const MAX_QUIET_WAIT := 12.0
const QUIET_POLL := 0.2
const SAME_ROOM_COOLDOWN := 30.0
const SAME_ROOM_MAX := 2
## Half the size of a room (matches StoryStage.ROOM_HALF_SIZE).
const ROOM_HALF_SIZE := Vector2(6.0, 8.0)

var _source: PaintingSource
var _cue_msec := -1 ## Ticks when the painting's last look line played.
var _pending := &"" ## Cue waiting for the narrator to go quiet (empty = none).
var _waited := 0.0
var _quiet_timer: Timer
var _was_in_room := false
var _same_room_msec := -1
var _same_room_count := 0

@onready var _canvas: MeshInstance3D = $Frame/Painting
@onready var _interactable: Interactable = $Interactable


func _ready() -> void:
	Kaleidoscope.ensure()
	_source = PaintingSource.new()
	add_child(_source)
	_source.setup(GameState.scope_password)
	var material := ShaderMaterial.new()
	material.shader = SHADER
	material.set_shader_parameter(&"source", _source.get_texture())
	material.set_shader_parameter(&"err", -deg_to_rad(GameState.scope_target * Kaleidoscope.STEP_DEG))
	material.set_shader_parameter(&"uv_rect", CANVAS_UV)
	_canvas.set_surface_override_material(1, material)
	_quiet_timer = Timer.new()
	_quiet_timer.wait_time = QUIET_POLL
	_quiet_timer.timeout.connect(_on_quiet_poll)
	add_child(_quiet_timer)
	_interactable.interacted.connect(_on_interacted)
	Story.switch_game_changed.connect(_sync.unbind(1))
	_sync()


func _sync() -> void:
	var current := Story.switch_game() == Kaleidoscope.ID
	_interactable.enabled = current or not _beaten()
	_interactable.verb = "look at the painting"
	set_process(current)


## True once the kaleidoscope game has been beaten (its switch step is past, or progress is beyond it).
func _beaten() -> bool:
	for step: int in Story.SWITCH_GAMES:
		var index: int = Story.SWITCH_GAMES[step].find(Kaleidoscope.ID)
		if index >= 0:
			return Story.step > step or (Story.step == step and GameState.switch_progress > index)
	return false


func _process(_delta: float) -> void:
	_interactable.verb = "look through the kaleidoscope" if GameState.has_scope else "twist the painting"
	_check_left_room()


func _on_interacted() -> void:
	if Story.switch_game() == Kaleidoscope.ID and GameState.has_scope:
		var scope: ScopeView = SCOPE_VIEW.instantiate()
		get_tree().current_scene.add_child(scope)
		scope.open(_source.get_texture())
		return
	var cue := _look_cue()
	if not cue or _pending or Narrator.current_cue == cue:
		return # Already queued or being said.
	if _cue_msec >= 0 and Time.get_ticks_msec() - _cue_msec < CUE_COOLDOWN * 1000.0:
		return
	_queue(cue)


## The line a look at the painting gets right now (empty = none).
func _look_cue() -> StringName:
	if Story.switch_game() == Kaleidoscope.ID:
		return &"" if GameState.has_scope else BARE_HANDS_CUE
	return TOO_EARLY_CUE if _interactable.enabled else &""


## Plays `cue` now if the narrator is quiet, else as soon as it is (see MAX_QUIET_WAIT).
func _queue(cue: StringName) -> void:
	_pending = cue
	_waited = 0.0
	if not Narrator.is_speaking():
		_flush()
	else:
		_quiet_timer.start()


func _on_quiet_poll() -> void:
	_waited += QUIET_POLL
	if not Narrator.is_speaking():
		_flush()
	elif _waited >= MAX_QUIET_WAIT:
		_quiet_timer.stop()
		_pending = &""


func _flush() -> void:
	_quiet_timer.stop()
	var cue := _pending
	_pending = &""
	if cue == SAME_ROOM_CUE:
		if _player_in_room() or GameState.has_scope or Story.switch_game() != Kaleidoscope.ID:
			return # Came back / picked it up meanwhile.
		_same_room_msec = Time.get_ticks_msec()
		_same_room_count += 1
	else:
		cue = _look_cue() # The state may have moved on while waiting.
		if not cue:
			return
		_cue_msec = Time.get_ticks_msec()
	Narrator.play(cue)


## The server room's contents (this painting's room, wherever the swap put it).
func _player_in_room() -> bool:
	var player := get_tree().get_first_node_in_group(&"player") as Node3D
	var room := get_parent().get_parent() as Node3D # Rooms/C1/Furniture/TwistMePainting
	if not player or not room:
		return false
	var offset := player.global_position - room.global_position
	return absf(offset.x) <= ROOM_HALF_SIZE.x and absf(offset.z) <= ROOM_HALF_SIZE.y


## Kaleidoscope's turn, told about it, not picked up: leaving the server room gets `SAME_ROOM_CUE`.
func _check_left_room() -> void:
	var inside := _player_in_room()
	var left := _was_in_room and not inside
	_was_in_room = inside
	if not left or GameState.has_scope or not Narrator.has_played(BARE_HANDS_CUE) or _pending:
		return
	if _same_room_count >= SAME_ROOM_MAX:
		return
	if _same_room_msec >= 0 and Time.get_ticks_msec() - _same_room_msec < SAME_ROOM_COOLDOWN * 1000.0:
		return
	_queue(SAME_ROOM_CUE)
