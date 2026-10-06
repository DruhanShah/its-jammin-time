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
@export var screams_needed := 5

## Shown while listening, one per attempt.
@export var prompts: Array[String] = [
	"Please say your password out loud.",
	"Please try again.",
	"One more time. Clearly.",
	"Try again. In Comic Sans this time.",
	"LOUDER.",
]
## The (always failing) verdict after each attempt.
@export var fail_lines: Array[String] = [
	"Sorry, I didn't catch that.",
	"Did you say: \"pastry bird\"?",
	"Please speak in Comic Sans.",
	"Audio received. Audio not processed. (Budget cuts.)",
	"Too loud. HR has been notified.",
]
## Narrator cue after each verdict (empty = none).
@export var fail_cues: Array[StringName] = [&"password_again", &"mic_pastry_bird", &"mic_comic_sans", &"mic_budget_cuts", &"mic_five_times"]
## Verdict of the first attempt when nothing was heard.
@export var silent_line := "We couldn't hear you."
@export var intro_cue := &"password_intro"
## Played (once) on the first attempt with nothing heard.
@export var silent_cue := &"mic_silent"
@export var close_refused_cue := &"mic_close_refused"
@export var accepted_cue := &"mic_accepted"
## When the text box appears.
@export var type_cue := &"password_type_instead"
@export var accepted_line := "Password accepted. It was 'password'. Everyone could hear it, by the way."

@export_group("Attempt gags (1-based attempt numbers)")
## This verdict waits for a [No] button.
@export var no_button_attempt := 2
## From this verdict on the waveform is drawn in wobbly comic style.
@export var comic_wave_attempt := 3
## From this verdict on the microphone droops.
@export var droop_attempt := 4
## The waveform panel shakes while listening on this attempt.
@export var shake_attempt := 5

@export_group("Timing")
## Seconds of quiet after speaking that end the attempt.
@export var quiet_time := 0.8
## Seconds without any voice before an attempt ends anyway.
@export var listen_timeout := 6.0
## Seconds an attempt never lasts longer than, even when the player keeps talking.
@export var max_listen_time := 10.0
@export var processing_time := 1.2
@export var verdict_time := 2.8
## Seconds the mic needs to be dead silent (no device, permission denied) before the fake waveform.
@export var fake_after := 1.5
