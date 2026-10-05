extends Node
## Autoload "GameState": small bits of state that must survive scene changes.

## Emitted when an id is unlocked or locked again.
signal unlock_changed(id: StringName, unlocked: bool)

## Where the player stood in each level (by scene path), so returning from a minigame puts them back.
## Each value is [body transform, head pitch].
var player_poses: Dictionary[String, Array] = {}

## Unlocked ids, global across scenes. Ids are snake_case names of the thing, e.g. &"genie_lamp".
var unlocked: Dictionary[StringName, bool] = {}

## Scene to return to when leaving the computer. Set it before switching to the computer scene;
## empty falls back to the office.
var computer_return_scene := ""
## How many pop-up ads the player has closed. Later ads get nastier.
var ads_closed := 0
## Total score from computer minigames. Change it through Computer.add_score() so the screen updates.
var score := 0


func unlock(id: StringName) -> void:
	if not unlocked.has(id):
		unlocked[id] = true
		unlock_changed.emit(id, true)


func lock(id: StringName) -> void:
	if unlocked.erase(id):
		unlock_changed.emit(id, false)


func is_unlocked(id: StringName) -> bool:
	return unlocked.has(id)