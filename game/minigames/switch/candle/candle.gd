extends Node3D
## Switch game "candle" (restore game of the third blackout, see switch_games.gd): behind the
## keypad's panel the fuse is a candle between two terminals, and it has no wick.
## 1. Roll the keys around G clockwise (`TwistInput`) to twist three loose threads into a wick.
## 2. The wick plants itself in the candle.
## 3. Strike the match (the `interact` key, or a click): it fizzles twice, lights on the third.
## 4. The match lights the wick; the flame leans out, touches both terminals and the spark arcs
##    across: the circuit is closed, the lever flips up by itself and the power comes back on.
## No instructions on screen: the twist hint, a keycap by the matchbox and the narrator carry it.
## Esc leaves (the candle starts over next time; the keypad stays beaten).

const ID := &"candle"
const STRAND_SHADER := preload("res://minigames/switch/candle/strand_twist.gdshader")
const FLAME_SHADER := preload("res://minigames/switch/candle/flame.gdshader")
const ARC_SEGMENTS := 5 ## Per leg (terminal → flame tip), per bolt.
const ARC_BOLTS := 2

enum Phase {WICK, PLANT, STRIKE, LIGHT, CIRCUIT, DONE}

## Degrees of clockwise twist that make a wick (one key step = 60°).
@export var wick_degrees := 720.0
## Full turns the strands wind round each other in a finished wick.
@export var wick_turns := 5.0
## Strand offset from the thread's axis: loose (start) and twisted tight (done), metres.
@export var loose_spread := 0.006
@export var tight_spread := 0.0016
## How fast the thread catches up with the keys (1/s).
@export var follow_speed := 12.0
## Match strikes that fizzle before one lights (rule of three).
@export var fizzles := 2
## Seconds after the lights come back before moving on (longer while the narrator is still talking).
@export var exit_delay := 1.5
## Longest wait for the narrator's line before moving on anyway.
@export var max_line_wait := 10.0
## Camera shots: [eye, target] for the thread, the candle + matches, and the whole switchboard.
@export var wick_shot: Array[Vector3] = [Vector3(-0.13, -0.25, 0.30), Vector3(-0.19, -0.33, -0.12)]
@export var candle_shot: Array[Vector3] = [Vector3(0.06, -0.17, 0.50), Vector3(0.03, -0.31, -0.12)]
@export var wide_shot: Array[Vector3] = [Vector3(0.14, 0.05, 1.45), Vector3(0.0, -0.02, -0.2)]
@export var twist_sound: AudioStream
@export var twist_volume_db := -8.0
@export var plant_sound: AudioStream
@export var match_sound: AudioStream
@export var light_sound: AudioStream
@export var whoosh_sound: AudioStream
@export var zap_sound: AudioStream
@export var lever_sound: AudioStream
@export var hum_sound: AudioStream

var _phase := Phase.WICK
var _twisted := 0.0 ## Degrees twisted (0..wick_degrees).
var _shown := 0.0 ## Degrees shown (eases toward `_twisted`).
var _strikes := 0
var _busy := false ## A strike (or the lighting) is animating.
var _lit := false
var _arc_on := false
var _arc_timer := 0.0
var _time := 0.0
var _strand_mats: Array[ShaderMaterial] = []
var _flame_mat: ShaderMaterial
var _flame_size := Vector3.ONE ## The flame's full-size scale (the candle model's units).
var _flame_energy := 1.4
var _wick_base := Vector3.ZERO ## Where the wick goes into the candle (global).
var _arc_segments: Array[MeshInstance3D] = []
var _camera_tween: Tween

@onready var _camera: Camera3D = $Camera3D
@onready var _twist: TwistInput = $TwistInput
@onready var _hint: TwistHint = $Hud/Hint
@onready var _keycap: Control = $Hud/Keycap
@onready var _keycap_label: Label = $Hud/Keycap/Key
@onready var _burst_layer: Control = $Hud/Bursts
@onready var _thread: Node3D = $Thread
@onready var _strands: Array[Node] = $Thread/Strands.get_children()
@onready var _knots: Node3D = $Thread/Knots
@onready var _candle: Node3D = $CandleModel
@onready var _match: Node3D = $Match
@onready var _match_head: Node3D = $Match/Head
@onready var _striker: Node3D = $Matchbox/Striker
@onready var _match_player: AudioStreamPlayer = $MatchPlayer
@onready var _crackle: AudioStreamPlayer = $Crackle
@onready var _lever: Node3D = $Lever
@onready var _terminal_plus: Node3D = $TerminalPlus/Tip
@onready var _terminal_minus: Node3D = $TerminalMinus/Tip
@onready var _arc: Node3D = $Arc
@onready var _key_lamp: OmniLight3D = $KeyLamp
@onready var _red_fill: OmniLight3D = $RedFill
@onready var _flame_light: OmniLight3D = $FlameLight
@onready var _room_light: OmniLight3D = $RoomLight
@onready var _env: Environment = $WorldEnvironment.environment

var _flame: MeshInstance3D
var _match_flame: MeshInstance3D


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	_split_candle()
	_make_strands()
	_make_wires()
	_make_arc()
	_set_shot(wick_shot)
	_keycap_label.text = PlayerHud.key_name(&"interact")
	_keycap.hide()
	_hint.arrow_direction = 1
	_twist.twisted.connect(_on_twisted)
	Narrator.play(&"candle_intro")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and _phase < Phase.CIRCUIT:
		Transition.change_scene(Story.OFFICE)
		return
	if _phase != Phase.STRIKE or _busy:
		return
	var click: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	if click or event.is_action_pressed(&"interact"):
		get_viewport().set_input_as_handled()
		_strike()


func _process(delta: float) -> void:
	_time += delta
	if _phase <= Phase.PLANT:
		_shown = lerpf(_shown, _twisted, 1.0 - exp(-follow_speed * delta))
		_update_strands(_shown / wick_degrees)
		_hint.progress = _twisted / wick_degrees
	if _lit:
		_flicker()
	if _keycap.visible:
		_place_keycap()
	if _arc_on:
		_arc_timer -= delta
		if _arc_timer <= 0.0:
			_arc_timer = 0.05
			_jitter_arc()


# --- 1. Wick -------------------------------------------------------------------------------------

func _on_twisted(delta: float) -> void:
	if _phase != Phase.WICK:
		return
	var before := _twisted
	_twisted = clampf(_twisted + delta, 0.0, wick_degrees) # Clockwise twists, anticlockwise untwists.
	if _twisted == before:
		return
	Audio.play_sfx(twist_sound, twist_volume_db)
	if _twisted >= wick_degrees:
		_plant()


func _update_strands(progress: float) -> void:
	for mat in _strand_mats:
		mat.set_shader_parameter(&"twist", progress * wick_turns * TAU)
		mat.set_shader_parameter(&"spread", lerpf(loose_spread, tight_spread, progress))


# --- 2. Plant ------------------------------------------------------------------------------------

## The finished wick lifts off the spool, flies over and sinks into the candle.
func _plant() -> void:
	_phase = Phase.PLANT
	_hint.hide()
	Narrator.play(&"candle_wick_done")
	_move_camera(candle_shot, 1.4)
	var above := _wick_base + Vector3(0, 0.07, 0)
	var t := create_tween()
	t.tween_interval(0.5)
	t.tween_property(_knots, "scale", Vector3.ZERO, 0.2)
	t.tween_property(_thread, "global_position:y", _thread.global_position.y + 0.06, 0.3).set_trans(Tween.TRANS_SINE)
	t.tween_property(_thread, "global_position", above, 0.6).set_trans(Tween.TRANS_SINE)
	t.tween_property(_thread, "scale", Vector3(0.7, 0.2, 0.7), 0.25)
	t.tween_property(_thread, "global_position", _wick_base - Vector3(0, 0.004, 0), 0.18).set_ease(Tween.EASE_IN)
	t.tween_callback(Audio.play_sfx.bind(plant_sound, -4.0))
	t.tween_interval(0.4)
	t.tween_callback(_ready_to_strike)


# --- 3. Strike -----------------------------------------------------------------------------------

func _ready_to_strike() -> void:
	_phase = Phase.STRIKE
	_keycap.show()
	_keycap.modulate.a = 0.0
	create_tween().tween_property(_keycap, "modulate:a", 1.0, 0.3)


## One scrape along the striker: fizzles `fizzles` times (a puff of smoke), then lights.
func _strike() -> void:
	_busy = true
	_strikes += 1
	_keycap.hide()
	var lights := _strikes > fizzles
	var rest := _match.position
	var start := _striker.global_position + Vector3(-0.03, 0.002, 0.006)
	var end := start + Vector3(0.065, 0.003, 0.0)
	var t := create_tween()
	t.tween_property(_match, "global_position", start, 0.14).set_trans(Tween.TRANS_SINE)
	t.tween_callback(_play_match.bind(lights))
	t.tween_property(_match, "global_position", end, 0.12).set_ease(Tween.EASE_OUT)
	t.tween_property(_match, "position", rest + Vector3(0.02, 0.02, 0.0), 0.15).set_trans(Tween.TRANS_SINE)
	if lights:
		t.tween_callback(_light_match)
		t.tween_interval(0.5)
		t.tween_callback(_light_wick)
		return
	t.tween_callback(_puff.bind(_match_head.global_position))
	t.tween_property(_match, "position", rest, 0.3).set_delay(0.35).set_trans(Tween.TRANS_SINE)
	t.tween_callback(func() -> void:
		_busy = false
		_keycap.show())
	if _strikes == 1:
		Narrator.play(&"candle_match_fizzle")


## The scrape: the whole "light_match" sound when it lights, its first scratch when it fizzles.
func _play_match(lights: bool) -> void:
	_match_player.stream = match_sound
	_match_player.volume_db = -2.0
	_match_player.pitch_scale = 1.0 if lights else randf_range(0.95, 1.1)
	_match_player.play()
	if not lights:
		create_tween().tween_property(_match_player, "volume_db", -40.0, 0.12).set_delay(0.2)


func _light_match() -> void:
	_match_flame.show()
	_match_flame.scale = Vector3.ZERO
	create_tween().tween_property(_match_flame, "scale", Vector3.ONE * 25.0, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## A little grey puff of smoke that grows and fades.
func _puff(at: Vector3) -> void:
	var puff := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.008
	mesh.height = 0.016
	mesh.radial_segments = 12
	mesh.rings = 6
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.7, 0.7, 0.72, 0.7)
	mesh.material = mat
	puff.mesh = mesh
	add_child(puff)
	puff.global_position = at
	var t := create_tween().set_parallel()
	t.tween_property(puff, "scale", Vector3.ONE * 3.5, 0.9).set_ease(Tween.EASE_OUT)
	t.tween_property(puff, "global_position:y", at.y + 0.04, 0.9)
	t.tween_property(mat, "albedo_color:a", 0.0, 0.9)
	t.chain().tween_callback(puff.queue_free)


# --- 4. Light ------------------------------------------------------------------------------------

## The lit match goes to the wick, the candle catches, the match is shaken out and dropped.
func _light_wick() -> void:
	_phase = Phase.LIGHT
	var rest := _match.global_position
	var t := create_tween()
	t.tween_property(_match, "global_position", _wick_base + Vector3(0.012, 0.022, 0.01), 0.6).set_trans(Tween.TRANS_SINE)
	t.tween_callback(_catch)
	t.tween_interval(0.5)
	t.tween_property(_match, "global_position", rest + Vector3(0.0, 0.03, 0.0), 0.4).set_trans(Tween.TRANS_SINE)
	for i in 4: # Shake it out.
		t.tween_property(_match, "rotation:z", _match.rotation.z + (0.5 if i % 2 == 0 else -0.5), 0.07)
	t.tween_callback(_match_flame.hide)
	t.tween_property(_match, "rotation:z", _match.rotation.z, 0.07)
	t.tween_property(_match, "global_position:y", rest.y - 0.6, 0.45).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	t.parallel().tween_property(_match, "rotation:x", 3.0, 0.45)
	t.tween_callback(_match.hide)
	t.tween_interval(0.6)
	t.tween_callback(_close_circuit)


func _catch() -> void:
	Audio.play_sfx(light_sound, -2.0)
	Audio.play_sfx(whoosh_sound, -6.0)
	_crackle.play()
	_flame.show()
	_flame.scale = Vector3.ZERO
	var t := create_tween().set_parallel()
	t.tween_property(_flame, "scale", _flame_size, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(_flame_light, "light_energy", _flame_energy, 0.5)
	t.tween_property(_key_lamp, "light_energy", 0.0, 1.2)
	t.chain().tween_callback(func() -> void: _lit = true)


## A burning candle's flicker (only while nothing else is animating the flame).
func _flicker() -> void:
	var wobble := 0.07 * sin(_time * 13.0) + 0.05 * sin(_time * 31.0 + 1.3) + 0.03 * sin(_time * 7.0 + 0.4)
	_flame.scale.y = _flame_size.y * (1.0 + wobble)
	_flame_light.light_energy = _flame_energy * (1.0 + wobble * 0.8)


# --- 5. Circuit ----------------------------------------------------------------------------------

## The flame stretches out to both terminals and turns into an electric arc: the circuit closes,
## the lever flips up by itself and the lights come back.
func _close_circuit() -> void:
	_phase = Phase.CIRCUIT
	_lit = false
	var t := create_tween()
	t.set_parallel()
	t.tween_property(_flame, "scale", Vector3(_flame_size.x * 2.6, _flame_size.y * 1.1, _flame_size.z * 1.2), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_method(_set_flame_colors.bind(Color(1.0, 0.95, 0.6), Color(1.0, 0.45, 0.05), Color(0.85, 0.97, 1.0), Color(0.2, 0.75, 1.0)), 0.0, 1.0, 0.35)
	t.tween_property(_flame_light, "light_color", Color(0.55, 0.85, 1.0), 0.35)
	t.tween_property(_flame_light, "light_energy", 1.8, 0.35)
	t.set_parallel(false)
	t.tween_callback(_zap)
	t.tween_interval(1.0)
	t.tween_callback(_move_camera.bind(wide_shot, 1.0))
	t.tween_interval(1.1)
	t.tween_callback(_flip_lever)
	t.tween_interval(0.35)
	t.tween_callback(_lights_on)


func _set_flame_colors(w: float, base_from: Color, tip_from: Color, base_to: Color, tip_to: Color) -> void:
	_flame_mat.set_shader_parameter(&"base_color", base_from.lerp(base_to, w))
	_flame_mat.set_shader_parameter(&"tip_color", tip_from.lerp(tip_to, w))


func _zap() -> void:
	_arc_on = true
	_arc.show()
	Audio.play_sfx(zap_sound, -2.0)
	Narrator.play(&"candle_circuit")
	var at := _camera.unproject_position(_flame.global_position + Vector3(0, 0.05, 0))
	ComicBurst.spawn(_burst_layer, at + Vector2(0, -120), "ZZZAP!", Color("#7fe6ff"))


func _flip_lever() -> void:
	Audio.play_sfx(lever_sound, -2.0)
	create_tween().tween_property(_lever, "rotation:x", 0.35, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Power's back: the emergency red flickers off, the room light flickers on, the flame calms down.
func _lights_on() -> void:
	var t := create_tween()
	for on in [true, false, true, false, true]:
		t.tween_callback(_set_power_light.bind(on))
		t.tween_interval(0.07)
	t.tween_callback(Audio.play_sfx.bind(hum_sound, -8.0))
	t.tween_interval(0.5)
	t.tween_callback(func() -> void:
		_arc_on = false
		_arc.hide())
	t.set_parallel()
	t.tween_property(_flame, "scale", _flame_size, 0.4).set_trans(Tween.TRANS_SINE)
	t.tween_method(_set_flame_colors.bind(Color(0.85, 0.97, 1.0), Color(0.2, 0.75, 1.0), Color(1.0, 0.95, 0.6), Color(1.0, 0.45, 0.05)), 0.0, 1.0, 0.4)
	t.tween_property(_flame_light, "light_color", Color(1.0, 0.6, 0.25), 0.4)
	t.tween_property(_flame_light, "light_energy", _flame_energy, 0.4)
	t.set_parallel(false)
	t.tween_callback(func() -> void:
		_phase = Phase.DONE
		_lit = true)
	t.tween_interval(exit_delay)
	await t.finished
	var waited := 0.0
	while Narrator.is_speaking() and waited < max_line_wait:
		await get_tree().create_timer(0.2).timeout
		waited += 0.2
	Story.switch_game_done(ID) # Last game of SWITCH_3: the power comes on, the story moves on.
	Transition.change_scene(Story.next_switch_scene())


func _set_power_light(on: bool) -> void:
	_room_light.light_energy = 1.6 if on else 0.0
	_red_fill.light_energy = 0.0 if on else 0.9
	_env.ambient_light_energy = 0.45 if on else 0.12


# --- Building bits -------------------------------------------------------------------------------

## The candle model has the wick and flame baked in as extra surfaces: rebuild it without them,
## keep the wick's spot as the socket for our twisted one and reuse the flame as our flame.
func _split_candle() -> void:
	var source: MeshInstance3D = _candle.find_children("*", "MeshInstance3D")[0]
	var mesh := source.mesh as ArrayMesh
	var wick := -1
	var flame := -1
	for i in mesh.get_surface_count():
		var material := mesh.surface_get_material(i)
		var mat_name := material.resource_name if material else ""
		if mat_name == "mat17":
			wick = i
		elif mat_name == "mat12":
			flame = i
	assert(wick >= 0 and flame >= 0, "candle.glb: wick (mat17) or flame (mat12) surface not found")
	var body := ArrayMesh.new()
	for i in mesh.get_surface_count():
		if i != wick and i != flame:
			body.add_surface_from_arrays(mesh.surface_get_primitive_type(i), mesh.surface_get_arrays(i))
			body.surface_set_material(body.get_surface_count() - 1, mesh.surface_get_material(i))
	source.mesh = body
	var wick_box := _surface_aabb(mesh, wick)
	_wick_base = source.global_transform * Vector3(wick_box.get_center().x, wick_box.position.y, wick_box.get_center().z)

	var flame_box := _surface_aabb(mesh, flame)
	var foot := Vector3(flame_box.get_center().x, flame_box.position.y, flame_box.get_center().z)
	var arrays := mesh.surface_get_arrays(flame)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	for i in verts.size():
		verts[i] -= foot
	arrays[Mesh.ARRAY_VERTEX] = verts
	var flame_mesh := ArrayMesh.new()
	flame_mesh.add_surface_from_arrays(mesh.surface_get_primitive_type(flame), arrays)
	_flame_mat = ShaderMaterial.new()
	_flame_mat.shader = FLAME_SHADER
	_flame_mat.set_shader_parameter(&"height", flame_box.size.y)
	flame_mesh.surface_set_material(0, _flame_mat)
	_flame = MeshInstance3D.new()
	_flame.mesh = flame_mesh
	_flame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	source.add_child(_flame)
	_flame.position = foot
	_flame_size = Vector3.ONE
	_flame.hide()
	# The match gets a small copy of the flame (upright, whatever the match's tilt).
	_match_flame = MeshInstance3D.new()
	_match_flame.mesh = flame_mesh
	_match_head.add_child(_match_flame)
	_match_flame.rotation.z = -_match.rotation.z
	_match_flame.position = Vector3(0, -0.004, 0)
	_match_flame.hide()
	_flame_light.global_position = _wick_base + Vector3(0, 0.05, 0.03)


static func _surface_aabb(mesh: ArrayMesh, surface: int) -> AABB:
	var verts: PackedVector3Array = mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
	var box := AABB(verts[0], Vector3.ZERO)
	for v in verts:
		box = box.expand(v)
	return box


func _make_strands() -> void:
	for i in _strands.size():
		var mat := ShaderMaterial.new()
		mat.shader = STRAND_SHADER
		mat.set_shader_parameter(&"phase", TAU * i / _strands.size())
		var strand: MeshInstance3D = _strands[i]
		mat.set_shader_parameter(&"height", (strand.mesh as CylinderMesh).height)
		strand.material_override = mat
		_strand_mats.append(mat)
	_update_strands(0.0)


## Red and black wires from the terminals up into the switchboard.
func _make_wires() -> void:
	for side in [[$TerminalPlus, Color(0.85, 0.12, 0.08), -1.0], [$TerminalMinus, Color(0.08, 0.08, 0.09), 1.0]]:
		var post: Node3D = side[0]
		var mat := StandardMaterial3D.new()
		mat.albedo_color = side[1]
		mat.roughness = 0.5
		var x: float = side[2]
		var top := post.global_position + Vector3(0, 0.17, -0.012)
		var points := [top, Vector3(top.x + x * 0.03, -0.17, -0.2), Vector3(top.x + x * 0.05, -0.09, -0.28)]
		for i in points.size() - 1:
			var bar := _new_bar(0.005, mat)
			add_child(bar)
			_place_bar(bar, points[i], points[i + 1])


func _make_arc() -> void:
	var mat := ShaderMaterial.new() # Same over-bright unshaded look as the flame, so it blooms.
	mat.shader = FLAME_SHADER
	mat.set_shader_parameter(&"base_color", Color(0.85, 0.97, 1.0))
	mat.set_shader_parameter(&"tip_color", Color(0.85, 0.97, 1.0))
	mat.set_shader_parameter(&"energy", 3.0)
	for i in ARC_SEGMENTS * 2 * ARC_BOLTS:
		var bar := _new_bar(0.003 if i < ARC_SEGMENTS * 2 else 0.0016, mat)
		bar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_arc.add_child(bar)
		_arc_segments.append(bar)
	_arc.hide()


## Zigzag bolts from each terminal tip to the flame's tip, re-jittered every few frames.
func _jitter_arc() -> void:
	var tip := _flame.global_position + Vector3(0, 0.014, 0) # Inside the flame: the bolts leap out of it.
	var index := 0
	for bolt in ARC_BOLTS:
		for from in [_terminal_plus.global_position, _terminal_minus.global_position]:
			var previous: Vector3 = from
			for s in ARC_SEGMENTS:
				var w := float(s + 1) / ARC_SEGMENTS
				var next: Vector3 = from.lerp(tip, w)
				if s < ARC_SEGMENTS - 1:
					next += Vector3(0, randf_range(-1.0, 1.0), randf_range(-0.5, 0.5)) * 0.016
				_place_bar(_arc_segments[index], previous, next)
				previous = next
				index += 1


static func _new_bar(radius: float, mat: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = 1.0
	mesh.radial_segments = 6
	mesh.rings = 1
	mesh.material = mat
	var bar := MeshInstance3D.new()
	bar.mesh = mesh
	return bar


## Stretches a unit-height bar from `a` to `b` (global).
static func _place_bar(bar: Node3D, a: Vector3, b: Vector3) -> void:
	var y := b - a
	var length := y.length()
	if length < 0.0001:
		return
	y /= length
	var x := y.cross(Vector3.BACK if absf(y.z) < 0.9 else Vector3.RIGHT).normalized()
	var z := x.cross(y)
	bar.global_transform = Transform3D(Basis(x, y * length, z), (a + b) / 2.0)


# --- Camera / HUD --------------------------------------------------------------------------------

func _set_shot(shot: Array[Vector3]) -> void:
	_camera.look_at_from_position(shot[0], shot[1])


func _move_camera(shot: Array[Vector3], seconds: float) -> void:
	var from_eye := _camera.global_position
	var from_target := from_eye - _camera.global_basis.z * from_eye.distance_to(shot[1])
	if _camera_tween:
		_camera_tween.kill()
	_camera_tween = create_tween()
	_camera_tween.tween_method(func(w: float) -> void:
		_camera.look_at_from_position(from_eye.lerp(shot[0], w), from_target.lerp(shot[1], w)), 0.0, 1.0, seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## The keycap floats above the match, bobbing.
func _place_keycap() -> void:
	var at := _camera.unproject_position(_match_head.global_position + Vector3(0, 0.05, 0))
	_keycap.position = at - _keycap.size / 2.0 + Vector2(0, -50.0 + 6.0 * sin(_time * 4.0))
