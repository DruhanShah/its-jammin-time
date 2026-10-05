class_name MinigameConfig
extends Resource
## Tunables shared by every minigame. Subclass it per minigame and export the knobs there.

## How many of this minigame can be on screen at once. 0 = no limit.
@export var max_concurrent := 1
