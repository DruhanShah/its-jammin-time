extends Node3D
## The TWIST ME painting beside the power switch (kaleidoscope game, see kaleidoscope.gd). It hangs there
## from the start as foreshadowing. While the kaleidoscope is the current switch game it's the puzzle;
## before that, looking at it only gets a narrator line (`TOO_EARLY_CUE`); once beaten, it's just a painting.
## Its canvas is the password picture shuffled into kaleidoscope wedges. Without the binoculars you
## get mocked; with them, the scope view opens on it.

const SCOPE_VIEW := preload("res://minigames/switch/kaleidoscope/scope_view.tscn")
const SHADER := preload("res://minigames/switch/kaleidoscope/painting_kaleido.gdshader")
## Where Painting.fbx's canvas sits in its UVs (x, y, width, height), measured from the mesh.
const CANVAS_UV := Vector4(0.00983, 0.009057, 0.984705, 0.476886)
## Played when the painting is looked at before the kaleidoscope's turn; repeats only once the narrator
## is quiet and at least `TOO_EARLY_COOLDOWN` seconds have passed since the last one.
const TOO_EARLY_CUE := &"painting_too_early"
const TOO_EARLY_COOLDOWN := 10.0

var _source: PaintingSource
var _too_early_msec := -1

@onready var _canvas: MeshInstance3D = $Frame/Painting
@onready var _interactable: Interactable = $Interactable


func _ready() -> void:
	Kaleidoscope.ensure()
	_source = PaintingSource.new()
	add_child(_source)
	_source.setup(GameState.scope_password)
	var material := ShaderMaterial.new()
	material.shader = SHADER
	material.set_shader_parameter(&"source", _source.get_texture())
	material.set_shader_parameter(&"err", -deg_to_rad(GameState.scope_target * Kaleidoscope.STEP_DEG))
	material.set_shader_parameter(&"uv_rect", CANVAS_UV)
	_canvas.set_surface_override_material(1, material)
	_interactable.interacted.connect(_on_interacted)
	Story.switch_game_changed.connect(_sync.unbind(1))
	_sync()


func _sync() -> void:
	var current := Story.switch_game() == Kaleidoscope.ID
	_interactable.enabled = current or not _beaten()
	_interactable.verb = "look at the painting"
	set_process(current)


## True once the kaleidoscope game has been beaten (its switch step is past, or progress is beyond it).
func _beaten() -> bool:
	for step: int in Story.SWITCH_GAMES:
		var index: int = Story.SWITCH_GAMES[step].find(Kaleidoscope.ID)
		if index >= 0:
			return Story.step > step or (Story.step == step and GameState.switch_progress > index)
	return false


func _process(_delta: float) -> void:
	_interactable.verb = "look through the binoculars" if GameState.has_scope else "twist the painting"


func _on_interacted() -> void:
	if Story.switch_game() != Kaleidoscope.ID:
		_play_too_early()
		return
	if not GameState.has_scope:
		Narrator.play(&"twist_me_bare_hands")
		return
	var scope: ScopeView = SCOPE_VIEW.instantiate()
	get_tree().current_scene.add_child(scope)
	scope.open(_source.get_texture())


func _play_too_early() -> void:
	var now := Time.get_ticks_msec()
	if Narrator.is_speaking() or (_too_early_msec >= 0 and now - _too_early_msec < TOO_EARLY_COOLDOWN * 1000.0):
		return
	_too_early_msec = now
	Narrator.play(TOO_EARLY_CUE)
