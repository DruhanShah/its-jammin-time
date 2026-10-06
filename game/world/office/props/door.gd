@tool
extends Node3D
## Openable door for a doorway (origin = middle of the opening at floor level, wall along local X).
## X (via the Interactable on the leaf) swings it open away from the player, X again closes it.
## The leaf is an AnimatableBody3D: it shoves chairs aside, and stops where it is if the player is in the way.

const LEAVES: Array[Mesh] = [
	preload("res://assets/vnb_office/meshes/Door_A.res"),
	preload("res://assets/vnb_office/meshes/Door_B.res"),
	preload("res://assets/vnb_office/meshes/Door_C.res"),
]
## The close sound's bang is this far into the clip, so it starts that long before the leaf shuts.
const CLOSE_LEAD := 0.35

@export_enum("Solid", "Small window", "Tall window") var leaf := 0:
	set(value):
		leaf = value
		if is_node_ready():
			$Hinge/Leaf.mesh = LEAVES[leaf]
## Wall-coloured panel filling the wall opening above the frame. Off for doors standing free or flat on a wall.
@export var transom := true:
	set(value):
		transom = value
		if is_node_ready():
			$Transom.visible = transom
## Only swing toward local +Z (into the room), for a door flat on a wall.
@export var one_way := false
## Locked until `GameState.unlock(unlock_id)`; pressing X then gets the narrator mocking you.
@export_custom(PROPERTY_HINT_ENUM_SUGGESTION, Unlocks.ALL) var unlock_id: StringName
@export var open_degrees := 90.0
@export var swing_speed := 150.0 ## Degrees per second.
@export var open_sound: AudioStream = preload("res://assets/audio/sfx/400_sounds_pack/door_open.wav")
@export var close_sound: AudioStream = preload("res://assets/audio/sfx/400_sounds_pack/door_close.wav")

var is_open := false
var _target := 0.0
var _close_pending := false

@onready var hinge: AnimatableBody3D = $Hinge
@onready var interactable: Interactable = $Hinge/Interactable
@onready var sound: AudioStreamPlayer3D = $Sound
@onready var _leaf_shape: CollisionShape3D = $Hinge/CollisionShape3D


func _ready() -> void:
	$Hinge/Leaf.mesh = LEAVES[leaf]
	$Transom.visible = transom
	set_physics_process(false)
	if Engine.is_editor_hint():
		return
	interactable.unlock_id = unlock_id
	interactable.interacted.connect(toggle)
	_update_verb()


func toggle() -> void:
	is_open = not is_open
	if is_open:
		var player_side := to_local(get_viewport().get_camera_3d().global_position).z
		# +degrees swings the leaf toward -Z, so open to the side the player isn't on.
		_target = -open_degrees if one_way or player_side < 0.0 else open_degrees
		_close_pending = false
		_play(open_sound)
	else:
		_target = 0.0
		_close_pending = true
	_update_verb()
	set_physics_process(true)


func _physics_process(delta: float) -> void:
	var angle := hinge.rotation_degrees.y
	if _close_pending and absf(angle) <= swing_speed * CLOSE_LEAD:
		_close_pending = false
		_play(close_sound)
	var next := move_toward(angle, _target, swing_speed * delta)
	if _player_in_way(next):
		set_physics_process(false) # Stay put; the next X swings it the other way.
		return
	hinge.rotation_degrees.y = next
	if next == _target:
		set_physics_process(false)


func _player_in_way(degrees: float) -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = _leaf_shape.shape
	query.transform = global_transform * Transform3D(Basis(Vector3.UP, deg_to_rad(degrees)), hinge.position) * _leaf_shape.transform
	query.exclude = [hinge.get_rid()]
	for hit in get_world_3d().direct_space_state.intersect_shape(query, 8):
		if hit.collider is CharacterBody3D:
			return true
	return false


func _update_verb() -> void:
	interactable.verb = "close the door" if is_open else "open the door"


func _play(stream: AudioStream) -> void:
	sound.stream = stream
	sound.play()
