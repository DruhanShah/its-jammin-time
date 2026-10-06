extends Node3D
## A banana on a plinth, slowly spinning and bobbing under its own spotlight (team TODO gag).
## Its light is not in the "office_lights" group, so it stays on through power cuts.

## Turns per second around the vertical axis (negative spins the other way).
@export var spin_speed := 0.25
## Bob height in metres (0 = no bob) and bob cycles per second.
@export var bob_height := 0.04
@export var bob_speed := 0.4
## Narrator line the first time the player comes within `notice_distance` m inside its room (only into
## silence).
@export var notice_cue := &"banana_seen"
@export var notice_distance := 6.0

@onready var _pivot: Node3D = $Pivot
var _t := 0.0
var _base_y := 0.0


func _ready() -> void:
	_base_y = _pivot.position.y


func _process(delta: float) -> void:
	_t += delta
	_pivot.rotate_y(TAU * spin_speed * delta)
	_pivot.position.y = _base_y + sin(_t * TAU * bob_speed) * bob_height
	if notice_cue and fmod(_t, 0.5) < delta and not Narrator.is_speaking():
		var player := get_tree().get_first_node_in_group(&"player") as Node3D
		if player and player.global_position.distance_to(global_position) <= notice_distance \
				and _in_my_room(player.global_position) and not player.get(&"frozen"):
			Narrator.play(notice_cue)
			notice_cue = &"" # The cue is `once` too.


## True if `pos` is inside the room this banana stands in (Rooms/<room>/Furniture/SpinningBanana), so it
## isn't noticed through a wall.
func _in_my_room(pos: Vector3) -> bool:
	var room := get_parent().get_parent() as Node3D
	if not room:
		return true
	var offset := pos - room.global_position
	return absf(offset.x) <= 6.0 and absf(offset.z) <= 8.0
