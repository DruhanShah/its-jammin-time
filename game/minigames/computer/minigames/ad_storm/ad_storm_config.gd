class_name AdStormConfig
extends MinigameConfig
## Tunables for the visit-1 ad storm (ad_storm.gd): scripted typing, then waves of comic ads, then the
## ECO MODE ad that turns the lights off. Edit ad_storm_default.tres.

## Typed one character per keypress whatever the player presses (spaces/newlines ride along).
@export_multiline var script_text := ""
## Typed in a loop once the script runs out.
@export var filler := "and then "
## Characters that count as "1 page" for the goal line (never reached: that's the joke).
@export var page_chars := 1800
## Status bar goal line; %d = percent of the page.
@export var goal_text := "comic_script_FINAL_final2.cmc · target: 1 page · %d%%"

@export_group("Triggers")
## Keypresses before the first ad.
@export var first_ad_after_keys := 3
## Seconds without typing before wave 1 starts anyway.
@export var wait_typing_idle := 15.0
## After wave 1 is cleared: keypresses (or idle seconds) before wave 2.
@export var next_wave_keys := 6
@export var next_wave_idle := 8.0
## After wave 2 is cleared: keypresses (or idle seconds) before the ECO MODE ad.
@export var eco_after_keys := 4
@export var eco_idle := 5.0

@export_group("Waves")
## Wave 1: one ad at a time, in this order.
@export var wave1_headlines: Array[String] = [
	"LIGHT BULBS 90% OFF: limited time, limited light",
	"HOT SINGLE FONTS IN YOUR AREA (Comic Sans wants to meet you)",
	"Download more overtime FREE",
]
## Seconds between one wave-1 ad closing and the next.
@export var wave1_gap := 0.6
## Seconds between the four wave-2 ads popping up.
@export var wave2_stagger := 0.3
## Wave 2 headlines: runner, nested, fake X, countdown.
@export var wave2_headlines: Array[String] = [
	"CATCH ME IF YOU CAN (the X, I mean)",
	"Close me. I dare you.",
	"Your PC is SLOW. Click X to speed up",
	"Watch this 5-second ad about light bulbs",
]
## ECO accepted: the screen dims twice over this many seconds before complete().
@export var screen_dip_time := 0.9

@export_group("Narrator cues")
@export var first_cue := &"ads_first"
@export var eco_cue := &"ads_eco"

@export_group("Sounds")
@export var type_sfx: AudioStream
@export var type_sfx_db := -8.0
