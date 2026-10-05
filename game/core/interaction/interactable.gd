class_name Interactable
extends Area3D
## Add as a child of any prop, give it a CollisionShape3D covering the prop, set the verb.
## The player's interaction ray finds it and calls interact() when the `interact` action is pressed.

signal interacted

const LAYER := 2 ## Physics layer "interactable"; the player's ray looks for it.

## Local on/off switch: when false the player ignores it (no prompt, no crosshair change).
## Resets when the scene reloads; for story progress use `unlock_id` instead.
@export var enabled := true
## Usable only once `GameState.unlock(unlock_id)` was called (from any scene). Empty = always usable.
@export var unlock_id: StringName
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


func is_usable() -> bool:
	return enabled and (unlock_id.is_empty() or GameState.is_unlocked(unlock_id))


func interact() -> void:
	if sound:
		Audio.play_sfx(sound, sound_volume_db)
	interacted.emit()
	if target_scene:
		Transition.change_scene(target_scene)
