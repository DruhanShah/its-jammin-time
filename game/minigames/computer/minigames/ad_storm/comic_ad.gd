extends "res://minigames/computer/minigames/ad_popup/ad_popup.gd"
## The ad storm's comic ad: the teammate's ad_popup (tiny X, decoys that spawn more ads, dodging X),
## inherited and skinned: halftone dots, a blinking frame, a wobbling "FREE!" sticker, POW!/BOING!
## bursts, plus variants (ComicAdConfig.Variant) that ad_storm.gd picks per spawn:
## RUNNER (the X hops away 3 times, then gives up), NESTED (closing opens a smaller copy, 3 deep),
## FAKE_X (the big "X CLOSE" is the decoy; the real close is a "no thanks" link), COUNTDOWN ("Skip ad in
## 5... 4... 7... 12...", then it skips itself) and ECO (the finale: a huge ad over the document whose
## button and microscopic X both "turn off the lights"; it stays up and emits `eco_accepted`).
## The ad_popup files are untouched, so the teammate's own ad behaves as before.

signal eco_accepted

const FRAME_COLORS: Array[Color] = [Color("#ff2fa0"), Color("#1fd1ff")]
const ECO_FRAME_COLORS: Array[Color] = [Color("#14853b"), Color("#ffe14d")]
const ECO_GREEN := Color("#14853b")

var _accepted := false
var _frame_style: StyleBoxFlat
var _base_font_sizes := {} ## Control -> its font size at 380 px wide (scaled for smaller ads).

@onready var body: Label = %Body
@onready var no_thanks: Button = %NoThanks
@onready var dots: ColorRect = $Dots
@onready var frame: Panel = $Frame


func _ready() -> void:
	super._ready()
	_frame_style = frame.get_theme_stylebox(&"panel").duplicate()
	frame.add_theme_stylebox_override(&"panel", _frame_style)
	for label: Control in [headline, body, decoy, countdown]:
		_base_font_sizes[label] = label.get_theme_font_size(&"font_size")


func begin() -> void:
	var cfg := config as ComicAdConfig
	if cfg.variant == ComicAdConfig.Variant.ECO:
		size = get_parent_area_size() * Vector2(0.86, 0.8) # Over the whole word processor.
	else:
		size = cfg.ad_size # Before super: placing and popping in use the size.
		_scale_fonts(size.x / 380.0)
	if cfg.variant == ComicAdConfig.Variant.RUNNER: # The config is this instance's own copy.
		cfg.dodge_after_closes = 0
		cfg.max_dodges = 3
		cfg.dodge_radius = 70.0
	super.begin()
	if cfg.headline:
		headline.text = cfg.headline
	if cfg.body_text:
		body.text = cfg.body_text
	if cfg.decoy_text:
		decoy.text = cfg.decoy_text
	if cfg.spawn_position.x >= 0.0:
		position = cfg.spawn_position
		_home = position
	# Pokes out above the top edge, left of the X (and under it, for when the runner's X hops past).
	var sticker := ComicBurst.sticker(self, Vector2(size.x - 92.0, 0.0), cfg.sticker_text)
	move_child(sticker, close_button.get_index())
	match cfg.variant:
		ComicAdConfig.Variant.FAKE_X:
			close_button.hide()
			decoy.text = "X  CLOSE"
			no_thanks.text = cfg.no_thanks_text
			no_thanks.show()
			no_thanks.pressed.connect(_on_close_pressed)
		ComicAdConfig.Variant.COUNTDOWN:
			close_button.hide()
			body.hide() # Room for the "Skip ad" pill under the button.
			_run_lying_countdown()
		ComicAdConfig.Variant.ECO:
			_eco_setup()


func _process(delta: float) -> void:
	super._process(delta)
	var cfg := config as ComicAdConfig
	var blink := int(Time.get_ticks_msec() / 1000.0 * cfg.blink_hz) % 2
	var colors := ECO_FRAME_COLORS if cfg.variant == ComicAdConfig.Variant.ECO else FRAME_COLORS
	_frame_style.border_color = ECO_GREEN if _accepted else colors[blink]


func _pop_in() -> void:
	if (config as ComicAdConfig).variant == ComicAdConfig.Variant.ECO:
		return # It slides up instead, once _eco_setup() knows where it goes.
	super._pop_in()


func _on_close_pressed() -> void:
	var cfg := config as ComicAdConfig
	if cfg.variant == ComicAdConfig.Variant.ECO:
		_accept_eco()
		return
	if is_queued_for_deletion():
		return
	if cfg.variant == ComicAdConfig.Variant.NESTED and cfg.nested_depth > 1:
		_open_nested()
	ComicBurst.spawn(get_parent(), _pow_point(), "POW!")
	super._on_close_pressed()


func _on_decoy() -> void:
	var cfg := config as ComicAdConfig
	match cfg.variant:
		ComicAdConfig.Variant.ECO:
			_accept_eco() # Clicking anywhere on it is consent.
		ComicAdConfig.Variant.FAKE_X:
			_boing()
			_shake()
			for i in cfg.fake_x_spawns:
				request_spawn.emit(id) # The host caps the window count (max_concurrent).
		_:
			_boing()
			super._on_decoy() # Shake + one more ad (the teammate's rule).


## Replaces the parent's 0.12 s hop with one you can see, and a give-up gag after the last one.
func _dodge() -> void:
	var cfg := config as ComicAdConfig
	_dodges_left -= 1
	_dodging = true
	_corner = (_corner + 1 + randi() % 3) % 4
	_play(cfg.dodge_sfx)
	var tween := create_tween()
	tween.tween_property(close_button, "position", _corner_position(_corner), cfg.dodge_time) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.finished.connect(_on_dodged)


func _on_dodged() -> void:
	_dodging = false
	if _dodges_left == 0:
		var cfg := config as ComicAdConfig
		ComicBurst.spawn(get_parent(), close_button.get_global_rect().get_center(), cfg.give_up_word, Color("#d9d9d9"))


## Spawned before this one completes, so the wave never looks cleared in between.
func _open_nested() -> void:
	var cfg := config as ComicAdConfig
	var depth := cfg.nested_depth - 1
	var child_size := size * cfg.nested_scale
	var index := clampi(cfg.nested_headlines.size() - depth, 0, cfg.nested_headlines.size() - 1)
	computer.start_minigame(id, {
		"variant": ComicAdConfig.Variant.NESTED, "nested_depth": depth, "ad_size": child_size,
		"spawn_position": position + (size - child_size) / 2.0, "headline": cfg.nested_headlines[index],
		"sticker_text": "AGAIN!",
	}) # Null at the window cap: then it just closes.
	_play(cfg.nested_sfx)


func _boing() -> void:
	ComicBurst.spawn(get_parent(), decoy.get_global_rect().get_center(), "BOING!", Color("#7af0a0"))
	_play((config as ComicAdConfig).decoy_sfx)


## "Skip ad in 5... 4... 7... 12...", then it skips itself (counts as closed).
func _run_lying_countdown() -> void:
	var cfg := config as ComicAdConfig
	countdown.show()
	var tween := create_tween()
	for i in cfg.countdown_steps.size():
		var n := cfg.countdown_steps[i]
		var lie := i > 0 and n > cfg.countdown_steps[i - 1]
		tween.tween_callback(_count.bind(n, lie))
		tween.tween_interval(cfg.countdown_step_time)
	tween.tween_callback(func() -> void: countdown.text = cfg.countdown_done_text)
	tween.tween_interval(1.2)
	tween.tween_callback(_on_close_pressed)


func _count(n: int, lie: bool) -> void:
	var cfg := config as ComicAdConfig
	countdown.text = "Skip ad in %d" % n
	_play(cfg.lie_sfx if lie else cfg.tick_sfx)
	if lie:
		countdown.pivot_offset = countdown.size / 2.0
		countdown.scale = Vector2.ONE * 1.5
		create_tween().tween_property(countdown, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## The finale: a huge green ad slides up over the word processor.
func _eco_setup() -> void:
	var cfg := config as ComicAdConfig
	_home = (get_parent_area_size() - size) / 2.0
	headline.text = "ECO MODE"
	headline.add_theme_font_size_override(&"font_size", 110)
	headline.add_theme_color_override(&"font_color", Color("#2fd16a"))
	headline.add_theme_constant_override(&"outline_size", 14)
	body.text = "Is your office too BRIGHT? Save up to 100% on electricity!"
	body.add_theme_font_size_override(&"font_size", 32)
	decoy.text = "TURN OFF LIGHTS"
	decoy.add_theme_font_size_override(&"font_size", 54)
	close_button.size = Vector2.ONE * 6.0 # Microscopic, but it works.
	close_button.position = _corner_position(0)
	var green_dots := dots.material.duplicate() as ShaderMaterial
	green_dots.set_shader_parameter(&"paper_color", Color("#d8ffc4"))
	green_dots.set_shader_parameter(&"dot_color", Color("#7fe08a"))
	dots.material = green_dots
	position = Vector2(_home.x, get_viewport_rect().size.y + 20.0)
	create_tween().tween_property(self, "position", _home, 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_play(cfg.eco_sfx, cfg.eco_sfx_db)


func _accept_eco() -> void:
	if _accepted:
		return
	_accepted = true
	var cfg := config as ComicAdConfig
	GameState.ads_closed += 1
	decoy.disabled = true
	close_button.hide()
	headline.text = cfg.eco_thanks_text
	headline.add_theme_font_size_override(&"font_size", 64)
	body.text = "Lights: OFF. Planet: grateful."
	_play(cfg.eco_accept_sfx)
	eco_accepted.emit() # The ad stays up: it dies with the screen.


func _pow_point() -> Vector2:
	for control: Control in [close_button, no_thanks, countdown]:
		if control.visible:
			return control.get_global_rect().get_center()
	return get_global_rect().get_center()


func _scale_fonts(factor: float) -> void:
	if is_equal_approx(factor, 1.0):
		return
	for control: Control in _base_font_sizes:
		control.add_theme_font_size_override(&"font_size", maxi(10, roundi(_base_font_sizes[control] * factor)))
	body.visible = factor > 0.7


func _play(stream: AudioStream, volume_db := 0.0) -> void:
	if stream:
		Audio.play_sfx(stream, volume_db)
