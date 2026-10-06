extends Node
## The office's lighting state. Follows `GameState.power_on`: when the power goes out, every
## light in the "office_lights" group (the CeilingLight scene) cuts to black at once, then after
## `dark_time` the emergency fixtures (every `every`-th light per room) fade in with the chosen
## `look`, and the WorldEnvironment (ambient, fog, glow) follows. Power back on = short dark, then
## the normal lights snap back on, like fluorescent tubes.
##
## Story code: `GameState.set_power(false)` / `GameState.set_power(true)`.
## Overrides (`OVERRIDES`, e.g. the gargoyle quiz's game-show look) sit on top of either state:
## `set_override("quiz")` slams one on instantly, `clear_override()` fades back to the power state.
## Find this node with `get_tree().get_first_node_in_group(&"office_lighting")`.
## Debug builds: F5 toggles the power, F6 cycles the emergency looks.

## Emergency looks. `energy` scales each light's normal energy; `every` = 2 keeps a checkerboard
## of fixtures per room (the rest go dark); `accent` (optional) colours every `accent_every`-th fixture;
## `env` sets Environment properties (energies dip to 30 % during the blackout and fade up).
const LOOKS := {
	"neon": {
		"color": Color(0.1, 0.8, 0.95), "accent": Color(0.95, 0.3, 0.85), "accent_every": 3,
		"energy": 0.7, "every": 2, "panel_energy": 4.0,
		"env": {
			"ambient_light_color": Color(0.3, 0.35, 0.55), "ambient_light_energy": 0.12,
			"fog_light_color": Color(0.1, 0.3, 0.4), "fog_light_energy": 0.2,
			"glow_intensity": 1.0, "glow_bloom": 0.1,
		},
	},
	"red": {
		"color": Color(1.0, 0.15, 0.1),
		"energy": 0.6, "every": 2, "panel_energy": 3.5,
		"env": {
			"ambient_light_color": Color(0.45, 0.3, 0.32), "ambient_light_energy": 0.12,
			"fog_light_color": Color(0.3, 0.05, 0.05), "fog_light_energy": 0.15,
			"glow_intensity": 0.9, "glow_bloom": 0.1,
		},
	},
	"mix": {
		"color": Color(1.0, 0.3, 0.12),
		"energy": 0.7, "every": 2, "panel_energy": 3.0,
		"env": {
			"ambient_light_color": Color(0.55, 0.35, 0.35), "ambient_light_energy": 0.14,
			"fog_light_color": Color(0.4, 0.15, 0.08), "fog_light_energy": 0.25,
			"glow_intensity": 0.9, "glow_bloom": 0.08,
		},
	},
}

## Temporary looks on top of the power state, same keys as `LOOKS` (see `set_override`).
const OVERRIDES := {
	"quiz": {
		"color": Color(0.25, 0.3, 1.0), "energy": 0.15, "every": 4, "panel_energy": 1.0,
		"env": {
			"ambient_light_color": Color(0.35, 0.15, 0.55), "ambient_light_energy": 0.08,
			"fog_light_color": Color(0.25, 0.05, 0.4), "fog_light_energy": 0.35,
			"glow_intensity": 1.4, "glow_bloom": 0.2,
		},
	},
}

@export_enum("neon", "red", "mix") var look := "mix":
	set(value):
		look = value
		if is_node_ready() and not GameState.power_on and _override.is_empty():
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
var _tween: Tween
var _override := "" ## Name of the active override, or empty.
## Environment values an override changed that neither the normal state nor the look sets: key -> old value.
var _override_env := {}


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


## Slams look `name` from `OVERRIDES` on at once (no fade), over whatever the power state is.
func set_override(name: String) -> void:
	if _tween:
		_tween.kill()
	_override = name
	var data: Dictionary = OVERRIDES[name]
	for key in data.env:
		if not _normal_env.has(key) and not _override_env.has(key):
			_override_env[key] = _env.get(key)
	_build_panels(data)
	_apply(data, 1.0)


## Dims or restores the active override (0 = dark, 1 = full), e.g. for a quick flicker.
func set_override_level(level: float) -> void:
	if _override:
		_apply(OVERRIDES[_override], level)


## Removes the override: back to the emergency look (fading in over `fade`) or the normal lights.
func clear_override(fade := 0.4) -> void:
	if _override.is_empty():
		return
	_override = ""
	if _tween:
		_tween.kill()
	for key in _override_env:
		_env.set(key, _override_env[key])
	_override_env.clear()
	if GameState.power_on:
		_set_normal()
		return
	_build_panels()
	if fade <= 0.0:
		_set_emergency(1.0)
		return
	_tween = create_tween()
	_tween.tween_method(_set_emergency, 0.3, 1.0, fade).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)


func _on_power_changed(on: bool) -> void:
	clear_override(0.0)
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


## `level` 0 = blackout, 1 = emergency lights fully on.
func _set_emergency(level: float) -> void:
	_apply(LOOKS[look], level)


## Applies a look (an entry of `LOOKS` or `OVERRIDES`) at `level` (0 = blackout, 1 = fully on).
func _apply(data: Dictionary, level: float) -> void:
	var every: int = data.every
	for l in _lights:
		if "powered" in l[0] and l[0].powered:
			l[0].powered = false # Stop the flicker so it doesn't fight us.
		var index: int = l[0].get_index()
		var fixture := level > 0.0 and index % every == 0
		@warning_ignore("integer_division") # Which group of `every` lights this one is in.
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


## Emissive panel materials for a look (default: the current emergency look): [main, accent].
func _build_panels(data: Dictionary = {}) -> void:
	if data.is_empty():
		data = LOOKS[look]
	_panel_mats.clear()
	for color: Color in [data.color, data.get("accent", data.color)]:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mat.emission_enabled = true
		mat.emission = color
		_panel_mats.append(mat)
