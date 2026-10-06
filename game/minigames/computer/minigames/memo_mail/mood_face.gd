@tool
class_name MoodFace
extends Control
## The boss's avatar in memo_mail, drawn (no emoji glyphs in the Comic fonts): a round head over a
## suit and a red tie; `mood` (-1..1) bends the mouth from frown to grin, turns him red with angry
## brows below -0.35 and gives him star eyes above 0.6. `draw_face()` is shared with FaceCrowd.

const SKIN := Color("#ffd9a8")
const ANGRY_SKIN := Color("#ff6b5b")
const INK := Color("#141414")
const STAR := Color("#ffd23f")
const MOUTH := Color("#8c1c1c")
const SUIT := Color("#3d4a66")
const TIE := Color("#e23b3b")
const ANGRY_BELOW := -0.35
const STARRY_ABOVE := 0.6

@export_range(-1.0, 1.0) var mood := 0.0:
	set(value):
		mood = value
		queue_redraw()
## Draw the suit and tie (the boss); off = just the head.
@export var suit := true

var _bounce: Tween


## Draws one face on `canvas` centred on `center`. `skin` is the calm skin colour.
static func draw_face(canvas: CanvasItem, center: Vector2, radius: float, face_mood: float, outline: float, skin := SKIN) -> void:
	var angry := clampf((ANGRY_BELOW - face_mood) / (1.0 + ANGRY_BELOW) * 1.6 + 0.35, 0.0, 1.0) if face_mood < ANGRY_BELOW else 0.0
	canvas.draw_circle(center, radius, skin.lerp(ANGRY_SKIN, angry))
	canvas.draw_arc(center, radius, 0.0, TAU, 48, INK, outline, true)
	var eye_dx := radius * 0.36
	var eye_y := center.y - radius * 0.12
	for side: float in [-1.0, 1.0]:
		var eye := Vector2(center.x + side * eye_dx, eye_y)
		if face_mood > STARRY_ABOVE:
			var points := _star_points(eye, radius * 0.24, radius * 0.1)
			canvas.draw_colored_polygon(points, STAR)
			points.append(points[0])
			canvas.draw_polyline(points, INK, maxf(outline * 0.5, 1.0), true)
		else:
			canvas.draw_circle(eye, maxf(radius * 0.09, 1.5), INK)
		if face_mood < ANGRY_BELOW: # Brows slanting down to the nose.
			var outer := eye + Vector2(side * radius * 0.2, -radius * 0.24)
			var inner := eye + Vector2(-side * radius * 0.16, -radius * 0.1)
			canvas.draw_line(outer, inner, INK, maxf(outline * 0.9, 1.5), true)
	# Mouth: a parabola whose middle drops with the mood (grin) or rises (frown).
	var half := radius * 0.42
	var mouth_y := center.y + radius * 0.4
	var bend := face_mood * radius * 0.3
	var mouth := PackedVector2Array()
	for i in 13:
		var t := lerpf(-1.0, 1.0, i / 12.0)
		mouth.append(Vector2(center.x + t * half, mouth_y - bend * 0.5 + bend * (1.0 - t * t)))
	if face_mood > STARRY_ABOVE: # Open grin.
		canvas.draw_colored_polygon(mouth, MOUTH)
		mouth.append(mouth[0])
	canvas.draw_polyline(mouth, INK, maxf(outline * 0.8, 1.5), true)


static func _star_points(center: Vector2, outer: float, inner: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 10:
		var angle := -PI / 2.0 + TAU * i / 10.0
		points.append(center + Vector2(cos(angle), sin(angle)) * (outer if i % 2 == 0 else inner))
	return points


## A quick scale pop (the boss reacting).
func bounce() -> void:
	if _bounce:
		_bounce.kill()
	pivot_offset = size / 2.0
	scale = Vector2.ONE * 1.25
	_bounce = create_tween()
	_bounce.tween_property(self, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _draw() -> void:
	var radius := minf(size.x, size.y) * (0.33 if suit else 0.45)
	var center := Vector2(size.x / 2.0, radius + 6.0 if suit else size.y / 2.0)
	if suit:
		var top := center.y + radius * 0.8
		var shoulders := Rect2(size.x / 2.0 - radius * 1.35, top, radius * 2.7, size.y - top)
		var body := StyleBoxFlat.new()
		body.bg_color = SUIT
		body.border_color = INK
		body.set_border_width_all(4)
		body.corner_radius_top_left = int(radius)
		body.corner_radius_top_right = int(radius)
		body.anti_aliasing = true
		draw_style_box(body, shoulders)
		var collar := PackedVector2Array([Vector2(size.x / 2.0 - radius * 0.45, top + 2.0),
				Vector2(size.x / 2.0 + radius * 0.45, top + 2.0), Vector2(size.x / 2.0, top + radius * 0.55)])
		draw_colored_polygon(collar, Color.WHITE)
		var tie := PackedVector2Array([Vector2(size.x / 2.0 - radius * 0.13, top + radius * 0.12),
				Vector2(size.x / 2.0 + radius * 0.13, top + radius * 0.12), Vector2(size.x / 2.0 + radius * 0.2, size.y - 8.0),
				Vector2(size.x / 2.0, size.y - 2.0), Vector2(size.x / 2.0 - radius * 0.2, size.y - 8.0)])
		draw_colored_polygon(tie, TIE)
		tie.append(tie[0])
		draw_polyline(tie, INK, 3.0, true)
	draw_face(self, center, radius, mood, 5.0)
	if suit: # A three-hair comb-over.
		for i in 3:
			var x := center.x + (i - 1) * radius * 0.28
			draw_arc(Vector2(x + radius * 0.25, center.y - radius * 0.95), radius * 0.3, PI * 1.05, PI * 1.6, 8, INK, 3.0, true)
	if mood > STARRY_ABOVE: # Sparkles.
		for spot: Vector2 in [Vector2(-1.25, -0.7), Vector2(1.3, -0.4), Vector2(1.1, 0.9)]:
			var p := center + spot * radius
			draw_colored_polygon(_star_points(p, radius * 0.16, radius * 0.05), STAR)
