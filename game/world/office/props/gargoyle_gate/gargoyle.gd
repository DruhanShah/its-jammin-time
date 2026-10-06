@tool
class_name Gargoyle
extends Node3D
## One stone gargoyle on its pedestal (a stand-in: a recoloured Quaternius demon). The model is
## instanced under `Body` from `model` (also in the editor, for placing). Asleep = a frozen statue
## pose; awake = its idle loop in slow motion. `talking` nods the head (TalkWobble), `gesture()` plays
## a one-shot clip at full speed and goes back to idle. The gate (gargoyle_gate.gd) drives all of it.

signal interacted

enum Eyes { STONE, AWAKE, QUIZ }

const ANIM_PREFIX := "CharacterArmature|"
## Awake idle speed: slow and heavy, like stone.
const AWAKE_SPEED := 0.35
const PEDESTAL_TOP := 1.0
const EYE_COLORS := {Eyes.AWAKE: Color(1.0, 0.7, 0.2), Eyes.QUIZ: Color(1.0, 0.25, 0.9)}

@export var display_name := "GAR"
@export var model: PackedScene:
	set(value):
		model = value
		if is_node_ready():
			_build_model()
@export var idle_anim := "Idle"
## The model's size and where it sits relative to the pedestal top (y 1 m), tuned per model.
@export var model_scale := 0.25:
	set(value):
		model_scale = value
		_place_body()
@export var model_offset := Vector3.ZERO:
	set(value):
		model_offset = value
		_place_body()
## Height of the speech balloon's tail tip above the floor.
@export var bubble_height := 2.0:
	set(value):
		bubble_height = value
		_place_body()
## Seconds into the idle clip used as the frozen "asleep" pose.
@export var asleep_pose_time := 0.4

var talking := false:
	set(value):
		talking = value
		if _wobble:
			_wobble.talking = value

var _model: Node3D
var _anim: AnimationPlayer
var _wobble: TalkWobble
var _eye_mat: StandardMaterial3D
var _awake := false
var _eyes := Eyes.STONE

@onready var _body: Node3D = $Body
@onready var _interactable: Interactable = $Interactable
@onready var bubble_anchor: Marker3D = $BubbleAnchor


func _ready() -> void:
	_build_model()
	if not Engine.is_editor_hint():
		_interactable.interacted.connect(interacted.emit)
		sleep()


## Frozen statue pose, grey eyes.
func sleep() -> void:
	_awake = false
	set_eyes(Eyes.STONE)
	if _anim:
		_anim.play(ANIM_PREFIX + idle_anim)
		_anim.seek(asleep_pose_time, true)
		_anim.speed_scale = 0.0


func wake(eyes := Eyes.AWAKE) -> void:
	_awake = true
	set_eyes(eyes)
	if _anim and not _anim.current_animation.ends_with(idle_anim):
		_anim.play(ANIM_PREFIX + idle_anim, 0.3)
	if _anim:
		_anim.speed_scale = AWAKE_SPEED


## Plays clip `clip` (e.g. "Yes", "No", "Headbutt") once at full speed, then back to the idle loop.
func gesture(clip: String) -> void:
	var anim_name := ANIM_PREFIX + clip
	if not _anim or not _anim.has_animation(anim_name):
		return
	_anim.speed_scale = 1.0
	_anim.play(anim_name, 0.15)


func set_eyes(eyes: Eyes) -> void:
	_eyes = eyes
	if not _eye_mat:
		return
	_eye_mat.emission_enabled = eyes != Eyes.STONE
	_eye_mat.albedo_color = Color(0.45, 0.45, 0.43) if eyes == Eyes.STONE else EYE_COLORS[eyes]
	if eyes != Eyes.STONE:
		_eye_mat.emission = EYE_COLORS[eyes]
		_eye_mat.emission_energy_multiplier = 3.0


func set_interactable(on: bool) -> void:
	_interactable.enabled = on


func _place_body() -> void:
	if not is_node_ready():
		return
	_body.scale = Vector3.ONE * model_scale
	_body.position = Vector3(0, PEDESTAL_TOP, 0) + model_offset
	bubble_anchor.position.y = bubble_height


func _build_model() -> void:
	_place_body()
	if _model:
		_model.queue_free()
		_model = null
	if not model or not _body:
		return
	_model = model.instantiate()
	_body.add_child(_model)
	_paint_stone(_model)
	_anim = _model.find_child("AnimationPlayer", true, false)
	if _anim:
		var idle := _anim.get_animation(ANIM_PREFIX + idle_anim)
		if idle:
			idle.loop_mode = Animation.LOOP_LINEAR
		_anim.animation_finished.connect(_on_animation_finished)
	var skeleton: Skeleton3D = _model.find_child("Skeleton3D", true, false)
	if skeleton and not Engine.is_editor_hint():
		_wobble = TalkWobble.new()
		skeleton.add_child(_wobble)


## Recolours the demon as stone by the source material names (Demon_Main, Black, Eye_White, Eye_Black).
func _paint_stone(root: Node) -> void:
	_eye_mat = StandardMaterial3D.new()
	var by_name := {
		"Demon_Main": _stone(Color(0.55, 0.55, 0.52)),
		"Black": _stone(Color(0.25, 0.25, 0.27)),
		"Eye_White": _eye_mat,
		"Eye_Black": _stone(Color(0.03, 0.03, 0.03)),
	}
	for mesh: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		for i in mesh.mesh.get_surface_count():
			var source := mesh.mesh.surface_get_material(i)
			var key := source.resource_name if source else ""
			mesh.set_surface_override_material(i, by_name.get(key, by_name.Demon_Main))


func _stone(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.95
	var noise := NoiseTexture2D.new()
	noise.noise = FastNoiseLite.new()
	noise.noise.frequency = 0.08
	noise.seamless = true
	mat.albedo_texture = noise
	mat.uv1_triplanar = true
	mat.uv1_world_triplanar = true
	mat.uv1_scale = Vector3.ONE * 2.5
	return mat


func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name.ends_with(idle_anim):
		return
	if _awake:
		wake(_eyes)
	else:
		sleep()
