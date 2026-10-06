class_name DownloadBar
extends Control
## The download screen's progress bar: a dark pill with a cream fill, checkpoint notches and the
## percentage in big outlined serif text centred on the fill. `value` 0..100 (eases toward it),
## `fill_color` (turns red-orange at the end), `flash()` = brief white pulse, `shake()`. `_draw()` only.

const TRACK := Color("#2a2a2d")
const NUMBER_FONT := preload("res://assets/fonts/Tinos-Regular-Latin.ttf")

@export var number_size := 62
@export var checkpoints: Array[float] = [25.0, 50.0, 75.0]

var value := 0.0
var fill_color := Color("#efe1bd")

var _shown := 0.0
var _flash := 0.0
var _number_font: FontVariation
var _offset := Vector2.ZERO


func _init() -> void:
	mouse_filter = MOUSE_FILTER_STOP
	_number_font = FontVariation.new()
	_number_font.base_font = NUMBER_FONT
	_number_font.variation_embolden = 0.9


func _process(delta: float) -> void:
	_shown = lerpf(_shown, value, 1.0 - exp(-delta / 0.06))
	_flash = maxf(0.0, _flash - delta * 2.5)
	queue_redraw()


func flash() -> void:
	_flash = 1.0


func shake(strength := 6.0) -> void:
	var tween := create_tween()
	for i in 5:
		tween.tween_property(self, "_offset", Vector2((1.0 if i % 2 == 0 else -1.0) * strength * (1.0 - i / 5.0), 0), 0.04)
	tween.tween_property(self, "_offset", Vector2.ZERO, 0.04)


func _draw() -> void:
	draw_set_transform(_offset)
	var h := size.y
	var rect := Rect2(Vector2.ZERO, size)
	var track := StyleBoxFlat.new()
	track.bg_color = TRACK
	track.border_color = Color.BLACK
	track.set_border_width_all(5)
	track.set_corner_radius_all(int(h / 2.0))
	track.anti_aliasing = true
	draw_style_box(track, rect)
	var inner := rect.grow(-9.0)
	for mark in checkpoints:
		var x := inner.position.x + inner.size.x * mark / 100.0
		draw_line(Vector2(x, inner.position.y + 4.0), Vector2(x, inner.position.y + 16.0), Color(1, 1, 1, 0.25), 3.0, true)
		draw_line(Vector2(x, inner.end.y - 16.0), Vector2(x, inner.end.y - 4.0), Color(1, 1, 1, 0.25), 3.0, true)
	var fill_width := maxf(inner.size.y, inner.size.x * clampf(_shown, 0.0, 100.0) / 100.0)
	var fill_rect := Rect2(inner.position, Vector2(fill_width, inner.size.y))
	var color := fill_color.lerp(Color.WHITE, _flash)
	if _shown > 0.3:
		var fill := StyleBoxFlat.new()
		fill.bg_color = color
		fill.set_corner_radius_all(int(inner.size.y / 2.0))
		fill.anti_aliasing = true
		draw_style_box(fill, fill_rect)
		# A darker band on the lower third for some depth.
		var band := StyleBoxFlat.new()
		band.bg_color = color.darkened(0.18)
		band.set_corner_radius_all(int(inner.size.y / 2.0))
		band.corner_radius_top_left = 0
		band.corner_radius_top_right = 0
		band.anti_aliasing = true
		var band_h := inner.size.y / 3.0
		draw_style_box(band, Rect2(fill_rect.position + Vector2(0, inner.size.y - band_h), Vector2(fill_width, band_h)))
	var text := "%d%%" % int(clampf(roundf(_shown), 0.0, 100.0))
	var text_size := _number_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, number_size)
	var cx := clampf(fill_rect.get_center().x, inner.position.x + text_size.x / 2.0 + 6.0, inner.end.x - text_size.x / 2.0 - 6.0)
	var baseline := Vector2(cx - text_size.x / 2.0,
			inner.get_center().y + (_number_font.get_ascent(number_size) - _number_font.get_descent(number_size)) / 2.0)
	draw_string_outline(_number_font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, number_size, 16, Color("#16171a"))
	draw_string(_number_font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, number_size, Color("#fff6dc"))
