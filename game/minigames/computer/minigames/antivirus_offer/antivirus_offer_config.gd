class_name AntivirusOfferConfig
extends MinigameConfig
## Tunables for the visit-2 antivirus pop-up (a window without a close X). Edit antivirus_offer_default.tres.

## Seconds after the step starts before the pop-up appears (the player sees the word processor first).
@export var appear_delay := 0.8
## Seconds without a click on the window before the DOWNLOAD button wiggles and the narrator nudges.
@export var nudge_after := 12.0
## The window snaps back to the middle when less than this fraction of it is left on screen after a drag.
@export var min_on_screen := 0.6

@export_group("Text")
@export var title := "ZappWare Total Defence 3000 - FREE*"
@export var headline := "WARNING! 4,096 VIRUSES DETECTED*"
@export_multiline var body := "Your comic is UNPROTECTED. ZappWare zaps viruses, malware, bugs and anything else that uses electricity."
@export var fine_print := "*number made up for marketing purposes"
@export var tagline := "Protects you from everything. Even the things you need."
@export var download_text := "DOWNLOAD NOW (FREE*)"
@export var later_text := "Remind me later"
@export var later_again_text := "Remind me NOW"

@export_group("Narrator cues")
@export var intro_cue := &"av_offer_intro"
## First click where the X should be (or Esc).
@export var no_x_cue := &"av_no_x"
## Every later one (only while the narrator is quiet).
@export var no_x_again_cue := &"av_no_x_again"
@export var remind_cue := &"av_remind_later"
@export var drag_away_cue := &"av_drag_away"
@export var nudge_cue := &"av_offer_nudge"

@export_group("Sounds")
@export var refuse_sfx: AudioStream
@export var refuse_db := -6.0
@export var download_sfx: AudioStream
@export var download_db := -4.0
