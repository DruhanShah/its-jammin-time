class_name PasswordScreamConfig
extends MinigameConfig

## Peak loudness (dB) that counts as a scream. Tune per mic.
@export var threshold_db := -20.0
## Seconds it has to stay that loud.
@export var scream_time := 0.4
## Screams needed before the text box shows up.
@export var screams_needed := 5
