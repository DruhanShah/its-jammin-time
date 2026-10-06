@tool
class_name ComicBackdrop
extends Control
## Full-screen comic backdrop for the menus (no computer): Ben-Day dots (core/ui/comic/halftone.gdshader)
## under a slowly turning sunburst of rays, like the splash panel of a comic book. Put it first under a
## full-rect Control; it ignores the mouse.

const HALFTONE := preload("res://core/ui/comic/halftone.gdshader")

@export var paper_color := Color("#ffd23f"):
	set(value):
		paper_color = value
		_update_dots()
@export var dot_color := Color("#ff9f1c"):
	set(value):
		dot_color = value
		_update_dots()
@export var ray_color := Color(1, 1, 1, 0.35):
	set(value):
		ray_color = value
		queue_redraw()
## Number of light rays (each followed by a gap of the same width).
@export var ray_count := 18:
	set(value):
		ray_count = maxi(value, 1)
		queue_redraw()
## Where the rays start, as a fraction of the size (0.5, 0.5 = the centre).
@export var ray_origin := Vector2(0.5, 0.45):
	set(value):
		ray_origin = value
		queue_redraw()
## Degrees per second the sunburst turns (0 = still).
@export var spin_speed := 3.0
@export var dot_cell_size := 14.0:
	set(value):
		dot_cell_size = value
		_update_dots()

var _angle := 0.0
var _dots: ColorRect


func _init() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_dots = ColorRect.new()
	_dots.mouse_filter = MOUSE_FILTER_IGNORE
	_dots.show_behind_parent = true # Under this node's own drawing (the rays).
	_dots.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_dots.material = ShaderMaterial.new()
	(_dots.material as ShaderMaterial).shader = HALFTONE
	add_child(_dots, false, INTERNAL_MODE_FRONT)
	_update_dots()


func _process(delta: float) -> void:
	if spin_speed != 0.0 and not Engine.is_editor_hint():
		_angle = fmod(_angle + deg_to_rad(spin_speed) * delta, TAU)
		queue_redraw()


func _draw() -> void:
	var origin := size * ray_origin
	var reach := size.length() * 1.2
	var half := PI / (ray_count * 2.0)
	for i in ray_count:
		var a := _angle + TAU * i / ray_count
		draw_colored_polygon([origin, origin + Vector2.from_angle(a - half) * reach, origin + Vector2.from_angle(a + half) * reach], ray_color)


func _update_dots() -> void:
	if not _dots:
		return
	var mat := _dots.material as ShaderMaterial
	mat.set_shader_parameter(&"paper_color", paper_color)
	mat.set_shader_parameter(&"dot_color", dot_color)
	mat.set_shader_parameter(&"cell_size", dot_cell_size)
	mat.set_shader_parameter(&"radial", 1.0)
	mat.set_shader_parameter(&"min_size", 0.1)
	mat.set_shader_parameter(&"max_size", 0.85)
