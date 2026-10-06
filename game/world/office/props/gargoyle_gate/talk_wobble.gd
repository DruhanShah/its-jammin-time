class_name TalkWobble
extends SkeletonModifier3D
## Fake "jaw" for models without one: while `talking`, nods the `bone` back and forth on top of
## whatever the AnimationPlayer posed (modifiers run after animation, so they don't fight).

@export var bone := "Head"
## Nod amplitude in radians and speed in radians per second.
@export var amount := 0.18
@export var speed := 22.0

var talking := false
var _time := 0.0
var _weight := 0.0 ## Eases the wobble in and out, so it never snaps.


func _process_modification_with_delta(delta: float) -> void:
	_weight = move_toward(_weight, 1.0 if talking else 0.0, delta * 8.0)
	if _weight <= 0.0:
		return
	var skeleton := get_skeleton()
	var index := skeleton.find_bone(bone) if skeleton else -1
	if index < 0:
		return
	_time += delta
	var nod := Quaternion(Vector3.RIGHT, sin(_time * speed) * amount * _weight)
	skeleton.set_bone_pose_rotation(index, skeleton.get_bone_pose_rotation(index) * nod)
