@tool
extends Node3D
## Wall clock (VNB `Clock` face + two `Clock_A` hands). Set the time it shows
## with `hour`/`minute`; `minutes_per_second` makes it run in game
## (0 = stopped, 1 = one clock minute per real second, -1 = runs backwards).

@export_range(0, 23) var hour := 6:
	set(value):
		hour = value
		_minutes = hour * 60.0 + minute
		_update_hands()
@export_range(0, 59) var minute := 59:
	set(value):
		minute = value
		_minutes = hour * 60.0 + minute
		_update_hands()
@export var minutes_per_second := 0.0

var _minutes := 6 * 60.0 + 59.0


func _ready() -> void:
	_minutes = hour * 60.0 + minute
	_update_hands()
	set_process(not Engine.is_editor_hint() and minutes_per_second != 0.0)


func _process(delta: float) -> void:
	_minutes = fposmod(_minutes + minutes_per_second * delta, 24.0 * 60.0)
	_update_hands()


func _update_hands() -> void:
	if not is_node_ready():
		return
	var m := fmod(_minutes, 60.0)
	var h := fmod(_minutes / 60.0, 12.0)
	# Hands point up (+Y) at 0; negative Z rotation turns them clockwise seen from +Z.
	$MinuteHand.rotation.z = -deg_to_rad(m * 6.0)
	$HourHand.rotation.z = -deg_to_rad(h * 30.0)
