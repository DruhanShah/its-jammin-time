@tool
extends Control
## A cartoon studio microphone (chrome capsule, grille, U holder, stand) drawn with thick outlines.
## `level` (0..1) lights the grille, `droop()` makes it hang its head (budget cuts).

const OUTLINE := Color.BLACK
const CHROME := Color("#d5dde6")
const CHROME_DARK := Color("#8c98a6")
const GLOW := Color("#ff5a4f")

var level := 0.0:
	set(value):
		level = value
		queue_redraw()

var _head_style := _rounded(CHROME, 36, 5)
var _base_style := _rounded(Color("#3a3f47"), 7, 4)
var _band_style := _rounded(CHROME_DARK, 6, 4)


func _init() -> void:
	custom_minimum_size = Vector2(120, 190)
	mouse_filter = MOUSE_FILTER_IGNORE


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		pivot_offset = Vector2(size.x / 2.0, size.y - 8.0)


## Sags to one side with a little bounce.
func droop() -> void:
	var tween := create_tween()
	tween.tween_property(self, "rotation_degrees", -28.0, 0.5).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


func _draw() -> void:
	var cx := size.x / 2.0
	# Holder (U), stem and base, behind the head.
	draw_arc(Vector2(cx, 92), 47, 0.0, PI, 24, OUTLINE, 7.0, true)
	draw_line(Vector2(cx, 139), Vector2(cx, 172), OUTLINE, 9.0)
	draw_style_box(_base_style, Rect2(cx - 34, 168, 68, 16))
	# Capsule head.
	var head := Rect2(cx - 36, 6, 72, 116)
	draw_style_box(_head_style, head)
	var glow := GLOW
	glow.a = clampf(level * 1.4, 0.0, 0.85)
	for y in range(26, 108, 11):
		var inset := 13.0 if y > 30 and y < 100 else 20.0
		draw_line(Vector2(head.position.x + inset, y), Vector2(head.end.x - inset, y), CHROME_DARK, 3.0)
		if glow.a > 0.0:
			draw_line(Vector2(head.position.x + inset, y), Vector2(head.end.x - inset, y), glow, 3.0)
	draw_line(Vector2(cx, 18), Vector2(cx, 110), CHROME_DARK, 2.0)
	# Shine.
	draw_line(Vector2(head.position.x + 14, 28), Vector2(head.position.x + 14, 58), Color.WHITE, 6.0)
	# Band where the head meets the holder.
	draw_style_box(_band_style, Rect2(cx - 40, 84, 80, 16))


static func _rounded(color: Color, radius: int, border: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = OUTLINE
	style.set_border_width_all(border)
	style.set_corner_radius_all(radius)
	style.anti_aliasing = true
	return style
