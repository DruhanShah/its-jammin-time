extends Node3D
## SWITCH_2's obstacle (switch game id `gargoyles`, in-world: no scene of its own). Two stone
## gargoyles block the aisle to the switch. X on one: they argue (speech balloons), then the lights
## slam into a game-show look and it becomes "WHO WANTS TO TURN ON THE LIGHTS?": one question, read out by
## the narrator, infinite tries (a wrong answer gets the buzzer and a jab, then pick again). The right
## one and they step aside, which beats the game (`Story.switch_game_done`), so the switch offers the
## next one. Esc (or WALK AWAY, twice) leaves and restores everything; X again goes straight to the
## show. Content (placeholder) is in quiz_content.gd, the screen in quiz_ui.gd.
##
## Authored at the server room's WEST end (C1 local), where the switch hangs once the server room has
## swapped places with A3 (`StoryStage._swap_rooms`). It only shows from SWITCH_2 on, which is always
## swapped, so it must NOT be added to `StoryStage.MIRRORED_TO_WEST_WALL` (that would flip it east).

enum State { ASLEEP, BANTER, QUIZ_ASK, QUIZ_LOCKED, QUIZ_REVEAL, PASSED }

## Emitted to end the wait for the current balloon (a key/click or its reading time).
signal _advanced

const GAME := &"gargoyles"
## What the "timer" shows instead of time.
const DIAL_POOL: Array[String] = ["30", "7", "29", "-4", "3.14", "812", "0", "∞", "NaN", "12:00", "BEES", "½", "π²", "69,105", "ERROR", "LOL"]
## Balloons stay up for their reading time (like subtitle-only narrator lines), at least MIN_LINE_TIME.
const READ_CHARS_PER_SECOND := 15.0
const MIN_LINE_TIME := 1.6
const WORD_BLIP_TIME := 0.17
## Narrator subtitle top edge (from the screen bottom) while the quiz strip is up.
const SUBTITLE_LIFTED_TOP := -360.0

## The narrator reads the question, then each option, one recording after another (no subtitles:
## it's all on screen). Script line "And your options are..." has no recording yet.
const QUESTION_CUES: Array[StringName] = [
	&"quiz_question", &"quiz_options_intro", &"quiz_option_1", &"quiz_option_2", &"quiz_option_3", &"quiz_option_4",
]
const SLAM := preload("res://assets/audio/sfx/freesound/quiz_lights_slam_grubzyy.wav")
const INTRO_HIT := preload("res://assets/audio/sfx/freesound/quiz_intro_hit_horns_devern.wav")
const THINK_MUSIC := preload("res://assets/audio/sfx/freesound/quiz_think_loop_portwain.wav")
const HEARTBEAT := preload("res://assets/audio/sfx/freesound/quiz_heartbeat_loop_loudernoises.wav")
const FINAL_BOOM := preload("res://assets/audio/sfx/freesound/quiz_final_answer_boom_harrisonlace.wav")
const CORRECT := preload("res://assets/audio/sfx/freesound/quiz_correct_bwg2020.wav")
const WRONG := preload("res://assets/audio/sfx/freesound/quiz_wrong_buzzer_kevinvg207.wav")
const HARP := preload("res://assets/audio/sfx/freesound/quiz_correct_harp_oggraphics.wav")
const GRIND := preload("res://assets/audio/sfx/freesound/stone_grind_step_aside_postproddog.wav")
const RUMBLE := preload("res://assets/audio/sfx/freesound/rumble_step_aside_unfa.wav")
const CLOCK_LOOP := preload("res://assets/audio/sfx/400_sounds_pack/clock_ticking.wav")
const CLOCK_TICK := preload("res://assets/audio/sfx/400_sounds_pack/clock_tick_only.wav")
const STONE_BLIP := preload("res://assets/audio/sfx/400_sounds_pack/stone_push_short.wav")
const LIFELINE_SOUND := preload("res://assets/audio/sfx/400_sounds_pack/pop_2.wav")

## How far each statue slides out of the way, and how long it takes.
@export var aside_distance := 1.3
@export var aside_time := 1.6
## Head pitch (degrees, negative = down) in the hot seat, so both statues sit above the quiz strip.
@export var hot_seat_pitch := -14.0

var state := State.ASLEEP
var _misses := 0 ## Wrong answers so far (kept when walking away).
var _seen_banter := false
var _psst_done := false
var _clock_zero_said := false
var _confirm_leave := false
var _run := 0 ## Bumped when the quiz is left or passed, so pending awaits drop out.
var _line := 0 ## Bumped per balloon, so a stale reading timer can't skip the next one.
var _lines_said := {} ## Rotating reaction lines: list name -> next index.
var _music_before: AudioStream
var _player ## The Player (untyped: player.gd has no class_name); `frozen`, `head`.
var _lighting ## The office's Lighting node (lighting.gd), or null outside the office.
var _blips: AudioStreamRandomizer
var _home := {} ## Gargoyle -> its guarding transform.
var _subtitle_offsets: Array[float] = [] ## The subtitles' own [offset_top, offset_bottom] while lifted.

@onready var _gar: Gargoyle = $Gar
@onready var _goyle: Gargoyle = $Goyle
@onready var _barrier: StaticBody3D = $Barrier
@onready var _wake_zone: Area3D = $WakeZone
@onready var _quiz_view: Marker3D = $QuizView
@onready var _rig: Node3D = $QuizRig
@onready var _sweep: Node3D = $QuizRig/Sweep
@onready var _loop: AudioStreamPlayer = $Loop
@onready var _clock: AudioStreamPlayer = $Clock
@onready var _dial_timer: Timer = $DialTimer
@onready var _ui: QuizUI = $QuizUI
@onready var _bubbles: Dictionary[Gargoyle, SpeechBubble] = {_gar: $Bubbles/GarBubble, _goyle: $Bubbles/GoyleBubble}


func _ready() -> void:
	_player = get_tree().get_first_node_in_group(&"player")
	_lighting = get_tree().get_first_node_in_group(&"office_lighting")
	_blips = AudioStreamRandomizer.new()
	_blips.add_stream(-1, STONE_BLIP)
	_blips.random_pitch = 1.35
	for gargoyle: Gargoyle in [_gar, _goyle]:
		_home[gargoyle] = gargoyle.transform
		gargoyle.interacted.connect(_on_statue_interacted)
	for spot: SpotLight3D in [$QuizRig/SpotGar, $QuizRig/SpotGoyle]:
		var target: Gargoyle = _gar if spot.name == &"SpotGar" else _goyle
		spot.look_at(target.global_position + Vector3.UP * 1.3)
	_bubbles[_goyle].lean = -1.0 # Goyle stands on the left from the hot seat, Gar on the right.
	_bubbles[_gar].lean = 1.0
	_set_rig(false)
	_wake_zone.body_entered.connect(_on_wake_zone_entered)
	_dial_timer.timeout.connect(_on_dial_tick)
	_ui.answer_selected.connect(_on_answer_selected)
	_ui.answer_locked.connect(_on_answer_locked)
	_ui.lifeline_used.connect(_on_lifeline_used)
	_ui.walk_away.connect(_on_walk_away)
	Story.switch_game_changed.connect(_sync.unbind(1))
	_sync()


func _exit_tree() -> void:
	# A scene change mid-quiz (e.g. F7): the player and lights are rebuilt with the scene, the cursor
	# and the music (autoloads) are not.
	if state in [State.BANTER, State.QUIZ_ASK, State.QUIZ_LOCKED, State.QUIZ_REVEAL]:
		ComicCursor.reset()
		_restore_music()
		_lift_subtitles(false)


func _process(delta: float) -> void:
	if _rig.visible:
		_sweep.rotate_y(delta * 0.9)


func _input(event: InputEvent) -> void:
	if state == State.ASLEEP or (state == State.PASSED and not _player.frozen):
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if state == State.BANTER:
			_leave()
		elif state != State.PASSED:
			_on_walk_away()
	elif _advance_pressed(event) and state in [State.BANTER, State.PASSED]:
		get_viewport().set_input_as_handled()
		_advanced.emit()


## Shows, blocks and arms the gate for the current story state (see the table in docs/plans/gargoyle_quiz.md).
func _sync() -> void:
	var current := Story.switch_game() == GAME
	var beaten := Story.step > Story.Step.SWITCH_2 or (Story.step == Story.Step.SWITCH_2 and not current)
	visible = current or beaten
	for shape: CollisionShape3D in _barrier.get_children():
		shape.set_deferred(&"disabled", not current)
	for gargoyle: Gargoyle in [_gar, _goyle]:
		gargoyle.set_interactable(current and state == State.ASLEEP)
		gargoyle.process_mode = PROCESS_MODE_INHERIT if visible else PROCESS_MODE_DISABLED
		for body: CollisionShape3D in gargoyle.find_children("*", "CollisionShape3D", true, false):
			if body.get_parent() is StaticBody3D:
				body.set_deferred(&"disabled", not visible)
	_wake_zone.set_deferred(&"monitoring", current)
	if beaten and state != State.PASSED:
		state = State.PASSED
		_step_aside(0.0)


func _on_wake_zone_entered(body: Node3D) -> void:
	if body != _player or _psst_done or state != State.ASLEEP:
		return
	_psst_done = true
	var run := _run
	while Narrator.is_speaking():
		await get_tree().create_timer(0.3).timeout
		if run != _run or state != State.ASLEEP:
			return
	var line: Array = QuizContent.LINES.psst[0]
	_gar.set_eyes(Gargoyle.Eyes.AWAKE)
	_say(line[0], line[1])
	await get_tree().create_timer(_read_time(line[1])).timeout
	if state == State.ASLEEP:
		_gar.set_eyes(Gargoyle.Eyes.STONE)
		_hide_bubbles()


func _on_statue_interacted() -> void:
	if state != State.ASLEEP or Story.switch_game() != GAME:
		return
	_run += 1
	var run := _run
	state = State.BANTER
	_freeze(true)
	_go_to_hot_seat() # Step back so both statues are in view for the argument and the show.
	_hide_bubbles()
	for gargoyle: Gargoyle in [_gar, _goyle]:
		gargoyle.set_interactable(false)
		gargoyle.wake()
	if not _seen_banter:
		await _play_lines(QuizContent.LINES.intro, run)
		if run != _run:
			return
		_seen_banter = true
	await _slam(run)
	if run != _run:
		return
	if _misses > 0:
		_say("BOTH", QuizContent.LINES.resume)
		get_tree().create_timer(1.6).timeout.connect(_hide_bubbles)
	state = State.QUIZ_ASK
	_ui.show_question(QuizContent.QUESTION)
	_start_thinking()
	# The narrator reads the question out (no subtitle: it's on screen) once any earlier line is over,
	# unless the player already answered.
	var misses := _misses
	while Narrator.is_speaking():
		await get_tree().create_timer(0.1).timeout
		if run != _run or state != State.QUIZ_ASK or _misses != misses:
			return
	for cue: StringName in QUESTION_CUES:
		Narrator.play(cue)
		await Narrator.line_finished
		# Stop if the player answered, left, or another line cut in (it is current while this one ends).
		if run != _run or state != State.QUIZ_ASK or _misses != misses or Narrator.current_cue != &"":
			return


## The lights slam into the game-show look, the rig's spots come on one by one, the screen slides up.
func _slam(run: int) -> void:
	_hide_bubbles()
	Audio.play_sfx(SLAM)
	if _lighting:
		_lighting.set_override("quiz")
	for gargoyle: Gargoyle in [_gar, _goyle]:
		gargoyle.wake(Gargoyle.Eyes.QUIZ)
	_rig.show()
	for spot: Node3D in [$QuizRig/SpotGar, $QuizRig/SpotGoyle, $QuizRig/SpotHotSeat]:
		await get_tree().create_timer(0.25).timeout
		if run != _run:
			return
		spot.show()
		Audio.play_sfx(SLAM, -8.0)
	await get_tree().create_timer(0.25).timeout
	if run != _run:
		return
	Audio.play_sfx(INTRO_HIT, -2.0)
	_sweep.show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	ComicCursor.apply()
	_ui.slide_in()
	_lift_subtitles(true)
	await get_tree().create_timer(0.4).timeout


## Think music, ticking clock and the nonsense timer while the player picks.
func _start_thinking() -> void:
	if Audio.music.stream != THINK_MUSIC:
		_music_before = Audio.music.stream if Audio.music.playing else null
	Audio.play_music(THINK_MUSIC)
	_loop.stop()
	_clock.stream = CLOCK_LOOP
	_clock.play()
	_on_dial_tick()


func _on_answer_selected(_index: int) -> void:
	_say_rotating(_goyle, "final_answer", 2.2)


func _on_answer_locked(index: int) -> void:
	state = State.QUIZ_LOCKED
	var run := _run
	_hide_bubbles()
	_confirm_leave = false
	if Narrator.current_cue in QUESTION_CUES:
		Narrator.stop() # Its silent reading time would hold up the next balloons.
	Audio.play_sfx(FINAL_BOOM, -3.0)
	_restore_music()
	_clock.stop()
	_dial_timer.stop()
	_ui.set_dial("???", 1.0)
	_loop.stream = HEARTBEAT
	_loop.play()
	_goyle.gesture("Duck")
	await get_tree().create_timer(randf_range(1.5, 3.0)).timeout
	if run == _run:
		_reveal(index, run)


func _reveal(index: int, run: int) -> void:
	state = State.QUIZ_REVEAL
	_loop.stop()
	if index == QuizContent.QUESTION.correct:
		Audio.play_sfx(CORRECT, -2.0)
		ComicBurst.spawn(_ui, _ui.answer_center(index), "BRILLIANT!", Color("#7dff8a"))
		Narrator.play(&"quiz_correct")
		_ui.mark_correct(index)
		_gar.gesture("Yes")
		_goyle.gesture("Yes")
		await get_tree().create_timer(1.8).timeout
		if run == _run:
			_pass()
		return
	_misses += 1
	Audio.play_sfx(WRONG)
	ComicBurst.spawn(_ui, _ui.answer_center(index), "BRUH.", Color("#ff5a4e"))
	Narrator.play(&"quiz_wrong")
	_ui.mark_wrong(index)
	_gar.gesture("No")
	_goyle.gesture("No")
	_flicker()
	_say_rotating(_gar, "wrong", 2.2)
	await get_tree().create_timer(2.4).timeout
	if run != _run:
		return
	state = State.QUIZ_ASK
	_ui.resume_picking()
	_start_thinking()


## Room lights blink twice (the "you lost" dip).
func _flicker() -> void:
	if not _lighting:
		return
	var tween := create_tween()
	for i in 2:
		tween.tween_callback(_lighting.set_override_level.bind(0.15))
		tween.tween_interval(0.06)
		tween.tween_callback(_lighting.set_override_level.bind(1.0))
		tween.tween_interval(0.06)


func _on_dial_tick() -> void:
	if state != State.QUIZ_ASK:
		return
	var text: String = DIAL_POOL.pick_random()
	_ui.set_dial(text, randf_range(0.1, 1.0))
	Audio.play_sfx(CLOCK_TICK, -10.0)
	if text == "0" and not _clock_zero_said and not _bubbles[_gar].visible:
		_clock_zero_said = true
		_show_for(_gar, QuizContent.LINES.clock_zero, 2.0)
	_dial_timer.start(randf_range(0.6, 1.1))


func _on_lifeline_used(lifeline: StringName) -> void:
	Audio.play_sfx(LIFELINE_SOUND)
	if lifeline == &"phone":
		_hide_bubbles()
		Narrator.play(&"quiz_phone_friend")


## First Esc / WALK AWAY asks (Goyle), the second within a few seconds leaves.
func _on_walk_away() -> void:
	if state != State.QUIZ_ASK:
		return
	if _confirm_leave:
		_leave()
		return
	_confirm_leave = true
	var line := _line + 1
	_show_for(_goyle, "%s\n%s" % [QuizContent.LINES.walk_away, QuizContent.LINES.walk_away_hint], 3.5)
	await get_tree().create_timer(3.5).timeout
	if _line == line:
		_confirm_leave = false


## Walks away: lights, music, mouse and controls back to normal. The streak is kept; X resumes at the slam.
func _leave() -> void:
	_run += 1
	_confirm_leave = false
	state = State.ASLEEP
	_hide_bubbles()
	_end_show()
	_ui.slide_out()
	for gargoyle: Gargoyle in [_gar, _goyle]:
		gargoyle.sleep()
		gargoyle.set_interactable(true)
	_freeze(false)


func _pass() -> void:
	_run += 1
	var run := _run
	state = State.PASSED
	_end_show(0.6)
	_ui.slide_out()
	Audio.play_sfx(HARP, -2.0)
	for gargoyle: Gargoyle in [_gar, _goyle]:
		gargoyle.wake()
	await _play_lines(QuizContent.LINES.passed, run)
	_freeze(false)
	_goyle.gesture("Wave")
	_step_aside(aside_time)
	await get_tree().create_timer(aside_time).timeout
	Story.switch_game_done(GAME) # The switch now offers the restore game.
	Narrator.play(&"quiz_passed")


## The statues slide outward along the wall and turn to face each other across the path. `time` 0 = instantly (on load).
func _step_aside(time: float) -> void:
	for shape: CollisionShape3D in _barrier.get_children():
		shape.set_deferred(&"disabled", true)
	for gargoyle: Gargoyle in [_gar, _goyle]:
		gargoyle.set_interactable(false)
		var home: Transform3D = _home[gargoyle]
		var outward := -1.0 if gargoyle == _gar else 1.0
		var target := Transform3D(Basis(Vector3.UP, 0.0 if gargoyle == _gar else PI), home.origin + Vector3(0, 0, outward * aside_distance))
		if time <= 0.0:
			gargoyle.transform = target
			continue
		var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(gargoyle, "transform", target, time)
	if time > 0.0:
		Audio.play_sfx(GRIND, -4.0)
		Audio.play_sfx(RUMBLE, -8.0)


## Leaves the show look: lights back (fading over `fade`), rig, music, loops, timer, mouse.
func _end_show(fade := 0.4) -> void:
	_lift_subtitles(false)
	if _lighting:
		_lighting.clear_override(fade)
	_set_rig(false)
	_restore_music()
	_loop.stop()
	_clock.stop()
	_dial_timer.stop()
	_ui.accepting = false
	ComicCursor.reset()


## Moves the narrator's subtitles above the quiz strip while it's up (they'd cover the answers),
## and back to their place after.
func _lift_subtitles(on: bool) -> void:
	var label: Label = Narrator.subtitle_label
	if on and _subtitle_offsets.is_empty():
		_subtitle_offsets = [label.offset_top, label.offset_bottom]
		label.offset_top = SUBTITLE_LIFTED_TOP
		label.offset_bottom = SUBTITLE_LIFTED_TOP + (_subtitle_offsets[1] - _subtitle_offsets[0])
	elif not on and _subtitle_offsets:
		label.offset_top = _subtitle_offsets[0]
		label.offset_bottom = _subtitle_offsets[1]
		_subtitle_offsets.clear()


func _set_rig(on: bool) -> void:
	_rig.visible = on
	for light: Node3D in _rig.get_children():
		light.visible = on


func _restore_music() -> void:
	if Audio.music.stream != THINK_MUSIC:
		return
	if _music_before:
		Audio.play_music(_music_before)
	else:
		Audio.stop_music()
		Audio.music.stream = null


## Freezes the player (no walking/looking/HUD) or gives control back with the mouse captured.
func _freeze(on: bool) -> void:
	if not _player:
		return
	_player.frozen = on
	if not on:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


## Moves the player onto the hot seat facing the statues (both above the quiz strip).
func _go_to_hot_seat() -> void:
	if not _player:
		return
	var seat := _quiz_view.global_position
	var tween := create_tween().set_parallel().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_player, "global_position", Vector3(seat.x, _player.global_position.y, seat.z), 0.5)
	var yaw: float = _player.rotation.y + wrapf(_quiz_view.global_rotation.y - _player.rotation.y, -PI, PI)
	tween.tween_property(_player, "rotation:y", yaw, 0.5)
	tween.tween_property(_player.head, "rotation:x", deg_to_rad(hot_seat_pitch), 0.5)


## Plays balloon lines ([speaker, text, gesture?, other's gesture?]) one after another, each waiting
## for the narrator to finish first, then for a key/click or its reading time.
func _play_lines(lines: Array, run: int) -> void:
	for line: Array in lines:
		while Narrator.is_speaking():
			await get_tree().create_timer(0.2).timeout
			if run != _run:
				return
		var speaker: Gargoyle = _goyle if line[0] == "GOYLE" else _gar
		if line.size() > 2:
			speaker.gesture(line[2])
		if line.size() > 3:
			(_gar if speaker == _goyle else _goyle).gesture(line[3])
		_say(line[0], line[1])
		await _wait_line(_read_time(line[1]))
		if run != _run:
			return
	_hide_bubbles()


func _wait_line(seconds: float) -> void:
	_line += 1
	var line := _line
	get_tree().create_timer(seconds).timeout.connect(func() -> void:
		if line == _line:
			_advanced.emit())
	await _advanced


## Shows `text` in the speaker's balloon (both for "BOTH") and makes them talk.
func _say(speaker: String, text: String) -> void:
	_hide_bubbles()
	for gargoyle: Gargoyle in [_gar, _goyle]:
		if speaker == "BOTH" or speaker == gargoyle.display_name:
			_bubbles[gargoyle].say(gargoyle.display_name, text, gargoyle.bubble_anchor)
			_talk(gargoyle, text)


## A balloon that hides itself after `seconds` (unless another one replaced it).
func _show_for(gargoyle: Gargoyle, text: String, seconds: float) -> void:
	_say(gargoyle.display_name, text)
	_line += 1
	var line := _line
	await get_tree().create_timer(seconds).timeout
	if line == _line:
		_hide_bubbles()


## The next line of a rotating list in QuizContent.LINES (e.g. "wrong", "final_answer").
func _say_rotating(gargoyle: Gargoyle, list: String, seconds: float) -> void:
	var lines: Array = QuizContent.LINES[list]
	var index: int = _lines_said.get(list, randi() % lines.size())
	_lines_said[list] = (index + 1) % lines.size()
	_show_for(gargoyle, lines[index], seconds)


## Head wobble + a soft stone blip per word while the words "come out".
func _talk(gargoyle: Gargoyle, text: String) -> void:
	gargoyle.talking = true
	var tween := create_tween()
	for word in mini(text.split(" ", false).size(), 14):
		tween.tween_callback(Audio.play_sfx.bind(_blips, -18.0))
		tween.tween_interval(WORD_BLIP_TIME)
	tween.tween_callback(func() -> void: gargoyle.talking = false)


func _hide_bubbles() -> void:
	for gargoyle: Gargoyle in _bubbles:
		_bubbles[gargoyle].hide()
		gargoyle.talking = false


func _read_time(text: String) -> float:
	return maxf(MIN_LINE_TIME, text.length() / READ_CHARS_PER_SECOND)


func _advance_pressed(event: InputEvent) -> bool:
	if event.is_action_pressed("interact") or event.is_action_pressed("touch"):
		return true
	return event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE
