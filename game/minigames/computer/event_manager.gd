extends Node
## Decides WHEN minigames start. Placeholder until the real event system is specified:
## for now it starts every id in start_on_open as soon as the computer opens.
## Only talk to the host through computer.start_minigame() and its signals, so this file can be
## swapped out (timers, typing thresholds, narrator beats, a global autoload...) without touching
## the minigames.

## Minigame ids (see minigame_registry.tres) started as soon as the computer opens, in order.
#@export var start_on_open: Array[StringName] = [&"corporate_speak", &"ad_popup"]
@export var start_on_open: Array[StringName] = [&"corporate_speak"]
@onready var computer := get_parent() as Computer


func _ready() -> void:
	for id in start_on_open:
		computer.start_minigame.call_deferred(id)
