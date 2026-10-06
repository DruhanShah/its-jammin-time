extends Minigame
## Visit 1, beat 3: the ad storm. Any key types the next bit of the comic script (the Emily-is-Away
## trick), and typing sets off the ads (`comic_ad`, each a real minigame started through the host):
## wave 1 = 3 plain ads one at a time; wave 2 = runner, nested, fake X and countdown, at most
## `max_ads` on screen at once (the rest wait for a free slot); then the ECO MODE ad. Ads never exceed
## `max_ads` (the comic ad's max_concurrent caps decoy and nested spawns too). Typing on (or idling)
## while ads are open plays the "close those ads" hint (at most twice). Accepting it ("TURN OFF LIGHTS", or its tiny X) dims the screen twice and completes:
## in the story the EventManager → Story → Computer.blackout() turns the lights out. This never calls
## blackout() itself, so free use doesn't cut the power. The root ignores the mouse: ads are siblings.

enum Phase { WAIT_TYPING, WAVE_1, WAIT_2, WAVE_2, WAIT_3, ECO, DONE }

const AD := &"comic_ad"
const SPACING := [" ", "\n"]
## Wave-2 ad spots (top-left corners as fractions of the screen), size and variants, in spawn order.
const WAVE2_SPOTS: Array[Vector2] = [Vector2(0.05, 0.1), Vector2(0.6, 0.13), Vector2(0.1, 0.5), Vector2(0.58, 0.5)]
const WAVE2_AD_SIZE := Vector2(360, 230)
const WAVE2_VARIANTS: Array[ComicAdConfig.Variant] = [
	ComicAdConfig.Variant.RUNNER, ComicAdConfig.Variant.NESTED, ComicAdConfig.Variant.FAKE_X, ComicAdConfig.Variant.COUNTDOWN,
]

var _phase := Phase.WAIT_TYPING
var _keys := 0 ## Non-echo keypresses since the phase started.
var _idle := 0.0 ## Seconds since the last keypress (or the phase start).
var _cursor := 0 ## Characters typed so far (the next one of script_text, then the filler).
var _wave1_index := 0
var _pending := 0 ## Ads scheduled but not spawned yet, so a wave never looks cleared too early.
var _last_sfx_ms := 0
var _eco: Minigame
var _wave2_queue: Array[Dictionary] = [] ## Wave-2 ads waiting for a free slot under max_ads.
var _hint_keys := 0 ## Keypresses while ads are open since one was last closed.
var _hint_idle := 0.0 ## Seconds with ads open and no key/mouse press.
var _hints_played := 0
var _hint_msec := -1


func begin() -> void:
	computer.minigame_completed.connect(_on_ad_completed)
	if computer.buffer and not computer.buffer.ends_with("\n"):
		computer.buffer += "\n"
	_refresh_goal()


## Mouse clicks go to the ads (siblings); only watch them, for the hint's idle timer.
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_hint_idle = 0.0


func cleanup() -> void:
	if computer.minigame_completed.is_connected(_on_ad_completed):
		computer.minigame_completed.disconnect(_on_ad_completed)
	computer.status_note = ""


## Any key writes the next bit of the script. Runs before the Computer's own typing (child first).
func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if not key.pressed:
		return
	if key.keycode in [KEY_ESCAPE, KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_META, KEY_CAPSLOCK] \
			or (key.keycode >= KEY_F1 and key.keycode <= KEY_F12) or key.ctrl_pressed or key.meta_pressed:
		return # Shortcuts and the debug keys (F5-F7) go through.
	get_viewport().set_input_as_handled()
	if _phase == Phase.DONE:
		return # The lights are going: no more typing.
	_type_next() # Backspace and Enter type too: it's a script, it only goes forwards.
	if key.echo:
		return # Holding a key types, but doesn't count towards the next wave.
	_keys += 1
	_idle = 0.0
	_hint_idle = 0.0
	if _ads_open():
		_hint_keys += 1
	match _phase:
		Phase.WAIT_TYPING:
			if _keys >= _cfg().first_ad_after_keys:
				_start_wave_1()
		Phase.WAIT_2:
			if _keys >= _cfg().next_wave_keys:
				_start_wave_2()
		Phase.WAIT_3:
			if _keys >= _cfg().eco_after_keys:
				_start_eco()


func _process(delta: float) -> void:
	var cfg := _cfg()
	if _phase in [Phase.WAIT_TYPING, Phase.WAIT_2, Phase.WAIT_3]:
		_idle += delta
	match _phase: # Nobody gets stuck: waiting long enough starts the next wave anyway.
		Phase.WAIT_TYPING:
			if _idle >= cfg.wait_typing_idle:
				_start_wave_1()
		Phase.WAIT_2:
			if _idle >= cfg.next_wave_idle:
				_start_wave_2()
		Phase.WAIT_3:
			if _idle >= cfg.eco_idle:
				_start_eco()
	_update_hint(delta)


## "Close those ads": the player keeps typing (or sits idle) while ads stay open. Never cuts a line.
func _update_hint(delta: float) -> void:
	var cfg := _cfg()
	if not (_phase in [Phase.WAVE_1, Phase.WAVE_2]) or not _ads_open():
		_hint_idle = 0.0
		return
	_hint_idle += delta
	if _hint_keys < cfg.hint_after_keys and _hint_idle < cfg.hint_after_idle:
		return
	if _hints_played >= 2 or Narrator.is_speaking():
		return
	if _hints_played == 1 and Time.get_ticks_msec() - _hint_msec < cfg.hint_repeat_after * 1000.0:
		return
	_hints_played += 1
	_hint_msec = Time.get_ticks_msec()
	_hint_keys = 0
	_hint_idle = 0.0
	Narrator.play(cfg.hint_cue)


func _ads_open() -> bool:
	return not computer.active_minigames(AD).is_empty()


func _type_next() -> void:
	var cfg := _cfg()
	var text := cfg.script_text
	var chunk := ""
	if _cursor < text.length():
		chunk = text[_cursor]
		_cursor += 1
		while _cursor < text.length() and text[_cursor] in SPACING: # Words land on letter keys.
			chunk += text[_cursor]
			_cursor += 1
	else:
		chunk = cfg.filler[(_cursor - text.length()) % cfg.filler.length()]
		_cursor += 1
	computer.buffer += chunk
	var now := Time.get_ticks_msec()
	if cfg.type_sfx and now - _last_sfx_ms > 40:
		_last_sfx_ms = now
		Audio.play_sfx(cfg.type_sfx, cfg.type_sfx_db)
	_refresh_goal()


func _refresh_goal() -> void:
	var cfg := _cfg()
	computer.status_note = cfg.goal_text % mini(99, int(100.0 * _cursor / maxi(1, cfg.page_chars)))


func _enter(phase: Phase) -> void:
	_phase = phase
	_keys = 0
	_idle = 0.0


func _start_wave_1() -> void:
	_enter(Phase.WAVE_1)
	Narrator.play(_cfg().first_cue)
	_wave1_index = 0
	_spawn_wave1()


func _spawn_wave1() -> void:
	_spawn({"variant": ComicAdConfig.Variant.PLAIN, "headline": _cfg().wave1_headlines[_wave1_index]})


func _start_wave_2() -> void:
	var cfg := _cfg()
	_enter(Phase.WAVE_2)
	_wave2_queue.clear()
	for i in WAVE2_VARIANTS.size():
		var overrides := {"variant": WAVE2_VARIANTS[i], "ad_size": WAVE2_AD_SIZE, "spawn_position": computer.screen.size * WAVE2_SPOTS[i]}
		if i < cfg.wave2_headlines.size():
			overrides["headline"] = cfg.wave2_headlines[i]
		_wave2_queue.append(overrides)
	_fill_wave2()


## Spawns queued wave-2 ads (staggered) while there's room under max_ads.
func _fill_wave2() -> void:
	var room := _cfg().max_ads - computer.active_minigames(AD).size() - _pending
	var i := 0
	while room > 0 and not _wave2_queue.is_empty():
		_pending += 1
		_after(i * _cfg().wave2_stagger, _spawn_pending.bind(_wave2_queue.pop_front()))
		room -= 1
		i += 1


func _start_eco() -> void:
	_enter(Phase.ECO)
	Narrator.play(_cfg().eco_cue)
	_eco = _spawn({"variant": ComicAdConfig.Variant.ECO, "sticker_text": "SAVE 100%!"})
	if _eco:
		_eco.connect(&"eco_accepted", _on_eco_accepted)
	else: # At the window cap (can't happen after a cleared wave, but never get stuck).
		_on_eco_accepted()


func _spawn(overrides: Dictionary) -> Minigame:
	overrides["max_concurrent"] = _cfg().max_ads
	return computer.start_minigame(AD, overrides)


func _spawn_pending(overrides: Dictionary) -> void:
	_pending -= 1
	if not _spawn(overrides) and _phase == Phase.WAVE_2:
		_wave2_queue.push_front(overrides) # Full (a decoy spawn took the slot): wait for a close.
		_check_cleared.call_deferred()


func _on_ad_completed(ad_id: StringName) -> void:
	if ad_id == AD:
		_hint_keys = 0
		_hint_idle = 0.0
		_check_cleared.call_deferred()


func _check_cleared() -> void:
	if _phase == Phase.WAVE_2 and not _wave2_queue.is_empty():
		_fill_wave2()
	if _pending > 0 or not computer.active_minigames(AD).is_empty():
		return
	match _phase:
		Phase.WAVE_1:
			_wave1_index += 1
			if _wave1_index < _cfg().wave1_headlines.size():
				_pending += 1
				_after(_cfg().wave1_gap, _spawn_next_wave1)
			else:
				_enter(Phase.WAIT_2)
		Phase.WAVE_2:
			_enter(Phase.WAIT_3)


func _spawn_next_wave1() -> void:
	_pending -= 1
	_spawn_wave1()


## Two brightness dips ("the lights are going"), then the story's blackout takes over.
func _on_eco_accepted() -> void:
	_enter(Phase.DONE)
	var dip := _cfg().screen_dip_time * 0.25
	var tween := create_tween()
	for i in 2:
		tween.tween_property(computer.screen, "modulate", Color(0.45, 0.45, 0.45), dip)
		tween.tween_property(computer.screen, "modulate", Color.WHITE, dip)
	tween.tween_callback(_finish)


func _finish() -> void:
	if not GameState.computer_queue.has(id) and is_instance_valid(_eco):
		_eco.complete() # Free use: no blackout, so the ad just goes away.
	complete()


## A tween, not a timer, so it dies with the minigame (e.g. Power pressed mid-wave).
func _after(seconds: float, callback: Callable) -> void:
	if seconds <= 0.0:
		callback.call()
		return
	create_tween().tween_interval(seconds).finished.connect(callback)


func _cfg() -> AdStormConfig:
	return config as AdStormConfig
