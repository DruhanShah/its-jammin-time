extends CharacterBody3D

@export var speed := 4.0
@export var mouse_sensitivity := 0.002
@export var bob_frequency := 3.0
@export var bob_amplitude := 0.05
@export var footstep_sound: AudioStream = preload("res://core/audio/footsteps.tres")
## Footsteps stay subtle under music and narration.
@export var footstep_volume_db := -10.0
@export var touch_sound: AudioStream = preload("res://assets/audio/sfx/400_sounds_pack/wood_small_hollow.wav")
@export var touch_volume_db := -6.0

var _bob_time := 0.0
var _step := 0

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var ray: RayCast3D = $Head/Camera3D/InteractRay
@onready var hands: PlayerHands = $Head/Camera3D/Hands
@onready var hud: PlayerHud = $HUD


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	ray.add_exception(self)
	var pose: Array = GameState.player_poses.get(owner.scene_file_path, [])
	if pose:
		global_transform = pose[0]
		head.rotation.x = pose[1]


func _exit_tree() -> void:
	# Remember where we were, e.g. when leaving the office for a minigame.
	GameState.player_poses[owner.scene_file_path] = [global_transform, head.rotation.x]


func _process(_delta: float) -> void:
	var target := _interactable()
	hud.show_prompt(target.verb if target else "")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# Body turns left/right, head tilts up/down.
		rotate_y(-event.relative.x * mouse_sensitivity)
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		head.rotation.x = clampf(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseButton and event.pressed:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed("interact"):
		var target := _interactable()
		if target:
			target.interact()
	elif event.is_action_pressed("touch"):
		_touch()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input.x, 0, input.y)).normalized()
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

	move_and_slide()
	_update_head_bob(delta)


func _update_head_bob(delta: float) -> void:
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	if is_on_floor() and horizontal_speed > 0.1:
		# Up/down once per step, side to side once per two steps.
		_bob_time += delta * horizontal_speed
		camera.position = Vector3(
			cos(_bob_time * bob_frequency * 0.5) * bob_amplitude,
			sin(_bob_time * bob_frequency) * bob_amplitude,
			0.0
		)
		# A step lands at the bottom of each bob.
		var step := floori(_bob_time * bob_frequency / TAU + 0.25)
		if step != _step:
			_step = step
			Audio.play_sfx(footstep_sound, footstep_volume_db)
	else:
		camera.position = camera.position.lerp(Vector3.ZERO, delta * 10.0)


## The Interactable the player is looking at (within the ray's reach), or null.
func _interactable() -> Interactable:
	return ray.get_collider() as Interactable


func _touch() -> void:
	if ray.is_colliding():
		hands.touch(ray.get_collision_point())
		Audio.play_sfx(touch_sound, touch_volume_db)
	else:
		hands.touch(ray.to_global(ray.target_position))
