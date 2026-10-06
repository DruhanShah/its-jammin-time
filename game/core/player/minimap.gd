class_name Minimap
extends Control
## North-up mini-map of the level, drawn with `_draw()` (no second camera): one box per room, gaps for
## doorways, the room you're in filled yellow and an arrow for where you stand and look.
##
## It reads the level's layout on the first frame: every child of the current scene's `Rooms` node is
## a room of `ROOM_SIZE` centred on it (unrotated), every child of `Doors` named after two rooms is a
## doorway. Positions only, no names, so swapping two rooms' contents (C1/A3) doesn't change the map.
## Levels without `Rooms` hide it. Hide it yourself with `visible = false` (e.g. over a close-up).
##
## Extras: the four corner rooms of the 3x3 grid (A1, C1, A3, C3 by position; "the server room is in a
## corner") pulse with a soft glow, the `Start` room (your desk) carries a star, and rooms you've been in
## get a green tint and a tick. Visited rooms are kept in `GameState.visited_rooms` (by rounded centre
## position, so it survives scene reloads and saves).

const ROOM_SIZE := Vector2(12.0, 16.0) ## Metres (x, z), as in docs/map/README.md.
const DOOR_NAME := "^(Start|[A-C][1-3]){2}$"
const DOORWAY_WIDTH := 2.0 ## Metres of wall left out per doorway (wider than the real 1.06 m, to read).

const OUTLINE := Color("#1b1b1b")
const PAPER := Color("#fff8e7")
const FLOOR := Color("#d9cdb4")
const HERE := Color("#ffd23f")
const PLAYER := Color("#ff4d4d")
const VISITED := Color("#bfe0a8")
const TICK := Color("#2e7d32")
const GLOW := Color("#3ad0ff")
const STAR := Color("#ff9f1c")
const START_ROOM := "Start" ## Node name of the room the player starts in (it never swaps contents).
const GLOW_PERIOD := 1.6 ## Seconds per corner-glow pulse.
const GLOW_FPS := 20.0 ## Redraws per second while corners glow.

## Pixels per metre.
@export var map_scale := 2.8
@export var padding := 9.0
@export var shadow_offset := Vector2(5, 5)
@export var wall_width := 2.0
@export var arrow_size := 7.5

var _rooms: Array[Rect2] = [] ## World XZ rectangles.
var _doors: Array[Rect2] = [] ## World XZ gaps cut into the walls.
var _origin := Vector2.ZERO ## World XZ of the map's top-left corner.
var _player_xz := Vector2.INF
var _facing := Vector2.UP
var _here := -1 ## Index in `_rooms`, -1 outside.
var _ids: Array[String] = [] ## Position id of each room in `_rooms` (see `_room_id`).
var _corners: Array[int] = [] ## Indices in `_rooms` of the grid's four corner rooms.
var _start := -1 ## Index in `_rooms` of the start room, -1 if none.
var _loaded := false
var _time := 0.0
var _since_redraw := 0.0


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	if not _loaded:
		_load_layout()
	var camera := get_viewport().get_camera_3d()
	if not camera or _rooms.is_empty():
		return
	_time += delta
	_since_redraw += delta
	var glow_due := not _corners.is_empty() and _since_redraw >= 1.0 / GLOW_FPS
	var xz := Vector2(camera.global_position.x, camera.global_position.z)
	var forward := -camera.global_basis.z
	var facing := Vector2(forward.x, forward.z).normalized() if Vector2(forward.x, forward.z).length() > 0.01 else _facing
	if xz.distance_squared_to(_player_xz) < 0.0004 and facing.dot(_facing) > 0.9999 and not glow_due:
		return
	_player_xz = xz
	_facing = facing
	_here = _room_index(xz)
	if _here >= 0 and not GameState.visited_rooms.has(_ids[_here]):
		GameState.visited_rooms[_ids[_here]] = true
	_since_redraw = 0.0
	queue_redraw()


func _draw() -> void:
	if _rooms.is_empty():
		return
	var panel := Rect2(Vector2.ZERO, size)
	draw_rect(Rect2(shadow_offset, size), Color(0, 0, 0, 0.85))
	draw_rect(panel, PAPER)
	var pulse := 0.5 + 0.5 * sin(_time * TAU / GLOW_PERIOD)
	# Corner glow spills a little past the outer walls (into the padding) under the floor.
	for i in _corners:
		var rect := _to_map(_rooms[i])
		for ring in 3:
			var grow := 2.0 + ring * 2.0 + pulse * 1.5
			draw_rect(rect.grow(grow), Color(GLOW, (0.5 - ring * 0.14) * (0.5 + 0.5 * pulse)))
	for i in _rooms.size():
		draw_rect(_to_map(_rooms[i]), _room_colour(i))
	for i in _corners:
		# Inner glow: soft rings fading towards the middle of the room.
		var rect := _to_map(_rooms[i])
		for ring in 4:
			var width := 2.0
			var inset := 1.0 + ring * width
			draw_rect(rect.grow(-inset), Color(GLOW, (0.8 - ring * 0.18) * (0.4 + 0.6 * pulse)), false, width)
	for room in _rooms:
		draw_rect(_to_map(room), OUTLINE, false, wall_width)
	for door in _doors:
		var gap := _to_map(door)
		# Each half of the gap takes the colour of the room on its side, so the current room's yellow
		# runs into its doorways.
		var half_size := gap.size * (Vector2(1.0, 0.5) if gap.size.x > gap.size.y else Vector2(0.5, 1.0))
		for corner: Vector2 in [gap.position, gap.end - half_size]:
			var half := Rect2(corner, half_size)
			var inside_here := _here >= 0 and _room_index(_to_world(half.get_center())) == _here
			var side := _room_index(_to_world(half.get_center()))
			draw_rect(half, HERE if inside_here else (_room_colour(side) if side >= 0 else FLOOR))
	for i in _rooms.size():
		if i != _here and GameState.visited_rooms.has(_ids[i]):
			_draw_tick(_to_map(_rooms[i]))
	if _start >= 0:
		var start := _to_map(_rooms[_start])
		_draw_star(start.position + Vector2(9.0, 9.0), 6.5) # Top-left, clear of the arrow at your desk.
	draw_rect(panel, OUTLINE, false, 3.0)
	if _player_xz.is_finite():
		_draw_arrow(_to_map_point(_player_xz), _facing)


func _room_colour(i: int) -> Color:
	if i == _here:
		return HERE
	return VISITED if GameState.visited_rooms.has(_ids[i]) else FLOOR


## A small green tick in the room's top-right corner.
func _draw_tick(rect: Rect2) -> void:
	var at := Vector2(rect.end.x - 9.0, rect.position.y + 8.0)
	var points := PackedVector2Array([at + Vector2(-4, 0), at + Vector2(-1.5, 3), at + Vector2(4, -3.5)])
	draw_polyline(points, Color.WHITE, 4.0, true)
	draw_polyline(points, TICK, 2.2, true)


## A five-point star: where you started (your desk).
func _draw_star(at: Vector2, radius: float) -> void:
	var points := PackedVector2Array()
	for i in 10:
		var r := radius if i % 2 == 0 else radius * 0.45
		points.append(at + Vector2.UP.rotated(i * TAU / 10.0) * r)
	draw_colored_polygon(points, STAR)
	points.append(points[0])
	draw_polyline(points, OUTLINE, 1.5, true)


func _draw_arrow(at: Vector2, dir: Vector2) -> void:
	# A faint view cone, then a notched arrowhead with its tip ahead of where you stand.
	var cone := PackedVector2Array([at])
	for i in 7:
		cone.append(at + dir.rotated(deg_to_rad(-35.0 + i * 70.0 / 6.0)) * arrow_size * 2.0)
	draw_colored_polygon(cone, Color(PLAYER, 0.3))
	var side := dir.orthogonal()
	var points := PackedVector2Array([
		at + dir * arrow_size,
		at - dir * arrow_size * 0.6 + side * arrow_size * 0.6,
		at - dir * arrow_size * 0.2,
		at - dir * arrow_size * 0.6 - side * arrow_size * 0.6,
	])
	draw_colored_polygon(points, PLAYER)
	points.append(points[0])
	draw_polyline(points, OUTLINE, 1.5, true)


func _load_layout() -> void:
	_loaded = true
	var level := get_tree().current_scene
	var rooms := level.get_node_or_null(^"Rooms") if level else null
	if not rooms:
		hide()
		return
	var grid := Rect2()
	var has_grid := false
	for room: Node3D in rooms.get_children():
		var rect := Rect2(Vector2(room.global_position.x, room.global_position.z) - ROOM_SIZE / 2.0, ROOM_SIZE)
		_rooms.append(rect)
		_ids.append(_room_id(rect))
		if room.name == START_ROOM:
			_start = _rooms.size() - 1
		else:
			grid = grid.merge(rect) if has_grid else rect
			has_grid = true
	var bounds := _rooms[0]
	for room in _rooms:
		bounds = bounds.merge(room)
	# The corner rooms of the grid (everything but the start room): the ones touching two of its edges.
	for i in _rooms.size():
		if i == _start:
			continue
		var on_x := is_equal_approx(_rooms[i].position.x, grid.position.x) or is_equal_approx(_rooms[i].end.x, grid.end.x)
		var on_z := is_equal_approx(_rooms[i].position.y, grid.position.y) or is_equal_approx(_rooms[i].end.y, grid.end.y)
		if on_x and on_z and grid.size.x > ROOM_SIZE.x and grid.size.y > ROOM_SIZE.y:
			_corners.append(i)
	_origin = bounds.position
	var doors := level.get_node_or_null(^"Doors")
	var door_name := RegEx.create_from_string(DOOR_NAME)
	for door: Node3D in doors.get_children() if doors else []:
		if not door_name.search(door.name):
			continue
		# A door's local x runs along its wall.
		var along_x := absf(door.global_basis.x.x) > 0.5
		var thickness := (wall_width + 2.0) / map_scale
		var gap_size := Vector2(DOORWAY_WIDTH, thickness) if along_x else Vector2(thickness, DOORWAY_WIDTH)
		var centre := Vector2(door.global_position.x, door.global_position.z)
		_doors.append(Rect2(centre - gap_size / 2.0, gap_size))
	custom_minimum_size = bounds.size * map_scale + Vector2.ONE * padding * 2.0


## A room's id: its rounded centre, e.g. "6,-16" (rooms never move; the C1/A3 swap only swaps contents).
static func _room_id(rect: Rect2) -> String:
	var c := rect.get_center()
	return "%d,%d" % [roundi(c.x), roundi(c.y)]


func _room_index(xz: Vector2) -> int:
	for i in _rooms.size():
		if _rooms[i].has_point(xz):
			return i
	return -1


func _to_map_point(xz: Vector2) -> Vector2:
	return (xz - _origin) * map_scale + Vector2.ONE * padding


func _to_world(point: Vector2) -> Vector2:
	return (point - Vector2.ONE * padding) / map_scale + _origin


func _to_map(world: Rect2) -> Rect2:
	return Rect2(_to_map_point(world.position), world.size * map_scale)
