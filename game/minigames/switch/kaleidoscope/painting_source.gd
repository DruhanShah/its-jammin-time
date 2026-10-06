class_name PaintingSource
extends SubViewport
## The TWIST ME painting's real picture, drawn once into a 512 px texture: paper, coloured glass
## shards (seeded from the password, so each password gets its own mandala) and the password in big
## outlined letters. Both the wall painting and the scope view sample this texture through the
## kaleidoscope shader (`kaleido.gdshaderinc`); nothing ever shows it unshuffled except the solved scope.

const SIZE := 512
const FONT := preload("res://assets/fonts/ComicRelief-Bold.ttf")
const PAPER := Color("#f4ead2")
const SHARD_COLORS: Array[Color] = [
	Color("#e8483b"), Color("#f6b93b"), Color("#3c8dde"), Color("#5bbf6a"), Color("#9b59b6"), Color("#ff7fb0"),
]
## The word must fit inside the scope's view: a disk of radius 0.707 * SIZE / 2 around the centre.
const WORD_WIDTH := 330.0
const OUTLINE := 14

var word := ""
var _canvas := Node2D.new()


func _init() -> void:
	size = Vector2i(SIZE, SIZE)
	disable_3d = true
	transparent_bg = false
	render_target_update_mode = SubViewport.UPDATE_DISABLED
	_canvas.draw.connect(_draw_canvas)
	add_child(_canvas)


## Draws `text` (and its shards) into the texture once.
func setup(text: String) -> void:
	word = text
	_canvas.queue_redraw()
	render_target_update_mode = SubViewport.UPDATE_ONCE


func _draw_canvas() -> void:
	_canvas.draw_rect(Rect2(0, 0, SIZE, SIZE), PAPER)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(word)
	var center := Vector2.ONE * SIZE / 2.0
	# Big shards fanning out from the middle, then small ones scattered around.
	for i in 22:
		var at := center + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(20.0, SIZE * 0.5)
		var reach := rng.randf_range(50.0, 140.0) if i < 12 else rng.randf_range(25.0, 60.0)
		var spin := rng.randf() * TAU
		var points := PackedVector2Array()
		for corner in 3:
			points.append(at + Vector2.from_angle(spin + corner * TAU / 3.0 + rng.randf_range(-0.5, 0.5)) * reach * rng.randf_range(0.5, 1.0))
		var color: Color = SHARD_COLORS[rng.randi() % SHARD_COLORS.size()]
		_canvas.draw_colored_polygon(points, color)
		points.append(points[0])
		_canvas.draw_polyline(points, Color(0.1, 0.08, 0.06), 4.0, true)
	if word.is_empty():
		return
	var font_size := 120
	var width := FONT.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	font_size = mini(font_size, floori(font_size * WORD_WIDTH / width))
	width = FONT.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var baseline := Vector2(center.x - width / 2.0, center.y + (FONT.get_ascent(font_size) - FONT.get_descent(font_size)) / 2.0)
	_canvas.draw_string_outline(FONT, baseline, word, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, OUTLINE * 2, Color.WHITE)
	_canvas.draw_string(FONT, baseline, word, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.08, 0.06, 0.1))
