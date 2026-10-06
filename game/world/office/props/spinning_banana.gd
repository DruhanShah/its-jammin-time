extends Node3D
## A banana on a plinth, slowly spinning and bobbing under its own spotlight (team TODO gag).
## Its light is not in the "office_lights" group, so it stays on through power cuts.

## Turns per second around the vertical axis (negative spins the other way).
@export var spin_speed := 0.25
## Bob height in metres (0 = no bob) and bob cycles per second.
@export var bob_height := 0.04
@export var bob_speed := 0.4

@onready var _pivot: Node3D = $Pivot
var _t := 0.0
var _base_y := 0.0


func _ready() -> void:
	_base_y = _pivot.position.y


func _process(delta: float) -> void:
	_t += delta
	_pivot.rotate_y(TAU * spin_speed * delta)
	_pivot.position.y = _base_y + sin(_t * TAU * bob_speed) * bob_height
