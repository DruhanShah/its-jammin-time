extends Node
## The office's lighting state. Follows `GameState.power_on`: when the power goes out, every
## light in the "office_lights" group (the CeilingLight scene) cuts to black at once, then after
## `dark_time` the emergency fixtures (every `every`-th light per room) fade in with the chosen
## `look`, and the WorldEnvironment (ambient, fog, glow) follows. Power back on = short dark, then
## the normal lights snap back on, like fluorescent tubes.
##
## Story code: `GameState.set_power(false)` / `GameState.set_power(true)`.
## Debug builds: F5 toggles the power, F6 cycles the emergency looks.

## Emergency looks. `energy` scales each light's normal energy; `every` = 2 keeps a checkerboard
## of fixtures per room (the rest go dark); `accent` (optional) colours every `accent_every`-th fixture;
## `env` sets Environment properties (energies dip to 30 % during the blackout and fade up).
const LOOKS := {
	"neon": {
		"color": Color(0.1, 0.8, 0.95), "accent": Color(0.95, 0.3, 0.85), "accent_every": 3,
		"energy": 0.7, "every": 2, "panel_energy": 4.0, "exit_signs": false,
		"env": {
			"ambient_light_color": Color(0.3, 0.35, 0.55), "ambient_light_energy": 0.12,
			"fog_light_color": Color(0.1, 0.3, 0.4), "fog_light_energy": 0.2,
			"glow_intensity": 1.0, "glow_bloom": 0.1,
		},
	},
	"red": {
		"color": Color(1.0, 0.15, 0.1),
		"energy": 0.6, "every": 2, "panel_energy": 3.5, "exit_signs": false,
		"env": {
			"ambient_light_color": Color(0.45, 0.3, 0.32), "ambient_light_energy": 0.12,
			"fog_light_color": Color(0.3, 0.05, 0.05), "fog_light_energy": 0.15,
			"glow_intensity": 0.9, "glow_bloom": 0.1,
		},
	},
	"mix": {
		"color": Color(1.0, 0.3, 0.12),
		"energy": 0.7, "every": 2, "panel_energy": 3.0, "exit_signs": true,
		"env": {
			"ambient_light_color": Color(0.55, 0.35, 0.35), "ambient_light_energy": 0.14,
			"fog_light_color": Color(0.4, 0.15, 0.08), "fog_light_energy": 0.25,
			"glow_intensity": 0.9, "glow_bloom": 0.08,
		},
	},
}
const EXIT_FONT := preload("res://assets/fonts/ComicRelief-Bold.ttf")

@export_enum("neon", "red", "mix") var look := "mix":
	set(value):
		look = value
		if is_node_ready() and not GameState.power_on:
			if _tween:
				_tween.kill()
			_build_panels()
			_set_emergency(1.0)
## Seconds of total darkness before the emergency lights kick in (or the power comes back).
@export var dark_time := 0.7
@export var fade_time := 0.6

var _env: Environment
var _normal_env := {}
## Per light: [root, SpotLight3D, Panel, colour, energy, panel material].
var _lights: Array[Array] = []
var _off_mat: StandardMaterial3D
var _panel_mats: Array[StandardMaterial3D] = []
var _exit_signs: Array[Label3D] = []
var _tween: Tween


func _ready() -> void:
	# Own copy: the scene's Environment is shared with the cached PackedScene, so edits would
	# otherwise leak into the next load of the office (and become its "normal").
	_env = $"../WorldEnvironment".environment.duplicate()
	$"../WorldEnvironment".environment = _env
	for key in LOOKS[look].env:
		_normal_env[key] = _env.get(key)
	for light: Node3D in get_tree().get_nodes_in_group(&"office_lights"):
		var spot: SpotLight3D = light.get_node("SpotLight3D")
		var panel: MeshInstance3D = light.get_node("Panel")
		_lights.append([light, spot, panel, spot.light_color, spot.light_energy, panel.material_override])
	_off_mat = StandardMaterial3D.new()
	_off_mat.albedo_color = Color(0.25, 0.27, 0.3)
	_add_exit_signs()
	GameState.power_changed.connect(_on_power_changed)
	if not GameState.power_on:
		_build_panels()
		_set_emergency(1.0)


func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	if event.is_action_pressed("debug_toggle_power"):
		GameState.set_power(not GameState.power_on)
	elif event.is_action_pressed("debug_next_light_look"):
		var names: Array = LOOKS.keys()
		look = names[(names.find(look) + 1) % names.size()]
		print("Emergency look: ", look)


func _on_power_changed(on: bool) -> void:
	if _tween:
		_tween.kill()
	_build_panels()
	_set_emergency(0.0) # Instant blackout either way.
	_tween = create_tween()
	_tween.tween_interval(dark_time if not on else dark_time * 0.5)
	if on:
		_tween.tween_callback(_set_normal)
	else:
		_tween.tween_method(_set_emergency, 0.0, 1.0, fade_time).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)


func _set_normal() -> void:
	for l in _lights:
		l[1].visible = true
		l[1].light_color = l[3]
		l[1].light_energy = l[4]
		l[2].material_override = l[5]
		if "powered" in l[0]:
			l[0].powered = true # Flicker lights restart from their own saved energy.
	for key in _normal_env:
		_env.set(key, _normal_env[key])
	for s in _exit_signs:
		s.visible = false


## `level` 0 = blackout, 1 = emergency lights fully on.
func _set_emergency(level: float) -> void:
	var data: Dictionary = LOOKS[look]
	var every: int = data.every
	for l in _lights:
		if "powered" in l[0] and l[0].powered:
			l[0].powered = false # Stop the flicker so it doesn't fight us.
		var index: int = l[0].get_index()
		var fixture := level > 0.0 and index % every == 0
		var accent: bool = data.has("accent") and (index / every) % data.accent_every == 1
		l[1].visible = fixture
		l[1].light_color = data.accent if accent else data.color
		l[1].light_energy = l[4] * data.energy * level
		l[2].material_override = (_panel_mats[1] if accent else _panel_mats[0]) if fixture else _off_mat
	for mat in _panel_mats:
		mat.emission_energy_multiplier = data.panel_energy * level
	for key in data.env:
		var value = data.env[key]
		_env.set(key, value * lerpf(0.3, 1.0, level) if key.ends_with("_energy") else value)
	for s in _exit_signs:
		s.visible = data.exit_signs


## Emissive panel materials for the current look: [main, accent].
func _build_panels() -> void:
	var data: Dictionary = LOOKS[look]
	_panel_mats.clear()
	for color: Color in [data.color, data.get("accent", data.color)]:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mat.emission_enabled = true
		mat.emission = color
		_panel_mats.append(mat)


## Green "EXIT" signs above both sides of every doorway (Doors/*), shown by looks with `exit_signs`.
func _add_exit_signs() -> void:
	for door: Node3D in $"../Doors".get_children():
		for side in [1.0, -1.0]:
			var label := Label3D.new()
			label.text = "EXIT"
			label.font = EXIT_FONT
			label.font_size = 64
			label.outline_size = 0
			label.modulate = Color(0.3, 3.0, 0.6)
			label.position = Vector3(0, 2.95, 0.12 * side)
			label.rotation.y = 0.0 if side > 0.0 else PI
			label.visible = false
			door.add_child(label)
			_exit_signs.append(label)
