class_name Interactable
extends Area3D
## Add as a child of any prop, give it a CollisionShape3D covering the prop, set the prompt.
## The player's interaction ray finds it and calls interact() when X is pressed.

signal interacted

const LAYER := 2 ## Physics layer "interactable"; the player's ray looks for it.

@export var prompt := "Press X to interact"
## Scene to switch to on interact (e.g. a minigame). Leave empty to only emit `interacted`.
@export_file("*.tscn") var target_scene := ""
@export var sound: AudioStream = preload("res://assets/audio/sfx/interact.wav")


func _ready() -> void:
	collision_layer = LAYER
	collision_mask = 0
	monitoring = false


func interact() -> void:
	if sound:
		Audio.play_sfx(sound)
	interacted.emit()
	if target_scene:
		get_tree().change_scene_to_file(target_scene)
