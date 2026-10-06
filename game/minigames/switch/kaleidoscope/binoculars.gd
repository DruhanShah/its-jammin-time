extends Node3D
## The binoculars on the server room's control desk (kaleidoscope game, see kaleidoscope.gd). They lie
## there while the kaleidoscope is the current switch game and you haven't got them yet; picking them
## up lets the TWIST ME painting open the scope view.

const PICKUP_SOUND := preload("res://assets/audio/sfx/400_sounds_pack/foley_creak_1.wav")

@onready var _interactable: Interactable = $Interactable


func _ready() -> void:
	_interactable.interacted.connect(_pick_up)
	Story.switch_game_changed.connect(_sync.unbind(1))
	_sync()


func _sync() -> void:
	var here := Story.switch_game() == Kaleidoscope.ID and not GameState.has_scope
	visible = here
	_interactable.enabled = here


func _pick_up() -> void:
	GameState.has_scope = true
	_interactable.enabled = false
	Audio.play_sfx(PICKUP_SOUND, -6.0)
	Narrator.play(&"scope_pickup")
	var tween := create_tween()
	tween.tween_property(self, "position:y", position.y + 0.25, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "scale", Vector3.ONE * 0.01, 0.25).set_ease(Tween.EASE_IN)
	tween.tween_callback(hide)
