class_name VisionBlur
extends CanvasLayer
## The ending's short-sighted vision: a full-screen blur of the 3D view (vision_blur.gdshader reads the
## screen texture, so it works in the Compatibility renderer and on the web) that drifts in and out of
## focus at an irregular, slow rhythm: eased fades, never faster than about one change a second, no
## flashes. `strength` scales how strong and how frequent the blurry spells are (0 = always sharp).
## `put_on()` plays the spectacles sliding down over the eyes: sharp inside the lenses, blurry outside.
## Layer 0: above the 3D view, below the HUD (layer 1) and the subtitles, so prompts stay readable.
## StoryStage adds it to the office in the ENDING step.

const SHADER := preload("res://world/office/vision_blur.gdshader")

## 0 = always sharp, 1 = blurry spells as long and strong as they get. Changes take effect gradually.
@export_range(0.0, 1.0) var strength := 1.0

var _rect: ColorRect
var _material: ShaderMaterial
var _blur := 0.0 ## Blur shown now (0..1).
var _goal := 0.0 ## Blur the current spell drifts toward (before `strength`).
var _speed := 1.0 ## Blur units per second toward `_goal`.
var _time_left := 0.0 ## Seconds until the next spell.
var _blurry := false
var _glasses := 0.0
var _flickering := true


func _init() -> void:
	layer = 0


func _ready() -> void:
	_rect = ColorRect.new()
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	_rect.material = _material
	add_child(_rect)
	_time_left = randf_range(0.3, 1.0) # The first spell comes quickly, so the problem reads at once.
	_apply()


func _process(delta: float) -> void:
	if not _flickering:
		return
	_time_left -= delta
	if _time_left <= 0.0:
		_next_spell()
	_blur = move_toward(_blur, _goal * strength, _speed * delta)
	_apply()


## Stops the flicker and plays the spectacles going on (about 1.2 s). Await the returned signal.
func put_on() -> Signal:
	_flickering = false
	var tween := create_tween()
	tween.tween_method(_set_blur, _blur, 1.0, 0.35).set_ease(Tween.EASE_OUT)
	tween.tween_method(_set_glasses, 0.0, 1.0, 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.1)
	return tween.finished


## True while the view is noticeably blurred (for tests and story checks).
func is_blurry() -> bool:
	return _blur > 0.3


## Alternates sharp and blurry spells. Sharp spells last longer when `strength` is low; a third of the
## time a sharp spell is only a short "almost there" before the eyes slip again.
func _next_spell() -> void:
	_blurry = not _blurry
	if _blurry:
		_goal = randf_range(0.6, 1.0)
		_speed = randf_range(1.2, 2.5) # Drifting out of focus takes 0.3–0.8 s.
		_time_left = randf_range(0.9, 2.6)
	else:
		_goal = 0.0
		_speed = randf_range(2.5, 4.0) # Snapping back into focus is quicker.
		_time_left = randf_range(1.0, 3.0) * lerpf(3.0, 1.0, strength)
		if randf() < 0.33:
			_time_left = randf_range(0.6, 0.9)


func _set_blur(value: float) -> void:
	_blur = value
	_apply()


func _set_glasses(value: float) -> void:
	_glasses = value
	_apply()


func _apply() -> void:
	_material.set_shader_parameter(&"blur", _blur)
	_material.set_shader_parameter(&"glasses", _glasses)
	_rect.visible = _blur > 0.002 or _glasses > 0.0
