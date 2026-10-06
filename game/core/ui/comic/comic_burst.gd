class_name ComicBurst
extends Control
## A comic onomatopoeia ("POOF!", "POW!", "BOING!"): a word in a jagged starburst balloon that pops
## in, holds, then puffs away and frees itself. Spawn one with `ComicBurst.spawn(parent, where, word)`.
## `ComicBurst.sticker()` makes a persistent one (a "FREE!" starburst on an ad) that stays and wobbles.

const FONT := preload("res://assets/fonts/ComicRelief-Bold.ttf")
const SPIKES := 13

var word := "POOF!"
var fill := Color("#ffe14d")
var text_color := Color("#ff3b30")
var font_size := 34
## Stays (wobbling) instead of puffing away; set by `sticker()`.
var persistent := false
var _points := PackedVector2Array()


## Adds a burst to `parent` (any Control, e.g. the screen) centred on `global_center`.
static func spawn(parent: Node, global_center: Vector2, text: String, color := Color("#ffe14d")) -> ComicBurst:
	var burst := ComicBurst.new()
	burst.word = text
	burst.fill = color
	parent.add_child(burst)
	burst.position = global_center - burst.size / 2.0 # top_level: position is in canvas space.
	return burst


## Adds a persistent burst to `parent`, centred on `local_center` in the parent's own coordinates. It is
## not top_level, so it moves (shakes, slides) with its parent; it wobbles until the parent frees it.
static func sticker(parent: Control, local_center: Vector2, text: String, color := Color("#ffe14d"), size_px := 20) -> ComicBurst:
	var burst := ComicBurst.new()
	burst.word = text
	burst.fill = color
	burst.font_size = size_px
	burst.persistent = true
	burst.top_level = false
	parent.add_child(burst)
	burst.position = local_center - burst.size / 2.0
	return burst


func _init() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	top_level = true # Containers (e.g. a CenterContainer parent) must not lay it out.


func _ready() -> void:
	var text_size := FONT.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var pad := font_size
	var radius := Vector2(text_size.x * 0.5 + pad, text_size.y * 0.5 + pad * 0.9)
	size = radius * 2.0
	pivot_offset = radius
	for i in SPIKES * 2:
		var angle := TAU * i / (SPIKES * 2) + randf_range(-0.08, 0.08)
		var reach := 1.0 if i % 2 == 0 else randf_range(0.62, 0.72)
		_points.append(radius + Vector2(cos(angle), sin(angle)) * radius * reach)
	rotation = randf_range(-0.25, 0.25)
	scale = Vector2.ONE * 0.2
	if persistent:
		_wobble()
		return
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE * 1.15, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.08)
	tween.tween_interval(0.35)
	tween.tween_property(self, "scale", Vector2.ONE * 1.3, 0.22).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.22)
	tween.tween_callback(queue_free)


## Sticker: pops in, then rocks ±6° forever.
func _wobble() -> void:
	var base := rotation
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func() -> void:
		var loop := create_tween().set_loops()
		loop.tween_property(self, "rotation", base + deg_to_rad(6.0), 0.45).set_trans(Tween.TRANS_SINE)
		loop.tween_property(self, "rotation", base - deg_to_rad(6.0), 0.45).set_trans(Tween.TRANS_SINE))


func _draw() -> void:
	draw_colored_polygon(_points, fill)
	var outline := _points.duplicate()
	outline.append(_points[0])
	draw_polyline(outline, Color.BLACK, minf(5.0, font_size * 0.18), true)
	var text_size := FONT.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var baseline := Vector2((size.x - text_size.x) / 2.0, (size.y + FONT.get_ascent(font_size) - FONT.get_descent(font_size)) / 2.0)
	draw_string_outline(FONT, baseline, word, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, maxi(4, int(font_size / 4.0)), Color.BLACK)
	draw_string(FONT, baseline, word, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, text_color)
