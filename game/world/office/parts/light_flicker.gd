extends Node3D
## Put on a CeilingLight instance (needs its `SpotLight3D` and `Panel` children).
## The light burns steadily, then every `min_gap`…`max_gap` seconds it stutters:
## a short burst of `min_drops`…`max_drops` partial dips (never fully dark, no
## full-strength strobing). Pauses with the game (default process mode).
##
## Story switches: `enabled = false` stops the flicker (steady light);
## `powered = false` turns the light fully off.

@export var enabled := true:
	set(value):
		enabled = value
		_reset()
@export var powered := true:
	set(value):
		powered = value
		_reset()
@export var min_gap := 2.0
@export var max_gap := 6.0
@export var min_drops := 2
@export var max_drops := 5
## Brightness during a dip, as a fraction of normal (kept partial on purpose).
@export_range(0.0, 1.0) var min_level := 0.25
@export_range(0.0, 1.0) var max_level := 0.6
## How long each dip lasts, and the steady gap between dips inside a burst.
@export var min_dip_time := 0.05
@export var max_dip_time := 0.15
@export var min_between := 0.15
@export var max_between := 0.3

var _light: SpotLight3D
var _panel_mat: StandardMaterial3D
var _energy := 1.0
var _emission := 1.0
var _timer := 0.0
var _drops_left := 0
var _dipped := false


func _ready() -> void:
	_light = $SpotLight3D
	_energy = _light.light_energy
	var panel: MeshInstance3D = $Panel
	if panel.material_override is StandardMaterial3D:
		# Own copy, so dimming this panel doesn't dim every panel sharing the material.
		_panel_mat = panel.material_override.duplicate()
		panel.material_override = _panel_mat
		_emission = _panel_mat.emission_energy_multiplier
	_reset()


func _process(delta: float) -> void:
	_timer -= delta
	if _timer > 0.0:
		return
	if _dipped:
		_dipped = false
		_set_level(1.0)
		_drops_left -= 1
		_timer = randf_range(min_between, max_between) if _drops_left > 0 else randf_range(min_gap, max_gap)
	else:
		if _drops_left <= 0:
			_drops_left = randi_range(min_drops, max_drops)
		_dipped = true
		_set_level(randf_range(min_level, max_level))
		_timer = randf_range(min_dip_time, max_dip_time)


func _reset() -> void:
	if not is_node_ready():
		return
	_dipped = false
	_drops_left = 0
	_timer = randf_range(min_gap, max_gap)
	_set_level(1.0 if powered else 0.0)
	set_process(enabled and powered)


func _set_level(level: float) -> void:
	_light.light_energy = _energy * level
	if _panel_mat:
		_panel_mat.emission_energy_multiplier = _emission * level
