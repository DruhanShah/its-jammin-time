class_name AntivirusDownloadConfig
extends MinigameConfig
## Tunables for the visit-2 antivirus download that only moves while the player cranks it (rolling the
## keys around G clockwise). Edit antivirus_download_default.tres.

## Full turns of the key ring (6 keys = 360°) from 0 % to 100 %.
@export var rotations_to_finish := 5.0
## Dial degrees per key-ring degree (the crank turns faster than the fingers).
@export var spin_ratio := 2.0
## Seconds without a clockwise step before the download starts slipping back.
@export var slip_delay := 1.0
## Percent per second lost while slipping (down to the highest checkpoint reached).
@export var slip_rate := 6.0
## Slipping and turning the wrong way stop at the highest of these the player has reached.
@export var checkpoints: Array[float] = [25.0, 50.0, 75.0]
## Seconds before an unclicked dial gets the narrator's nudge.
@export var dial_nudge_after := 8.0
## Seconds between 100 % and complete() (the self-spinning "quarantine" bit).
@export var finish_hold := 2.5
## Dial degrees per second once it's done ("now it spins by itself").
@export var done_spin := 720.0

@export_group("Text")
@export var title := "ZappWare Total Defence 3000 - Installer"
@export var heading := "ZappWare Total Defence 3000"
@export var file_text := "Downloading ZappWare_Setup_FINAL_v2.exe (4.7 GB)"
@export var waiting_text := "Download paused: waiting for user input"
@export var restart_text := "Previous download corrupted. Starting over."
## Status line by progress: [percent, text], ascending. From `alarm_from` % on it is red.
@export var status_texts: Array = [
	[0.0, "Connecting to ZappWare servers (a hamster)..."],
	[10.0, "Downloading virus definitions..."],
	[25.0, "Downloading definitions of the word 'virus'..."],
	[40.0, "Downloading more crank..."],
	[55.0, "Unpacking (it brought a lot of luggage)..."],
	[70.0, "Scanning your office for threats..."],
	[85.0, "THREAT FOUND: ELECTRICITY (120 sources)"],
	[95.0, "Preparing to protect you from it..."],
]
@export var alarm_from := 85.0
@export var done_text := "Quarantining 120 lights..."
@export var speed_text := "Speed: %d RPM    Time remaining: up to you"

@export_group("Narrator cues")
## When the installer appears (team script: "Download antivirus").
@export var intro_cue := &"av_download_intro"
@export var bar_click_cue := &"av_bar_click"
@export var dial_nudge_cue := &"av_dial_nudge"
@export var engaged_cue := &"av_engaged"
@export var slipping_cue := &"av_slipping"
@export var wrong_way_cue := &"av_wrong_way"
@export var dial_again_cue := &"av_dial_again"
@export var halfway_cue := &"av_halfway"
@export var done_cue := &"av_done"

@export_group("Sounds")
## One per key step (an AudioStreamRandomizer).
@export var ratchet_sfx: AudioStream
@export var ratchet_db := -6.0
## Pitch of the slow ticks while it slips back.
@export var slip_pitch := 0.7
@export var slip_tick := 0.25
## Once per full turn of the crank.
@export var creak_sfx: AudioStream
@export var creak_db := -14.0
## The dial turning into a crank.
@export var engage_sfx: AudioStream
@export var engage_db := -4.0
## The pawl catching at a checkpoint.
@export var clack_sfx: AudioStream
@export var clack_db := -6.0
@export var done_sfx: AudioStream
@export var done_db := -4.0
