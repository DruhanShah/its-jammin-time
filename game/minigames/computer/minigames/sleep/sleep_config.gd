class_name SleepConfig
extends MinigameConfig

## Money lost per second while asleep.
@export var drain_per_second := 25
## How dark the screen gets (0 = clear, 1 = black).
@export_range(0.0, 1.0) var dim_alpha := 0.85
## Seconds the screen takes to dim.
@export var fade_seconds := 1.0
