extends Node3D
## The TWIST ME painting beside the power switch (kaleidoscope game, see kaleidoscope.gd). It hangs there
## from the start as foreshadowing; it's only usable while the kaleidoscope is the current switch game.
## Its canvas is the password picture shuffled into kaleidoscope wedges. Without the binoculars you
## get mocked; with them, the scope view opens on it.

const SCOPE_VIEW := preload("res://minigames/switch/kaleidoscope/scope_view.tscn")
const SHADER := preload("res://minigames/switch/kaleidoscope/painting_kaleido.gdshader")
## Where Painting.fbx's canvas sits in its UVs (x, y, width, height), measured from the mesh.
const CANVAS_UV := Vector4(0.00983, 0.009057, 0.984705, 0.476886)

var _source: PaintingSource

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
	_interactable.enabled = Story.switch_game() == Kaleidoscope.ID
	set_process(_interactable.enabled)


func _process(_delta: float) -> void:
	_interactable.verb = "look through the binoculars" if GameState.has_scope else "twist the painting"


func _on_interacted() -> void:
	if not GameState.has_scope:
		Narrator.play(&"twist_me_bare_hands")
		return
	var scope: ScopeView = SCOPE_VIEW.instantiate()
	get_tree().current_scene.add_child(scope)
	scope.open(_source.get_texture())
