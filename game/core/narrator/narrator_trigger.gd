extends Area3D
## Plays a narrator cue when the player walks in. Resize via the CollisionShape3D (make its shape unique first).

@export var cue_id: StringName


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group(&"player"):
		Narrator.play(cue_id)
