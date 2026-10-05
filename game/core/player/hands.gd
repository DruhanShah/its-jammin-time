class_name PlayerHands
extends Node3D
## First-person arms (PSX First Person Arms rig), attached to the camera.
## The rig is turned to face -Z and its `camera` bone sits on the camera. It's scaled down around the camera,
## which doesn't change how big the arms look but keeps them inside the player's 0.3 m capsule, so they can't poke into walls.
## `Arms/AnimationTree`: `relax` loops, `push` blends the right arm into a palm-forward push pose, and the `grab_R`/`grab_L` one-shots
## play the visible part (0.15–0.5 s) of a grab on that arm's bones only, so the other arm keeps doing what it was.

## A target more than this many degrees left of the crosshair is grabbed with the left hand.
@export var left_grab_angle := 5.0
## Seconds to blend the push pose in and out.
@export var push_blend_time := 0.2
## Seconds the push pose is kept after the last bump, so it doesn't flicker while the chair rolls off.
@export var push_hold := 0.3
## The arms lag this many seconds of turning behind the camera (rotating around the camera keeps them inside the capsule).
@export var sway_lag := 0.04
@export var max_sway_degrees := 4.0
## How quickly the arms catch up with the sway target (1/s).
@export var sway_speed := 12.0

var _push_left := 0.0
var _sway := Vector2.ZERO

@onready var _tree: AnimationTree = $Arms/AnimationTree
@onready var _camera: Node3D = get_parent_node_3d()
@onready var _last_camera_basis := _camera.global_basis


func _process(delta: float) -> void:
	_push_left -= delta
	var push: float = _tree.get(&"parameters/push/blend_amount")
	push = move_toward(push, 1.0 if _push_left > 0.0 else 0.0, delta / push_blend_time)
	_tree.set(&"parameters/push/blend_amount", push)
	_update_sway(delta)


## Grab toward a world point (left hand if it's to the left), then back to idle. Ignored while already grabbing.
func touch(target: Vector3) -> void:
	if _tree.get(&"parameters/grab_R/active") or _tree.get(&"parameters/grab_L/active"):
		return
	var local := _camera.to_local(target)
	var left := local.x < -absf(local.z) * tan(deg_to_rad(left_grab_angle))
	_tree.set(&"parameters/grab_L/request" if left else &"parameters/grab_R/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)


## Call every physics frame the player is pushing something.
func push() -> void:
	_push_left = push_hold


func _update_sway(delta: float) -> void:
	# How far the camera turned this frame, in its own space (x = pitch, y = yaw).
	var turn := (_last_camera_basis.inverse() * _camera.global_basis).get_euler()
	_last_camera_basis = _camera.global_basis
	# Smooth before clamping: mouse events don't arrive every frame, so a single frame's turn is spiky.
	var target := -Vector2(turn.x, turn.y) / delta * sway_lag
	_sway = _sway.lerp(target, 1.0 - exp(-sway_speed * delta)).limit_length(deg_to_rad(max_sway_degrees))
	rotation = Vector3(_sway.x, _sway.y, 0.0)
