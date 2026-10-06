extends Node
## Autoload "Story": the main story as a linear list of steps (the current one is kept in
## `GameState.story_step`). Advances when the queued computer minigame is beaten or the power
## comes back on; each scene derives what it shows from the current step (the office: see
## `world/office/story_stage.gd`), so reloading a scene always shows the right state.
## The power comes back once the step's switch games (`SWITCH_GAMES`) are beaten.
## Debug builds: F7 (`debug_next_story_step`) skips to the next step and reloads the office; F8 toggles
## the ESDF control shift (see `Controls`).

signal step_changed(step: Step)
## Emitted when the current switch game changes (new step, or one was beaten); empty = none.
signal switch_game_changed(id: StringName)

enum Step {
	INTRO, ## At the computer: minigame 1 (the game starts here).
	SWITCH_1, ## Lights out: flip the switch in the server room (C1).
	COMPUTER_2, ## Back to the desk: minigame 2.
	SWITCH_2, ## Lights out, and the server room has swapped places with A3.
	COMPUTER_3, ## Back to the desk: minigame 3.
	SWITCH_3, ## Lights out again; the server room stays in A3.
	FREE_ROAM, ## End of the current content.
}

const OFFICE := "res://world/office/office.tscn"
## Computer minigames each computer visit plays, in order (registry ids, see
## minigames/computer/minigame_registry.tres). Edit these lists to change a visit; the step ends
## once the whole list is beaten.
const FIRST_VISIT: Array[StringName] = [&"password_scream", &"font_picker", &"ad_storm"]
const SECOND_VISIT: Array[StringName] = [&"corporate_speak"]
const THIRD_VISIT: Array[StringName] = [&"memo_mail"]
const MINIGAMES := {Step.INTRO: FIRST_VISIT, Step.COMPUTER_2: SECOND_VISIT, Step.COMPUTER_3: THIRD_VISIT}
## Narrator line when the lights go out in each switch step.
const BLACKOUT_CUES := {Step.SWITCH_1: &"lights_out_1", Step.SWITCH_2: &"lights_out_2", Step.SWITCH_3: &"lights_out_3"}
## Switch games each blackout plays, in order: an obstacle (to get at the switchboard), then a
## restore game (finishing it turns the power back on). Ids are listed in
## minigames/switch/switch_games.gd; progress through a pair is `GameState.switch_progress`.
const SWITCH_GAMES := {
	Step.SWITCH_1: [&"screwdriver", &"wires"],
	Step.SWITCH_2: [&"gargoyles", &"valve"],
	Step.SWITCH_3: [&"kaleidoscope", &"candle"],
}
## Narrator line for the next office load after entering a step.
const ARRIVAL_CUES := {Step.COMPUTER_2: &"switch_fixed_1", Step.COMPUTER_3: &"switch_fixed_2", Step.FREE_ROAM: &"to_be_continued"}
## Escalating lines when the player wanders off the objective (see story_stage.gd), in order.
const OFF_PATH_CUES: Array[StringName] = [&"off_path_1", &"off_path_2", &"off_path_3", &"off_path_4"]
## From this step on the controls are shifted one key to the right (WASD → ESDF, X → C; see `Controls`).
const CONTROLS_SHIFT_STEP := Step.SWITCH_3
## Played once the shift's blackout line (`BLACKOUT_CUES[CONTROLS_SHIFT_STEP]`) has finished.
const CONTROLS_SHIFT_CUE := &"controls_shift"
## Played when the player presses W or A (by position) after the shift was explained.
const CONTROLS_SHIFT_W_CUE := &"controls_shift_w"

## The current step (stored in GameState so it sits with the rest of the persistent state).
var step: Step:
	get:
		return GameState.story_step as Step

## Line the office plays when it next loads (see `take_arrival_cue`).
var _arrival_cue := &""
## Off-path lines played in the current step, so they escalate and reset with each new step.
var _off_path_count := 0
## True until the game opens the computer for the intro (only on a fresh start).
var _fresh_start := true
## The opening line waits for the computer scene, so the scene change doesn't cut it.
var _intro_pending := false
## The controls just shifted and `CONTROLS_SHIFT_CUE` hasn't been played yet.
var _controls_cue_pending := false


func _ready() -> void:
	GameState.computer_queue_finished.connect(_on_computer_queue_finished)
	GameState.power_changed.connect(_on_power_changed)
	get_tree().scene_changed.connect(_on_scene_changed)
	Narrator.line_finished.connect(_on_line_finished)
	_go_to(GameState.story_step as Step)


func is_switch_step() -> bool:
	return step in BLACKOUT_CUES


## True once the server room has swapped places with A3 (from the second blackout on).
func is_swapped() -> bool:
	return step >= Step.SWITCH_2


## The switch game to play next in this switch step, or empty (not a switch step / all beaten).
func switch_game() -> StringName:
	var games: Array = SWITCH_GAMES.get(step, [])
	return games[GameState.switch_progress] if GameState.switch_progress < games.size() else &""


## Call when switch game `id` is beaten (ignored if it isn't the current one). Beating the last one of
## the step restores the power, which moves the story on.
func switch_game_done(id: StringName) -> void:
	if id.is_empty() or id != switch_game():
		return
	GameState.switch_progress += 1
	switch_game_changed.emit(switch_game())
	if switch_game().is_empty():
		GameState.set_power(true)


## Where a close-up switch game goes once beaten: straight into the next game's scene, or back to
## the office (all done, or the next game is in-world).
func next_switch_scene() -> String:
	var path := SwitchGames.scene(switch_game())
	return path if path else OFFICE


## The office calls this on its first load: true once, on a fresh start, to begin at the computer.
func take_fresh_start() -> bool:
	var fresh := _fresh_start and step == Step.INTRO
	_fresh_start = false
	_intro_pending = fresh
	return fresh


func take_arrival_cue() -> StringName:
	var cue := _arrival_cue
	_arrival_cue = &""
	return cue


## The next escalating off-path line, or empty once all of them were played this step.
func next_off_path_cue() -> StringName:
	if _off_path_count >= OFF_PATH_CUES.size():
		return &""
	_off_path_count += 1
	return OFF_PATH_CUES[_off_path_count - 1]


func _go_to(new_step: Step) -> void:
	GameState.story_step = new_step
	GameState.switch_progress = 0
	GameState.scope_password = ""
	GameState.scope_target = 0
	GameState.has_scope = false
	GameState.scope_solved = false
	_off_path_count = 0
	_arrival_cue = ARRIVAL_CUES.get(new_step, &"")
	if new_step in MINIGAMES:
		Computer.queue(MINIGAMES[new_step], false) # The visit ends with Computer.blackout(), not an exit.
	_sync_unlocks()
	_sync_controls()
	step_changed.emit(new_step)
	switch_game_changed.emit(switch_game())


## The desk computer works while the power is on and nothing needs fixing; the switch only while it's off.
func _sync_unlocks() -> void:
	if GameState.power_on and not is_switch_step():
		GameState.unlock(Unlocks.COMPUTER)
	else:
		GameState.lock(Unlocks.COMPUTER)
	if GameState.power_on:
		GameState.lock(Unlocks.SWITCHBOARD)
	else:
		GameState.unlock(Unlocks.SWITCHBOARD)


## Derived from the step, so debug skips and scene reloads stay right with no extra state.
func _sync_controls() -> void:
	var was := Controls.shifted
	Controls.set_shifted(step >= CONTROLS_SHIFT_STEP)
	_controls_cue_pending = Controls.shifted and not was


func _on_line_finished(cue_id: StringName) -> void:
	if _controls_cue_pending and cue_id == BLACKOUT_CUES.get(CONTROLS_SHIFT_STEP):
		_play_controls_cue.call_deferred() # Not from inside Narrator.play() (an interrupt emits this too).


func _play_controls_cue() -> void:
	if _controls_cue_pending and not Narrator.is_speaking():
		_controls_cue_pending = false
		Narrator.play(CONTROLS_SHIFT_CUE)


## A beaten visit ends with the computer itself cutting the power (the office loads already dark).
func _on_computer_queue_finished() -> void:
	if step in MINIGAMES:
		_go_to(step + 1 as Step)
		var computer := get_tree().current_scene as Computer
		if computer:
			computer.blackout()


func _on_power_changed(on: bool) -> void:
	if on and is_switch_step():
		_go_to(step + 1 as Step)
		return
	if not on and is_switch_step():
		_arrival_cue = BLACKOUT_CUES[step] # The office plays it (now, or on its next load).
	_sync_unlocks()


func _on_scene_changed() -> void:
	if _intro_pending and get_tree().current_scene is Computer:
		_intro_pending = false
		Narrator.play(&"story_intro")


func _unhandled_input(event: InputEvent) -> void:
	if OS.is_debug_build() and event.is_action_pressed("debug_next_story_step"):
		_debug_skip()
		return
	var key := event as InputEventKey
	if not key or not key.pressed or key.echo:
		return
	if OS.is_debug_build() and key.physical_keycode == KEY_F8:
		Controls.set_shifted(not Controls.shifted)
		print("Story: controls ", "shifted (ESDF, C)" if Controls.shifted else "normal (WASD, X)")
	elif Controls.shifted and key.physical_keycode in [KEY_W, KEY_A] \
			and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not Narrator.is_speaking():
		# Walking around (not typing), and never over another line (e.g. the blackout's directions).
		Narrator.play(CONTROLS_SHIFT_CUE if _controls_cue_pending else CONTROLS_SHIFT_W_CUE)
		_controls_cue_pending = false


## Finishes the current step as if the player did it, then (re)loads the office.
func _debug_skip() -> void:
	if step == Step.FREE_ROAM:
		return
	print("Story: skipping ", Step.keys()[step])
	if step in MINIGAMES:
		GameState.computer_queue.clear()
		_go_to(step + 1 as Step)
	elif not GameState.power_on:
		GameState.set_power(true) # Advances through _on_power_changed.
	else:
		_go_to(step + 1 as Step) # Switch step before the blackout happened.
	Transition.change_scene(OFFICE)
