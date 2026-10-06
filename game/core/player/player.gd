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
## Force (N) on rigid bodies we walk into, e.g. office chairs. Only while they're slower than us.
@export var push_force := 300.0

## Narrator cues played once the player has pushed chairs for this many seconds in total.
const CHAIR_JABS := {15.0: &"chair_push_1", 45.0: &"chair_push_2"}
## Narrator cue when a chair we pushed rolls into a different room than it started in.
const CHAIR_NEW_ROOM_JAB := &"chair_new_room"
## Seconds after our last push that a rolling chair still counts as pushed by us.
const CHAIR_PUSH_MEMORY := 2.0

var _bob_time := 0.0
var _step := 0
var _target: Interactable ## What we're aiming at (highlighted), or null.
## Chairs we've pushed: body -> [room it was in when first pushed, Time.get_ticks_msec() of the last push].
var _pushed_chairs: Dictionary[RigidBody3D, Array] = {}

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
	if target != _target:
		if is_instance_valid(_target):
			_target.set_highlighted(false)
		if target:
			target.set_highlighted(true)
		_target = target
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
			# Reach toward the object's centre, so things off to the left get the left hand.
			hands.touch(target.global_position)
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
	_push_bodies(delta)
	_update_head_bob(delta)


## CharacterBody3D doesn't move rigid bodies by itself, so nudge what we bumped into.
func _push_bodies(delta: float) -> void:
	var pushed := false
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var body := collision.get_collider() as RigidBody3D
		if not body:
			continue
		hands.push()
		pushed = true
		if not _pushed_chairs.has(body):
			_pushed_chairs[body] = [_room_at(body.global_position), 0]
		_pushed_chairs[body][1] = Time.get_ticks_msec()
		var push := -collision.get_normal()
		push.y = 0.0  # Only sideways, so standing on or brushing past it doesn't press it into the floor.
		push = push.normalized()
		if body.linear_velocity.dot(push) < speed:
			body.apply_central_impulse(push * push_force * delta)
	# Only chairs are rigid bodies so far. The clock pauses while the narrator talks, so a jab never cuts a line off.
	if pushed and not Narrator.is_speaking():
		var before := GameState.chair_push_time
		GameState.chair_push_time += delta
		for seconds: float in CHAIR_JABS:
			if before < seconds and GameState.chair_push_time >= seconds:
				Narrator.play(CHAIR_JABS[seconds])
	_check_chair_rooms()


## Jab once a chair we're pushing (or just shoved) crosses into another room. Waits while the narrator talks.
func _check_chair_rooms() -> void:
	if Narrator.is_speaking():
		return
	for chair: RigidBody3D in _pushed_chairs:
		var start_room: Node3D = _pushed_chairs[chair][0]
		if Time.get_ticks_msec() - _pushed_chairs[chair][1] > CHAIR_PUSH_MEMORY * 1000.0:
			continue
		var room := _room_at(chair.global_position)
		if start_room and room and room != start_room:
			Narrator.play(CHAIR_NEW_ROOM_JAB)
			return


## The room (a child of the level's `Rooms`, at its floor centre, 12 x 16 m) that contains `pos`, or null.
func _room_at(pos: Vector3) -> Node3D:
	var rooms := owner.get_node_or_null(^"Rooms")
	if not rooms:
		return null
	for room: Node3D in rooms.get_children():
		var offset := pos - room.global_position
		if absf(offset.x) <= 6.0 and absf(offset.z) <= 8.0:
			return room
	return null


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


## The enabled Interactable the player is looking at (within the ray's reach), or null. May be locked.
func _interactable() -> Interactable:
	var target := ray.get_collider() as Interactable
	return target if target and target.enabled else null


func _touch() -> void:
	if ray.is_colliding():
		hands.touch(ray.get_collision_point())
		Audio.play_sfx(touch_sound, touch_volume_db)
	else:
		hands.touch(ray.to_global(ray.target_position))
