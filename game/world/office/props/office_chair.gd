@tool
extends RigidBody3D
## Wheeled office chair the player can push around (see Player.push_force).
## Rolls on a low-friction cylinder; linear damping is the rolling resistance.
## Plays a rolling loop that gets louder and higher with speed.

const BACKS: Array[Mesh] = [
	preload("res://assets/vnb_office/meshes/Chair_Office_Base_A.res"),
	preload("res://assets/vnb_office/meshes/Chair_Office_Base_B.res"),
	preload("res://assets/vnb_office/meshes/Chair_Office_Base_C.res"),
]

@export_enum("Task (blue)", "Armchair (black)", "Executive (high back)") var model := 1:
	set(value):
		model = value
		if is_node_ready():
			$Back.mesh = BACKS[model]
## Speed (m/s) at which the rolling sound reaches full volume and pitch.
@export var loud_speed := 3.0
@export var roll_volume_db := -6.0

var _level := 0.0

@onready var roll: AudioStreamPlayer3D = $RollSound


func _ready() -> void:
	$Back.mesh = BACKS[model]
	set_physics_process(not Engine.is_editor_hint())


func _physics_process(delta: float) -> void:
	var speed := Vector2(linear_velocity.x, linear_velocity.z).length()
	# Smoothed so pushes and bumps don't make the sound flutter.
	_level = move_toward(_level, clampf(speed / loud_speed, 0.0, 1.0), delta * 4.0)
	if _level < 0.02:
		roll.stop()
		return
	if not roll.playing:
		roll.play(randf() * roll.stream.get_length())
	roll.volume_db = roll_volume_db + linear_to_db(_level)
	roll.pitch_scale = lerpf(0.8, 1.2, _level)
