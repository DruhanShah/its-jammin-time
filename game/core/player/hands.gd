class_name PlayerHands
extends Node3D
## Placeholder first-person hands, attached to the camera.
## Kept small and close to the camera (inside the player's collision capsule) so they can't poke into walls.

@export var reach_time := 0.12
@export var return_time := 0.2

var _tween: Tween

@onready var right_hand: Node3D = $RightHand
@onready var _rest := right_hand.position


## Quick reach of the right hand toward a world point, then back.
func touch(target: Vector3) -> void:
	if _tween and _tween.is_running():
		return
	# Stretch at most 0.15 m forward so the hand stays mostly on screen.
	var local_target := to_local(target)
	var reach := _rest + (local_target - _rest).limit_length(0.15)
	_tween = create_tween().set_trans(Tween.TRANS_SINE)
	_tween.tween_property(right_hand, "position", reach, reach_time).set_ease(Tween.EASE_OUT)
	_tween.tween_property(right_hand, "position", _rest, return_time).set_ease(Tween.EASE_IN_OUT)
