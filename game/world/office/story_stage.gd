extends Node
## The office's side of `Story` (core/story.gd). On every load it rebuilds the office for the
## current step: begins at the computer on a fresh start, swaps the server room (C1) with A3 from
## the second blackout on and plays the step's arrival line (after a blackout from the computer that's
## the lights_out line, since the power is already off); in a switch step that still has the power on
## (e.g. after F7) it puts the lights out a moment after you're back. While you play it plays the room,
## idle and server-room lines.
##
## Ending (Story.Step.ENDING, after the third blackout is fixed): the view drifts in and out of focus
## (`VisionBlur`, mild anywhere, full strength in the Start office), a pair of spectacles lies on the
## player's desk (the objective). Walking into Start cues the narrator to try them on, with nudges
## while you dawdle there; putting them on plays the glasses sliding down over the eyes, then
## `Story.REAL_LIFE` (the real-life video, then the credits).

## Seconds back in the office before the lights go out in a switch step.
@export var blackout_delay := 1.5
## Ending: seconds in the Start office without trying the glasses on between two nudges.
@export var glasses_nudge_time := 20.0
## Ending: blur strength outside the Start office (1 inside).
@export_range(0.0, 1.0) var outside_blur_strength := 0.4
## Seconds of narrator silence before the next idle fun fact plays.
@export var idle_silence := 7.0

const CHECK_INTERVAL := 0.5
## First-entry lines by room *content* (the room node, wherever it stands: C1 moves to A3's spot).
const ROOM_LINES: Dictionary[StringName, StringName] = {&"C1": &"room_server", &"C2": &"room_upside_down", &"B2": &"room_employee_month", &"B3": &"room_family_chairs"}
## Played in order when the narrator has been silent for a while; `idle_out` ends the facts.
const IDLE_CUES: Array[StringName] = [&"idle_1", &"idle_2", &"idle_3", &"idle_4", &"idle_5", &"idle_6", &"idle_out"]
## Most idle lines played per story step (i.e. per lights-out).
const IDLE_PER_STEP := 2
const ROOM_HALF_SIZE := Vector2(6.0, 8.0)
## Where the server room is built, and the room it swaps places with ("the room on the right" from A2).
const SERVER_ROOM := &"C1"
const SWAP_ROOM := &"A3"
## Doorways of A3 that C1's furniture would cover after the swap: C1's switch wall (east) holds A3's
## east doorway, so the switch, its marker and the clock above it move to the west wall (C1's own west
## doorway, a plain wall at A3's spot, at the end of the same aisle).
## The TWIST ME painting (kaleidoscope, third blackout) hangs beside the switch, so it moves with it.
const MIRRORED_TO_WEST_WALL: Array[NodePath] = [^"Furniture/PowerSwitch", ^"Furniture/SwitchboardSpot", ^"Furniture/Clock", ^"Furniture/TwistMePainting"]
## A3's LONDON clock and its label would hang over C1's south doorway; they slide east along the wall.
const A3_CLEAR_OF_SOUTH_DOOR: Array[NodePath] = [^"Furniture/Clock2", ^"Furniture/Label2"]
const A3_CLEAR_X := 5.5
## Ending: the room with the player's desk, the spectacles and where they lie (Start's furniture
## coordinates: left of the keyboard as you sit at the desk).
const OWN_ROOM := &"Start"
const SPECTACLES_SCENE := preload("res://world/office/props/spectacles.tscn")
const SPECTACLES_SPOT := Transform3D(Basis(Vector3.UP, deg_to_rad(75.0)), Vector3(-4.22, 0.949, -0.5))
## Ending lines: walking into Start, then nudges while there (in order, then they stop).
const GLASSES_HINT := &"ending_glasses_hint"
const GLASSES_NUDGES: Array[StringName] = [&"ending_glasses_nudge_1"]

## Room centres as built (before any swap), by room name: these are fixed locations.
var _cells: Dictionary[StringName, Vector3] = {}
var _tick := 0.0
## Ending state (null/false until the ENDING step is set up in this load).
var _vision: VisionBlur
var _spectacles: Node3D
var _hinted := false ## The "try them on" line played (this load).
var _in_room_time := 0.0 ## Seconds in Start since the hint or the last nudge.
var _nudges := 0
var _putting_on := false
var _silence := 0.0 ## Seconds since the narrator last spoke.

@onready var _rooms: Node3D = $"../Rooms"
@onready var _player: Node3D = $"../Player"
@onready var _computer: Node3D = $"../Rooms/Start/Furniture/Computer"


func _ready() -> void:
	for room: Node3D in _rooms.get_children():
		_cells[room.name] = room.position
	if Story.is_swapped():
		_swap_rooms()
	if Story.take_fresh_start():
		set_process(false)
		get_tree().change_scene_to_file.call_deferred(Computer.SCENE)
		return
	var cue := Story.take_arrival_cue()
	if cue:
		Narrator.play(cue) # From _ready, so the scene change doesn't cut it.
	if Story.is_switch_step() and GameState.power_on:
		get_tree().create_timer(blackout_delay).timeout.connect(_blackout)
	Story.step_changed.connect(_on_step_changed)
	if Story.step == Story.Step.ENDING:
		_start_ending()


func _process(delta: float) -> void:
	_tick += delta
	if _tick < CHECK_INTERVAL:
		return
	var here := room_at(_player.global_position)
	_check_server_room(here)
	_check_idle(_tick)
	_check_room_lines()
	_check_ending(here, _tick)
	_tick = 0.0


## Name of the room location (as built) containing `pos`, or empty outside the building.
func room_at(pos: Vector3) -> StringName:
	for room_name in _cells:
		var offset := pos - _cells[room_name]
		if absf(offset.x) <= ROOM_HALF_SIZE.x and absf(offset.z) <= ROOM_HALF_SIZE.y:
			return room_name
	return &""


## Swaps the server room's contents (furniture, signs, amber/flickering lights, switch) with A3's.
## Floors, walls and doors stay, so only the items that would cover the other room's doorways move.
func _swap_rooms() -> void:
	var server: Node3D = _rooms.get_node(String(SERVER_ROOM))
	var other: Node3D = _rooms.get_node(String(SWAP_ROOM))
	var server_position := server.position
	server.position = other.position
	other.position = server_position
	for path in MIRRORED_TO_WEST_WALL:
		var item: Node3D = server.get_node(path)
		item.position.x = -item.position.x
		item.rotate_y(PI)
	for path in A3_CLEAR_OF_SOUTH_DOOR:
		(other.get_node(path) as Node3D).position.x = A3_CLEAR_X


## Fallback for a switch step that starts with the lights still on (e.g. F7): the usual blackout comes
## from the computer (`Computer.blackout()`), and the office then just loads dark and plays the line.
func _blackout() -> void:
	if not Story.is_switch_step() or not GameState.power_on:
		return
	GameState.set_power(false) # Story queues the step's lights_out line as the arrival cue.
	var cue := Story.take_arrival_cue()
	if cue:
		Narrator.play(cue)


## Walking into the server room's old spot after it moved.
func _check_server_room(here: StringName) -> void:
	if here != SERVER_ROOM or not Story.is_swapped() or GameState.power_on or Narrator.is_speaking():
		return
	if Story.step == Story.Step.SWITCH_2:
		Narrator.play(&"server_room_empty")
	elif Story.step == Story.Step.SWITCH_3:
		Narrator.play(&"server_room_still_empty")


## A room's line the first time you're inside its content.
func _check_room_lines() -> void:
	if Narrator.is_speaking() or _player.get(&"frozen") or get_tree().get_first_node_in_group(&"scope_view"):
		return
	for room: Node3D in _rooms.get_children():
		var cue: StringName = ROOM_LINES.get(room.name, &"")
		var offset := _player.global_position - room.position
		if cue and absf(offset.x) <= ROOM_HALF_SIZE.x and absf(offset.z) <= ROOM_HALF_SIZE.y:
			Narrator.play(cue) # `once`: a no-op after the first time.
			return


## Idle facts: after `idle_silence` s with no narration, play the next fun fact (in order, at most
## IDLE_PER_STEP per story step, i.e. per lights-out; `idle_out` closes the list).
func _check_idle(delta: float) -> void:
	if GameState.idle_step != Story.step:
		GameState.idle_step = Story.step
		GameState.idle_lines_this_step = 0
	if Narrator.is_speaking():
		_silence = 0.0
		return
	_silence += delta
	if GameState.idle_lines_played >= IDLE_CUES.size() or GameState.idle_lines_this_step >= IDLE_PER_STEP \
			or _player.get(&"movement_locked") or _player.get(&"frozen") \
			or get_tree().get_first_node_in_group(&"scope_view"):
		return
	if _silence >= idle_silence:
		Narrator.play(IDLE_CUES[GameState.idle_lines_played])
		GameState.idle_lines_played += 1
		GameState.idle_lines_this_step += 1
		_silence = 0.0


## Power came back while the player was in the office (an in-world restore game): set the ending up now.
func _on_step_changed(step: Story.Step) -> void:
	if step == Story.Step.ENDING and not _vision:
		_start_ending()


## Puts the spectacles on the desk and starts the blurry vision.
func _start_ending() -> void:
	_vision = VisionBlur.new()
	_vision.strength = outside_blur_strength
	add_child(_vision)
	_spectacles = SPECTACLES_SCENE.instantiate()
	_spectacles.transform = SPECTACLES_SPOT
	_computer.get_parent().add_child(_spectacles) # Start's Furniture, beside the computer.
	var interactable: Interactable = _spectacles.get_node(^"Interactable")
	interactable.interacted.connect(_put_on_glasses)


## Ending: full blur in the Start office, the hint on walking in, nudges while you dawdle there.
func _check_ending(here: StringName, delta: float) -> void:
	if not _vision or _putting_on:
		return
	var home := here == OWN_ROOM
	_vision.strength = 1.0 if home else outside_blur_strength
	if not home or Narrator.is_speaking():
		return
	if not _hinted:
		_hinted = true
		_in_room_time = 0.0
		Narrator.play(GLASSES_HINT)
		return
	_in_room_time += delta
	if _in_room_time >= glasses_nudge_time and _nudges < GLASSES_NUDGES.size():
		Narrator.play(GLASSES_NUDGES[_nudges])
		_nudges += 1
		_in_room_time = 0.0


## The spectacles go on: the player stops and the screen fades straight into the real-life video.
func _put_on_glasses() -> void:
	if _putting_on:
		return
	_putting_on = true
	_spectacles.visible = false
	(_spectacles.get_node(^"Interactable") as Interactable).enabled = false
	_player.set_physics_process(false)
	_player.set_process_unhandled_input(false)
	var hud := _player.get_node_or_null(^"HUD") as CanvasLayer
	if hud:
		hud.visible = false
	Narrator.stop()
	Transition.change_scene(Story.REAL_LIFE)
