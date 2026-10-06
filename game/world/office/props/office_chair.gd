@tool
extends RigidBody3D
## Wheeled office chair the player can push around (see Player.push_force).
## Rolls on a low-friction cylinder; linear damping is the rolling resistance.
## Plays a rolling loop that gets louder and higher with speed, an occasional caster squeak,
## and a bump when it hits something.

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
## Speed change (m/s) on impact below which a bump is silent, and at which it's full volume.
@export var min_bump_speed := 0.8
@export var loud_bump_speed := 4.0
@export var bump_volume_db := -3.0
## Seconds after a bump before another one can sound.
@export var bump_cooldown := 0.3
## Chance of a squeak when the chair starts rolling, and squeaks per second while it rolls.
@export var start_squeak_chance := 0.3
@export var squeaks_per_second := 0.15

var _level := 0.0
## Velocities of the last two physics frames, to measure how hard we hit.
var _last_velocity := Vector3.ZERO
var _older_velocity := Vector3.ZERO
var _next_bump_msec := 0

@onready var roll: AudioStreamPlayer3D = $RollSound
@onready var bump: AudioStreamPlayer3D = $BumpSound
@onready var squeak: AudioStreamPlayer3D = $SqueakSound


func _ready() -> void:
	$Back.mesh = BACKS[model]
	set_physics_process(not Engine.is_editor_hint())


func _physics_process(delta: float) -> void:
	_check_bump()
	var speed := Vector2(linear_velocity.x, linear_velocity.z).length()
	# Smoothed so pushes and bumps don't make the sound flutter.
	_level = move_toward(_level, clampf(speed / loud_speed, 0.0, 1.0), delta * 4.0)
	if _level < 0.02:
		roll.stop()
		return
	var squeak_chance := squeaks_per_second * delta
	if not roll.playing:
		roll.play(randf() * roll.stream.get_length())
		squeak_chance = start_squeak_chance
	if randf() < squeak_chance and not squeak.playing:
		squeak.play()
	roll.volume_db = roll_volume_db + linear_to_db(_level)
	roll.pitch_scale = lerpf(0.8, 1.2, _level)


## A sudden sideways change of velocity means we hit something (wall, desk, chair, door, the player).
## Measured here rather than in body_entered: with Jolt, that signal can arrive after the velocity
## is already zero, so it can't tell how hard the hit was. Over two frames, since Jolt's speculative
## contacts often spread one hit over two steps.
func _check_bump() -> void:
	var hit := _older_velocity - linear_velocity
	_older_velocity = _last_velocity
	_last_velocity = linear_velocity
	var hit_speed := Vector2(hit.x, hit.z).length()
	if hit_speed < min_bump_speed or Time.get_ticks_msec() < _next_bump_msec:
		return
	_next_bump_msec = Time.get_ticks_msec() + int(bump_cooldown * 1000.0)
	bump.volume_db = bump_volume_db + linear_to_db(clampf(hit_speed / loud_bump_speed, 0.1, 1.0))
	bump.play()
