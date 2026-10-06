extends Node
## Autoload "GameState": small bits of state that must survive scene changes.

## Emitted when an id is unlocked or locked again.
signal unlock_changed(id: StringName, unlocked: bool)

## Where the player stood in each level (by scene path), so returning from a minigame puts them back.
## Each value is [body transform, head pitch].
var player_poses: Dictionary[String, Array] = {}

## Seconds the player has spent pushing chairs, for the narrator's jabs (Player.CHAIR_JABS).
var chair_push_time := 0.0

## Unlocked ids, global across scenes. Ids are snake_case names of the thing, e.g. &"genie_lamp".
var unlocked: Dictionary[StringName, bool] = {}


func unlock(id: StringName) -> void:
	if not unlocked.has(id):
		unlocked[id] = true
		unlock_changed.emit(id, true)


func lock(id: StringName) -> void:
	if unlocked.erase(id):
		unlock_changed.emit(id, false)


func is_unlocked(id: StringName) -> bool:
	return unlocked.has(id)
