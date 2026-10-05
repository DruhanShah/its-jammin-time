class_name Interactable
extends Area3D
## Add as a child of any prop, give it a CollisionShape3D covering the prop, set the verb.
## The player's interaction ray finds it and calls interact() when the `interact` action is pressed.

signal interacted

const LAYER := 2 ## Physics layer "interactable"; the player's ray looks for it.

## Prompt reads "Press <interact key> to <verb>".
@export var verb := "interact"
## Scene to switch to on interact (e.g. a minigame). Leave empty to only emit `interacted`.
@export_file("*.tscn") var target_scene := ""
@export var sound: AudioStream = preload("res://assets/audio/sfx/400_sounds_pack/click_double_on.wav")
@export var sound_volume_db := -4.0


func _ready() -> void:
	collision_layer = LAYER
	collision_mask = 0
	monitoring = false


func interact() -> void:
	if sound:
		Audio.play_sfx(sound, sound_volume_db)
	interacted.emit()
	if target_scene:
		get_tree().change_scene_to_file(target_scene)
