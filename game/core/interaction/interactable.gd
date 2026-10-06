class_name Interactable
extends Area3D
## Add as a child of any prop, give it a CollisionShape3D covering the prop, set the verb.
## The player's interaction ray finds it and calls interact() when the `interact` action is pressed.
## While locked (see `unlock_id`) it still shows its prompt, but interacting does nothing.

signal interacted

const LAYER := 2 ## Physics layer "interactable"; the player's ray looks for it.
const HIGHLIGHT: Material = preload("res://core/interaction/highlight.tres")

## Local on/off switch: when false the player ignores it (no prompt, no crosshair change).
## Resets when the scene reloads; for story progress use `unlock_id` instead.
@export var enabled := true
## Locked until `GameState.unlock(unlock_id)` was called (from any scene). Empty = never locked.
## Pick from the ids in `core/unlocks.gd` (add new ones there).
@export_custom(PROPERTY_HINT_ENUM_SUGGESTION, Unlocks.ALL) var unlock_id: StringName
## Prompt reads "Press <interact key> to <verb>".
@export var verb := "interact"
## Scene to switch to on interact (e.g. a minigame). Leave empty to only emit `interacted`.
@export_file("*.tscn") var target_scene := ""
@export var sound: AudioStream = preload("res://assets/audio/sfx/400_sounds_pack/toggle_on.wav")
@export var sound_volume_db := -4.0
## Meshes under this node get the highlight while the player aims at it. Default: the whole prop (our parent).
@export var highlight_root: NodePath = ^".."

var _highlighted := false


func _ready() -> void:
	collision_layer = LAYER
	collision_mask = 0
	monitoring = false
	if unlock_id and not Unlocks.has(unlock_id):
		push_warning("%s: unlock_id '%s' is not in core/unlocks.gd" % [get_path(), unlock_id])


func is_usable() -> bool:
	return enabled and not is_locked()


func is_locked() -> bool:
	return not unlock_id.is_empty() and not GameState.is_unlocked(unlock_id)


func interact() -> void:
	if is_locked():
		return
	if sound:
		Audio.play_sfx(sound, sound_volume_db)
	interacted.emit()
	if target_scene:
		Transition.change_scene(target_scene)


## Shows or hides the highlight overlay on the prop's meshes (doesn't touch their own materials).
func set_highlighted(on: bool) -> void:
	if on == _highlighted:
		return
	_highlighted = on
	var root := get_node_or_null(highlight_root)
	if not root:
		return
	for mesh: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		if on and mesh.material_overlay == null:
			mesh.material_overlay = HIGHLIGHT
		elif not on and mesh.material_overlay == HIGHLIGHT:
			mesh.material_overlay = null
