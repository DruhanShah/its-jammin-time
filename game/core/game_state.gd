extends Node
## Autoload "GameState": small bits of state that must survive scene changes.

## Where the player stood in each level (by scene path), so returning from a minigame puts them back.
## Each value is [body transform, head pitch].
var player_poses: Dictionary[String, Array] = {}

## Scene to return to when leaving the computer. Set it before switching to the computer scene;
## empty falls back to the office.
var computer_return_scene := ""
## How many pop-up ads the player has closed. Later ads get nastier.
var ads_closed := 0
## Total score from computer minigames. Change it through Computer.add_score() so the screen updates.
var score := 0
