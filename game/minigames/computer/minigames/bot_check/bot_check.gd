extends Minigame
## "Are you a bot?" pop-up. A big "click me if you are a bot" button (a trap), an
## "I'm not a robot" captcha that takes a random number of tries to pass, and a close X
## that only appears after a delay. Tunables live in BotCheckConfig (bot_check_default.tres).

var _tries_needed := 1
var _tries := 0
var _verifying := false
var _close_left := 0.0

@onready var bot_button: Button = %BotButton
@onready var captcha_box: Button = %CaptchaBox
@onready var captcha_status: Label = %CaptchaStatus
@onready var close_button: Button = %CloseButton
@onready var countdown: Label = %Countdown


func _ready() -> void:
	bot_button.pressed.connect(_on_bot_pressed)
	captcha_box.pressed.connect(_on_captcha_pressed)
	close_button.pressed.connect(complete)


func begin() -> void:
	var cfg := config as BotCheckConfig
	_tries_needed = 1 if randf() < cfg.first_try_chance else randi_range(2, cfg.max_tries)
	_close_left = cfg.close_delay
	close_button.visible = _close_left <= 0.0
	countdown.visible = not close_button.visible
	captcha_status.text = ""
	_place_on_screen()


func _process(delta: float) -> void:
	if _close_left <= 0.0:
		return
	_close_left -= delta
	countdown.text = "%d" % ceili(_close_left)
	if _close_left <= 0.0:
		countdown.hide()
		close_button.show()


func _on_bot_pressed() -> void:
	_play_click()
	if computer:
		computer.add_score(-(config as BotCheckConfig).bot_penalty)
	fail()


func _on_captcha_pressed() -> void:
	if _verifying:
		return
	_play_click()
	_verifying = true
	_tries += 1
	captcha_box.text = "…"
	captcha_status.text = "Verifying…"
	get_tree().create_timer((config as BotCheckConfig).verify_time).timeout.connect(_on_verified)


func _on_verified() -> void:
	_verifying = false
	if _tries >= _tries_needed:
		captcha_box.text = "✓"
		captcha_status.text = "Verified human. Probably."
		if computer:
			computer.add_score((config as BotCheckConfig).pass_points)
		get_tree().create_timer(0.6).timeout.connect(complete)
	else:
		captcha_box.text = ""
		captcha_status.text = (config as BotCheckConfig).fail_messages.pick_random()


func _play_click() -> void:
	var sfx := (config as BotCheckConfig).click_sfx
	if sfx:
		Audio.play_sfx(sfx)


## Random spot over the editor text, kept inside the layer.
func _place_on_screen() -> void:
	var area := computer.editor.get_rect() if computer else Rect2(Vector2.ZERO, get_parent_area_size())
	var room := (area.size - size).max(Vector2.ZERO)
	position = area.position + Vector2(randf() * room.x, randf() * room.y)
