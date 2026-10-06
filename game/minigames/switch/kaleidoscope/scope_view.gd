class_name ScopeView
extends CanvasLayer
## Looking at the TWIST ME painting through the "binoculars" (a kaleidoscope, see kaleidoscope.gd):
## a full-screen eyepiece over the office. The player is held still (`Player.movement_locked`: the twist
## ring shares F with ESDF movement) and the mini-map hidden. Rolling the keys around G turns the
## barrel `Kaleidoscope.STEP_DEG` per key; once the wedges line up and stay still for
## `settle_time`, the password reads clearly and is remembered. Feedback on the way: the wedges
## visibly nearly join, gold seams and "Almost!" one or two steps off, the clicks rise in pitch as
## it closes in, and the hint's arrow flips on an overshoot. Esc (or the interact key) lowers it.

## Seconds aligned without twisting before it counts as solved.
@export var settle_time := 0.6
## How fast the picture catches up with the keys (1/s).
@export var follow_speed := 10.0
@export var tick_sound: AudioStream
@export var tick_volume_db := -8.0
@export var solve_sound: AudioStream
@export var fanfare_sound: AudioStream

const SEAM_DARK := Color(0.05, 0.05, 0.08, 1.0)
const SEAM_GOLD := Color(1.0, 0.8, 0.2, 1.0)
const BRASS := Color("#b8892c")
const BRASS_DARK := Color("#6e4e14")
## Steps off that count as "almost".
const ALMOST_STEPS := 2

var _steps := 0 ## Barrel steps twisted (signed).
var _shown := 0.0 ## Eased `_steps`.
var _still := 0.0 ## Seconds aligned without moving.
var _solved := false
var _opened_msec := 0
var _player: Node
var _minimap_was_visible := true
var _almost_shown := false
var _glow := 0.0

@onready var _view: ColorRect = $View
@onready var _material: ShaderMaterial = $View.material
@onready var _barrel: Control = $Barrel
@onready var _twist: TwistInput = $TwistInput
@onready var _hint: TwistHint = $Hint
@onready var _feedback: Label = $Feedback
@onready var _ticker: AudioStreamPlayer = $Ticker


func _ready() -> void:
	add_to_group(&"scope_view")
	_twist.twisted.connect(_on_twisted)
	_barrel.draw.connect(_draw_barrel)
	_ticker.stream = tick_sound
	_ticker.volume_db = tick_volume_db
	_feedback.hide()


## Raises the scope at the painting whose source picture is `source`.
func open(source: Texture2D) -> void:
	Kaleidoscope.ensure()
	_opened_msec = Time.get_ticks_msec()
	_material.set_shader_parameter(&"source", source)
	_player = get_tree().get_first_node_in_group(&"player")
	if _player:
		_player.movement_locked = true
		_minimap_was_visible = _player.hud.minimap.visible
		_player.hud.minimap.visible = false
	if GameState.scope_solved:
		_steps = GameState.scope_target
		_shown = _steps
		_solved = true
		_hint.hide()
		_show_password(false)
	else:
		_hint.arrow_direction = 1 if Kaleidoscope.error_steps(0) < 0 else -1 # The short way round.
		Narrator.play(&"scope_open")
	_update_view()
	# Raise it: the eyepiece grows in from a squint.
	_view.scale = Vector2(1.0, 0.15)
	_view.pivot_offset = _view.size / 2.0
	create_tween().tween_property(_view, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func close() -> void:
	if _player:
		_player.movement_locked = false
		_player.hud.minimap.visible = _minimap_was_visible
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	# The interact press that raised the scope must not lower it straight away.
	var settled := Time.get_ticks_msec() - _opened_msec > 300
	if event.is_action_pressed("ui_cancel") or (settled and event.is_action_pressed("interact")):
		get_viewport().set_input_as_handled()
		close()


func _process(delta: float) -> void:
	_shown = lerpf(_shown, _steps, 1.0 - exp(-follow_speed * delta))
	if absf(_shown - _steps) < 0.002:
		_shown = _steps
	if not _solved and Kaleidoscope.error_steps(_steps) == 0:
		_still += delta
		if _still >= settle_time:
			_solve()
	_update_view()


func _update_view() -> void:
	var size := _view.size
	_material.set_shader_parameter(&"aspect", size.x / maxf(size.y, 1.0))
	_material.set_shader_parameter(&"err", deg_to_rad((_shown - GameState.scope_target) * Kaleidoscope.STEP_DEG))
	_material.set_shader_parameter(&"glow", _glow)
	_barrel.queue_redraw()


func _on_twisted(delta_degrees: float) -> void:
	if _solved:
		return
	_steps += roundi(delta_degrees / 60.0)
	_still = 0.0
	var error := Kaleidoscope.error_steps(_steps)
	_ticker.pitch_scale = 1.0 + 0.6 * (1.0 - clampf(absi(error) / 6.0, 0.0, 1.0))
	_ticker.play()
	if error != 0:
		_hint.arrow_direction = 1 if error < 0 else -1 # "Other way!" after an overshoot.
	var almost := error != 0 and absi(error) <= ALMOST_STEPS
	_material.set_shader_parameter(&"seam_color", SEAM_GOLD if almost or error == 0 else SEAM_DARK)
	if almost and not _almost_shown:
		_feedback.text = "Almost!"
		_feedback.add_theme_color_override(&"font_color", SEAM_GOLD)
		_feedback.show()
		_feedback.pivot_offset = _feedback.size / 2.0
		_feedback.scale = Vector2.ONE * 0.5
		create_tween().tween_property(_feedback, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	elif not almost and error != 0:
		_feedback.hide()
	_almost_shown = almost
	if absi(error) == 1:
		Narrator.play(&"scope_almost") # A `once` cue.


func _solve() -> void:
	_solved = true
	GameState.scope_solved = true
	_hint.hide()
	Audio.play_sfx(solve_sound, -2.0)
	Audio.play_sfx(fanfare_sound, -6.0)
	var flash := create_tween()
	flash.tween_property(self, "_glow", 1.0, 0.15)
	flash.tween_property(self, "_glow", 0.0, 0.5)
	_show_password(true)
	ComicBurst.spawn(_barrel, _view.get_global_rect().get_center() + Vector2(0, -_view.size.y * 0.3), "CLICK!")
	Narrator.play(&"scope_solved")


func _show_password(pop: bool) -> void:
	_feedback.text = "PASSWORD: %s" % GameState.scope_password
	_feedback.add_theme_color_override(&"font_color", Color(0.55, 1.0, 0.55))
	_feedback.show()
	_feedback.pivot_offset = _feedback.size / 2.0
	if pop:
		_feedback.scale = Vector2.ONE * 0.4
		create_tween().tween_property(_feedback, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## The scope's brass barrel around the eyepiece: knurled ring with tick marks that turn with the twist.
func _draw_barrel() -> void:
	var size := _barrel.size
	var center := size / 2.0
	var r := size.y * (_material.get_shader_parameter(&"radius") as float)
	var width := size.y * 0.07
	var turn := deg_to_rad(_shown * Kaleidoscope.STEP_DEG)
	_barrel.draw_arc(center, r + width * 0.5, 0.0, TAU, 96, BRASS, width, true)
	_barrel.draw_arc(center, r + 2.0, 0.0, TAU, 96, Color.BLACK, 5.0, true)
	_barrel.draw_arc(center, r + width, 0.0, TAU, 96, Color.BLACK, 5.0, true)
	for i in 48:
		var angle := turn + i * TAU / 48.0
		var dir := Vector2.from_angle(angle)
		var long := i % 4 == 0
		var inner := r + width * (0.2 if long else 0.45)
		_barrel.draw_line(center + dir * inner, center + dir * (r + width * 0.85), BRASS_DARK if not long else Color.BLACK, 4.0 if long else 2.5, true)
