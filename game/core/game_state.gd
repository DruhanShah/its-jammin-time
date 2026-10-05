extends Node
## Autoload "GameState": small bits of state that must survive scene changes.

## Where the player stood in each level (by scene path), so returning from a minigame puts them back.
## Each value is [body transform, head pitch].
var player_poses: Dictionary[String, Array] = {}
