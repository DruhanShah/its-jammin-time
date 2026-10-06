extends Node
## The office's side of `Story` (core/story.gd). On every load it rebuilds the office for the
## current step: begins at the computer on a fresh start, swaps the server room (C1) with A3 from
## the second blackout on and plays the step's arrival line (after a blackout from the computer that's
## the lights_out line, since the power is already off); in a switch step that still has the power on
## (e.g. after F7) it puts the lights out a moment after you're back. While you play it tracks the objective (the desk computer, or the
## power switch while the lights are out) and the narrator nags when you stop getting closer.
##
## Off-path heuristic: rooms and doors form a graph (room cells as built, linked by the `Doors`
## children, named after the two rooms they join). Every `CHECK_INTERVAL` it takes the number of
## rooms between you and the objective's room. Reaching a new best (closer than ever since this load
## or the last nag) resets the clock; otherwise, outside the objective's room, the clock runs, and
## after `off_path_time` the next of Story's escalating off-path lines plays (at most one per
## `off_path_cooldown`), and the best is reset to where you are. The clock stops while the narrator talks.

## Seconds back in the office before the lights go out in a switch step.
@export var blackout_delay := 1.5
## Seconds without getting closer to the objective before the narrator nags.
@export var off_path_time := 25.0
## Minimum seconds between two off-path lines.
@export var off_path_cooldown := 30.0

const CHECK_INTERVAL := 0.5
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

## Room centres as built (before any swap), by room name: these are fixed locations.
var _cells: Dictionary[StringName, Vector3] = {}
## Room name -> neighbouring room names through a door.
var _links: Dictionary[StringName, Array] = {}
var _tick := 0.0
var _best := -1 ## Fewest rooms to the objective since this load / the last nag; -1 = not measured.
var _stall := 0.0 ## Seconds without a new best.
var _since_nag := INF

@onready var _rooms: Node3D = $"../Rooms"
@onready var _player: Node3D = $"../Player"
@onready var _computer: Node3D = $"../Rooms/Start/Furniture/Computer"
@onready var _switch: Node3D = $"../Rooms/C1/Furniture/PowerSwitch"


func _ready() -> void:
	for room: Node3D in _rooms.get_children():
		_cells[room.name] = room.position
	_build_links()
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
	GameState.power_changed.connect(_reset_tracking.unbind(1))
	Story.step_changed.connect(_reset_tracking.unbind(1))


func _process(delta: float) -> void:
	_tick += delta
	if _tick < CHECK_INTERVAL:
		return
	var here := room_at(_player.global_position)
	_check_server_room(here)
	_check_off_path(here, _tick)
	_tick = 0.0


## Name of the room location (as built) containing `pos`, or empty outside the building.
func room_at(pos: Vector3) -> StringName:
	for room_name in _cells:
		var offset := pos - _cells[room_name]
		if absf(offset.x) <= ROOM_HALF_SIZE.x and absf(offset.z) <= ROOM_HALF_SIZE.y:
			return room_name
	return &""


## Number of doors between two rooms (breadth-first over `_links`), -1 if unreachable.
func rooms_between(from: StringName, to: StringName) -> int:
	var dist := {from: 0}
	var todo: Array[StringName] = [from]
	while todo:
		var room: StringName = todo.pop_front()
		if room == to:
			return dist[room]
		for next: StringName in _links.get(room, []):
			if not dist.has(next):
				dist[next] = dist[room] + 1
				todo.append(next)
	return -1


## The objective's node: the switch while the lights are out, the desk computer while a
## minigame is queued, nothing otherwise.
func objective() -> Node3D:
	if Story.step == Story.Step.FREE_ROAM:
		return null
	if Story.is_switch_step():
		return _switch if not GameState.power_on else null
	return _computer if GameState.computer_queue else null


func _build_links() -> void:
	var names := RegEx.create_from_string("Start|[A-C][1-3]")
	for door in $"../Doors".get_children():
		var pair := names.search_all(door.name)
		if pair.size() != 2:
			continue
		var a := StringName(pair[0].get_string())
		var b := StringName(pair[1].get_string())
		_links.get_or_add(a, []).append(b)
		_links.get_or_add(b, []).append(a)


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


func _check_off_path(here: StringName, delta: float) -> void:
	var target := objective()
	if not target or here.is_empty() or Narrator.is_speaking() or get_tree().get_first_node_in_group(&"scope_view"):
		return
	_since_nag += delta
	var dist := rooms_between(here, room_at(target.global_position))
	if _best < 0 or dist < _best:
		_best = dist
		_stall = 0.0
		return
	if dist == 0:
		_stall = 0.0 # In the objective's room: let them look around.
		return
	_stall += delta
	if _stall >= off_path_time and _since_nag >= off_path_cooldown:
		var cue := Story.next_off_path_cue()
		if cue:
			Narrator.play(cue)
		_since_nag = 0.0
		_stall = 0.0
		_best = dist


func _reset_tracking() -> void:
	_best = -1
	_stall = 0.0
