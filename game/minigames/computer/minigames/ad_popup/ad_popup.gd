extends Minigame
## Pop-up ad over the editor. The real close button is tiny; clicking anything else spawns more ads.
## Tunables live in AdPopupConfig (ad_popup_default.tres).

const CORNER_MARGIN := 4.0

var _dodges_left := 0
var _dodging := false
var _corner := 0
var _countdown_left := 0.0
var _home := Vector2.ZERO
var _shake_tween: Tween

@onready var headline: Label = %Headline
@onready var decoy: Button = %Decoy
@onready var close_button: Button = %CloseButton
@onready var countdown: Label = %Countdown


func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)
	close_button.draw.connect(_draw_close_x)
	decoy.pressed.connect(_on_decoy)


func begin() -> void:
	var cfg := config as AdPopupConfig
	headline.text = cfg.headlines.pick_random()
	decoy.text = cfg.decoy_labels.pick_random()
	close_button.size = Vector2.ONE * cfg.close_button_size
	close_button.position = _corner_position(_corner)
	_dodges_left = cfg.max_dodges if GameState.ads_closed >= cfg.dodge_after_closes else 0
	_countdown_left = cfg.skip_countdown
	close_button.visible = _countdown_left <= 0.0
	countdown.visible = not close_button.visible
	_place_on_screen()
	_pop_in()
	if cfg.spawn_sfx:
		Audio.play_sfx(cfg.spawn_sfx)


func _process(delta: float) -> void:
	if _countdown_left > 0.0:
		_countdown_left -= delta
		countdown.text = "Skip ad in %d" % ceili(_countdown_left)
		if _countdown_left <= 0.0:
			countdown.hide()
			close_button.show()
		return
	if _dodges_left > 0 and not _dodging:
		var cursor := get_global_mouse_position()
		if cursor.distance_to(close_button.get_global_rect().get_center()) < (config as AdPopupConfig).dodge_radius:
			_dodge()


## Clicking the ad itself (not a button) counts as falling for it.
func _gui_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		_on_decoy()
		accept_event()


func _on_close_pressed() -> void:
	GameState.ads_closed += 1
	var cfg := config as AdPopupConfig
	if cfg.close_sfx:
		Audio.play_sfx(cfg.close_sfx)
	complete()


func _on_decoy() -> void:
	_shake()
	if (config as AdPopupConfig).spawn_on_decoy_click:
		request_spawn.emit(id)


## Random spot over the editor text, kept inside the layer.
func _place_on_screen() -> void:
	var area := computer.editor.get_rect() if computer else Rect2(Vector2.ZERO, get_parent_area_size())
	var room := (area.size - size).max(Vector2.ZERO)
	_home = area.position + Vector2(randf() * room.x, randf() * room.y)
	position = _home


func _pop_in() -> void:
	pivot_offset = size / 2.0
	scale = Vector2.ONE * 0.3
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.25) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _shake() -> void:
	if _shake_tween:
		_shake_tween.kill()
	_shake_tween = create_tween()
	for offset in [Vector2(10, 0), Vector2(-10, 0), Vector2(6, 0), Vector2.ZERO]:
		_shake_tween.tween_property(self, "position", _home + offset, 0.04)


func _dodge() -> void:
	_dodges_left -= 1
	_dodging = true
	_corner = (_corner + 1 + randi() % 3) % 4
	var tween := create_tween()
	tween.tween_property(close_button, "position", _corner_position(_corner), 0.12)
	tween.finished.connect(func() -> void: _dodging = false)


## 0 top-right, 1 top-left, 2 bottom-right, 3 bottom-left.
func _corner_position(corner: int) -> Vector2:
	var far := size - close_button.size - Vector2.ONE * CORNER_MARGIN
	var x := far.x if corner in [0, 2] else CORNER_MARGIN
	var y := CORNER_MARGIN if corner < 2 else far.y
	return Vector2(x, y)


func _draw_close_x() -> void:
	var s := close_button.size
	var inset := s * 0.25
	var color := Color(0.4, 0.4, 0.4)
	close_button.draw_line(inset, s - inset, color, 1.0)
	close_button.draw_line(Vector2(s.x - inset.x, inset.y), Vector2(inset.x, s.y - inset.y), color, 1.0)
