@tool
class_name FaceCrowd
extends Control
## The people CC'd on an email: a grid of small faces (MoodFace.draw_face). Each face sits at the
## crowd's `mood` plus its own fixed offset, so every word picked flips a few of them.

const SKINS: Array[Color] = [Color("#ffd9a8"), Color("#f1c27d"), Color("#c68642"), Color("#8d5524"), Color("#ffe0bd")]

@export_range(-1.0, 1.0) var mood := 0.0:
	set(value):
		mood = value
		queue_redraw()
@export var count := 40
@export var columns := 8


## Mood of face `i`: the crowd's mood plus a deterministic spread (-0.6..0.6).
func face_mood(i: int) -> float:
	return clampf(mood + lerpf(-0.6, 0.6, fposmod(i * 0.618, 1.0)), -1.0, 1.0)


## Faces at least happy (the grin band).
func happy_count() -> int:
	var happy := 0
	for i in count:
		if face_mood(i) >= 0.15:
			happy += 1
	return happy


func _draw() -> void:
	var rows := ceili(count / float(columns))
	var cell := Vector2(size.x / columns, size.y / rows)
	var radius := minf(cell.x, cell.y) * 0.44
	for i in count:
		var center := Vector2((i % columns + 0.5) * cell.x, (floorf(i / float(columns)) + 0.5) * cell.y)
		MoodFace.draw_face(self, center, radius, face_mood(i), 2.0, SKINS[(i * 7) % SKINS.size()])
