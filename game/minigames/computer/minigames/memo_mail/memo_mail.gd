extends Minigame
## Corporate speak as replies to the boss: three emails arrive in "MemoMail" over the ComicWord
## document; each reply is a corporate_speak sentence whose blanks you fill from word options. The
## boss's face (and, on email 2, the 40 people CC'd) reacts live to every word you pick; Send gets his
## answer by mood band. Email 3's Reply All presses itself, and the replies flood in until the mail
## server takes the power down (the visit ends with Story → Computer.blackout()).
## Reuses PiBot314's corporate_speak sentence format and parser (their files are untouched).

const CorporateSpeak := preload("res://minigames/computer/minigames/corporate_speak/corporate_speak.gd")
const BLANK_TEXT := "________"
const ACTIVE_COLOR := Color(0.15, 0.35, 0.85)
const BANDS: Array[StringName] = [&"angry", &"neutral", &"happy", &"starry"]
const BAND_LABELS: Array[String] = ["Boss mood: FURIOUS", "Boss mood: meh", "Boss mood: pleased", "Boss mood: STARSTRUCK"]
const BAND_COLORS: Array[Color] = [Color("#d92b2b"), Color("#555555"), Color("#1f8a3a"), Color("#c98a00")]
## Mood thresholds between the bands (angry | neutral | happy | starry).
const THRESHOLDS: Array[float] = [-0.35, 0.15, 0.6]
## Extra distance past a threshold before the shown band changes (no flicker on the edge).
const HYSTERESIS := 0.05
const TYPE_SPEED := 30.0 ## Characters per second when the To: line types itself.

var _email_index := -1
var _email: MemoEmail
var _segments: Array = [] ## String (plain text) or Blank, in sentence order.
var _blanks: Array[Blank] = []
var _active: Blank
var _target := 0.0 ## Mood the picked words add up to (-1..1).
var _mood := 0.0 ## Shown mood, easing towards _target.
var _band := 1 ## Shown band (index into BANDS).
var _sending := false

@onready var window: AppWindow = %Window
@onready var boss: MoodFace = %Boss
@onready var mood_label: Label = %MoodLabel
@onready var crowd: FaceCrowd = %Crowd
@onready var crowd_label: Label = %CrowdLabel
@onready var bubble: PanelContainer = %Bubble
@onready var boss_reply: Label = %BossReply
@onready var to_label: Label = %To
@onready var subject_label: Label = %Subject
@onready var body_label: Label = %Body
@onready var mail_box: Control = %MailBox
@onready var sentence_flow: HFlowContainer = %Sentence
@onready var options_flow: HFlowContainer = %Options
@onready var reply_all_button: Button = %ReplyAll
@onready var send_button: Button = %Send
@onready var toasts: Control = %Toasts


## One blank in the reply (corporate_speak's own Blank is an inner class of their script).
class Blank:
	var options: Array[Dictionary] = [] ## {"word": String, "points": int}
	var chosen := -1
	var button: Button

	func word() -> String:
		return options[chosen].word if chosen >= 0 else ""

	func points() -> int:
		return options[chosen].points if chosen >= 0 else 0

	func best() -> int:
		var top: int = options[0].points
		for option in options:
			top = maxi(top, option.points)
		return top

	func worst() -> int:
		var low: int = options[0].points
		for option in options:
			low = mini(low, option.points)
		return low

	## -1 (worst word) .. 1 (best word); 0 while unfilled.
	func score() -> float:
		if chosen < 0 or best() == worst():
			return 0.0
		return remap(points(), worst(), best(), -1.0, 1.0)


func _ready() -> void:
	send_button.pressed.connect(_on_send_pressed)
	window.close_requested.connect(_on_close_requested)
	window.closed.connect(complete)
	set_process(false)


func begin() -> void:
	var cfg := config as MemoMailConfig
	if cfg.emails.is_empty():
		push_error("MemoMail: no emails in config")
		fail()
		return
	window.pop_in()
	set_process(true)
	_next_email()


func _process(delta: float) -> void:
	_mood = lerpf(_mood, _target, 1.0 - exp(-6.0 * delta))
	boss.mood = _mood
	if crowd.visible:
		crowd.mood = _mood
		crowd_label.text = "CC: %d people. Happy: %d/%d" % [crowd.count, crowd.happy_count(), crowd.count]
	var band := _band
	while band < BANDS.size() - 1 and _mood >= THRESHOLDS[band] + HYSTERESIS / 2.0:
		band += 1
	while band > 0 and _mood < THRESHOLDS[band - 1] - HYSTERESIS / 2.0:
		band -= 1
	if band != _band:
		_set_band(band)


func _set_band(band: int) -> void:
	var cfg := config as MemoMailConfig
	var up := band > _band
	_band = band
	mood_label.text = BAND_LABELS[band]
	mood_label.add_theme_color_override(&"font_color", BAND_COLORS[band])
	boss.bounce()
	_sfx(cfg.mood_up_sfx if up else cfg.mood_down_sfx, -6.0)


func _next_email() -> void:
	var cfg := config as MemoMailConfig
	_email_index += 1
	if _email_index >= cfg.emails.size():
		_finish()
		return
	_email = cfg.emails[_email_index]
	_sending = false
	_target = 0.0
	subject_label.text = _email.subject
	body_label.text = _email.body
	to_label.text = "Boss" if _email.cc_count <= 0 else "Boss; +%d others" % _email.cc_count
	crowd.visible = _email.cc_count > 0
	crowd_label.visible = crowd.visible
	if crowd.visible:
		crowd.count = _email.cc_count
	bubble.hide()
	window.title = "MemoMail - Inbox (1)"
	mail_box.modulate.a = 1.0
	send_button.disabled = true
	reply_all_button.disabled = true
	reply_all_button.button_pressed = false
	_build(CorporateSpeak.parse(_email.reply))
	if not _blanks.is_empty():
		_select_blank(_blanks[0])
	_sfx(cfg.arrive_sfx, -4.0)
	if _email_index > 0:
		window.shake(6.0)
	if _email.arrive_cue:
		Narrator.play(_email.arrive_cue)


func _build(parsed: Array) -> void:
	for child in sentence_flow.get_children():
		child.queue_free()
	_segments.clear()
	_blanks.clear()
	_active = null
	var token_regex := RegEx.create_from_string("\\s*\\S+\\s*")
	for segment in parsed:
		if segment is String:
			# One label per word (keeping its spaces) so the line wraps between words.
			for token in token_regex.search_all(segment):
				var label := Label.new()
				label.text = token.get_string()
				label.theme_type_variation = &"SentenceLabel"
				sentence_flow.add_child(label)
			_segments.append(segment)
			continue
		var blank := Blank.new()
		blank.options = segment
		if (config as MemoMailConfig).shuffle_options:
			blank.options.shuffle()
		blank.button = Button.new()
		blank.button.text = BLANK_TEXT
		blank.button.theme_type_variation = &"BlankButton"
		blank.button.focus_mode = Control.FOCUS_NONE
		blank.button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		blank.button.pressed.connect(_select_blank.bind(blank))
		sentence_flow.add_child(blank.button)
		_blanks.append(blank)
		_segments.append(blank)


func _select_blank(blank: Blank) -> void:
	if _sending:
		return
	if _active:
		_active.button.remove_theme_color_override(&"font_color")
		_active.button.theme_type_variation = &"BlankButton"
	_active = blank
	blank.button.theme_type_variation = &"ActiveBlankButton"
	for child in options_flow.get_children():
		child.queue_free()
	for i in blank.options.size():
		var option := Button.new()
		option.text = blank.options[i].word
		option.theme_type_variation = &"WordChip"
		option.focus_mode = Control.FOCUS_NONE
		option.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		option.pressed.connect(_choose.bind(blank, i))
		options_flow.add_child(option)


func _choose(blank: Blank, index: int) -> void:
	if _sending:
		return
	var cfg := config as MemoMailConfig
	blank.chosen = index
	blank.button.text = blank.word()
	_sfx(cfg.choose_sfx)
	_target = _target_mood()
	var unfilled := _blanks.filter(func(b: Blank) -> bool: return b.chosen < 0)
	if not unfilled.is_empty():
		_select_blank(unfilled[0])
		return
	if _email.forced_reply_all:
		_forced_reply_all()
	else:
		send_button.disabled = false


func _target_mood() -> float:
	var total := 0.0
	for blank in _blanks:
		total += blank.score()
	return clampf(total / maxf(_blanks.size(), 1.0), -1.0, 1.0)


## The reply's band (no hysteresis: what the words actually add up to).
func _target_band() -> int:
	var band := 0
	while band < THRESHOLDS.size() and _target >= THRESHOLDS[band]:
		band += 1
	return band


func _on_send_pressed() -> void:
	if not _sending:
		_send()


## Email 3: the moment the reply is complete, Reply All presses itself and the mail goes to everyone.
func _forced_reply_all() -> void:
	var cfg := config as MemoMailConfig
	_lock_reply()
	send_button.disabled = true
	await _wait(0.6)
	reply_all_button.disabled = false
	reply_all_button.button_pressed = true
	_sfx(cfg.reply_all_sfx, -4.0)
	ComicBurst.spawn(self, reply_all_button.get_global_rect().get_center(), "CLICK!", Color("#ff8a5b"))
	Narrator.play(cfg.reply_all_cue)
	await _wait(0.4)
	reply_all_button.button_pressed = false
	reply_all_button.disabled = true
	var typed := "Boss; "
	to_label.text = typed
	for character in cfg.reply_all_to:
		typed += character
		to_label.text = typed
		await _wait(1.0 / TYPE_SPEED)
	window.title = cfg.reply_all_title
	await _wait(1.0)
	_send()


func _lock_reply() -> void:
	_sending = true
	if _active:
		_active.button.theme_type_variation = &"BlankButton"
	for blank in _blanks:
		blank.button.disabled = true
	for child in options_flow.get_children():
		child.queue_free()


func _send() -> void:
	var cfg := config as MemoMailConfig
	_lock_reply()
	send_button.disabled = true
	var total := 0
	for blank in _blanks:
		total += blank.points()
	if computer:
		computer.add_score(total)
		if cfg.append_to_document:
			var separator := " " if computer.buffer and not computer.buffer.right(1) in [" ", "\n", "\t"] else ""
			computer.buffer += separator + _filled_sentence()
	_sfx(cfg.send_sfx, -2.0)
	ComicBurst.spawn(self, send_button.get_global_rect().get_center(), "WHOOSH!", Color("#8fd3ff"))
	create_tween().tween_property(mail_box, "modulate:a", 0.45, 0.3)
	if _email.forced_reply_all:
		await _toast_wave(cfg.reply_all_toasts, cfg.toast_interval, false)
	var band := _target_band()
	var honest := _blanks.any(func(b: Blank) -> bool: return b.word() in _email.honest_words)
	var reply: String = _email.honest_reply if honest else _email.replies.get(BANDS[band], "")
	var cue := &""
	if honest:
		_target = 0.45 # Relieved: he hates it here too.
		_sfx(cfg.honest_sfx, -4.0)
	elif BANDS[band] == &"starry" and _email.promote_on_starry:
		cue = cfg.promoted_cue
		_sfx(cfg.promoted_sfx, -4.0)
		ComicBurst.spawn(self, boss.get_global_rect().get_center(), "PROMOTED!", Color("#ffd23f"))
	elif BANDS[band] in [&"happy", &"starry"]:
		cue = cfg.promoted_cue # "HR is pleased" (once).
	elif BANDS[band] == &"angry":
		cue = cfg.angry_cue # "HR would like a word" (once).
	boss_reply.text = reply
	bubble.visible = reply != ""
	boss.bounce()
	if cue:
		await _until_quiet(3.0)
		Narrator.play(cue)
	await _wait(cfg.reply_time)
	_next_email()


## Last email answered: the replies-to-the-reply-all flood the screen, then the inbox gives up.
func _finish() -> void:
	var cfg := config as MemoMailConfig
	set_process(false)
	if not cfg.flood_toasts.is_empty():
		await _toast_wave(cfg.flood_toasts, cfg.flood_interval, true)
		await _wait(0.6)
	await _until_quiet(4.0)
	window.close("SENT!")


## Pops `lines` ("Sender|text") one after another: stacked bottom-right, or (flood) cascading over the screen.
func _toast_wave(lines: Array[String], interval: float, flood: bool) -> void:
	var cfg := config as MemoMailConfig
	for i in lines.size():
		_add_toast(lines[i], i, flood)
		_sfx(cfg.toast_sfx, -8.0)
		await _wait(interval)


func _add_toast(line: String, index: int, flood: bool) -> void:
	var cfg := config as MemoMailConfig
	var parts := line.split("|", true, 1)
	var toast := PanelContainer.new()
	toast.theme_type_variation = &"Toast"
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast.custom_minimum_size.x = 300.0
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 0)
	var sender := Label.new()
	sender.theme_type_variation = &"ToastSender"
	sender.text = "RE: quick q - " + (parts[0] if parts.size() > 1 else "Someone")
	var text := Label.new()
	text.theme_type_variation = &"ToastText"
	text.text = parts[parts.size() - 1]
	box.add_child(sender)
	box.add_child(text)
	toast.add_child(box)
	toasts.add_child(toast)
	toast.reset_size()
	var area := toasts.size
	if flood: # Cascades down like a pile of windows, then starts a new pile to the right.
		var step := Vector2(30.0, 44.0)
		var start := Vector2(40.0, 30.0)
		var per_pile := maxi(int((area.y - start.y * 2.0 - toast.size.y) / step.y) + 1, 1)
		var pile := floori(index / float(per_pile))
		var row := index % per_pile
		toast.position = start + Vector2(pile * 330.0 + row * step.x, row * step.y)
	else:
		toast.position = Vector2(area.x - toast.size.x - 18.0, area.y - 70.0 - (index + 1) * (toast.size.y + 8.0))
	toast.pivot_offset = toast.size / 2.0
	toast.rotation = randf_range(-0.04, 0.04)
	toast.scale = Vector2.ONE * 0.3
	var tween := toast.create_tween()
	tween.tween_property(toast, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if not flood: # The flood stays until the window goes.
		tween.tween_interval(cfg.toast_time)
		tween.tween_property(toast, "modulate:a", 0.0, 0.3)
		tween.tween_callback(toast.queue_free)


func _filled_sentence() -> String:
	var text := ""
	for segment in _segments:
		text += segment if segment is String else (segment as Blank).word()
	return text


func _on_close_requested() -> void:
	window.shake()


## Waits for the narrator to finish (at most `max_seconds`), so a story line isn't cut off.
func _until_quiet(max_seconds: float) -> void:
	var waited := 0.0
	while Narrator.is_speaking() and waited < max_seconds:
		await _wait(0.1)
		waited += 0.1


## A delay that dies with this minigame (a tween, not a SceneTreeTimer), so nothing resumes after it's freed.
func _wait(seconds: float) -> Signal:
	return create_tween().tween_interval(seconds).finished


func _sfx(stream: AudioStream, volume_db := 0.0) -> void:
	if stream:
		Audio.play_sfx(stream, volume_db)
