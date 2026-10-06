class_name Minimap
extends Control
## North-up mini-map of the level, drawn with `_draw()` (no second camera): one box per room, gaps for
## doorways, the room you're in filled yellow and an arrow for where you stand and look.
##
## It reads the level's layout on the first frame: every child of the current scene's `Rooms` node is
## a room of `ROOM_SIZE` centred on it (unrotated), every child of `Doors` named after two rooms is a
## doorway. Positions only, no names, so swapping two rooms' contents (C1/A3) doesn't change the map.
## Levels without `Rooms` hide it. Hide it yourself with `visible = false` (e.g. over a close-up).

const ROOM_SIZE := Vector2(12.0, 16.0) ## Metres (x, z), as in docs/map/README.md.
const DOOR_NAME := "^(Start|[A-C][1-3]){2}$"
const DOORWAY_WIDTH := 2.0 ## Metres of wall left out per doorway (wider than the real 1.06 m, to read).

const OUTLINE := Color("#1b1b1b")
const PAPER := Color("#fff8e7")
const FLOOR := Color("#d9cdb4")
const HERE := Color("#ffd23f")
const PLAYER := Color("#ff4d4d")

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
var _loaded := false


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	if not _loaded:
		_load_layout()
	var camera := get_viewport().get_camera_3d()
	if not camera or _rooms.is_empty():
		return
	var xz := Vector2(camera.global_position.x, camera.global_position.z)
	var forward := -camera.global_basis.z
	var facing := Vector2(forward.x, forward.z).normalized() if Vector2(forward.x, forward.z).length() > 0.01 else _facing
	if xz.distance_squared_to(_player_xz) < 0.0004 and facing.dot(_facing) > 0.9999:
		return
	_player_xz = xz
	_facing = facing
	_here = _room_index(xz)
	queue_redraw()


func _draw() -> void:
	if _rooms.is_empty():
		return
	var panel := Rect2(Vector2.ZERO, size)
	draw_rect(Rect2(shadow_offset, size), Color(0, 0, 0, 0.85))
	draw_rect(panel, PAPER)
	for i in _rooms.size():
		draw_rect(_to_map(_rooms[i]), HERE if i == _here else FLOOR)
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
			draw_rect(half, HERE if inside_here else FLOOR)
	draw_rect(panel, OUTLINE, false, 3.0)
	if _player_xz.is_finite():
		_draw_arrow(_to_map_point(_player_xz), _facing)


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
	for room: Node3D in rooms.get_children():
		_rooms.append(Rect2(Vector2(room.global_position.x, room.global_position.z) - ROOM_SIZE / 2.0, ROOM_SIZE))
	var bounds := _rooms[0]
	for room in _rooms:
		bounds = bounds.merge(room)
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
