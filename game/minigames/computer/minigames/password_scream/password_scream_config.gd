class_name PasswordScreamConfig
extends MinigameConfig
## Tunables for the VoiceLogin password screen (say/scream your password; it fails on purpose).
## Edit password_scream_default.tres. `prompts`, `fail_lines` and `fail_cues` are per attempt, in
## order; `screams_needed` of them play before the text box appears.

## Peak loudness (dB) that counts as a scream. Tune per mic.
@export var threshold_db := -20.0
## Seconds it has to stay that loud.
@export var scream_time := 0.4
## Attempts (scripted fails) before the text box shows up; at most the size of `fail_lines`.
@export var screams_needed := 2

## Shown while listening, one per attempt.
@export var prompts: Array[String] = [
	"Please say your password out loud.",
	"One more time. Clearly.",
]
## The (always failing) verdict after each attempt.
@export var fail_lines: Array[String] = [
	"We couldn't hear you.",
	"Still nothing.",
]
## Narrator cue after each verdict (empty = none).
## (The 2nd attempt says nothing: `type_cue` follows right after it.)
@export var fail_cues: Array[StringName] = [&"mic_too_quiet", &""]
## Played instead of the first verdict cue when there is no mic access (the waveform is faked).
@export var no_mic_cue := &"mic_no_access"
@export var accepted_cue := &"mic_accepted"
## When the text box appears.
@export var type_cue := &"password_type_instead"
@export var accepted_line := "Password accepted. It was 'password'. Everyone could hear it, by the way."

@export_group("Attempt gags (1-based attempt numbers)")
## This verdict waits for a [No] button (0 = never; the verdicts say nothing was heard).
@export var no_button_attempt := 0
## From this verdict on the microphone droops.
@export var droop_attempt := 2

@export_group("Timing")
## Seconds of quiet after speaking that end the attempt.
@export var quiet_time := 0.8
## Seconds without any voice before an attempt ends anyway.
@export var listen_timeout := 3.5
## Seconds an attempt never lasts longer than, even when the player keeps talking.
@export var max_listen_time := 3.5
@export var processing_time := 1.2
@export var verdict_time := 2.8
## Seconds the input needs to be dead silent before the fake waveform shows (visual only: a working
## mic can be silent too, e.g. while starting up or with noise suppression in a quiet room).
@export var fake_after := 0.6
## Seconds of running mic without a single non-zero sample (desktop) or with the web permission
## prompt still unanswered before the narrator may say there's no mic access (see has_no_access()).
@export var no_access_after := 3.0
