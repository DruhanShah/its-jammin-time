extends CharacterBody3D

@export var speed := 4.0
@export var mouse_sensitivity := 0.002
@export var bob_frequency := 3.0
@export var bob_amplitude := 0.05

var _bob_time := 0.0

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# Body turns left/right, head tilts up/down.
		rotate_y(-event.relative.x * mouse_sensitivity)
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		head.rotation.x = clampf(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


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
	else:
		camera.position = camera.position.lerp(Vector3.ZERO, delta * 10.0)
